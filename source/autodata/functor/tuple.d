/**
    provides functorial capabilities for tuples,
    and some functions for manupulating the structure of tuples
*/
module autodata.functor.tuple;

private {//import
	import std.typecons;
	import std.traits;
	import std.conv;
	import evx.meta;
}

/**
    tuples are imported from std.typecons
*/
alias Tuple = std.typecons.Tuple;
/**
    ditto
*/
alias tuple = std.typecons.tuple;

/**
    functor map for tuples
*/
auto fmap (alias f, T...)(Tuple!T values)
{
    auto transformed (uint i)()
    {
        return f(values[i]);
    }

    return Map!(transformed, Ordinal!T).tuple;
}
///
unittest {
    import std.conv: to;

    auto x = Tuple!(int, int)(2,5);
    assert (x.fmap!(i => i*2) == tuple(4,10));

    auto y = Tuple!(string, size_t)("55", 55);
    assert (y.fmap!(to!int) == tuple(55,55));
}

/**
    map a tuple of functions over a tuple
*/
template fprod (funcs...)
{
    auto fprod (T...)(T values)
    if (T.length > 1 && not (is (T[0] == Tuple!U, U...)))
    {
        return fprod (values.tuple);
    }
    auto fprod (T...)(Tuple!T tuple)
    {
        auto apply (uint i)()
        {
            return funcs[i](tuple[i]);
        }

        return Map!(apply, Ordinal!T).tuple;
    }
}
///
unittest {
    static assert (tuple(1,1,1).fprod!(x => x, y => 2*y, z => 3*z) == tuple(1,2,3));
}

template Flatten (T...)
{
	static if (is (T[0] == Tuple!U, U...))
		alias Flatten = Cons!(Flatten!U, Flatten!(T[1..$]));

	else static if (is (T[0] == U, U))
		alias Flatten = Cons!(U, Flatten!(T[1..$]));

	else alias Flatten = Cons!();
}
/**
    flattens a tuple by recursively expanding it
*/
auto flatten (T)(T x)
{
	return (*cast(Tuple!(Flatten!T)*)&x);
}
///
unittest {
    auto x = tuple(2,5,7);
    auto y = tuple(2, 5, tuple(7));
    auto z = tuple(tuple(2), tuple(5, tuple(7)));

    assert (not (is (typeof(x == y))));
    assert (not (is (typeof(x == z))));
    assert (not (is (typeof(y == z))));

    assert (x.flatten == y.flatten);
    assert (x.flatten == z.flatten);
    assert (y.flatten == z.flatten);
}

/**
    swap the two elements in a tuple indexed by i and j
*/
auto swap (uint i, uint j, T...)(Tuple!T args)
{
    import std.algorithm: min, max;

    enum a = min (i,j);
    enum b = max (i,j);

    return tuple (args[0..a], args[b], args[a+1..b], args[a], args[b+1..$]);
}
///
unittest {
    assert (swap!(0,5)(tuple(0,1,2,3,4,5)) == tuple(5,1,2,3,4,0));
    assert (swap!(3,2)(tuple(0,1,2,3,4,5)) == tuple(0,1,3,2,4,5));
}
