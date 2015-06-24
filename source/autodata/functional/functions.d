module autodata.functional.functions; // REVIEW naming

private {// imports
    import evx.meta;
    import autodata.tuple;
}

template fprod (funcs...)
{
    auto fprod (T...)(Tuple!T tuple)
    {
        auto apply (uint i)()
        {
            return funcs[i](tuple[i]);
        }

        return Map!(apply, Ordinal!T).tuple;
    }
}

