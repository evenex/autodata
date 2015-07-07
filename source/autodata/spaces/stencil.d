module autodata.spaces.stencil;

private { // import
    import std.conv;
    import std.math;
    import evx.meta;
    import autodata.spaces.reindexed;
    import autodata.traversal;
}

auto stencil (T, uint n)(T[n] values)
{
    return values
        .laminate (Repeat!(2, sqrt(real(n)).to!int))
        .center_origin;
}
