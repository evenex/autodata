module evx.range;

private {/*imports}*/
	private {/*std}*/
		import std.typetuple;
		import std.range;
		import std.conv;
	}
	private {/*evx}*/
		import evx.logic; 
		import evx.traits;
		import evx.math;
	}

	alias map = evx.functional.map;
	alias zip = evx.functional.zip;
}

/* explicitly counts the number of elements in an InputRange 
*/
auto count_elements (R)(R range)
	if (isInputRange!R)
	{/*...}*/
		size_t count;

		foreach (_; range)
			++count;

		return count;
	}

pure:

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

/* always-false test for infinite ranges, for ranges which do not define an is_infinite property 
*/
bool is_infinite (R)(R)
	if (isInputRange!R)
	{/*...}*/
		return false;
	}

auto stride (R,T)(R range, T stride)
	{/*...}*/
		return Stride!R (range, stride.to!size_t);
	}
struct Stride (R)
	{/*...}*/
		R range;

		size_t stride;

		this (R range, size_t stride)
			{/*...}*/
				this.range = range;
				this.stride = stride;
			}

		auto front ()
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

		const @property length ()
			{/*...}*/
				return range.length / stride;
			}
	}
