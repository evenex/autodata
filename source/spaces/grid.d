module autodata.spaces.grid;

private {/*imports}*/
	import std.conv;

	import autodata.core;
	import autodata.meta;
	import autodata.operators;
}

struct Grid (S)
	{/*...}*/
		S space;
		Repeat!(dimensionality!S, size_t) lengths;

		ElementType!S access (typeof(lengths) point)
			{/*...}*/
				auto domain_transform (uint d)() {return space.limit!d.left + (point[d] * space.limit!d.width) / lengths[d];}

				auto sample ()() {return space[Map!(domain_transform, Ordinal!(typeof(point)))];}// REVIEW why does it work without tuple.expand?
				auto stride ()() {return space[($*point[0])/lengths[0]];}

				return Match!(sample, stride);
			}

		auto limit (uint d)() const
			{/*...}*/
				return interval (0, lengths[d]);
			}

		mixin AdaptorOps!(access, Map!(limit, Iota!(dimensionality!S)), RangeExt);
	}
auto grid (S, T...)(S space, T cells)
	{/*...}*/
		static assert (typeof(cells).length == dimensionality!S,
			`only ` ~T.length.text~ ` cell given for ` ~dimensionality!S.text~ `D space`
		);

		return Grid!S (space, cells);
	}
	unittest {/*...}*/
		import std.range;

		static struct IntegralIndex
			{/*...}*/
				auto access (size_t i)
					{/*...}*/
						return i;
					}

				size_t length = 100;

				mixin SliceOps!(access, length);
			}
		static struct FloatingPointIndex
			{/*...}*/
				auto access (float x) {return x;}

				float[2] bounds = [-1,1];

				mixin SliceOps!(access, bounds);
			}
		static struct MultiDimensional
			{/*...}*/
				auto access (size_t i, size_t j) {return i * columns + j;}

				size_t rows = 100;
				size_t columns = 100;

				mixin SliceOps!(access, rows, columns);
			}

		IntegralIndex a;
		FloatingPointIndex b;
		auto c = [1,2,3,4,5,6,7,8];
		MultiDimensional d;

		assert (a[].grid (10)[] == [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]);
		assert (b[].grid (4)[] == [-1, -0.5, 0, 0.5]);
		assert (c.grid (4)[] == c.stride (2));
		assert (c[0..4].grid (2)[] == c[0..4].stride (2));

		assert (d[].grid (10,10)[0, 0..$] == [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]);
		assert (d[].grid (10,10)[1, 0..$] == [1000, 1010, 1020, 1030, 1040, 1050, 1060, 1070, 1080, 1090]);
		assert (d[].grid (10,10)[0..$, 0] == [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000]);
	}
