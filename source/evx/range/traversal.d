module evx.range.traversal;

public import evx.range.traits;

private {/*imports}*/
	import std.range;

	import evx.math.arithmetic;
	import evx.math.functional;

	mixin(FunctionalToolkit!());
	mixin(ArithmeticToolkit!());
}

alias contains = std.algorithm.canFind;

/* construct a ForwardRange out of a range of ranges such that the inner ranges appear concatenated 
*/
struct Contigious (R)
	if (allSatisfy!(is_indexable, R, ElementType!R))
	{/*...}*/
		public:
		@property {/*range}*/
			const length ()
				{/*...}*/
					import std.traits;
					auto s = cast(Unqual!R)ranges; // HACK to shed constness so that sum can operate
					return s.map!(r => r.length).sum;
				}

			auto ref front ()
				{/*...}*/
					return ranges[j][i];
				}
			void popFront ()
				{/*...}*/
					if (++i == ranges[j].length)
						{/*...}*/
							++j;
							i = 0;
						}
				}
			auto empty ()
				{/*...}*/
					return j >= ranges.length;
				}

			auto save ()
				{/*...}*/
					return this;
				}
			alias opSlice = save;
		}
		public {/*ctor}*/
			this (R ranges)
				{/*...}*/
					this.ranges = ranges;
				}
		}
		private:
		private {/*data}*/
			size_t i, j;
			R ranges;
		}
	}
struct Contigious (R)
	if (allSatisfy!(isForwardRange, R, ElementType!R) && not (is_indexable!(ElementType!R)))
	{/*...}*/
		public:
		@property {/*range}*/
			auto length ()
				{/*...}*/
					return ranges.map!(r => r.length).sum;
				}
			auto ref front ()
				{/*...}*/
					return ranges.front.front;
				}
			void popFront ()
				{/*...}*/
					ranges.front.popFront;

					if (ranges.front.empty)
						ranges.popFront;
				}
			auto empty ()
				{/*...}*/
					return ranges.empty;
				}
			auto save ()
				{/*...}*/
					return this;
				}
		}
		public {/*ctor}*/
			this (R ranges)
				{/*...}*/
					this.ranges = ranges;
				}
		}
		private:
		private {/*data}*/
			R ranges;
		}

	}
auto contigious (R)(R ranges)
	{/*...}*/
		return Contigious!R (ranges);
	}
	unittest {/*contigious}*/
		int[2] x = [1,2];
		int[2] y = [3,4];
		int[2] z = [5,6];

		int[2][] A = [x,y,z];

		assert (A.contigious.equal ([1,2,3,4,5,6]));
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
		return range.zip (range.rotate_elements);
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

/* always-false test for infinite ranges, for ranges which do not define an is_infinite property 
*/
bool is_infinite (R)(R)
	if (isInputRange!R)
	{/*...}*/
		return false;
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
