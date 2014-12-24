module evx.math.sequence;

private {/*imports}*/
	import std.conv;

	import evx.type;
	import evx.range.classification;
	import evx.math.logic;
	import evx.math.algebra;
	import evx.math.intervals;
}

/* a sequence defined by a generating function of the form f(T, size_t) 
*/
struct Sequence (alias f, T) 
	{/*...}*/
		T initial;
		size_t[2] bounds = [0, size_t.max];

		T access (size_t i)
			{/*...}*/
				return f (initial, i + bounds.left).to!T;
			}

		version (all) // TODO pending bugfix
			{/*...}*/
				auto opIndex (size_t i)
					{/*...}*/
						return access (i);
					}
				auto opIndex (size_t[2] slice)
					{/*...}*/
						auto t = this;

						t.bounds.left += slice.left;
						t.bounds.right = t.bounds.left + slice.width;

						return t;
					}
				auto opIndex ()
					{/*...}*/
						return this;
					}
				size_t[2] opSlice (size_t d: 0)(size_t i, size_t j)
					{/*...}*/
						return [i,j];
					}
				auto front ()
					{/*...}*/
						return this[0];
					}
				auto back ()
					{/*...}*/
						return this[$-1];
					}
				auto opDollar ()
					{/*...}*/
						return length;
					}
				auto popFront ()
					{/*...}*/
						bounds.left++;
					}
				auto popBack ()
					{/*...}*/
						bounds.right--;
					}
				auto empty ()
					{/*...}*/
						return length == 0;
					}
				@property save ()
					{/*...}*/
						return this;
					}
				bool opEquals (R)(R range)
					{/*...}*/
						return evx.range.equal (save, range);
					}
				@property length () const
					{/*...}*/
						return bounds.width;
					}
			}

		//mixin SliceOps!(access, bounds, RangeOps);// BUG https://issues.dlang.org/show_bug.cgi?id=13861
	//	mixin RangeOps;
	}

/* build a sequence from an index-based generating function and an initial value 
*/
auto sequence (alias func, T)(T initial)
	{/*...}*/
		return Sequence!(func, T)(initial);
	}
	unittest {/*...}*/
		auto N = ℕ;
		assert (ℕ[0..10] == [0,1,2,3,4,5,6,7,8,9]);
		assert (ℕ[4..9] == [4,5,6,7,8]);

		assert (N[4..9][1..4] == [5,6,7]);
		assert (N[4..9][1..4][1] == 6);

		for (auto i = 0; i < 10; ++i)
			assert (ℕ[0..10][i] == i);
	}
