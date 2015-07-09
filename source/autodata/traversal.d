module autodata.traversal;

private {//import
	import std.conv: to;

	import evx.meta;
	import evx.interval;

	import autodata.traits;
	import autodata.morphism;
	import autodata.operators;
	import autodata.list;
	import autodata.spaces.orthotope;
}

// REVIEW why are these coming through
alias min = autodata.list.min;
alias max = autodata.list.max;

/** 
    pair each element in a space with its index.

	foreach exploits the automatic tuple foreach index unpacking trick which is obscure and under some controversy

	<a href="https://issues.dlang.org/show_bug.cgi?id=7361">reference</a>
*/
auto index (S)(S space)
{
    auto space_limit (uint i)()
    {
        return space.limit!i;
    }

	return zip (
        Map!(space_limit, Iota!(dimensionality!S)).orthotope,
        space
    );
}
///
unittest {
    auto s = [1,2,3,4].laminate (2,2).index;

    assert (s[0,0] == tuple(tuple(0,0), 1));
    assert (s[1,0] == tuple(tuple(1,0), 2));
    assert (s[0,1] == tuple(tuple(0,1), 3));
    assert (s[1,1] == tuple(tuple(1,1), 4));
}

/**
    swap the two elements in a tuple indexed by i and j
*/
auto swap (uint i, uint j, T...)(Tuple!T args)
{
    enum a = min (i,j);
    enum b = max (i,j);

    return tuple (args[0..a], args[b], args[a+1..b], args[a], args[b+1..$]);
}
///
unittest {
    assert (swap!(0,5)(tuple(0,1,2,3,4,5)) == tuple(5,1,2,3,4,0));
    assert (swap!(3,2)(tuple(0,1,2,3,4,5)) == tuple(0,1,3,2,4,5));
}

// REVIEW SOMEWHERE ELSE
struct Transposed (uint x, uint y, S)
{
    S space;

    enum a = min (x,y);
    enum b = max (x,y);

    enum dims = dimensionality!S;

    alias CoordIndices = Swap!(a,b, Iota!dims);
    alias Coords = Swap!(a,b, CoordinateType!S);

    auto access (Coords coord)
    {
        return space[swap!(a,b)(coord.tuple).expand];
    }

    auto limit (uint i)() const
    {
        return space.limit!(CoordIndices[i]);
    }

    mixin AdaptorOps!(access, Map!(limit, Iota!dims), RangeExt);
}
/**
    swap the positions of two dimensions in a space.

    defaults to a typical 2D transposition
*/
auto transpose (uint x = 0, uint y = 1, S)(S space)
{
    return Transposed!(x,y,S)(space);
}
///
unittest {
    auto x = [
        1,2,
        3,4
    ].laminate (2,2);

    auto y = x.transpose;

    assert (x[0..2, 0] == [1,2]);
    assert (x[0..2, 1] == [3,4]);

    assert (y[0..2, 0] == [1,3]);
    assert (y[0..2, 1] == [2,4]);
}

// REVIEW SOMEWHERE ELSE
/**
    index, for 1D ranges
*/
auto enumerate (R)(R range)
if (is_input_range!R && has_length!R)
{
    return index (range);
}
///
unittest {
    auto xs = list (1,2,3,4);

    assert (not (__traits(compiles, (){  
        foreach (i, x; xs)
            assert (x);
    })));

    foreach (i, x; enumerate (xs))
        assert (x + i);
}

// REVIEW TO RESHAPE
/** 
    lexicographic traversal
    over n-dimensional spaces indexed by integral types
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
/**
    ditto
*/
auto lexicographic (S)(S space)
{
	return Lexicographic!S (space);
}
/**
    ditto
*/
alias lexi = lexicographic;
///
unittest {
	auto test = [
        1,2,3,
        1,2,3,
        1,2,3,
    ].laminate (3,3);

	assert (test.lexi == [1,2,3,1,2,3,1,2,3]);
	assert (test.lexi[0] == test[0,0]);
	assert (test.lexi[6] == test[2,0]);
}

// REVIEW TO RESHAPE
/**
	reshape a 1D range into an n-dimensional space by breaking it into rows of the given lengths
*/
struct Laminated (R, uint n)
{
	R range;
	Repeat!(n, size_t) lengths;

	auto ref access (typeof(lengths) coord)
	{
		return range[
			zip (list (coord), list (1, lengths[0..$-1]))
				.map!product.sum
		];
	}
	auto limit (uint i)() const
	{
		return interval (0, lengths[i]);
	}

	mixin AdaptorOps!(access, Map!(limit, Iota!n), RangeExt);
}
/**
    ditto
*/
auto laminate (R, T...)(R range, T lengths)
{
	return Laminated!(R, T.length)(range, lengths);
}
///
unittest {
	auto a = [1,2,3,4].laminate (2,2);

	assert (a[0..$,0] == [1,2]);
	assert (a[0..$,1] == [3,4]);
	assert (a[0,0..$] == [1,3]);
	assert (a[1,0..$] == [2,4]);
}
