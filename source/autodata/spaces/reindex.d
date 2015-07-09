module autodata.spaces.reindexed;

private { // import
    import std.conv;
    import evx.meta;
    import evx.interval;
    import autodata.morphism;
    import autodata.traits;
    import autodata.operators;
    import autodata.functor.tuple;
    import autodata.list;
    import autodata.spaces.orthotope;
    import autodata.functor.vector;
}

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
template cast_index_to (T...)
{
    auto cast_index_to (S)(S space)
    {
        return IndexCast!(S,T)(space);
    }
}

auto center_origin (S)(S space)
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
