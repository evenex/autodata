module autodata.spaces.indexed;

private {//import
	import std.conv: to;

	import evx.meta;
	import evx.interval;

	import autodata.traits;
	import autodata.transform;
	import autodata.operators;
	import autodata.list;
	import autodata.functor;
	import autodata.spaces.orthotope;
}

/** 
    pair each element in a space with its index.

	foreach exploits the automatic tuple foreach index unpacking trick which is obscure and under some controversy

	<a href="https://issues.dlang.org/show_bug.cgi?id=7361">reference</a>
*/
auto index (S)(S space)
{
    auto space_limit (uint i)()
    {
        return space.limit!i;
    }

	return zip (
        Map!(space_limit, Iota!(dimensionality!S)).orthotope,
        space
    );
}
///
unittest {
    import autodata.spaces.reshape;

    auto s = [1,2,3,4].laminate (2,2).index;

    assert (s[0,0] == tuple(tuple(0,0), 1));
    assert (s[1,0] == tuple(tuple(1,0), 2));
    assert (s[0,1] == tuple(tuple(0,1), 3));
    assert (s[1,1] == tuple(tuple(1,1), 4));
}

/**
    index, for 1D ranges
*/
auto enumerate (R)(R range)
if (is_input_range!R && has_length!R)
{
    return index (range);
}
///
unittest {
    auto xs = list (1,2,3,4);

    assert (not (__traits(compiles, (){  
        foreach (i, x; xs)
            assert (x);
    })));

    foreach (i, x; enumerate (xs))
        assert (x + i);
}
