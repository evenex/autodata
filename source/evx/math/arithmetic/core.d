module evx.math.arithmetic.core;

private {/*imports}*/
	import std.typecons;
	import std.typetuple;
	import std.traits;

	import evx.math.logic;
	import evx.math.algebra;

	import evx.traits;
}

/* test whether a type is capable of addition, subtraction, multiplication and division 
*/
template supports_arithmetic (T)
	{/*...}*/
		enum one = unity!(const(Unqual!T));

		enum supports_arithmetic = __traits(compiles,
			{auto x = one, y = one; static assert (__traits(compiles, x+y, x-y, x*y, x/y));}
		);
	}

/* test whether a number is odd or even at compile-time 
*/
template is_even (size_t n)
	{/*...}*/
		enum is_even = n % 2 == 0;
	}
template is_odd (size_t n)
	{/*...}*/
		enum is_odd = not (is_even);
	}
template is_multiple_of (size_t m)
	{/*...}*/
		template is_multiple_of (size_t n)
			{/*...}*/
				enum is_multiple_of = n % m == 0;
			}
	}

pure add (T,U)(T a, U b) 
	if (not (Any!(is_tuple, T, U)))
	{/*...}*/
		return a + b;
	}
pure subtract (T,U)(T a, U b) 
	if (not (Any!(is_tuple, T, U)))
	{/*...}*/
		return a - b;
	}
pure multiply (T,U)(T a, U b) 
	if (not (Any!(is_tuple, T, U)))
	{/*...}*/
		return a * b;
	}
pure divide (T,U)(T a, U b) 
	if (not (Any!(is_tuple, T, U)))
	{/*...}*/
		return a / b;
	}

pure add (T,U)(Tuple!(T,U) τ)
	{/*...}*/
		return τ[0] + τ[1];
	}
pure subtract (T,U)(Tuple!(T,U) τ)
	{/*...}*/
		return τ[0] - τ[1];
	}
pure multiply (T,U)(Tuple!(T,U) τ)
	{/*...}*/
		return τ[0] * τ[1];
	}
pure divide (T,U)(Tuple!(T,U) τ)
	{/*...}*/
		return τ[0] / τ[1];
	}

auto squared (T)(T value)
	{/*...}*/
		return value * value;
	}
alias sq = squared;

auto cubed (T)(T value)
	{/*...}*/
		return value.sq * value;
	}
alias cu = cubed;
