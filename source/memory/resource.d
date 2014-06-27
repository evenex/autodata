module memory.resource;

import std.algorithm;
import std.exception;
import std.range;
import std.ascii;
import std.conv;
import utils;

/* Resources

Resources are handles to contigious arrays of data, manually allocated with 
	Allocators. Because Resources are reference types, they are able to maintain 
	correctness even if the Allocator moves the data in memory. 

Resources will automatically free themselves upon destruction. Because of this, they
	are unique and cannot be copied, but they may be moved with the assignment 
	operator (=). This will move the reference information to the LHS Resource and 
	nullify the RHS Resource. Assigning to a non-null Resource will trigger the LHS 
	destructor, freeing the associated data before moving the reference info from 
	the RHS.

Resources themselves do not support any Range primitives, but do offer mutable 
	indexing, slicing and appending.
Since the Resource's underlying data is contigious, slicing it returns an Array, 
	which can then be manipulated as a RandomAccessRange.
Since the Resource's size is declared in advance, appending never allocates. 
	It is an error to append to a Resource beyond its capacity.

*/

class Allocator (T)
	{/*...}*/
 // TODO if this is gonna be a class, might as well make the capacity a ctor arg... 
 // TODO and while we're at it, might as well make it automatically extend its capacity instead of throwing an "out of memory" error.
 // REVIEW on the other hand, it is nice to have buffer sizes listed in the declaration. if done right, we can keep the buffer sizes static and just use a dynamic allocator underneath
		private struct Range
			{/*...}*/
				union {/*bounds}*/
					size_t[2] range; // union
					struct {size_t start, end;}
				}

				@property size_t capacity () const
					{/*...}*/
						return range[1] - range[0];
					}

				@disable this ();
				this (size_t start, size_t capacity)
					{/*...}*/
						range[0] = start;
						range[1] = start + capacity;
					}

				alias range this;
			}
		struct Resource
			{/*...}*/
				static assert (not (isOutputRange!(Resource, T)));
				static assert (not (isInputRange!Resource));
				static assert (isRandomAccessRange!(typeof(this[])));
				static assert (isOutputRange!(typeof(this[]), T));

				public {/*[i]}*/
					auto opIndex (size_t i)
						in {/*...}*/
							assert (i < length, `range violation`);
						}
						body {/*...}*/
							auto R = allocator.allocated[id];

							return allocator.pool[R[0] + i];
						}
					auto opIndexUnary (string op)(size_t i)
						{/*...}*/
							static if (op.length == 1)
								mixin(q{
									auto x = this[i];
									return }~op~q{ x;
								});
							else mixin(q{
								auto x = this[i];
								return this[i] = }~op~q{ x;
							});
						}
					auto opIndexAssign (T)(T that, size_t i)
						{/*...}*/
							auto R = allocator.allocated[id];

							return allocator.pool[R[0] + i] = that;
						}
					auto opIndexOpAssign (string op, T)(T that, size_t i)
						{/*...}*/
							return this[i] = this[i] + that;
						}
				}
				public {/*[i..j]}*/
					auto opSlice (size_t start, size_t end)
						in {/*...}*/
							assert (start <= end, `range reversed`);
							assert (end <= length, `range violation [`
								~ start.text ~ `..` ~ end.text ~ `]` 
								` exceeds ` ~ length.text
							);
						}
						body {/*...}*/
							auto R = allocator.allocated[id];

							return allocator.pool[R[0] + start..R[0] + end];
						}
					auto opSliceAssign (U)(U that, size_t start, size_t end)
						{/*...}*/
							static if (isInputRange!U)
								that.copy (this[start..end]);
							else this[start..end] = that.repeat (end - start);
						}
					auto opSliceOpAssign (string op, U)(U that, size_t start, size_t end)
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
					auto opSliceUnary (string op)(size_t start, size_t end)
						{/*...}*/
							mixin(q{
								return this[start..end] = this.map!(a => }~op~q{ a);
							});
						}
				}
				public {/*[]}*/
					auto opSlice ()
						{/*...}*/
							return this[0..$];
						}
					auto opSliceAssign (U)(U that)
						{/*...}*/
							static if (isInputRange!U)
								length = that.length;
							this[0..$] = that;
						}
					auto opSliceOpAssign (string op, U)(U that)
						in {/*...}*/
							static if (isInputRange!U)
								assert (this.length == that.length, `dimension mismatch for `~this[].text~` `~op~` `~that.text);
						}
						body {/*...}*/
							mixin(q{
								this[0..$] }~op~q{= that;
							});
						}
					auto opSliceUnary (string op)()
						{/*...}*/
							mixin(q{
								return }~op~q{this[0..$];
							});
						}
				}
				public {/*$}*/
					auto opDollar () 
						{/*...}*/
							return length;
						}
				}
				public {/*=}*/
					auto opAssign (Resource that)
						{/*...}*/
							this.id = that.id;
							this.length = that.length;
							this.allocator = that.allocator;

							that.id = Id.init;
							that.length = 0;
							that.allocator = null;
						}
				}
				public {/*~=}*/
					@disable auto opBinary (string op: `~`, U)(U);
					auto opOpAssign (string op: `~`, U)(U that)
						in {/*...}*/
							debug  {/*...}*/
								static if (hasLength!U || isForwardRange!U)
									assert (length + that.length <= allocator.allocated[id].capacity, 
										`range overflow: ` ~ (length + that.length).text ~ ` exceeds ` 
										~ allocator.allocated[id].capacity.text
									);
								else assert (length + 1 <= allocator.allocated[id].capacity, `range overflow`);
							}
						}
						body {/*...}*/
							static if (isInputRange!U && hasLength!U)
								{/*...}*/
									auto start = length;
									this.length = this.length + that.length;

									assert (that.length, `range was exhausted after length check. `~isForwardRange!U? `it was a forward range`:``);

									this[start..length] = that;
								}
							else {/*...}*/
								length = length + 1;
								this[$-1] = that;
							}
						}
				}
				public {/*length}*/
					size_t length = 0; // TODO property set/get w/ debug bounds check
				}
				@property {/*capacity}*/
					size_t capacity ()
						{/*...}*/
							return allocator.allocated[id].capacity;
						}
				}
				@property {/*clear}*/
					void clear ()
						{/*...}*/
							length = 0;
						}
				}
						
				public ~this ()
					{/*...}*/
						if (allocator !is null)
							allocator.free (id);
					}

				private:
				mixin TypeUniqueId;

				this (Allocator allocator, Id id)
					{/*...}*/
						this.allocator = allocator;
						this.id = id;
					}
				@disable this (this);

				Id id;
				Allocator allocator;
				invariant (){/*...}*/
					if (allocator !is null && id != Id.init)
						assert (length <= allocator.allocated[id].capacity);
				}
			}

		auto allocate (size_t size)
			{/*...}*/
				foreach (ref range; free_ranges)
					{/*find free range}*/
						if (range.capacity >= size)
							{/*allocate memory}*/
								auto id = Resource.Id.create;

								allocated[id] = Range (range.start, size);
								range.start += size;

								return Resource (this, id);
							}
					}
				assert (0, Allocator.stringof~` out of memory! 
					free: 
						`~free_ranges.to!string~`
					used:
						`~allocated.to!string);
			}
		void free (Resource.Id id) 
			{/*...}*/
				auto R = allocated[id];
				Range[] left;
				Range[] right; 

				left = free_ranges.find!(S => S.end == R.start);
				if (left.length)
					{/*...}*/
						left.front.end += R.capacity;
						right = left.find!(S => S.start == R.end);
					}
				else right = free_ranges.find!(S => S.start == R.end);

				if (right.length && left.length)
					{/*...}*/
						left.front.end = right.front.end;
						free_ranges = free_ranges.remove (free_ranges.length - right.length);
					}
				else if (right.length)
					{/*...}*/
						right.front.start -= R.capacity;
					}
				else if (left.empty && right.empty)
					{/*...}*/
						free_ranges ~= R;
						free_ranges.sort!((a,b) => a.start < b.start).copy (free_ranges);
					}

				allocated.remove (id);
			}
		void defrag ()
			{/*...}*/
			}
		@property auto capacity ()
			{/*...}*/
				return pool.length;
			}
		public {/*ctor}*/
			this (uint capacity = 2^^12)
				{/*...}*/
					pool = new T[capacity];
					free_ranges = [Range(0, capacity)];
					free_ranges.reserve (2^^10);
				}
		}

		private:
		T[] pool; 
		Range[] free_ranges;
		Range[Resource.Id] allocated;
	}

shared static this ()
	{/*...}*/
		core.memory.GC.disable ();
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

		X[] = [1.0, 2.0];
		assert (X[].length == 2);

		assert (X[0] == 1.0);
		X[0] += 1.0;
		assert (X[0] == 2.0);
		X[0] = 3.0;
		assert (X[0] == 3.0);
		--X[0];
		assert (X[0] == 2.0);

		X ~= [1.0, 2.0, 3.0]; 
		assert (X[].length == 5);
		X[0..3] = [1.0, 2.0, 3.0];
		X[3..5] += 2.0;
		assert (X[] == [1.0, 2.0, 3.0, 4.0, 5.0]);

		assert (X[].length == 5);
		X[] = 0;
		assert (X[] == [0.0, 0.0, 0.0, 0.0, 0.0]);

		X[] = 1.0.repeat (3);
		assert (X[].length == 3);

		assertThrown!Error (X[] += [1.0]);
		X[] += [1.0, 1.0, 1.0];
		assert (X[] == [2.0, 2.0, 2.0]);

		assertThrown!Error (X ~= 0.0.repeat (999));
	}
