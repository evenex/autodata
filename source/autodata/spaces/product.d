module autodata.spaces.product;

private {/*import}*/
	import autodata.transform;
	import autodata.operators;
	import autodata.traits;
	import autodata.functor.tuple;
	import autodata.spaces.orthotope;
	import evx.meta;
	import evx.interval;
}

struct ProductSpace (Spaces...)
{
	alias Offsets = Scan!(Sum, Map!(dimensionality, Spaces));

	Spaces spaces;

	auto limit (size_t d)() const
	{
		enum exceeds_d (int i) = d < i;
		alias LimitOffsets = Offsets[0..$ - Filter!(exceeds_d, Offsets).length + 1];
			
		enum i = LimitOffsets.length - 1;
		enum j = LimitOffsets[0] - 1;

		return spaces[i].limit!j;
	}

	auto access (Map!(CoordinateType, Spaces) point)
	in {
		static assert (typeof(point).length >= Spaces.length,
			`could not deduce coordinate type for ` ~Spaces.stringof
		);
	}
	body {
		template projection (size_t i)
		{
			auto π_i ()() {return spaces[i][point[0..Offsets[i]]];}
			auto π_n ()() {return spaces[i][point[Offsets[i-1]..Offsets[i]]];}

			alias projection = Match!(π_i, π_n);
		}

		return Map!(projection, Ordinal!Spaces).tuple.flatten;
	}

	mixin AdaptorOps!(access, Map!(limit, Ordinal!(Domain!access)), RangeExt);
}

/**
    take the cartesian product of two spaces.

    equivalent to a functional product of the indexing function.
*/
auto product_space (S,R...)(S left, R right)
{
	static if (is (S == ProductSpace!T, T...))
		return ProductSpace!(T,R)(left.spaces, right);

	else return ProductSpace!(S,R)(left, right);
}
///
unittest {
	import autodata.transform; 

	int[3] x = [1,2,3];
	int[3] y = [4,5,6];

	auto z = x[].by (y[]);

	assert (z.access (0,1) == tuple (1,5));
	assert (z.access (1,1) == tuple (2,5));
	assert (z.access (2,1) == tuple (3,5));

	auto w = z[].map!((a,b) => a * b);

	assert (w[0,0] == 4);
	assert (w[1,1] == 10);
	assert (w[2,2] == 18);

	auto p = w[].by (z[]);

	assert (p[0,0,0,0] == tuple (4,1,4));
	assert (p[1,1,0,1] == tuple (10,1,5));
	assert (p[2,2,2,1] == tuple (18,3,5));
}
/**
    ditto
*/
alias by = product_space;

/**
    add a dimension, whose limits are given by "extrusion", to a space.

    each slice along the added dimension is equivalent to the original space.
*/
auto extrude (S,T)(S space, T extrusion)
{
	auto a ()() if (is_interval!T) {return extrusion;}
	auto b ()() {return interval (T(0), extrusion);}

	return space.by (orthotope (Match!(a,b)))
		.extract!`expand[0]`;
}
///
unittest {
    auto x = [1,2,3].extrude (5);

    assert (dimensionality!(typeof(x)) == 2);
    assert (x[~$..$, 0] == x[~$..$, 4]);
    assert (x[~$..$, 0] == [1,2,3]);

    auto y = "hello".extrude (interval (12f, 15f));

    //assert (y[~$..$, 14.999] == "hello"); // BUG bounds exceeded on dimension 1! 14.999 not in const(Interval!(float, float))(14.999, 14.999)
    assert (y[~$..$, 14.999f] == "hello"); // BUG OK???
}
