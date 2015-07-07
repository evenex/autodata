module autodata.morphism.functions; // REVIEW naming

private {// imports
    import evx.meta;
    import autodata.functor.tuple;
}

template fprod (funcs...)
{
    auto fprod (T...)(T values)
    if (T.length > 1 && not (is (T[0] == Tuple!U, U...)))
    {
        return fprod (values.tuple);
    }
    auto fprod (T...)(Tuple!T tuple)
    {
        auto apply (uint i)()
        {
            return funcs[i](tuple[i]);
        }

        return Map!(apply, Ordinal!T).tuple;
    }
}

