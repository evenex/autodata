module autodata.spaces.stencil;

private { // import
    import std.conv;
    import std.math;
    import evx.meta;
    import autodata.spaces.indexed;
    import autodata.spaces.reindexed;
    import autodata.spaces.reshape;
}

/**
    create a 2D square space out of a static array
*/
auto stencil (T, uint n)(T[n] values)
{
    return values
        .laminate (Repeat!(2, sqrt(real(n)).to!int))
        .center_origin;
}
///
unittest {
    import evx.interval;

    auto x = [
        0.5, 1.0, 0.5,
        1.0, 0.0, 1.0,
        0.5, 1.0, 0.5
    ].stencil;

    assert (x.limit!0 == interval(-1,2));
    assert (x.limit!1 == interval(-1,2));

    auto y = [
        0.2, 0.4, 0.6, 0.4, 0.2,
        0.4, 0.6, 0.8, 0.6, 0.4,
        0.6, 0.8, 1.0, 0.8, 0.6,
        0.4, 0.6, 0.8, 0.6, 0.4,
        0.2, 0.4, 0.6, 0.4, 0.2,
    ].stencil;

    assert (y.limit!0 == interval(-2,3));
    assert (y.limit!1 == interval(-2,3));
}
