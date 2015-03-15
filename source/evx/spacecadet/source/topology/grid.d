module spacecadet.topology.grid;

private {/*imports}*/
	import std.conv;

	import spacecadet.core;
	import spacecadet.meta;
	import spacecadet.operators;
}

struct Grid (S)
	{/*...}*/
		S space;
		Repeat!(dimensionality!S, size_t) lengths;

		ElementType!S access (typeof(lengths) point)
			{/*...}*/
				auto space_limit (uint d)()
					{/*...}*/
						auto limit ()() {return space.limit!d;}
						typeof(space.length)[2] length ()() if (d == 0) {return [0, space.length];}

						return Match!(limit, length);
					}

				auto domain_transform (uint d)() {return space_limit!d.left + (point[d] * space_limit!d.width) / lengths[d];}

				auto sample ()() {return space[Map!(domain_transform, Count!(typeof(point)))];}
				auto stride ()() {return space[($*point[0])/lengths[0]];}

				return Match!(sample, stride);
			}

		size_t[2] limit (uint d)() const
			{/*...}*/
				return [0, lengths[d]];
			}

		mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!S)), RangeOps);
	}
auto grid (S, T...)(S space, T cells)
	{/*...}*/
		static assert (typeof(cells).length == dimensionality!S,
			`only ` ~ T.length.text ~ ` cell given for ` ~ dimensionality!S.text ~ `D space`
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
