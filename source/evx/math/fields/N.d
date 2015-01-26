module evx.math.fields.nats;

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
	import evx.math.vector;
	import evx.math.functional;
	import evx.math.sequence;
}

/* the set¹ of natural numbers 
	1. actually a subset of cardinality 2⁶⁴
*/
struct Nat
	{/*...}*/
		static:

		enum size_t length = size_t.max;

		size_t access (size_t i)
			{/*...}*/
				return i;
			}

		mixin SliceOps!(access, length, RangeOps);
	}
	unittest {/*...}*/
		auto N = ℕ[];
		assert (ℕ[0..10] == [0,1,2,3,4,5,6,7,8,9]);
		assert (ℕ[4..9] == [4,5,6,7,8]);

		assert (N[4..9][1..4] == [5,6,7]);
		assert (N[4..9][1..4][1] == 6);

		for (auto i = 0; i < 10; ++i)
			assert (ℕ[0..10][i] == i);
	}

alias ℕ = Nat; // REVIEW
