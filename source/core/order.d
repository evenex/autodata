module autodata.core.order;

private {/*import}*/
	import autodata.meta;
}

/* emulate opCmp 
*/
auto compare (T,U)(T a, U b)
	{/*...}*/
		static if (Any!(is_floating_point, T, U))
			if (a != a || b != b)
				return real.nan;

		if (a < b)
			return -1;
		else if (a > b)
			return 1;
		else return 0;
	}
