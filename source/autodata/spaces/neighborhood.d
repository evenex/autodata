private {// imports
    import evx.interval;
    import evx.meta;
    import evx.infinity;
    import autodata.traits;
    import autodata.functional;
    import autodata.spaces.sequence;
    import autodata.spaces.embedded;
    import autodata.spaces.orthotope;
    import autodata.spaces.repeat;
    import autodata.spaces.vector;
}

auto neighborhood (alias boundary_condition = _ => ElementType!S.init, S, T, uint n)(S space, Vector!(n,T) origin, T radius)
{
    alias r = radius;

    auto diameter = interval (-r, r+T(1));

    alias infinite = Repeat!(n, interval (-infinity!T, infinity!T));
    alias stencil = Repeat!(n, diameter);

    static index_into (R)(Vector!(n,T) index, R outer_space)
    {
        return outer_space[index.tuple.expand];
    }

    return stencil.orthotope
        .map!(typeof(origin))
        .map!sum (origin)
        .map!index_into (
            space.embedded_in (
                infinite.orthotope
                    .map!boundary_condition 
            )
        );
}

