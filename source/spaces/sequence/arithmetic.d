module autodata.spaces.sequence.arithmetic;

private {//import
	import std.range.primitives: front, back, popFront, popBack, empty;

	import autodata.functional;
	import autodata.traits;

	import evx.meta;
}

/* get the product of a sequence 
*/
auto product (R)(R range)
if (is_input_range!R)
{
	alias fold = reduce!((a,b) => a*b);

	return range.empty?
		typeof(fold (range))(0)
		: fold (range);
}
auto product (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return recursive_op!`*` (args);
}
alias Π = product;

/* get the sum of a sequence 
*/
auto sum (R)(R range)
if (is_input_range!R)
{
	return range.reduce!((a,b) => a+b)(ElementType!R (0));
}
auto sum (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return recursive_op!`+` (args);
}
alias Σ = sum;

/* get the arithmetic mean of a sequence
*/
auto mean (R)(R range)
if (is_input_range!R && has_length!R)
{
	return range.sum/range.length;
}
auto mean (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return args.sum/args.length;
}

/* get the first-order difference of elements in a range
*/
auto diff (R)(R range)
{
	return zip (range[1..$], range[0..$-1])
		.map!((a,b) => a - b);
}

unittest {
	assert ([1,2,3,4].sum == 10);
	assert (sum (1,2,3,4) == 10);

	assert ([1,2,3,4].product == 24);
	assert (product (1,2,3,4) == 24);

	assert ([1,2,3,4].mean == 2);
	assert ([1,2,3,4f].mean == 2.5);
	assert (mean (1,2,3,4f) == 2.5);

	assert (diff ([1,2,3,4]) == [1,1,1]);
	assert (diff (diff ([1,2,3,4])) == [0,0]);
}

private {//impl
	auto recursive_op (string op, T...)(T args)
	{
		static if (is (T[1]))
			return mixin(q{
				args[0] }~(op)~q{ recursive_op!op (args[1..$])
			});
		else return args[0];
	}
}
