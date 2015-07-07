module autodata.spaces.neighborhood;

private {// imports
    import evx.interval;
    import evx.meta;
    import evx.infinity;
    import autodata.traits;
    import autodata.morphism;
    import autodata.spaces.sequence;
    import autodata.spaces.embedded;
    import autodata.spaces.orthotope;
    import autodata.spaces.reindexed;
    import autodata.spaces.repeat;
    import autodata.functor.vector;
}

auto neighborhood (alias boundary_condition = _ => ElementType!S.init, S, T, uint n)(S space, Vector!(n,T) origin, T radius)
{
    alias r = radius;

    auto diameter = interval (-r, r+T(1));

    alias infinite = Repeat!(n, interval (-infinity!T, infinity!T));
    alias stencil = Repeat!(n, diameter);

    return stencil.orthotope
        .map!(Vector!(n,T))
        .map!sum (origin)
        .index_into (
            space.embedded_in (
                infinite.orthotope
                    .map!boundary_condition 
            )
        );
}

