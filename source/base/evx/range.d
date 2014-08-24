module evx.range;

private {/*import std}*/
	import std.typetuple:
		allSatisfy;

	import std.range:
		ElementType, isForwardRange, cycle;
}
private {/*import evx}*/
	import evx.logic: 
		And, Not, not;

	import evx.traits:
		is_indexable, is_comparable;

	import evx.arithmetic:
		sum;

	import evx.functional:
		map, zip;
}

pure nothrow:

/* construct a ForwardRange out of a range of ranges such that the inner ranges appear concatenated 
*/
struct Contigious (R)
	if (allSatisfy!(is_indexable, R, ElementType!R) && not (isForwardRange!(ElementType!R)))
	{/*...}*/
		pure nothrow:

		public:
		@property {/*range}*/
			const length ()
				{/*...}*/
					return ranges.map!(r => r.length).sum;
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
			const empty ()
				{/*...}*/
					return j >= ranges.length;
				}

			inout save ()
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
			size_t i, j;
			R ranges;
		}
	}
struct Contigious (R)
	if (allSatisfy!(isForwardRange, R, ElementType!R))
	{/*...}*/
		pure nothrow:

		public:
		@property {/*range}*/
			const length ()
				{/*...}*/
					import math: sum;
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
			const empty ()
				{/*...}*/
					return ranges.empty;
				}
			inout save ()
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
	import std.range: equal;

	int[2] x = [1,2];
	int[2] y = [3,4];
	int[2] z = [5,6];

	int[2][] A = [x,y,z];

	assert (A.contigious.equal ([1,2,3,4,5,6]));
}

/* traverse a range with elements rotated left by some number of positions 
*/
auto rotate_elements (R)(R range, int positions = 1)
	in {/*...}*/
		auto n = range.length;
		assert ((positions + n) % n > 0);
	}
	body {/*...}*/
		auto n = range.length;
		auto i = (positions + n) % n;
		
		return range.cycle[i..n+i];
	}

/* pair each element with its successor in the range, pairing the last element with the first 
*/
auto adjacent_pairs (R)(R range)
	{/*...}*/
		return range.zip (range.rotate_elements);
	}

/* test if an attempted slice will be within some bounds 
*/
bool slice_within_bounds (T,U,V)(T i, U j, V length)
	if (allSatisfy!(is_comparable, T,U,V))
	{/*...}*/
		return i <= j && j <= length && i < length;
	}