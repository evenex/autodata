module autodata.spaces.product;

private {/*import}*/
	import autodata.core;
	import autodata.functional;
	import autodata.meta;
	import autodata.operators;
}

struct CartesianProduct (Spaces...)
	{/*...}*/
		alias Offsets = Scan!(Sum, Map!(dimensionality, Spaces));

		Spaces spaces;

		auto limit (size_t d)() const
			{/*...}*/
				mixin LambdaCapture;

				alias LimitOffsets = Offsets[0..$ - Filter!(λ!q{(int i) = d < i}, Offsets).length + 1];
					
				enum i = LimitOffsets.length - 1;
				enum d = LimitOffsets[0] - 1;

				return spaces[i].limit!d;
			}

		auto access (Map!(CoordinateType, Spaces) point)
			in {/*...}*/
				static assert (typeof(point).length >= Spaces.length,
					`could not deduce coordinate type for ` ~Spaces.stringof
				);
			}
			body {/*...}*/
				template projection (size_t i)
					{/*...}*/
						auto π_i ()() {return spaces[i][point[0..Offsets[i]]];}
						auto π_n ()() {return spaces[i][point[Offsets[i-1]..Offsets[i]]];}

						alias projection = Match!(π_i, π_n);
					}

				return Map!(projection, Ordinal!Spaces).tuple.flatten;
			}

		mixin SliceOps!(access, Map!(limit, Ordinal!(Domain!access)), RangeOps);
	}

auto cartesian_product (S,R)(S left, R right)
	{/*...}*/
		static if (is (S == CartesianProduct!T, T...))
			return CartesianProduct!(T,R)(left.spaces, right);

		else return CartesianProduct!(S,R)(left, right);
	}
	unittest {/*...}*/
		import autodata.functional; 

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

alias by = cartesian_product;

auto extrude (S,R)(S space, R extrusion)
	if (dimensionality!R == 1)
	{/*...}*/
		return space.by (extrusion)
			.map!((e,_) => e);
	}
