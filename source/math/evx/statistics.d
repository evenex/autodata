module evx.statistics;

private {/*import std}*/
	import std.range: ElementType;
	import std.math: sqrt;
}
private {/*import evx}*/
	import evx.arithmetic: sum;
	import evx.functional: map;
}

pure nothrow:

/* compute the mean value over a set */
auto mean (T)(T set)
	{/*...}*/
		auto n = set.length;
		return set.sum/n;
	}
/* compute the standard deviation of a value over a set */
auto std_dev (T)(T set)
	{/*...}*/
		return set.std_dev (set.mean);
	}
/* supplying a precomputed mean will accelerate the calculation */
auto std_dev (T, U = ElementType!T)(T set, const U mean)
	if (is (ElementType!T : U))
	{/*...}*/
		alias μ = mean;
		return set[].map!(x => (x-μ)^^2).mean.sqrt;
	}

unittest {/*...}*/
	import evx.analysis: approx;

	// http://www.mathsisfun.com/data/standard-deviation-formulas.html
	auto x = [9.0, 2, 5, 4, 12, 7, 8, 11, 9, 3, 7, 4, 12, 5, 4, 10, 9, 6, 9, 4];

	assert (x.mean == 7);
	assert (x.std_dev.approx (2.983));
	assert (x.std_dev (x.mean).approx (2.983));
}
