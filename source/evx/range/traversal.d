module evx.range.traversal;

private {/*imports}*/
	import std.range;
	import std.algorithm;

	import evx.math.sequence;
}

/* check if a range contains a value 
*/
alias contains = std.algorithm.canFind;

/* construct a range from a repeated value 
*/
alias repeat = std.range.repeat;

/* construct a ForwardRange out of a range of ranges such that the inner ranges appear concatenated 
*/
alias join = std.algorithm.joiner;
	unittest {/*join}*/
		int[2] x = [1,2];
		int[2] y = [3,4];
		int[2] z = [5,6];

		int[][] A = [x[], y[], z[]];

		assert (A.join.equal ([1,2,3,4,5,6]));
	}

/* const-correct replacement for std.range.stride 
*/
struct Stride (R)
	{/*...}*/
		R range;

		size_t stride;

		this (R range, size_t stride)
			{/*...}*/
				this.range = range;
				this.stride = stride;
			}

		const @property length ()
			{/*...}*/
				return range.length / stride;
			}

		static if (isInputRange!R)
			{/*...}*/
				auto ref front ()
					{/*...}*/
						return range.front;
					}
				void popFront ()
					{/*...}*/
						foreach (_; 0..stride)
							range.popFront;
					}
				bool empty () const
					{/*...}*/
						return range.length < stride;
					}

				static assert (isInputRange!Stride);
			}
		static if (isForwardRange!R)
			{/*...}*/
				@property save ()
					{/*...}*/
						return this;
					}

				static assert (isForwardRange!Stride);
			}
		static if (isBidirectionalRange!R)
			{/*...}*/
				auto ref back ()
					{/*...}*/
						return range.back;
					}
				void popBack ()
					{/*...}*/
						foreach (_; 0..stride)
							range.popBack;
					}

				static assert (isBidirectionalRange!Stride);
			}


		invariant() {/*}*/
			assert (stride != 0, `stride must be nonzero`);
		}
	}
auto stride (R,T)(R range, T stride)
	{/*...}*/
		return Stride!R (range, stride.to!size_t);
	}

/* traverse a range with elements rotated left by some number of positions 
*/
auto rotate_elements (R)(R range, int positions = 1)
	in {/*...}*/
		auto n = range.length;

		if (n > 0)
			assert ((positions + n) % n > 0);
	}
	body {/*...}*/
		auto n = range.length;

		if (n == 0)
			return typeof(range.cycle[0..0]).init;

		auto i = (positions + n) % n;
		
		return range.cycle[i..n+i];
	}

/* pair each element with its successor in the range, pairing the last element with the first 
*/
auto adjacent_pairs (R)(R range)
	{/*...}*/
		return evx.math.functional.zip (range, range.rotate_elements);
	}

/* generate a foreach index for a custom range 
	this exploits the automatic tuple foreach index unpacking trick which is obscure and under controversy
	reference: https://issues.dlang.org/show_bug.cgi?id=7361
*/
auto enumerate (R)(R range)
	if (isInputRange!R && hasLength!R)
	{/*...}*/
		return ℕ[0..range.length].zip (range);
	}

/* explicitly count the number of elements in an InputRange 
*/
size_t count (R)(R range)
	if (isInputRange!R)
	{/*...}*/
		size_t count;

		foreach (_; range)
			++count;

		return count;
	}

/* verify that the length of a range is its true length 
*/
debug void verify_length (R)(R range)
	{/*...}*/
		auto length = range.length;
		auto count = range.count;

		if (length != count)
			assert (0, R.stringof~ ` length (` ~count.text~ `) doesn't match reported length (` ~length.text~ `)`);
	}
