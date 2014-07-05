module resource.allocator;

import std.algorithm;
import std.exception;
import std.range;
import std.ascii;
import std.conv;
import utils;
import math;

import resource.array;
import resource.directory;
/*
	[RAW DATA (capacity)]
		↓ array bounds held by resource
	[RESOURCE (length/capacity)]  ← this intercepts instead of routing through because it is not an IdentityView
		↓ 								
		↓ view slices resource
	[VIEW]
		↓
		to network

*/

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

Resources will automatically free themselves upon destruction. Because of this, they TODO this is no longer true
	are unique and cannot be copied, but they may be moved with the assignment 
	operator (=). This will move the reference information to the LHS Resource and 
	nullify the RHS Resource. Assigning to a non-null Resource will trigger the LHS 
	destructor, freeing the associated data before moving the reference info from 
	the RHS.

Each user of the Allocator is responsible for maintaining its own static list of
	Resources.

*/

alias Index = size_t;
private alias Interval = math.Interval!Index;
// and so you have a static function indexed by entity.id that uses it to pick up a Range from an allocator and slice it
// all i need is an up-to-date, high performance view at all times
// up to date means against moves - so use a look sourced possibly by a pinned member function
// also it means against in-place mutation - the look returns a view, and views take care of that automatically
// looks are for passively up-to-date info (pulls)
// views are for pinned, up-to-date ranges (pulls)
struct Allocator (T, Id = Index)
	{/*...}*/
// TODO make it automatically extend its capacity instead of throwing an "out of memory" error.
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
				{/*...}*/
					foreach (i, ref interval; free_list)
						{/*find free interval}*/
							if (interval.size >= size)
								{/*allocate memory}*/
									resources.append (id, Resource (interval.start, size));
									interval.start += size;

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
							`~resources.text);
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
			this (uint capacity = 2^^12)
				{/*...}*/
					pool = StaticArray!T (capacity);

					free_list = DynamicArray!Interval (100); // REVIEW
					free_list ~= Interval (0, capacity);

					resources = Directory!(Resource, Id) (100); // REVIEW
				}
		}
		private:
		private {/*substructs}*/
			struct Resource
				{/*...}*/
					this (Index start, Index capacity)
						{/*...}*/
							bounds.start = start;
							bounds.end = start + capacity;
						}

					Index length;
					Interval bounds;

					invariant (){/*...}*/
						assert (length <= bounds.size);
					}
				}
			struct ResourceHandle
				{/*...}*/
					private {/*contract}*/
						static assert (not (isOutputRange!(ResourceHandle, T)));
						static assert (not (isInputRange!ResourceHandle));
						static assert (isRandomAccessRange!(typeof(this[])));
						static assert (isOutputRange!(typeof(this[]), T));
					}
					public:
					public {/*[i]}*/
						ref auto opIndex (Index i)
							in {/*...}*/
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
							body {/*...}*/
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
							{/*...}*/
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
							in {/*...}*/
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
									this[$-1] = that;
								}
							}
					}
					@property {/*length}*/
						ref auto length ()
							{/*...}*/
								return allocator.length_of (id);
							}
					}
					@property {/*capacity}*/
						Index capacity ()
							{/*...}*/
								return allocator.capacity_of (id);
							}
					}
					@property {/*clear}*/
						void clear ()
							{/*...}*/
								length = 0;
							}
					}
					@property {/*valid}*/
						bool valid ()
							{/*...}*/
								return allocator? true:false;
							}
					}
					public {/*free}*/
						void free ()
							{/*...}*/
								allocator.free (id);
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
			StaticArray!T pool;
			DynamicArray!Interval free_list;
			Directory!(Resource, Id) resources;
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
template Resource (T)
	{/*...}*/
		alias Resource = Allocator!T.ResourceHandle;
	}

unittest
	{/*ResourceHandle ops}*/
		mixin(report_test!`allocator`);

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
unittest
	{/*free_list}*/
		mixin(report_test!`free list`);

		auto mem = Allocator!int (10);
		assert (mem.free_list[].equal ([Interval(0,10)]));

		auto a2 = mem.save (2.ℕ!int);
		assert (mem.free_list[].equal ([Interval(2,10)]));

		auto a3 = mem.save (3.ℕ!int);
		assert (mem.free_list[].equal ([Interval(5,10)]));

		auto a4 = mem.save (4.ℕ!int);
		assert (mem.free_list[].equal ([Interval(9,10)]));

		a3.free;
		assert (mem.free_list[].equal (
			[Interval(2,5), Interval(9,10)]
		));

		a2.free;
		assert (mem.free_list[].equal (
			[Interval(0,5), Interval(9,10)]
		));

		a4.free;
		assert (mem.free_list[].equal ([Interval(0,10)]));
	}
