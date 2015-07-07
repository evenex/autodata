module autodata.spaces.indexed;

private {
	import evx.meta;
	import evx.interval;
	import autodata.morphism;
	import autodata.traits;
}

auto indexed (S)(S space)
{
	auto limit (uint i)()
	{
		return space.limit!i;
	}

	return orthotope (Map!(limit, Iota!(dimensionality!S)))
		.zip (space);
}
