/**
    provides arithmetic functions for expanded lists (which can be passed into functions as argument lists)
        and iterable ranges
*/
module autodata.list.arithmetic;

private {//import
	import std.range.primitives: front, back, popFront, popBack, empty;

	import autodata.morphism;
	import autodata.traits;

	import evx.meta;
}

/** get the product of a sequence 
*/
auto product (R)(R range)
if (is_input_range!R)
{
	alias fold = reduce!((a,b) => a*b);

	return range.empty?
		typeof(fold (range))(0)
		: fold (range);
}
/**
    ditto
*/
auto product (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return recursive_op!`*` (args);
}
/**
    ditto
*/
alias Π = product;
///
unittest {
	assert ([1,2,3,4].product == 24);
	assert (product (1,2,3,4) == 24);
}

/** get the sum of a sequence 
*/
auto sum (R)(R range)
if (is_input_range!R)
{
	return range.reduce!((a,b) => a+b)(ElementType!R (0));
}
/**
    ditto
*/
auto sum (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return recursive_op!`+` (args);
}
/**
    ditto
*/
alias Σ = sum;
///
unittest {
	assert ([1,2,3,4].sum == 10);
	assert (sum (1,2,3,4) == 10);
}

/** get the arithmetic mean of a sequence
*/
auto mean (R)(R range)
if (is_input_range!R && has_length!R)
{
	return range.sum/range.length;
}
/**
    ditto
*/
auto mean (T...)(T args)
if (not (Any!(is_input_range, T)))
{
	return args.sum/args.length;
}
///
unittest {
	assert ([1,2,3,4].mean == 2);
	assert ([1,2,3,4f].mean == 2.5);
	assert (mean (1,2,3,4f) == 2.5);
}

/** get the first-order difference of elements in a range
*/
auto diff (R)(R range)
{
	return zip (range[1..$], range[0..$-1])
		.map!((a,b) => a - b);
}
///
unittest {
	assert (diff ([1,2,3,4]) == [1,1,1]);
	assert (diff (diff ([1,2,3,4])) == [0,0]);
}

private enum OptimizedSide {min, max}

/**
	get the min and max of a range or a set of parameters
*/
alias min = optimum!(OptimizedSide.min);
/**
    ditto
*/
alias max = optimum!(OptimizedSide.max);
///
unittest {
    alias items = Cons!(4,2,6,7,1,2);

    assert (items.min == 1);
    assert (items.max == 7);
    assert ([items].min == 1);
    assert ([items].max == 7);
}

template optimum (OptimizedSide side)
{
	auto optimum (T...)(T args)
    if (not (Any!(is_input_range, T)))
	{
		enum choice = side == OptimizedSide.min? 1 : 0;

		static if (T.length == 1)
			return args[0];
		else
			return optimum (
				args[0] > args[1]?
					args[choice] 
					: args[(choice + 1)%2]
				, args[2..$]
			);
	}

	auto optimum (R)(R range)
    if (is_input_range!R)
	{
        return range.reduce!(optimum!(Repeat!(2, ElementType!R)));
	}
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
