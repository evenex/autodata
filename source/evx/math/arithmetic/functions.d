module evx.math.arithmetic.functions;

private {/*imports}*/
	private {/*std}*/
		import std.range;
		import std.typetuple;
		import std.numeric;
	}
	private {/*evx}*/
		import evx.math.logic;
		import evx.math.functional;
		import evx.math.algebra;

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
// REVIEW ↑ superceded by vector?

/* import disambiguation string mixin 
*/
template ArithmeticToolkit ()
	{/*...}*/
		enum ArithmeticToolkit = q{
			alias sum = evx.math.arithmetic.sum;
			alias product = evx.math.arithmetic.product;
		};
	}

/* compute the product of a sequence 
*/
auto product (R)(R range)
	if (isInputRange!R)
	{/*...}*/
		return range.select!(
			r => r.empty, r => zero!(ElementType!R),
			reduce!multiply
		);
	}
alias Π = product;

/* compute the sum of a sequence 
*/
auto sum (R)(R range)
	if (isInputRange!R)
	{/*...}*/
		return range.reduce!add (zero!(ElementType!R));
	}
alias Σ = sum;

/* compute the least common multiple of two numbers 
*/
pure lcm (T)(T a, T b)
	{/*...}*/
		if (a == 0 || b == 0)
			return a*b;
		else return a * (b / gcd (a,b));
	}
	unittest {/*...}*/
		assert (lcm (21, 6) == 42);
		assert (lcm (15, 6) == 30);
		assert (lcm (9, 0) == 0);
	}
