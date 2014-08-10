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
}
private {/*import evx}*/
	import evx.utils:
		τ;

	import evx.functional:
		map, reduce;
}

pure nothrow:

/* test whether a type is capable of addition, subtraction, multiplication and division 
*/
template supports_arithmetic (T)
	{/*...}*/
		enum supports_arithmetic = __traits(compiles,
			{T x, y; static assert (__traits(compiles, x+y, x-y, x*y, x/y));}
		);
	}

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
