module autodata.spaces.repeat;

private {/*import}*/
	import autodata.meta;
	import autodata.operators;
}

struct Repeated (T, size_t dim)
	{/*...}*/
		T value;
		Repeat!(dim, size_t) lengths;

		auto limit (size_t d)() const
			{/*...}*/
				return interval (lengths[d]);
			}
		size_t length (size_t d)() const
			{/*...}*/
				return lengths[d];
			}
		auto access (typeof(lengths))
			{/*...}*/
				return value;
			}

		auto front ()() if (dim == 1)
			{/*...}*/
				return value;
			}
		void popFront ()() if (dim == 1)
			{/*...}*/
				lengths[0]--;
			}
		bool empty ()() if (dim == 1)
			{/*...}*/
				return lengths[0] == 0;
			}
		auto length ()() const if (dim == 1)
			{/*...}*/
				return length!0;
			}
		alias back = front;
		alias popBack = popFront;

		bool opEquals (R)(R range) if (dim == 1)
			{/*...}*/
				return this[] == range;
			}

		mixin SliceOps!(access, Map!(length, Iota!dim), RangeOps);
	}

auto repeat (T, U...)(T value, U lengths)
	if (All!(is_integral, U))
	{/*...}*/
		return Repeated!(T, U.length)(value, lengths);
	}
	unittest {/*...}*/
		import autodata.functional;

		auto x = 6.repeat (3);
		auto y = 1.repeat (2,2,2);

		assert (x.length == 3);
		assert (x == [6,6,6]);
		assert (y[0..$, 0, 0] == [1,1]);
		assert (y[0, 0..$, 0] == [1,1]);
		assert (y[0, 0, 0..$] == [1,1]);

		assert (x.front == 6);
		assert (x.map!(q => q*2) == [12, 12, 12]);

		// TODO test repeat infinity
	}
