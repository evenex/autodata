module autodata.spaces.embedded;

private {// imports
	import autodata.traits;
	import autodata.operators;
	import autodata.spaces.orthotope;
	import evx.meta;
	import evx.interval;
	import std.traits : CommonType;
}

struct Embedded (Outer, Inner)
{
	Outer outer;
	Inner inner;

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
/**
    overlay inner space over outer space.

    indexing the space within the bounds of the inner space will access the inner space,
    otherwise the outer will be accessed
*/
auto embed (Outer, Inner)(Outer outer, Inner inner)
{
	foreach (i; Iota!(dimensionality!Outer))
		static assert (
			not (is (CommonType!(CoordinateType!Inner[i], CoordinateType!Outer[i]) == void)),
			`coordinate type mismatch: `
			~CoordinateType!Inner[i].stringof~
			` != `
			~CoordinateType!Outer[i].stringof
		);
	
	return Embedded!(Outer, Inner)(outer, inner);
}
/**
    ditto
*/
auto embedded_in (Inner, Outer)(Inner inner, Outer outer)
{
	return outer.embed (inner);
}
///
unittest {
	import autodata.morphism;

	auto x = ortho (interval (-1f, 1f), interval (-1f, 1f))
		.embed (
			map!((x,y) => tuple(2*x, 2*y))(
				ortho (interval (0f, 0.5f), interval (0f, 0.5f))
			)
		);

	assert (x[-0.1f, -0.1f] == tuple(-0.1f, -0.1f));
	assert (x[0.4f, 0.4f] == tuple(0.8f, 0.8f));
	assert (x[0.6f, 0.6f] == tuple(0.6f, 0.6f));
}
