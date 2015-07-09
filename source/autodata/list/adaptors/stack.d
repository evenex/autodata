module autodata.list.adaptors.stack;

private {//imports
	import std.conv: text;
	import autodata.traits;
	import autodata.operators;
	import autodata.list.adaptors.policy;
	import autodata.list.adaptors.common;
	import evx.interval;
}

/**
    appendable stack wrapper for a list which supports element assignment
*/
struct Stack (R, OnOverflow overflow_policy = OnOverflow.error)
{
	R store;
	alias store this;

	mixin AdaptorCapacity;
	mixin AdaptorCtor;

    /**
        gives the length of the queue (as opposed to the length of the backing store)
    */
	auto length () const
	{
		return _length;
	}

    /**
        provides index assignment operators
    */
	auto ref access (size_t i)
	{
		return store[i];
	}

    /**
        provides slice assignment operators
    */
	void pull (R)(R range, size_t i)
	{
		pull (range, i, i+1);
	}
    /**
        ditto
    */
	void pull (R)(R range, Interval!size_t interval)
	{
		auto i = interval.left, j = interval.right;

		auto pulled ()() {store[i..j] = range;}
		auto iterated ()() {foreach (k; i..j) store[k] = range[k-i];}

		Match!(pulled, iterated);
	}

    /**
        push appends a single element or all the elements in a given range to the top of the stack
    */
	auto ref push (S)(S range)
	if (not (is (S : ElementType!R)))
	{
		if (exit_on_overflow (range.length))
			return this;

		_length += range.length;

		this[$-range.length..$] = range;

		return this;
	}
    /**
        ditto
    */
	auto ref push (T)(T element)
	if (is (T : ElementType!R))
	{
		if (exit_on_overflow (1))
			return this;

		++_length;

		this[$-1] = element;

		return this;
	}

    /**
        pop removes count elements from the top of the stack, or 1 element if no count is given
    */
	auto ref pop (size_t count)
	in {
		assert (count <= length,
			`attempted to pop ` ~ count.text ~ ` from ` ~ Stack.stringof ~ ` of length ` ~ length.text
		);
	}
	body {
		_length -= count;

		return this;
	}
    /**
        ditto
    */
	auto ref pop ()
	{
		return this -= 1;
	}

    /**
        aliased to push
    */
	alias opOpAssign (string op : `~`) = push;
    /**
        aliased to pop
    */
    alias opOpAssign (string op : `-`) = pop;
    /**
        ditto
    */
	alias opUnary (string op : `--`) = pop;

    /**
        sets the length of the queue to 0
    */
	auto clear ()
	{
		_length = 0;
	}

	mixin TransferOps!(pull, SliceOps, access, length, RangeExt);

	private mixin OverflowPolicy;
	private size_t _length;
}
///
unittest {
	auto A = Stack!(int[])();

	A.capacity = 100;

	A ~= 1;
	A ~= 2;

	assert (A[].length == 2);
	assert (A[] == [1,2]);

	A ~= [3,4];

	assert (A[] == [1,2,3,4]);

	A--;

	assert (A[] == [1,2,3]);

	A -= 2;

	assert (A[] == [1]);

	A.clear;

	assert (A[].empty);

	A ~= [1,2,3,4,5];
	A[1..4] = [4,3,2];

	assert (A[] == [1,4,3,2,5]);
}
