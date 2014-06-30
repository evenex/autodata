module resource.allocator;

import std.algorithm;
import std.exception;
import std.range;
import std.ascii;
import std.conv;
import utils;

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
// and so you have a static function indexed by entity.id that uses it to pick up a Range from an allocator and slice it
// all i need is an up-to-date, high performance view at all times
// up to date means against moves - so use a look sourced possibly by a pinned member function
// also it means against in-place mutation - the look returns a view, and views take care of that automatically
// looks are for passively up-to-date info (pulls)
// views are for pinned, up-to-date ranges (pulls)
class Allocator (T, Id = Index)
	{/*...}*/
 // TODO make it automatically extend its capacity instead of throwing an "out of memory" error.
		public:
		public {/*allocation}*/
			static if (is (Id == Index))
				{/*auto-generated id forwarding}*/
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
					foreach (ref range; free_list)
						{/*find free range}*/
							if (range.size >= size)
								{/*allocate memory}*/
									resources.append (Resource (id, range.start, size));
									range.start += size;

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

					auto resource = allocate (range.length, id);
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
					auto saved = range.save;

					auto resource = allocate (size, id);
					resource ~= range;

					return resource;
				}
		}
		public {/*upkeep}*/
			void free (Id id)
				{/*...}*/
					auto R = fetch (id).bounds;
					Range[] left;
					Range[] right; 

					left = free_list.up_to (R);
					if (left.length)
						{/*...}*/
							left.front.end += R.size;
							right = left.find!(S => S.start == R.end);
						}
					else right = free_list.after (R);

					if (right.length && left.length)
						{/*...}*/
							left.front.end = right.front.end;
							free_list.remove (R);
						}
					else if (right.length)
						{/*...}*/
							right.front.start -= R.size;
						}
					else if (left.empty && right.empty)
						{/*...}*/
							free_list.add (R);
						}

					resources.remove (Resource (id,0,0));
				}
			void defrag ()
				{/*...}*/
				}
		}
		public @property {/*}*/
			@property auto capacity ()
				{/*...}*/
					return pool.length;
				}
		}
		public {/*ctor/dtor}*/
			this (uint capacity = 2^^12)
				{/*...}*/
					pool = new T[capacity];
					free_list = new Directory!Range (100);
					resources = new Directory!Resource (100);
					free_list.append (Range (0, capacity));
				}
		}
		private:
		private {/*substructs}*/
			struct Resource
				{/*...}*/
					public:
					int opCmp (ref const Resource that) const
						{/*...}*/
							return compare (this.id, that.id);
						}
					private:
					private {/*ctor}*/
						this (Id id, Index start, Index capacity)
							{/*...}*/
								this.id = id;
								bounds.start = start;
								bounds.end = start + capacity;
							}
					}
					private {/*data}*/
						Id id;
						Index length;
						Range bounds;
					}
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
						auto opSlice (Index start, size_t end)
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
						auto opSliceAssign (U)(U that, Index start, size_t end)
							{/*...}*/
								static if (isInputRange!U)
									that.copy (this[start..end]);
								else this[start..end] = that.repeat (end - start);
							}
						auto opSliceOpAssign (string op, U)(U that, Index start, size_t end) // BUG these copy methods are gonna stomp over themselves. you gotta do in-place mutation with a forloop. bonus - it can be @safe or whatever
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
						auto opSliceUnary (string op)(Index start, size_t end)
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
					private:
					private {/*data}*/
						Allocator allocator;
						Id id;
					}
					private {/*ctor}*/
						this (Allocator allocator, Id id)
							{/*...}*/
								this.allocator = allocator;
								this.id = id;
							}
					}
				}
			struct Range
				{/*...}*/
					Index start;
					Index end;
					@property size () const
						{/*...}*/
							return end-start;
						}
					int opCmp (ref const Range that) const
						{/*...}*/
							if (this.end < that.start)
								return -1;
							else if (this.end == that.start)
								return 0;
							else return 1;
						}
				}
		}
		private {/*access}*/
			ref auto fetch (Id id)
				{/*...}*/
					return resources.get (Resource (id,0,0));
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
			T[] pool;
			Directory!Range free_list;
			Directory!Resource resources;
		}
	}
template Resource (T)
	{/*...}*/
		alias Resource = Allocator!T.ResourceHandle;
	}

unittest
	{/*...}*/
		mixin(report_test!`allocator`);

		scope alloc = new Allocator!double (10);

		auto X = alloc.allocate (5);
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
