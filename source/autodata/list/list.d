module autodata.list.list;

private {//imports 
    import evx.interval;
    import std.traits;
    import autodata.operators;
}

struct List (T, uint n)
{
    T[n] items;
    Interval!size_t slice;

    auto front ()
    {
        return items[slice.left];
    }
    auto popFront ()
    {
        ++slice.left;
    }
    auto back ()
    {
        return items[slice.right-1];
    }
    auto popBack ()
    {
        --slice.right;
    }
    auto empty ()
    {
        return slice.width == 0;
    }

    auto access (size_t i)
    {
        return items[i];
    }
    auto length () const
    {
        return slice.width;
    }

    mixin AdaptorOps!(access, length, RangeExt);
    mixin RangeOps!(items, length);
}

/**
    encapsulates a list of items in a slicable, iterable structure
*/
auto list (Items...)(Items items)
{
    enum n = Items.length;

    return List!(CommonType!Items, n)(
        [items],
        interval (0,n)
    );
}
///
unittest {
    assert (list (1,2,3,4) == [1,2,3,4]);
    assert (list (1,2,3,4)[1..3] == [2,3]);
}
