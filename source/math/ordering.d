module evx.ordering;

pure nothrow:

/* a < b 
*/ 
bool less_than (T)(auto ref in T a, auto ref in T b)
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
bool antisymmetrically_equivalent (alias compare, T, U)(auto ref in T a, auto ref in U b)
	if (__traits(compiles, compare (a, b)))
	{/*...}*/
		return not (compare (a,b) || compare (b,a));
	}
bool antisymmetrically_equivalent (T,U)(auto ref in T a, auto ref in U b)
	if (__traits(compiles, a < b))
	{/*...}*/
		return not (a < b || b < a);
	}
