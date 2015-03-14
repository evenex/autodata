module spacecadet.math.algebra;

private {/*import}*/
	import spacecadet.meta;
}

/* generic identity transform
*/
T identity (T)(T that)
	{/*...}*/
		return that;
	}

/* test if identity transform is defined for a type 
*/
enum has_identity (T...) = is (typeof(T[0].identity));

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
