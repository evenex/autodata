module evx.arithmetic;

private {/*import std}*/
	import std.traits:
		isNumeric, isIntegral,
		FieldTypeTuple;
	
	import std.range:
		isInputRange;

	import std.typetuple:
		staticMap;

	import std.typecons:
		Tuple;

	import std.conv:
		to;
	import std.numeric:
		gcd;
}
private {/*import evx}*/
	import evx.utils:
		τ;

	import evx.functional:
		map, reduce;
}

pure nothrow:

/* ctfe-able arithmetic predicates 
*/
auto add (T,U)(T a, U b) 
	{return a + b;}
auto subtract (T,U)(T a, U b) 
	{return a - b;}
auto multiply (T,U)(T a, U b) 
	{return a * b;}
auto divide (T,U)(T a, U b) 
	{return a / b;}

/* mappable arithmetic predicates 
*/
auto add (T,U)(Tuple!(T,U) τ)
	{return τ[0] + τ[1];}
auto subtract (T,U)(Tuple!(T,U) τ)
	{return τ[0] - τ[1];}
auto multiply (T,U)(Tuple!(T,U) τ)
	{return τ[0] * τ[1];}
auto divide (T,U)(Tuple!(T,U) τ)
	{return τ[0] / τ[1];}

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
auto sum (R)(R sequence)
	if (isInputRange!R)
	{/*...}*/
		return sequence.reduce!((Σ,x) => Σ+x);
	}
alias Σ = sum;

/* compute the least common multiple of two numbers 
*/
auto lcm (T)(T a, T b) // TODO over more than two numbers
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
