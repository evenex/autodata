module evx.arithmetic;

private {/*import std}*/
	import std.traits:
		isIntegral;

	import std.conv:
		to;
}
private {/*import evx}*/
	import evx.functional:
		map, reduce;
}

pure nothrow:

/* ctfe-able arithmetic predicates 
*/
auto add (T)(T a, T b) 
	{return a + b;}
auto subtract (T)(T a, T b) 
	{return a - b;}

/* compute the product of a sequence 
*/
auto Π (T)(auto ref T sequence)
	{/*...}*/
		return sequence.reduce!((Π,x) => Π*x);
	}

/* compute the sum of a sequence 
*/
auto sum (T)(auto ref T sequence)
	{/*...}*/
		return sequence.reduce!((Σ,x) => Σ+x);
	}
alias Σ = sum;
