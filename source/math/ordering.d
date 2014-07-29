module evx.ordering;

pure nothrow:

/* ¬(a < b || b < a) ⇒ a == b
*/
bool antisymmetrically_equivalent (alias compare, T,U)(auto ref in T a, auto ref in U b)
	if (__traits(compiles, compare (a, b)))
	{/*...}*/
		return not (compare (a,b) || compare (b,a));
	}
bool antisymmetrically_equivalent (T,U)(auto ref in T a, auto ref in U b)
	if (__traits(compiles, a < b))
	{/*...}*/
		return not (a < b || b < a);
	}

/* a < b 
*/ 
bool less_than (T)(auto ref in T a, auto ref in T b)
	{/*...}*/
		return a < b;
	}
