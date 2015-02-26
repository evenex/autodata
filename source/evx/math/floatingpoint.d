module evx.math.floatingpoint;
// TODO MAJOR GOAL: REPLACE COMPLICATED STATIC-IF LADDERS WITH MATCH PATTERN, REPLACE INDUCTIVE TYPE ANALYSIS WITH PATTERN MATCHING

private {/*imports}*/
	import std.typetuple;
	import std.traits;
	import std.math;
	import std.conv;

	import evx.range;
	import evx.operators;
	import evx.math.infinity;
	import evx.math.algebra;
	import evx.math.ordinal;
	import evx.math.logic;
	import evx.math.vector;
	import evx.math.functional;
}

template ε_std (T = real)
	{/*...}*/
		enum ε_std = group_element!(1e-5).of_group!T;
	}

/* test if a number or range is approximately equal to another 
*/
auto approx (T,U)(T a, U b)
	if (All!(is_input_range, T, U))
	{/*...}*/
		foreach (x,y; zip (a,b))
			if (x.approx (y))
				continue;
			else return false;

		return true;
	}
auto approx (T,U)(T a, U b)
	if (All!(is_vector_like, T, U))
	{/*...}*/
		return approx (a[], b[]); 
	}
auto approx (T,U,V = CommonTypeHack!(T,U))(T a, U b, V tolerance = ε_std!V)
	if (All!(not!(or!(is_input_range, is_vector_like)), T, U))
	{/*...}*/
		alias V = CommonType!(T,U);

		auto abs_a = abs (a.to!double);
		auto abs_b = abs (b.to!double);

		if ((abs_a + abs_b) < tolerance.to!double)
			return true;

		auto ε = max (abs_a, abs_b) * tolerance;

		return abs (a-b) < ε;			
	}

private template CommonTypeHack (T,U) //HACK to get around BUG Error: cannot have parameter of type void -- evidently something that was meant to fail semantic analysis causes a syntactic failure
	{/*...}*/
		alias Common = CommonType!(T,U);
		alias CommonTypeHack = Select!(is (Common == void), byte[0], Common);
	}

/* a.approx (b) && b.approx (c) && ...
*/
bool all_approx_equal (Args...)(Args args)
	if (Args.length > 1)
	{/*...}*/
		foreach (i,_; args[0..$-1])
			if (not (args[i].approx (args[i+1])))
				return false;
		return true;
	}
