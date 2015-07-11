module autodata.spaces.neighborhood;

private {// imports
    import evx.interval;
    import evx.meta;
    import evx.infinity;
    import autodata.traits;
    import autodata.morphism;
    import autodata.list;
    import autodata.spaces.embedded;
    import autodata.spaces.orthotope;
    import autodata.spaces.reindexed;
    import autodata.spaces.repeat;
    import autodata.functor.vector;

    alias ElementType = autodata.traits.ElementType;//REVIEW where is it coming from
}

/**
    the minimal orthotope containing the "radius" elements in each indexed direction around the central element given by "origin"
*/
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
///
unittest {
    import autodata.spaces.reshape;

    auto x = [
         1, 2, 3, 4,
         5, 6, 7, 8,
         9,10,11,12,
        13,14,15,16,
    ]
        .laminate (4,4);

    assert (x.neighborhood (vector (1,2), 1).lexi == [
        5,  6, 7,
        9, 10, 11,
        13,14, 15
    ]);

    assert (x.neighborhood (vector (0,0), 1).lexi == [
        0, 0, 0,
        0, 1, 2,
        0, 5, 6
    ]);
}
