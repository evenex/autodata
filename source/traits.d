module autodata.traits;

private {//import
	import std.traits;
	import std.range;

	import evx.meta;
	import evx.interval;
}

/* get the element type, which a space contains 
*/
template ElementType (S)
{
	static if (
		CoordinateType!S.length > 0 
		&& is (typeof(S.init[CoordinateType!S.init]) == T, T)
	)
		alias ElementType = T;

	else static if (is (S.Element == T, T))
		alias ElementType = T;

	else alias ElementType = std.range.ElementType!S;

	static assert (!(is (S == ElementType)),
		`could not deduce element type of `~(S.stringof)
	);
}

/* get the coordinate type of a space, which can be used to index into the space 
*/
template CoordinateType (S)
{
	template Coord (size_t i)
	{
		static if (is (typeof(S.opIndex.limit!i.identity).Element == T, T))
			alias Coord = T;

		else static if (i == 0 && is (typeof(S.init[0])))
			alias Coord = size_t;

		else alias Coord = void;
	}

	alias CoordinateType = Map!(Coord, Iota!(dimensionality!S));
}

/* get the number of dimensions of a space 
*/
template dimensionality (S)
{
	template count (size_t d = 0)
	{
		static if (
			is (typeof(S.init.opSlice!d))
			|| is (typeof(S.init.opIndex.limit!d))
		)
			enum count = 1 + count!(d+1);

		else static if (d == 0  
			&& is (typeof(S.init[].length.identity))
		)
			enum count = 1;

		else enum count = 0;
	}

	enum dimensionality = count!();
}
