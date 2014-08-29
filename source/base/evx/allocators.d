module evx.allocators;

private {/*imports}*/
	private {/*std}*/
		import std.exception;
		import std.range;
		import std.conv;
	}
	private {/*evx}*/
		import evx.search;
		import evx.utils;
		import evx.math;
		import evx.arrays;
		import evx.move;
	}

	alias zip = evx.functional.zip;
	alias map = evx.functional.map;
}

/* Resources 

	Resources are handles to contigious arrays of data, manually allocated with 
		Allocators. They are a strictly-controlled, high-speed replacement for 
		D Arrays.

	Resources themselves do not support any Range primitives, but do offer mutable 
		indexing, slicing and appending.
	Since the Resource's underlying data is contigious, slicing it returns an Array, 
		which can then be manipulated as a RandomAccessRange.
	Since the Resource's size is declared in advance, appending never allocates. 
		It is an error to append to a Resource beyond its capacity.
	Because Resources are reference types, they are able to maintain 
		correctness even if the Allocator moves the data in memory. 

	Allocators automatically track allocated Resources, which must be manually freed.
*/

struct Allocator (T, Id = Index)
	{/*...}*/
		public:
		public {/*allocation}*/
			static if (is (Id == Index))
				{/*auto-assigned id}*/
					static Index generator;
					auto allocate (Index size)
						{/*...}*/
							return allocate (size, ++generator);
						}
					auto save (R)(R range)
						{/*...}*/
							return save (range, ++generator);
						}
					void allocate_and_save (R)(Index size, R range)
						{/*...}*/
							static Index i;
							return allocate_and_save (size, range, ++generator);
						}
				}

			auto allocate (Index size, Id id)
				in {/*...}*/
					assert (not (free_list.empty), T.stringof ~` allocator not initialized`);
				}
				body {/*...}*/
					foreach (i, ref interval; free_list)
						{/*find free interval}*/
							if (interval.size >= size)
								{/*allocate memory}*/
									resources.insert (id, Resource (interval.start, size));
									interval.start = interval.start + size;

									if (interval.empty)
										free_list.shift_down_on (i);

									return ResourceHandle (this, id);
								}
						}
					assert (0, Allocator.stringof~` insufficient memory! 
						requested:
							` ~size.text~ `
						free: 
							`~free_list.text~`
						used:
							`~resources.text
					);
				}
			auto save (R)(R range, Id id)
				if (isForwardRange!R)
				{/*...}*/
					auto saved = range.save;

					auto resource = allocate (saved.length, id);

					resource ~= range;

					return resource;
				}
			void allocate_and_save (R)(Index size, R range, Id id)
				if (isForwardRange!R)
				in {/*...}*/
					auto saved = range.save;
					assert (saved.length <= size);
				}
				body {/*...}*/
					auto resource = allocate (size, id);

					resource ~= range;
 
					return resource;
				}
		}
		public {/*upkeep}*/
			void free (Id id)
				{/*...}*/
					auto A = fetch (id).bounds;

					auto result = free_list[].binary_search!(starts_before_start!Index) (A);
					auto i = result.position;

					assert (not (result.found), `attempted to free interval which is already free`);

					bool merged;
					if (i < free_list.length)
						{/*check right interval}*/
							auto B = &free_list[i];

							if (A.end == B.start)
								{/*merge left}*/
									B.start = A.start;
									merged = true;
								}
						}
					if (i > 0) 
						{/*check left interval}*/
							auto B = &free_list[i-1];
							
							if (A.start == B.end)
								{/*merge right}*/
									if (merged)
										{/*merge again and prune}*/
											free_list[i].start = B.start;
											free_list.shift_down_on (i-1);
										}
									else {/*just merge}*/
										B.end = A.end;
										merged = true;
									}
								}
						}
					if (not (merged))
						{/*insert}*/
							free_list.shift_up_from (i);
							free_list[i] = A;
						}

					resources.remove (id);
				}
			void defrag () // TODO
				{/*...}*/
				}
		}
		public @property {/*}*/
			@property auto capacity ()
				{/*...}*/
					return pool.length;
				}
		}
		public {/*ctor}*/
			this (size_t capacity = 2^^14, size_t max_resources = 2^^12)
				{/*...}*/
					pool = Array!T (capacity);

					free_list = typeof(free_list) (max_resources);
					free_list ~= Indices (0, capacity);

					resources = typeof(resources) (max_resources);
				}
		}
		private:
		private {/*resources}*/
			struct Resource
				{/*...}*/
					this (Index start, Index capacity)
						{/*...}*/
							bounds = interval (start, start + capacity);
						}

					Index length;
					Indices bounds;

					invariant (){/*...}*/
						assert (length <= bounds.size);
					}
				}
			struct ResourceHandle
				{/*...}*/
					private {/*contract}*/
						static assert (not (isInputRange!ResourceHandle));
						static assert (isRandomAccessRange!(typeof(this[])));
						static assert (isOutputRange!(ResourceHandle, T));
					}
					public:
					public {/*[i]}*/
						ref auto opIndex (Index i)
							in {/*...}*/
								assert_allocated;
								assert (i < length, `range violation`);
							}
							body {/*...}*/
								return this[][i];
							}
					}
					public {/*[i..j]}*/
						auto opSlice (Index start, Index end)
							in {/*...}*/
								assert (start <= end, `range reversed`);
								assert (end <= length, `range violation [`
									~ start.text ~ `..` ~ end.text ~ `]` 
									` exceeds ` ~ length.text
								);
							}
							body {/*...}*/
								return this[][start..end];
							}
						auto opSliceAssign (U)(U that, Index start, Index end)
							{/*...}*/
								static if (isInputRange!U)
									that.copy (this[start..end]);
								else this[start..end] = that.repeat (end - start);
							}
						auto opSliceOpAssign (string op, U)(U that, Index start, Index end)
							{/*...}*/
								static if (isInputRange!U)
									mixin(q{
										this[start..end] = this[start..end].zip (that)
											.map!(τ => τ[0] }~op~q{ τ[1]);
									});
								else mixin(q{
									this[start..end] }~op~q{= that.repeat (end-start);
								});
							}
						auto opSliceUnary (string op)(Index start, Index end)
							{/*...}*/
								mixin(q{
									return this[start..end].map!(a => }~op~q{ a);
								});
							}
					}
					public {/*[]}*/
						auto opSlice ()
							in {/*...}*/
								assert_allocated;
							}
							body {/*...}*/
								return allocator.slice (id);
							}
						auto opSliceAssign (U)(U that)
							in {/*...}*/
								static if (isInputRange!U)
									assert (this.length == that.length, `dimension mismatch for `~this[].text~` = `~that.text);
							}
							body {/*...}*/
								static if (isInputRange!U)
									that.copy (this[]);
								else this[] = that.repeat (this.length);
							}
						auto opSliceOpAssign (string op, U)(U that)
							in {/*...}*/
								static if (isInputRange!U)
									assert (this.length == that.length, `dimension mismatch for `~this[].text~` `~op~` `~that.text);
							}
							body {/*...}*/
								static if (isInputRange!U)
									mixin(q{
										this[] = this[].zip (that).map!(τ => τ[0] } ~op~ q{ τ[1]);
									});
								else mixin(q{
									this[] = this[].map!(a => }~op~q{ that);
								});
							}
						auto opSliceUnary (string op)()
							{/*...}*/
								mixin(q{
									return this[].map!(a => }~op~q{ a);
								});
							}
					}
					public {/*$}*/
						auto opDollar () 
							{/*...}*/
								return length;
							}
					}
					public {/*~=}*/
						@disable auto opBinary (string op: `~`, U)(U);
						auto opOpAssign (string op: `~`, U)(U that)
							{/*...}*/
								this.put (that);
							}
					}
					public {/*=}*/
						void opAssign ()(auto ref ResourceHandle that)
							{/*...}*/
								this.swap (that);
							}
					}
					public {/*output}*/
						auto put (U)(U that)
							in {/*...}*/
								assert_allocated;
								static if (hasLength!U || isForwardRange!U)
									assert (length + that.length <= allocator.capacity_of (id), 
										`range overflow: ` ~ (length + that.length).text ~ ` exceeds ` 
										~ allocator.capacity_of (id).text
									);
								else assert (length + 1 <= allocator.capacity_of (id), `range overflow`);
							}
							body {/*...}*/
								static if (isInputRange!U && hasLength!U)
									{/*...}*/
										auto start = this.length;
										this.length += that.length;

										assert (that.length, `range was exhausted after length check. `~isForwardRange!U? `it was a forward range`:``);

										this[start..length] = that;
									}
								else {/*...}*/
									++length;

									(&this[$-1])[0..1] = (&that)[0..1];
								}
							}
					}
					@property {/*length}*/
						ref auto length ()
							in {/*...}*/
								assert_allocated;
							}
							body {/*...}*/
								return allocator.length_of (id);
							}
					}
					@property {/*capacity}*/
						Index capacity ()
							in {/*...}*/
								assert_allocated;
							}
							body {/*...}*/
								return allocator.capacity_of (id);
							}
					}
					@property {/*clear}*/
						void clear ()
							{/*...}*/
								length = 0;
							}
					}
					public {/*dtor}*/
						~this ()
							{/*...}*/
								if (is_allocated)
									allocator.free (id);
							}
					}
					public {/*status}*/
						bool is_allocated ()
							{/*...}*/
								return allocator !is null;
							}
					}
					private:
					private {/*data}*/
						Allocator* allocator;
						Id id;
					}
					private {/*ctor}*/
						this (ref Allocator allocator, Id id)
							{/*...}*/
								this.allocator = &allocator;
								this.id = id;
							}
					}
					debug {/*...}*/
						void assert_allocated () 
							{/*...}*/
								assert (this.is_allocated, `attempted to use unallocated Resource`);
							}
					}
				}
		}
		private {/*access}*/
			ref auto fetch (Id id)
				{/*...}*/
					return resources.get (id);
				}
			auto slice (Id id)
				{/*...}*/
					auto resource = fetch (id);
					with (resource.bounds)
					return pool[start..start + resource.length];
				}
			ref auto length_of (Id id)
				{/*...}*/
					return fetch (id).length;
				}
			auto capacity_of (Id id)
				{/*...}*/
					return fetch (id).bounds.size;
				}
		}
		private {/*data}*/
			Array!T pool;
			Appendable!(Array!Indices) free_list;
			Associative!(Array!Resource, Id) resources;
		}
		invariant () {/*assumptions}*/
			string violated (lazy string assumption)
				{/*...}*/
					return `violated assumption: ` ~assumption~ ` ` ~ free_list.text;
				}
			foreach (i, ref interval; free_list)
				{/*...}*/
					assert (interval.start < interval.end, 
						violated (`intervals are non-empty`)
					);
					if (i+1 < free_list.length)
						{/*...}*/
							assert (interval.start < free_list[i+1].start,
								violated (`intervals are ordered`)
							);
							assert (interval.end <= free_list[i+1].start,
								violated (`intervals are non-overlapping`)
							);
						}
				}
		}
	}
	unittest {/*ResourceHandle ops}*/
		auto mem = Allocator!double (10);

		auto X = mem.allocate (5);
		assert (X.capacity == 5);
		assert (X[].length == 0);

		X ~= 1.0;
		assert (X[].length == 1);

		X[] = [2.0];
		assert (X[].length == 1);

		assert (X[0] == 2.0);
		X[0] += 1.0;
		assert (X[0] == 3.0);
		X[0] = 3.0;
		assert (X[0] == 3.0);
		--X[0];
		assert (X[0] == 2.0);

		X ~= [1.0, 2.0, 3.0]; 
		assert (X[].length == 4);
		X[0..3] = [1.0, 2.0, 3.0];
		X[3..4] += 1.0;
		assert (X[] == [1.0, 2.0, 3.0, 4.0]);

		assert (X[].length == 4);
		X[] = 0;
		assert (X[] == [0.0, 0.0, 0.0, 0.0]);

		X.clear;
		assert (X[].length == 0);
		X ~= 1.0.repeat (3);
		assert (X[].length == 3);

		assertThrown!Error (X[] += [1.0]);
		X[] += [1.0, 1.0, 1.0];
		assert (X[] == [2.0, 2.0, 2.0]);
		assert ((-X[]).equal ([-2.0, -2.0, -2.0]));

		assertThrown!Error (X ~= 0.0.repeat (999));
	}
	unittest {/*free_list}*/
		auto mem = Allocator!int (10);
		assert (mem.free_list[].equal ([Indices(0,10)]));

		auto a2 = mem.save (ℕ[0..2]);
		assert (mem.free_list[].equal ([Indices(2,10)]));

		auto a3 = mem.save (ℕ[0..3]);
		assert (mem.free_list[].equal ([Indices(5,10)]));

		auto a4 = mem.save (ℕ[0..4]);
		assert (mem.free_list[].equal ([Indices(9,10)]));

		a3.destroy;
		assert (mem.free_list[].equal (
			[Indices(2,5), Indices(9,10)]
		));

		// overwrite assignment automatically frees allocated data
		a2 = mem.save (ℕ[0..3]);
		assert (mem.free_list[].equal (
			[Indices(0,2), Indices(9,10)]
		));

		a2.destroy;
		assert (mem.free_list[].equal (
			[Indices(0,5), Indices(9,10)]
		));

		a4.destroy;
		assert (mem.free_list[].equal ([Indices(0,10)]));
	}

template Resource (T)
	{/*...}*/
		alias Resource = Allocator!T.ResourceHandle;
	}
