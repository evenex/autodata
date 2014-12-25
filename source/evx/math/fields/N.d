module evx.math.fields.ℕ;

private {/*imports}*/
	import std.typetuple;
	import std.traits;
	import std.math;
	import std.conv;

	import evx.range;
	import evx.operators;
	import evx.math.infinity;
	import evx.math.algebra;
	import evx.math.ordinal;
	import evx.math.logic;
	import evx.math.vectors;
	import evx.math.functional;
	import evx.math.sequence;
}

/* the set¹ of natural numbers 
	1. actually a subset of cardinality 2⁶⁴
*/
struct ℕ
	{/*...}*/
		static:

		enum size_t length = size_t.max;

		size_t access (size_t i)
			{/*...}*/
				return i;
			}

		mixin SliceOps!(access, length, RangeOps);
	}
