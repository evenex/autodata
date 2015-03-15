module spacecadet.sequence.arithmetic;

private {/*import}*/
	import std.range.primitives: front, back, popFront, popBack, empty;

	import spacecadet.core;
	import spacecadet.meta;
	import spacecadet.functional;
}

/* compute the product of a sequence 
*/
auto product (R)(R range)
	if (is_input_range!R)
	{/*...}*/
		alias fold = reduce!((a,b) => a*b);

		return range.empty?
			typeof(fold (range))(0)
			: fold (range);
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
		return range.reduce!((a,b) => a+b)(ElementType!R (0));
	}
auto sum (T...)(T args)
	if (not (Any!(is_input_range, T)))
	{/*...}*/
		return recursive_op!`+` (args);
	}
alias Σ = sum;

unittest {/*...}*/
	assert ([1,2,3,4].sum == 10);
	assert (sum (1,2,3,4) == 10);

	assert ([1,2,3,4].product == 24);
	assert (product (1,2,3,4) == 24);
}

private {/*impl}*/
	auto recursive_op (string op, T...)(T args)
		{/*...}*/
			static if (is (T[1]))
				mixin(q{
					return args[0] } ~ op ~ q{ recursive_op!op (args[1..$]);
				});
			else return args[0];
		}
}
