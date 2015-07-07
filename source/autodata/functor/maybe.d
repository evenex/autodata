/**
    provides the maybe functor
*/
module autodata.functor.maybe;

private {
    import evx.meta;
}

/**
    a type which may be inhabited, or may contain nothing
*/
struct Maybe (T)
{
	T value;
	bool exists;

	this (T value)
	{
		this.value = value;
		exists = true;
	}
	this (typeof(null))
	{
	}

	auto opEquals (this that) const
	{
		if (this.exists && that.exists)
			return this.value == that.value;
		else if (this.exists || that.exists)
			return false;
		else
			return true;
	}

	auto toString ()() const
	{
		import std.conv : text;

		if (this.exists)
			return value.text;
		else
			return `null`;
	}

    // range interface
    alias front = value;
    alias empty = not!exists;
    auto popFront () {exists = false;}
}
///
unittest {
    import std.algorithm: equal;

    auto x = Maybe!int ();
    auto y = Maybe!int (5);

    assert (x.equal ((int[]).init));
    assert (y.equal ([5]));
}

/**
    functor map for maybe types
*/
auto fmap (alias f, T)(Maybe!T x)
{
	alias Return = Maybe!(typeof(f(x.value)));

	if (x.exists)
		return Return(f(x.value));
	else return Return(null);
}

/**
    Returns:
        true if value is inhabited
        false if it is nothing
*/
auto exists (T)(Maybe!T x)
{
    return x.exists;
}

/**
    assume a maybe is inhabited and extract its value

    Returns:
        the value in an inhabited maybe
*/
auto get (T)(Maybe!T x)
{
	assert (x.exists);

	return x.value;
}

/**
    Returns:
        if a maybe is inhabited, return its value.
        otherwise return the default value for the functor domain
*/
auto coerce (T)(Maybe!T x)
{
    if (x.exists)
        return x.get!T;
    else return T.init;
}
