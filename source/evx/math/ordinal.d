module evx.math.ordinal;

private {/*imports}*/
	import std.traits;

	import evx.math.logic;
}

alias min = std.algorithm.min;
alias max = std.algorithm.max;

pure nothrow:

/* test if a type is comparable using the < operator 
*/
template is_comparable (T...)
	if (T.length == 1)
	{/*...}*/
		static if (is (T[0]))
			{/*...}*/
				const T[0] a, b;
				enum is_comparable = is(typeof(a < b) == bool);
			}
		else enum is_comparable = false;
	}

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

/* ¬(a < b || b < a) ¿ a == b 
*/
bool antisymmetrically_equivalent (alias compare, T, U)(const T a, const U b)
	if (is (typeof(compare (a, b)) : bool))
	{/*...}*/
		return not (compare (a,b) || compare (b,a));
	}
bool antisymmetrically_equivalent (T,U)(const T a, const U b)
	if (is (typeof(a < b) : bool))
	{/*...}*/
		return not (a < b || b < a);
	}

/* emulate opCmp 
*/
auto compare (T,U)(T a, U b)
	{/*...}*/
		static if (Any!(isFloatingPoint, T, U))
			if (a != a || b != b)
				return real.nan;

		if (a < b)
			return -1;
		else if (a > b)
			return 1;
		else return 0;
	}

/* test if t0 <= t <= t1 
*/
bool between (T, U, V) (T t, U t0, V t1) 
	{/*...}*/
		return t0 <= t && t <= t1;
	}
