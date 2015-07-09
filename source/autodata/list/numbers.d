/**
    provides numeric sequences
*/
module autodata.list.numbers;

private {//imports
	import evx.meta;
	import evx.infinity;
	import evx.interval;
	import autodata.operators;
}

/** a static identity space of size_t, represents the set of natural numbers
*/
struct Nat
{static mixin AdaptorOps!(identity!size_t, infinity!size_t, RangeExt);}
///
unittest {
	auto N = Nat[];
	assert (Nat[0..10] == [0,1,2,3,4,5,6,7,8,9]);
	assert (Nat[4..9] == [4,5,6,7,8]);

	assert (N[4..9][1..4] == [5,6,7]);
	assert (N[4..9][1..4][1] == 6);

	for (auto i = 0; i < 10; ++i)
		assert (Nat[0..10][i] == i);
}

/** a static identity space of doubles, represents the set of real numbers 
*/
struct Real
{static mixin AdaptorOps!(identity!double, interval!double (-infinity, infinity));}
///
unittest {
    assert (Real[0.45] == 0.45);

    auto R = Real[10..20];

    assert (R[0] == 10);
    assert (R[5] == 15);
}
