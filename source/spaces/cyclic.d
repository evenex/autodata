module autodata.spaces.cyclic;

private {/*import}*/
	import std.math;

	import autodata.meta;
	import autodata.operators;
	import autodata.core;
	import autodata.sequence;
	import autodata.functional;
	import autodata.topology;
}

/* traverse a range with elements rotated left by some number of positions 
*/
auto rotate_elements (int dim = -1, R)(R range, int positions = 1)
	in {/*...}*/
		auto n = range.length;

		if (n > 0)
			assert ((-positions + (abs (positions)/n) * n) % n >= 0);
	}
	body {/*...}*/
		auto n = range.length;

		return range.cycle
			.drop ((-positions + (abs (positions)/n) * n) % n)
			.take (n);
	}
	unittest {/*...}*/
		assert ([1,2,3,4].rotate_elements[] == [4,1,2,3]);
		assert ([1,2,3,4].rotate_elements[] == [1,2,3,4].rotate_elements);
		assert ([1,2,3,4].rotate_elements (-1) == [1,2,3,4].rotate_elements (3));
	}

/* pair each element with its successor in the range, and the last element with the first 
*/
auto adjacent_pairs (R)(R range)
	{/*...}*/
		return zip (range, range.rotate_elements (-1));
	}
	void main ()
		{/*...}*/
			import std.stdio;

			writeln (["abc", "def", "ghi", "jkl", "mno"].adjacent_pairs.map!((a,b) => [a,b]));
		}

struct Cycle (R, uint[] cyclic_dims)
	{/*...}*/
		R space;

		auto access (CoordinateType!R coords)
			{/*...}*/
				auto coord (uint i)()
					{/*...}*/
						static if (cyclic_dims.contains (i))
							return (coords[i] - space.limit!i.left) % space.limit!i.width + space.limit!i.left;
						else return coords[i];
					}

				return space[Map!(coord, Ordinal!coords).tuple.expand];
			}
		auto limit (uint i)() const
			{/*...}*/
				alias Coord = CoordinateType!R[i];

				static if (cyclic_dims.contains (i))
					return Interval!(
						Select!(is_unsigned!Coord,
							Coord, Infinite!Coord,
						),
						Infinite!(Coord)
					)();
				else return space.limit!i;
			}

		mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!R)), RangeExt);

		static if (cyclic_dims.length == 1)
			{/*range ops}*/
				auto length ()() const
					{/*...}*/
						return limit!0.width;
					}

				mixin RangeOps!(space, length);
			}
	}
auto cycle (uint[] dim = [], S)(S space)
	{/*...}*/
		static if (dim.empty)
			enum d = [Iota!(dimensionality!S)];
		else alias d = dim;

		return Cycle!(S, d)(space);
	}
	unittest {/*...}*/
		import autodata.spaces.array;
		import autodata.spaces.product;
		import autodata.meta.test;

		auto x = [1,2,3].cycle;

		assert (x.limit!0.width == infinity);

		assert (x[0] == x[3]);
		assert (x[1] == x[4]);
		assert (x[2] == x[5]);

		assert (x[][0] == x[][3]);
		assert (x[][1] == x[][4]);
		assert (x[][2] == x[][5]);

		assert (x[0..infinity!size_t].limit!0.width == infinity);
		assert (x[0..infinity].limit!0.width == infinity);

		auto y = x[7..11];
		auto z = x[6..10];

		assert (z.length == y.length);
		assert (z.length == 4);

		assert (y[0] == z[1]);
		assert (y[1] == z[2]);
		assert (y[2] == z[3]);
		assert (y[3] == z[1]);

		auto a = ℕ[0..10].by (ℕ[0..10])
			.map!((a,b) => [a,b])
			.cycle;

		assert (a.limit!0.width == infinity);
		assert (a.limit!1.width == infinity);

		auto b = a[18..20, 9..$];

		assert (b.limit!0.width == 2);
		assert (b.limit!1.width == infinity);

		assert (b[0,0] == [8,9]);
		assert (b[0,1] == [8,0]);
		assert (b[$-1, 2] == [9,1]);

		/* cannot index a point at infinity 
		*/
		static assert (not (is (typeof(b[0, $-1]))));

		/*
			passing a compile-time array of indices to cycle specifies which dimensions to cycle
		*/
		auto c = ℕ[2..4].by (ℕ[5..7]).by (ℕ[66..71])
			.map!((a,b,c) => [a,b,c])
			.cycle!([1,2]);

		assert (c.limit!0.width == 2);
		assert (c.limit!1.width == infinity);
		assert (c.limit!2.width == infinity);
	}
