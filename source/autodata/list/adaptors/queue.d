module autodata.list.adaptors.queue;

private {//imports
	import autodata.traits;
	import autodata.operators;
	import autodata.list.adaptors.policy;
	import autodata.list.adaptors.common;

	import evx.interval;
}

/**
    appendable queue wrapper for a list which supports element assignment
*/
struct Queue (R, OnOverflow overflow_policy = OnOverflow.error)
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
		auto i = limit[0], j = limit[1];

		if (i <= j)
			return j - i;
		else return (capacity - i) + j + 1;
	}

    /**
        provides index assignment operators
    */
	auto ref access (size_t i)
	{
		return store[(limit[0] + i) % capacity];
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
		auto i = limit[0] + interval.left,
			j = limit[0] + interval.right; 

		i %= capacity;
		j = (j == capacity)? j : j % capacity;

		if (i <= j)
		{
			auto pulled ()() {store[i..j] = range;}
			auto iterated ()() {foreach (k; i..j) store[k] = range[k-i];}

			Match!(pulled, iterated);
		}
		else {
			immutable c = capacity;

			auto wrapped_pulled ()() 
			{
				store[i..c] = range[0..c-i];
				store[0..j] = range[c-i..$];
			}
			auto wrapped_iterated ()()
			{
				foreach (k; i..c) store[k] = range[k-i];
				foreach (k; 0..j) store[k] = range[k-(c-i)];
			}

			Match!(wrapped_pulled, wrapped_iterated);
		}
	}

    /**
        push appends a single element or all the elements in a given range to the end of the queue
    */
    auto ref push (S)(S range)
	if (not (is (S : ElementType!R)))
	{
		if (exit_on_overflow (range.length))
			return this;

		limit[1] += range.length;
		limit[1] %= (capacity + 1);

		this[$ - range.length..$] = range;

		return this;
	}
    /**
        ditto
    */
	auto ref push  (T)(T element)
	if (is (T : ElementType!R))
	{
		if (exit_on_overflow (1))
			return this;

		++limit[1];
		limit[1] %= (capacity + 1);

		this[$-1] = element;

		return this;
	}

    /**
        pop removes count elements from the beginning of the queue, or 1 element if no count is given
    */
	auto ref pop (size_t count)
	in {
		assert (count < length);
	}
	body {
		limit[0] += count + capacity;
		limit[0] %= capacity;

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
		limit[0] = limit[1] = 0;
	}

	mixin TransferOps!(pull, SliceOps, access, length, RangeExt);

	private mixin OverflowPolicy;
	private size_t[2] limit;
}
///
unittest {
	auto A = Queue!(int[])();

	A.capacity = 5;

	A ~= 1;
	A ~= 2;

	assert (A[].length == 2);
	assert (A[] == [1,2]);

	A ~= [3,4];

	assert (A[] == [1,2,3,4]);

	A--;

	assert (A[] == [2,3,4]);

	A ~= 5;

	assert (A[] == [2,3,4,5]);

	A -= 2;

	assert (A[] == [4,5]);

	A ~= [6,7,8];

	assert (A[] == [4,5,6,7,8]);

	A[1..4] = [7,6,5];

	assert (A[] == [4,7,6,5,8]);

	A.clear;

	assert (A[].empty);

	A ~= 1;
	A ~= 2;
	A ~= [3,4,5];
	A -= 2;
	A ~= [6,7];

	assert (A[] == [3,4,5,6,7]);
}
