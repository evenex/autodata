module evx.arithmetic;

private {/*import std}*/
	import std.traits:
		isNumeric, isIntegral,
		FieldTypeTuple;
	
	import std.typetuple:
		staticMap;

	import std.conv:
		to;
}
private {/*import evx}*/
	import evx.functional:
		map, reduce;
}

pure nothrow:

/* returns unity (1) for a given type 
	if T cannot be constructed from 1, then unity recursively attempts to call a constructor with unity for all field types
*/
auto unity (T)()
	{/*...}*/
		static if (isNumeric!T)
			return cast(T) 1;
		else static if (__traits(compiles, T(1)))
			return T(1);
		else static if (__traits(compiles, T(staticMap!(unity, FieldTypeTuple!T))))
			return T(staticMap!(unity, FieldTypeTuple!T));
		else static assert (0, `can't compute unity for ` ~T.stringof);
	}

/* returns zero (0) for a given type 
	if T cannot be constructed from 1, then zero recursively attempts to call a constructor with zero for all field types
*/
auto zero (T)()
	{/*...}*/
		static if (isNumeric!T)
			return cast(T) 0;
		else static if (__traits(compiles, T(0)))
			return T(0);
		else static if (__traits(compiles, T(staticMap!(zero, FieldTypeTuple!T))))
			return T(staticMap!(zero, FieldTypeTuple!T));
		else static assert (0, `can't compute zero for ` ~T.stringof);
	}

/* ctfe-able arithmetic predicates 
*/
auto add (T)(T a, T b) 
	{return a + b;}
auto subtract (T)(T a, T b) 
	{return a - b;}

/* compute the product of a sequence 
*/
auto Π (R)(R sequence)
	{/*...}*/
		return sequence.reduce!((Π,x) => Π*x);
	}

/* compute the sum of a sequence 
*/
auto sum (R)(R sequence)
	{/*...}*/
		return sequence.reduce!((Σ,x) => Σ+x);
	}
alias Σ = sum;
