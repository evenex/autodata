module autodata.spaces.along;

private {//imports
    import autodata.traits;
    import autodata.list;
    import autodata.operators;
    import std.conv;
    import std.range;
    import evx.meta;
    import evx.interval;

    alias ElementType = autodata.traits.ElementType;
}

struct Along (uint[] axes, S)
{
    S space;

    enum n_dims = axes.length;

    alias Coord (uint axis) = CoordinateType!S[axis];

    template ConsAxes (uint[] a)
    {
        static if (a.length > 1)
            alias ConsAxes = Cons!(a[0], ConsAxes!(a[1..$]));
        else 
            alias ConsAxes = Cons!(a[0]);
    }

    alias Axes = ConsAxes!(axes);

    auto access (Map!(Coord, Axes) index)
    {
        enum coord (uint i) = axes.contains (i)? 
            q{index[axes.count_until (}~(i.text)~q{)]} : q{~$..$};

        return mixin(q{
            space[} ~ [Map!(coord, Iota!(dimensionality!S))].join (`,`).to!string ~ q{]
        });
    }

    auto limit (uint i)() const
    {
        return space.limit!(axes[i]);
    }

    auto length ()() const
    if (axes.length == 1)
    {
        return limit!0.width;
    }

    mixin AdaptorOps!(access, Map!(limit, Ordinal!Axes), RangeExt);
    mixin RangeOps!(opIndex, length);
}

/**
    collapses the given dimensions of a space into points. 
    essentially, decomposing each of the indexing/slicing functions into two - the first of which partially applies the coordinates indexed by [axes], the second of which completes it.
*/
auto along (uint[] axes, S)(S space)
{
    return Along!(axes, S)(space);
}
///
unittest {
    import autodata.spaces.product;
    import autodata.transform;

    auto x = Nat[8..12].map!(x => 2*x)
        .by (Nat[10..13].map!(x => x/2));

    assert (x.along!([1])[0].map!((a,b) => a) == [16, 18, 20, 22]);
    assert (x.along!([0])[0].map!((a,b) => b) == [5, 5, 6]);

    enum N = Nat[0..100];
    auto y = N.by (N).by (N);

    alias dims = dimensionality;

    alias R = typeof(y.along!([0]));

    static assert (dims!R == 1);
    static assert (dims!(ElementType!R) == 2);

    alias S = typeof(y.along!([0,1]));

    static assert (dims!S == 2);
    static assert (dims!(ElementType!S) == 1);
}
