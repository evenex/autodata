module evx.math.sequence;
version(none):

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

		mixin SliceOps!(access, bounds, RangeOps);
		mixin RangeOps;
	}

/* build a sequence from an index-based generating function and an initial value 
*/
auto sequence (alias func, T)(T initial)
	{/*...}*/
		return Sequence!(func, T)(initial);
	}
