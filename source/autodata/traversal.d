module autodata.traversal;

private {//import
	import std.conv: to;

	import evx.meta;
	import evx.interval;

	import autodata.traits;
	import autodata.morphism;
	import autodata.operators;
	import autodata.spaces.sequence;
	import autodata.spaces.only;
}

/* generate a foreach index for a custom range 
	this exploits the automatic tuple foreach index unpacking trick which is obscure and under controversy
	reference: https://issues.dlang.org/show_bug.cgi?id=7361
*/
auto enumerate (R)(R range)
if (is_input_range!R && has_length!R)
{
	return zip (Nat[0..range.length], range);
}

/* lexicographic traversal
*/
struct Lexicographic (S)
{
	S space;
	CoordinateType!S index;

	auto index_tuple () const
	{
		auto idx (uint i)()
		{
			return index[i] + space.limit!i.left;
		}

		return Map!(idx, Ordinal!index).tuple;
	}

	auto access (size_t i)
	{
		auto coord (uint j)() {return (i / space.limit!j.width).to!(typeof(index[j]));}

		return space[Map!(coord, Iota!(dimensionality!S)).tuple.expand];
	}

	auto ref front ()
	{
		return space[index_tuple.expand];
	}
	auto popFront ()
	{
		void advance (uint i = 0)()
		{
			if (++index[i] >= space.limit!i.width)
				static if (i+1 < index.length)
				{
					index[i] = 0;
					advance!(i+1);
				}
		}

		advance;
	}
	auto empty ()
	{
		return index[$-1] >= space.limit!(index.length-1).width;
	}

	auto opEquals (R)(R range)
	{
		import std.algorithm: equal;

		return this.equal (range);
	}

	auto length () const // REVIEW abstract into volume
	{
		auto dims (uint i)()
		{
			return space.limit!i.width;
		}

		return product (Map!(dims, Iota!(dimensionality!S))).to!size_t;
	}

	mixin AdaptorOps!(access, length, RangeExt);
}
auto lexicographic (S)(S space)
{
	return Lexicographic!S (space);
}
alias lexi = lexicographic;
unittest {
	import autodata.spaces;

	auto test = Array!(int, 2)(
		[1,2,3].extrude (3)
	);

	assert (test.lexi == [1,2,3,1,2,3,1,2,3]);
	assert (test.lexi[0] == test[0,0]);
	assert (test.lexi[6] == test[2,0]);
}

/*
	reshapes a 1D range into an nD space by breaking it into rows of the given lengths
*/
struct Laminated (R, uint n)
{
	R range;
	Repeat!(n, size_t) lengths;

	auto ref access (typeof(lengths) coord)
	{
		return range[
			zip (only (coord), only (1, lengths[0..$-1]))
				.map!product.sum
		];
	}
	auto limit (uint i)() const
	{
		return interval (0, lengths[i]);
	}

	mixin AdaptorOps!(access, Map!(limit, Iota!n), RangeExt);
}
auto laminate (R, T...)(R range, T lengths)
{
	return Laminated!(R, T.length)(range, lengths);
}
unittest {
	auto a = [1,2,3,4].laminate (2,2);

	assert (a[0..$,0] == [1,2]);
	assert (a[0..$,1] == [3,4]);
	assert (a[0,0..$] == [1,3]);
	assert (a[1,0..$] == [2,4]);
}
