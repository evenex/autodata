module evx.math.arithmetic.sequences;
version(none):

private {/*...}*/
	import std.numeric;

	import evx.range;

	import evx.math.arithmetic.core;
	import evx.math.logic;
	import evx.math.functional;
	import evx.math.algebra;
}

/* compute the product of a sequence 
*/
auto product (R)(R range)
	if (is_input_range!R)
	{/*...}*/
		return range.empty?
			zero!(typeof(range.reduce!multiply))
			: range.reduce!multiply;
	}
auto product (T...)(T args)
	if (not (Any!(is_input_range, T)))
	{/*...}*/
		return recursive_op!`*` (args);
	}
alias Π = product;

/* compute the sum of a sequence 
*/
auto sum (R)(R range)
	if (is_input_range!R)
	{/*...}*/
		return range.reduce!add (zero!(ElementType!R));
	}
auto sum (T...)(T args)
	if (not (Any!(is_input_range, T)))
	{/*...}*/
		return recursive_op!`+` (args);
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

private auto recursive_op (string op, T...)(T args)
	{/*...}*/
		static if (is (T[1]))
			mixin(q{
				return args[0] } ~ op ~ q{ recursive_op!op (args[1..$]);
			});
		else return args[0];
	}
