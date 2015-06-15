module autodata.spaces.embedded;

private { // imports
	import autodata.traits;
	import autodata.spaces.orthotope;
	import evx.meta;
	import evx.interval;
}

// TODO doc
// TODO test
struct Embedded (Outer, Inner)
{
	Outer outer;
	Inner inner;
	CoordinateType!Outer origin;

	auto access (CoordinateType!Outer coord)
	{
		return coord in inner.orthotope?
			inner[coord]
			: outer[coord];
	}
	auto limit (uint i)() const
	{
		return outer.limit!i;
	}

	mixin AdaptorOps!(access, Map!(limit, Iota!(dimensionality!Outer)));
}
auto embed (Outer, Inner, Coord...)(Outer outer, Inner inner, Coord origin)
{
	foreach (i,_; Coord)
		static assert (
			is (Coord[i] : CoordinateType!Outer[i])
			&& is (Coord[i] : CoordinateType!Inner[i]),
			`coordinate type mismatch`
		);
	
	return Embedded!(Outer, Inner)(outer, inner, origin);
}
