module evx.ordinal;

private {/*imports}*/
	private {/*std}*/
		import std.typetuple;
		import std.traits;
	}
	private {/*evx}*/
		import evx.functional;
		import evx.logic;
	}
}

pure nothrow:

/* the set¹ of natural numbers 
	1. actually a subset of cardinality 2⁶⁴
*/
static ℕ () {return 0L.sequence!((n,i) => n + i);}

/* a < b 
*/ 
bool less_than (T)(const T a, const T b)
	{/*...}*/
		return a < b;
	}

/* a == b && b == c && ...
*/
bool all_equal (Args...)(Args args)
	if (Args.length > 1)
	{/*...}*/
		foreach (i,_; args[0..$-1])
			if (args[i] != args[i+1])
				return false;
		return true;
	}

/* ¬(a < b || b < a) ⇒ a == b 
*/
bool antisymmetrically_equivalent (alias compare, T, U)(const T a, const U b)
	if (__traits(compiles, compare (a, b)))
	{/*...}*/
		return not (compare (a,b) || compare (b,a));
	}
bool antisymmetrically_equivalent (T,U)(const T a, const U b)
	if (__traits(compiles, a < b))
	{/*...}*/
		return not (a < b || b < a);
	}

/* emulate opCmp 
*/
auto compare (T,U)(T a, U b)
	{/*...}*/
		static if (anySatisfy!(isFloatingPoint, T, U))
			if (a != a || b != b)
				return real.nan;

		if (a < b)
			return -1;
		else if (a > b)
			return 1;
		else return 0;
	}
