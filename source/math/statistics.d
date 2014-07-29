module evx.statistics;

private {/*import evx}*/
	import evx.arithmetic: sum;
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
auto std_dev (T, U = ElementType!T)(T set, U mean)
	if (is (U == ElementType!T))
	{/*...}*/
		alias μ = mean;
		return sqrt (set.map!(x => (x-μ)^^2).mean);
	}
