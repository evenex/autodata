module evx.math.fields.ℝ;

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
}

/* the set of real¹ numbers 
	1. actually the doubles
*/

struct ℝ
	{/*...}*/
		static:

		enum double[2] boundary = [-infinity, infinity];

		double access (double x)
			{/*...}*/
				return x;
			}

		mixin SliceOps!(access, boundary);
	}
