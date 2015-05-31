module autodata.spaces.sequence.numbers;

private {//imports
	import evx.meta;
	import evx.infinity;
	import evx.interval;
	import autodata.operators;
}

/* the set of natural numbers¹
	1. actually a subset of cardinality 2⁶⁴
*/
struct Nat
{static mixin AdaptorOps!(identity!size_t, infinity!size_t, RangeExt);}
unittest {
	auto N = Nat[];
	assert (Nat[0..10] == [0,1,2,3,4,5,6,7,8,9]);
	assert (Nat[4..9] == [4,5,6,7,8]);

	assert (N[4..9][1..4] == [5,6,7]);
	assert (N[4..9][1..4][1] == 6);

	for (auto i = 0; i < 10; ++i)
		assert (Nat[0..10][i] == i);
}

/* the set of real¹ numbers 
	1. actually the doubles
*/
struct Real
{static mixin AdaptorOps!(identity!double, interval!double (-infinity, infinity));}
