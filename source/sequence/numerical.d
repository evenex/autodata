module autodata.sequence.numerical;

private {/*import}*/
	import autodata.core;
	import autodata.operators;
	import autodata.meta;
}

/* the set¹ of natural numbers 
	1. actually a subset of cardinality 2⁶⁴
*/
struct Nat
	{/*...}*/
		static mixin SliceOps!(identity!size_t, infinity!size_t, RangeExt);
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

/* the set of real¹ numbers 
	1. actually the doubles
*/
struct Real
	{/*...}*/
		enum double[2] boundary = [-double.infinity, double.infinity];

		static mixin SliceOps!(identity!double, boundary);
	}

alias ℕ = Nat;
alias ℝ = Real;
