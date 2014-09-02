module evx.arithmetic;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.range;
		import std.typetuple;
		import std.typecons;
		import std.conv;
		import std.numeric;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.logic;
		import evx.functional;
		import evx.traits;
	}
}

public {/*ctfe-able arithmetic predicates}*/
	pure add (T,U)(T a, U b) 
		if (not (anySatisfy!(is_tuple, T, U)))
		{/*...}*/
			return a + b;
		}

	pure subtract (T,U)(T a, U b) 
		if (not (anySatisfy!(is_tuple, T, U)))
		{/*...}*/
			return a - b;
		}

	pure multiply (T,U)(T a, U b) 
		if (not (anySatisfy!(is_tuple, T, U)))
		{/*...}*/
			return a * b;
		}

	pure divide (T,U)(T a, U b) 
		if (not (anySatisfy!(is_tuple, T, U)))
		{/*...}*/
			return a / b;
		}
}
public {/*zipped arithmetic predicates}*/
	pure add (T,U)(Tuple!(T,U) τ)
		{return τ[0] + τ[1];}
	pure subtract (T,U)(Tuple!(T,U) τ)
		{return τ[0] - τ[1];}
	pure multiply (T,U)(Tuple!(T,U) τ)
		{return τ[0] * τ[1];}
	pure divide (T,U)(Tuple!(T,U) τ)
		{return τ[0] / τ[1];}
}
public {/*tuple arithmetic predicates}*/
	pure add (T...)(Tuple!T a, Tuple!T b)
		{/*...}*/
			mixin(tuple_op!`+`);
		}

	pure subtract (T...)(Tuple!T a, Tuple!T b)
		{/*...}*/
			mixin(tuple_op!`-`);
		}

	pure multiply (T...)(Tuple!T a, Tuple!T b)
		{/*...}*/
			mixin(tuple_op!`*`);
		}

	pure divide (T...)(Tuple!T a, Tuple!T b)
		{/*...}*/
			mixin(tuple_op!`/`);
		}

	private string tuple_op (string op)()
		{/*...}*/
			return q{
				foreach (i, ref c; a)
					c } ~op~ q{= b[i];

				return a;
			};
		}
}

/* compute the product of a sequence 
*/
auto product (R)(R sequence)
	if (isInputRange!R)
	{/*...}*/
		return sequence.reduce!((Π,x) => Π*x);
	}
alias Π = product;

/* compute the sum of a sequence 
*/
auto sum (R)(R range)
	if (isInputRange!R)
	{/*...}*/
		return range.reduce!add;
	}
alias Σ = sum;

/* compute the least common multiple of two numbers 
*/
pure lcm (T)(T a, T b) // TODO over more than two numbers
	{/*...}*/
		if (a == 0 || b == 0)
			return a*b;
		else try return a * (b / gcd (a,b));
			catch (Exception) assert (0);
	}
	unittest {/*...}*/
		assert (lcm (21, 6) == 42);
		assert (lcm (15, 6) == 30);
		assert (lcm (9, 0) == 0);
	}

/* generic squaring predicate 
*/
pure squared (T)(T x)
	{/*...}*/
		return x^^2;
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
