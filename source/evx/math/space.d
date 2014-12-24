module evx.math.space;

private {/*import}*/
	import std.conv;

	import evx.type;
	import evx.operators;
	import evx.range;

	import evx.math.logic;
	import evx.math.algebra;
	import evx.math.intervals;
}

template dimensionality (Space)
	{/*...}*/
		template count (size_t d = 0)
			{/*...}*/
				static if (is (typeof(Space.init.limit!d)))
					enum count = 1 + count!(d+1);

				else static if (d == 0 && is (typeof(Space.init.length)))
					enum count = 1;

				else enum count = 0;
			}

		enum dimensionality = count!();
	}

template Coords (Space)
	{/*...}*/
		template Coord (size_t i)
			{/*...}*/
				static if (is (typeof(Space.init.limit!i.left) == T, T))
					alias Coord = T;

				else static if (i == 0 && is (typeof(Space.init.length.identity)))
					alias Coord = size_t;

				else static assert (0);
			}

		alias Coords = Map!(Coord, Iota!(dimensionality!(Space)));
	}

auto volume (S)(S space) // TODO doc and unittest
	{/*...}*/
		static if (dimensionality!S == 1 && is (typeof(space.length)))
			return space.length;
		else {/*...}*/
			auto product (T...)(T args) // REVIEW generalize... how conflicts with range product? can template constraints reconcile?
				{/*...}*/
					static if (is (T[1]))
						return args[0] * product (args[1..$]);
					else return args[0];
				}

			Map!(Element, typeof(space.bounds)) measures;

			foreach (i, ref measure; measures)
				measure = space.bounds[i].width;

			return product (measures);
		}
	}

struct Grid (Space)
	{/*...}*/
		Space space;
		Coords!Space[0] width;

		Element!Space access (Repeat!(dimensionality!Space, size_t) point)
			{/*...}*/
				auto domain_transform (uint d)() {return point[d] * width;}

				return space[Map!(domain_transform, Count!(typeof(point)))];
			}

		size_t[2] limit (uint d)() const // TODO static warning about non-constness... this will cause the limit to "disappear" from static analysis
			{/*...}*/
				auto pre = space.limit!d;
				
				pre[] /= width;

				return [pre.left.to!size_t, pre.right.to!size_t];
			}

		mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!Space)), RangeOps);
	}
auto grid (S,T)(S space, T width)
	{/*...}*/
		static assert (All!(is_type_of!T, Coords!S));

		return Grid!S (space, width);
	}
