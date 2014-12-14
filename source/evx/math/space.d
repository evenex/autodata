module evx.math.space;

private {/*import}*/
	import evx.type;
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
