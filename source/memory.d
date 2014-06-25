import std.algorithm;
import std.exception;
import std.range;
import std.ascii;
import std.conv;
import utils;

/** Resources

Resources are handles to contigious arrays of data, manually allocated with 
	Allocators. Because Resources are reference types, they are able to maintain 
	correctness even if the Allocator moves the data in memory. 

Resources will automatically free themselves upon destruction. Because of this, they
	are unique and cannot be copied, but they may be moved with the assignment 
	operator (=). This will move the reference information to the LHS Resource and 
	nullify the RHS Resource. Assigning to a non-null Resource will trigger the LHS 
	destructor, freeing the associated data before moving the reference info from 
	the RHS.

Resources themselves do not have Range semantics, but do offer mutable slicing and 
	indexing. Because the Resource's underlying data is contigious, slicing it 
	returns an Array, which can then be manipulated as a RandomAccessRange.
*/

struct Allocator (T, uint capacity = 2^^12)
	{/*...}*/
		@safe private struct Range
			{/*...}*/
				union {/*bounds}*/
					size_t[2] range; // union
					struct {size_t start, end;}
				}

				@property size_t capacity () const pure nothrow
					{/*...}*/
						return range[1] - range[0];
					}

				@disable this ();
				this (size_t start, size_t capacity) nothrow pure
					{/*...}*/
						range[0] = start;
						range[1] = start + capacity;
					}

				alias range this;
			}
		struct Resource
			{/*...}*/
				static assert (!isRandomAccessRange!Resource);
				static assert (isRandomAccessRange!(typeof(this[])));
				// REVIEW doc this shit
				// IDEA: thisa is the lowest level of data storage in the system
				// it is not a range, but it generates random-access ranges with opSlice

				@safe const nothrow {/*[i]}*/
					auto opIndex (size_t i) @trusted
						in {/*...}*/
							assert (i < length, `range violation`);
						}
						body {/*...}*/
							auto R = Allocator.allocated[id];

							return Allocator.pool[R[0] + i];
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
					auto opIndexAssign (T)(T that, size_t i) @trusted
						{/*...}*/
							auto R = Allocator.allocated[id];

							return Allocator.pool[R[0] + i] = that;
						}
					auto opIndexOpAssign (string op, T)(T that, size_t i)
						{/*...}*/
							return this[i] = this[i] + that;
						}
				}
				const {/*[i..j]}*/
					auto opSlice (size_t start, size_t end) nothrow @trusted
						in {/*...}*/
							assert (start <= end, `range reversed`);
							assert (end <= length, `range violation`);
						}
						body {/*...}*/
							auto R = Allocator.allocated[id];

							return Allocator.pool[R[0] + start..R[0] + end];
						}
					auto opSliceAssign (T)(T that, size_t start, size_t end)
						{/*...}*/
							static if (isInputRange!T)
								that.copy (this[start..end]);
							else this[start..end] = that.repeat (end - start);
						}
					auto opSliceOpAssign (string op, T)(T that, size_t start, size_t end) nothrow @safe 
						body {/*...}*/
							static if (isInputRange!T)
								mixin(q{
									this[start..end] = this[start..end].zip (that)
										.map!(τ => τ[0] }~op~q{ τ[1]);
								});
							else mixin(q{
								this[start..end] }~op~q{= that.repeat (end-start);
							});
						}
					auto opSliceUnary (string op)(size_t start, size_t end) nothrow pure @safe 
						{/*...}*/
							mixin(q{
								return this[start..end] = this.map!(a => }~op~q{ a);
							});
						}
				}
				public {/*[]}*/
					auto opSlice () const nothrow @safe
						{/*...}*/
							return this[0..$];
						}
					auto opSliceAssign (T)(T that)
						{/*...}*/
							static if (isInputRange!T)
								length = that.length;
							this[0..$] = that;
						}
					auto opSliceOpAssign (string op, T)(T that) const nothrow
						in {/*...}*/
							static if (isInputRange!T)
								assert (this.length == that.length, `dimension mismatch for `~this[].text~` `~op~` `~that.text);
						}
						body {/*...}*/
							mixin(q{
								this[0..$] }~op~q{= that;
							});
						}
					auto opSliceUnary (string op)() const nothrow pure @safe
						{/*...}*/
							mixin(q{
								return }~op~q{this[0..$];
							});
						}
				}
				public {/*~}*/
					@disable auto opBinary (string op: `~`, T)(T);
					auto opOpAssign (string op: `~`, T)(T that)
						in {/*...}*/
							debug  {/*...}*/
								static if (hasLength!T || isForwardRange!T)
									assert (length + that.length <= Allocator.allocated[id].capacity, `range overflow`);
								else assert (length + 1 <= Allocator.allocated[id].capacity, `range overflow`);
							}
						}
						body {/*...}*/
							static if (hasLength!T || isForwardRange!T)
								{/*...}*/
									auto start = length;
									length += that.length;

									assert (that.length, `range was exhausted after length check. `~isForwardRange!T? `it was a forward range`:``);

									this[start..length] = that;
								}
							else {/*...}*/
								++length;
								this[$-1] = that;
							}
						}
				}
				const pure nothrow @safe {/*$}*/
					auto opDollar () 
						{/*...}*/
							return length;
						}
				}
				public {/*=}*/
					auto opAssign (Resource that)
						in {/*...}*/
							assert (this.id == Id.init, `reassigned allocated resource without free`);
						}
						body {/*...}*/
							this.id = that.id;
							this.length = that.length;

							that.id = Id.init;
							that.length = 0;
						}
				}
						
				public ~this () @safe
					{/*...}*/
						Allocator.free (id);
					}

				private:

				@disable this (this);

				mixin Type_Unique_Id;

				Id id;
				size_t length = 0;
				@trusted invariant (){/*...}*/
					assert (length <= allocated[id].capacity);
				}

				this (Id id) nothrow @safe 
					{/*...}*/
						this.id = id;
					}
			}

		static auto allocate (size_t size) @trusted
			{/*...}*/
				foreach (ref range; free_ranges)
					{/*find free range}*/
						if (range.capacity >= size)
							{/*allocate memory}*/
								auto id = Resource.Id.create;

								allocated[id] = Range (range.start, size);
								range.start += size;

								return Resource (id);
							}
					}
				assert (0, Allocator.stringof~` out of memory! 
					free: 
						`~free_ranges.to!string~`
					used:
						`~allocated.to!string);
			}
		static void free (Resource.Id id) @trusted 
			{/*...}*/
				if (id == Resource.Id.init)
					return;

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
					right.front.start -= R.capacity;
				else if (left.empty && right.empty)
					{/*...}*/
						free_ranges ~= R;
						free_ranges.sort!((a,b) => a.start < b.start).copy (free_ranges);
					}

				allocated.remove (id);
			}
		static void defrag () @safe nothrow pure
			{/*...}*/
			}

		private:
		__gshared T[]
			pool;
		__gshared Range[] 
			free_ranges;
		__gshared Range[Resource.Id] 
			allocated;

		 @trusted shared static this ()
			{/*...}*/
				pool = new T[capacity];
				free_ranges = [Range(0, capacity)];
				free_ranges.reserve (2^^10);
			}
	}

unittest
	{/*...}*/
		Allocator!double alloc;

		auto X = alloc.allocate (5);
		assert (X[].capacity == 0);
		assert (alloc.allocated[X.id].capacity == 5);

		assert (X.length == 0);
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
