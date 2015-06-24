module autodata.spaces.only;

private {//imports 
    import evx.interval;
    import std.traits;
    import autodata.operators;
}

struct Only (T, uint n)
{
    T[n] data;
    Interval!size_t slice;

    auto front ()
    {
        return data[slice.left];
    }
    auto popFront ()
    {
        ++slice.left;
    }
    auto back ()
    {
        return data[slice.right-1];
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
        return data[i];
    }
    auto length () const
    {
        return slice.width;
    }

    mixin AdaptorOps!(access, length, RangeExt);
}
auto only (Args...)(Args args)
{
    enum n = Args.length;

    return Only!(CommonType!Args, n)([args], interval (0, n));
}
