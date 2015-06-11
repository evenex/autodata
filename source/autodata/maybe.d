module autodata.maybe;

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

	auto toString () const
	{
		import std.conv : text;

		if (this.exists)
			return value.text;
		else
			return `null`;
	}
}
auto fmap (alias f, T)(Maybe!T x)
{
	alias Return = Maybe!(typeof(f(x.value)));

	if (x.exists)
		return Return(f(x.value));
	else return Return(null);
}
auto get (T)(Maybe!T x)
{
	assert (x.exists);

	return x.value;
}
T[1] to_list (T)(Maybe!T x)
{
	if (x.exists)
		return [x.value];
	else return typeof(return).init;
}
