module evx.math.statistics;

private {/*imports}*/
	import evx.math.logic;
	import evx.math.arithmetic;
	import evx.math.functional;
	import evx.math.overloads;
	import evx.range;
}

/* compute the mean value over a set */
auto mean (T)(T set)
	if (has_length!T)
	{/*...}*/
		auto n = set.length;

		return set.sum/n;
	}
auto mean (T)(T set)
	if (not (has_length!T))
	{/*...}*/
		auto v = enumerate (set).sum;

		return v[1]/v[0];
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

		return set[].map!(x => (x-μ).squared).mean.sqrt;
	}

unittest {/*...}*/
	import evx.math.floatingpoint: approx;

	// http://www.mathsisfun.com/data/standard-deviation-formulas.html
	auto x = [9.0, 2, 5, 4, 12, 7, 8, 11, 9, 3, 7, 4, 12, 5, 4, 10, 9, 6, 9, 4];

	assert (x.mean == 7);
	assert (x.std_dev.approx (2.983, 1e-4));
	assert (x.std_dev (x.mean).approx (2.983, 1e-4));

	static if (__traits(compiles, {import evx.math.units;}))
		{/*...}*/
			import evx.math.units;
			auto y = x.map!(i => i.meters);

			assert (y.mean == 7.meters);
			assert (y.std_dev.approx (2.98329.meters));
			assert (y.std_dev (y.mean).approx (2.98329.meters));
		}
}
