module evx.math.grid;

private {/*imports}*/
	import std.conv;

	import evx.math.logic;
	import evx.math.space;
	import evx.math.intervals;

	import evx.type;
	import evx.operators;
	import evx.range;
	import evx.misc.patch;
}

struct Grid (Space)
	{/*...}*/
		Space space;
		Repeat!(dimensionality!Space, size_t) lengths;

		Element!Space access (typeof(lengths) point)
			{/*...}*/
				auto domain_transform (uint d)() {return space.limit!d.left + point[d] * space.limit!d.width / lengths[d];}

				return space[Map!(domain_transform, Count!(typeof(point)))];
			}

		size_t[2] limit (uint d)() const
			{/*...}*/
				return [0, lengths[d]];
			}

		mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!Space)), RangeOps);
	}
auto grid (S, T...)(S space, T cells)
	{/*...}*/
		static assert (typeof(cells).length == dimensionality!S);

		return Grid!S (space, cells);
	}
