module autodata.spaces.reindexed;

private { // import
    import std.conv;
    import evx.meta;
    import autodata.transform;
    import autodata.traits;
    import autodata.operators;
    import autodata.functor;
    import autodata.list;
    import autodata.spaces.orthotope;
    import evx.interval;

    // REVIEW where is std.range coming through?
    alias ElementType = autodata.traits.ElementType;
}

/**
    use the elements of inner_space to access elements in outer_space
*/
auto index_into (R,S)(R inner_space, S outer_space)
{
    static reindex (ElementType!R index, S into)
    {
        auto tuple ()() {return into[index.expand];}
        auto vector ()() {return into[index.tuple.expand];}

        return Match!(tuple, vector);
    }

    return inner_space.map!reindex (outer_space);
}
///
unittest {
    auto x = [9,8,7,6,  5,4,3,2,  1,0];

    auto y = ortho (interval (4,8))
        .index_into (x);

    assert (y == [5,4,3,2]);
}

struct IndexCast (S,T...)
{
    S space;

    alias U = CoordinateType!S;

    static if (T.length == 1)
        alias Coord = Repeat!(U.length, T);
    else static if (T.length == U.length)
        alias Coord = T;
    else
        static assert (0);

    auto access (Coord coord)
    {
        auto reindex (uint i)() {return coord[i].to!(U[i]);}
    
        return space[Map!(reindex, Ordinal!U).tuple.expand];
    }
    auto limit (uint i)() const
    {
        return space.limit!i.fmap!(to!(Coord[i]));
    }

    mixin AdaptorOps!(access, Map!(limit, Iota!(dimensionality!S)), RangeExt);
}
/**
    cast the coordinate type of a space to the given types, or all to the same type if only one type argument is given
*/
template cast_index_to (T...)
{
    auto cast_index_to (S)(S space)
    {
        return IndexCast!(S,T)(space);
    }
}

/**
    moves the origin of a space so that the 0 point has an equal measure of elements in each direction
*/
auto center_origin (S)(S space)
if (dimensionality!S > 1)
{
    auto width (uint i)()
    {
        return space.limit!i.width/2;
    }
    auto relimit (uint i)()
    {
        return (space.limit!i - width!i).fmap!signed;
    }
    alias dims = Iota!(dimensionality!S);

    return Map!(relimit, dims).orthotope
        .map!vector
        .map!sum (Map!(width, dims).vector)
        .index_into (space);
}
/**
    ditto
*/
auto center_origin (R)(R range)
if (dimensionality!R == 1)
{
    auto limit = range.limit!0;

    return (limit - limit.width/2)
        .fmap!signed.orthotope
        .map!sum (limit.width/2)
        .index_into (range);
}
///
unittest {
    auto r = [1,2,3,4,5,6,7,8];

    assert (r.center_origin[-4..4] == r[0..8]);
}
