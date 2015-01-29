module evx.math.space;

private {/*import}*/
	import evx.type;
	import evx.range;

	import evx.math.algebra;
	import evx.math.intervals;
	import evx.math.arithmetic;
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

auto volume (S)(auto ref S space) // TODO doc and unittest
	{/*...}*/
		static if (dimensionality!S == 0)
			return volume (space[]);
		else static if (dimensionality!S == 1 && is (typeof(space.length)))
			return space.length;
		else {/*...}*/
			Coords!S measures;

			foreach (i, ref measure; measures)
				measure = space.bounds[i].width;

			return product (measures);
		}
	}
