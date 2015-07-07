module autodata.operators.range;

/** extension template meant to generate random access range primitives in a Sub structure

	Note that, in Phobos, the resulting range will only qualify as bidirectional
	because std.range.isRandomAccessRange does not handle template or non-property range primitives,
	although the range does meet the definition of random access as given in D range references.
*/
template RangeExt ()
{
	static if (Filter!(λ!q{(Axis) = Axis.is_free}, Axes).length == 1)
	@property {
		enum iterated_dimension = Filter!(λ!q{(Axis) = Axis.is_free}, Axes)[0].index;

		auto ref front () {return this[~$];}
		auto ref back ()() {return this[$-1];}

		auto popFront () {++bounds[iterated_dimension].left;}
		auto popBack ()() {--bounds[iterated_dimension].right;}

		auto empty () {return length == 0;}
		auto length () const {return bounds[iterated_dimension].width;}

		auto save () {return this;}

		auto opEquals (R)(R range)
		{
			import std.algorithm: equal;
			return equal (save, range);
		}
	}
}
///
unittest {
	import autodata.operators.slice;

	static struct Basic
	{
		int[] data = [1,2,3,4];

		auto access (size_t i) {return data[i];}
		auto length () const {return data.length;}

		mixin SliceOps!(access, length, RangeExt);
	}
	assert (Basic()[].length == 4);
	assert (Basic()[0..$/2].length == 2);
	foreach (_; Basic()[]){}
	foreach_reverse (_; Basic()[]){}

	static struct MultiDimensional
	{
		double[9] matrix = [
			1, 2, 3,
			4, 5, 6,
			7, 8, 9,
		];

		auto ref access (size_t i, size_t j)
		{
			return matrix[3*i + j];
		}

		enum size_t rows = 3, columns = 3;

		mixin SliceOps!(access, rows, columns, RangeExt);
	}
	assert (MultiDimensional()[0..$, 0].length == 3);
	assert (MultiDimensional()[0, 0..$].length == 3);
	foreach (_; MultiDimensional()[0..$, 0]){}
	foreach (_; MultiDimensional()[0, 0..$]){}
	foreach_reverse (_; MultiDimensional()[0..$, 0]){}
	foreach_reverse (_; MultiDimensional()[0, 0..$]){}
}

/**
	mixes range primitives into a struct

	all primitives act as forwarding calls and will be overridden by an existing definition
	save will pass saved_fields into constructor after base.save
	opEquals assumes the space has SliceOps with RangeExt

    RangeOps can be mixed in to the base space, while RangeExt is meant to be passed in as a Sub Extension.

    Using them together will equip a space with range ops,
    while using just RangeExt will equip only the Sub with range ops
*/
template RangeOps (alias base, alias length, saved_fields...)
{
	auto front ()()
	{
		return base.front;
	}
	auto popFront ()()
	{
		base.popFront;
	}
	auto back ()()
	{
		return base.back;
	}
	auto popBack ()()
	{
		base.popBack;
	}
	auto empty ()()
	{
		return length == 0;
	}
	auto save ()()
	{
		return typeof(this)(base.save, saved_fields);
	}
	bool opEquals (R)(R range)
	{
		return this[] == range;
	}
}
///
unittest {
    import autodata.operators.slice;

    struct T
    {
        int[] range = [1,2,3,4];

        auto length () const
        {
            return range.length;
        }

        auto access (size_t i)
        {
            return range[i];
        }

        mixin SliceOps!(access, length, RangeExt);
        mixin RangeOps!(range, length);
    }

    T t;

    import std.algorithm: equal;

    assert (t == [1,2,3,4]);
}
