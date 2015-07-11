module autodata.spaces.orthotope;

private {/*imports}*/
	import std.conv : to;
	import autodata.operators;
	import autodata.traits;
	import autodata.functor.tuple;
	import evx.interval;
	import evx.meta;
}

struct Orthotope (Intervals...)
{
	Intervals bounds;

	auto access (Map!(ElementType, Intervals) args)
	{
		return args.tuple;
	}

	auto limit (uint i)() const
	{
		return bounds[i];
	}

	mixin template InOperator ()
	{
		auto opBinaryRight (string op : `in`)(Domain!access coords)
		{
			auto coord_contained (int i = Intervals.length - 1)()
			{
				static if (i == -1)
					return true;
				else 
					return coords[i].is_contained_in (this.limit!i)
						&& coord_contained!(i-1)
						;
			}

			return coord_contained;
		}
		auto opBinaryRight (string op : `in`, T)(T vector)
		{
			auto coord (uint i)() {return vector[i].to!(Domain!access[i]);}

			return opBinaryRight!`in` (Map!(coord, Ordinal!Intervals));
		}
	}

	mixin InOperator;
	mixin AdaptorOps!(access, Map!(limit, Ordinal!Intervals), RangeExt, InOperator);

    static if (Intervals.length == 1)
    {
        auto front ()()
        {
            return tuple(bounds[0].left);
        }
        auto popFront ()()
        {
            ++bounds[0].left;
        }
        auto empty ()()
        {
            return bounds[0].width == typeof(bounds[0]).Left(0);
        }
        auto length ()() const
        {
            return limit!0.width;
        }
    }
}

/**
    construct a space whose limits are given by the supplied intervals.

    the elements of the space are tuples of the coordinates used to access them.
    
    in other words, indexing is an identity function.

    they can be useful to form the base of a more complex space,

    and for bounds checking.
*/
auto orthotope (Intervals...)(Intervals intervals)
if (All!(is_interval, Intervals))
{
	return Orthotope!Intervals (intervals);
}
///
unittest {
	import autodata.transform;

	assert (
		ortho (interval (3.9, 10.9), interval (10, 14))[5.6, ~$..$]
			.map!(x => [x.expand])
		== [[5.6, 10], [5.6, 11], [5.6, 12], [5.6, 13]]
	);
}

/**
    construct an orthotope with the same limits as a given space
*/
auto orthotope (S)(S space)
if (not (is_interval!S))
{
	auto lim (uint i)() {return space.limit!i;}

	return orthotope (Map!(lim, Iota!(dimensionality!S)));
}
///
unittest {
    /*
        orthotopes can be queried for containing a given set of coordinates.

        this can be convenient for bounds checking.
    */
	assert (0 in ortho (interval (0,11)));
	assert (10 in ortho (interval (0,11)));
	assert (11 !in ortho (interval (0,11)));
	assert (-1 !in ortho (interval (0,11)));
}

/**
*/
alias ortho = orthotope;
