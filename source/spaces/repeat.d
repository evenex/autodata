module autodata.spaces.repeat;

private {/*import}*/
	import autodata.meta;
	import autodata.operators;
}

struct Repeated (T, Dims...)
	{/*...}*/
		T value;
		Dims lengths;

		auto limit (size_t d)() const
			{/*...}*/
				return interval (0, lengths[d]);
			}
		auto length (size_t d)() const
			{/*...}*/
				return lengths[d];
			}
		auto access (typeof(lengths))
			{/*...}*/
				return value;
			}

		auto front ()() if (Dims.length == 1)
			{/*...}*/
				return value;
			}
		void popFront ()() if (Dims.length == 1)
			{/*...}*/
				lengths[0]--;
			}
		bool empty ()() if (Dims.length == 1)
			{/*...}*/
				return lengths[0] == 0;
			}
		auto length ()() const if (Dims.length == 1)
			{/*...}*/
				return length!0;
			}
		alias back = front;
		alias popBack = popFront;

		bool opEquals (R)(R range) if (Dims.length == 1)
			{/*...}*/
				return this[] == range;
			}

		mixin SliceOps!(access, Map!(length, Ordinal!Dims), RangeOps);
	}

auto repeat (T, U...)(T value, U lengths)
	if (All!(Compose!(is_integral, InitialType), U))
	{/*...}*/
		return Repeated!(T, U)(value, lengths);
	}
	void main () {/*...}*/
		import autodata.functional;
		import autodata.core;

		auto x = 6.repeat (3);
		auto y = 1.repeat (2,2,2);

		assert (x.length == 3);
		assert (x == [6,6,6]);
		assert (y[0..$, 0, 0] == [1,1]);
		assert (y[0, 0..$, 0] == [1,1]);
		assert (y[0, 0, 0..$] == [1,1]);

		assert (x.front == 6);
		assert (x.map!(q => q*2) == [12, 12, 12]);

		auto z = 9.repeat (infinity!int); // TODO auto alias infinity to infinity!long instead of infinity!void?
		// TODO test repeat infinity
	}
