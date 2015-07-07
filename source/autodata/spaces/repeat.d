module autodata.spaces.repeat;

private {/*import}*/
	import std.conv;
	import autodata.operators;
	import evx.meta;
	import evx.infinity;
	import evx.interval;
}

struct Repeated (T, Dims...)
{
	T value;

	alias FiniteDims = Filter!(
		Not!(λ!q{(uint i, Dim) = __traits(hasMember, Dim, `is_infinite`)}), 
		Enumerate!Dims
	);

	Map!(Second, FiniteDims) lengths;

	auto limit (size_t d)() const
	{
		static if (is (typeof(Dims[d].is_infinite)))
			return interval (0, Infinite!(Dims[d])());
		else return interval (0, lengths[IndexOf!(d, Map!(First, FiniteDims))]);
	}
	auto access (Map!(Finite, Dims))
	{
		return value;
	}

	static if (Dims.length == 1)
	{
		auto front ()()
		{
			return value;
		}
		void popFront ()()
		{
			static if (FiniteDims.length > 0)
				lengths[0]--;
		}

		alias back = front;
		alias popBack = popFront;

		auto length ()()
		{
			return limit!0.width;
		}
		auto save ()()
		{
			return this;
		}

		mixin RangeOps!(null, length);
	}

	mixin SliceOps!(access, Map!(limit, Ordinal!Dims), RangeExt);
}
auto repeat (T, U...)(T value, U lengths)
{
	auto force_length (uint i)()
	{
		static if (is (U[i] == Infinite!void))
			return Infinite!size_t ();
		else return lengths[i];
	}

	alias Lengths = Map!(Compose!(ExprType, force_length), Ordinal!U);

	static assert (All!(Compose!(is_integral, Finite), Lengths));

	return Repeated!(T, Lengths)(
		value, 
		Map!(Compose!(force_length, First),
			Filter!(Not!(λ!q{(uint i, Length) = __traits(hasMember, Length, `is_infinite`)}), 
				Enumerate!U
			)
		)
	);
}
unittest {
	import autodata.morphism;

	auto x = 6.repeat (3);
	auto y = 1.repeat (2,2,2);

	assert (x.length == 3);
	assert (x == [6,6,6]);
	assert (y[0..$, 0, 0] == [1,1]);
	assert (y[0, 0..$, 0] == [1,1]);
	assert (y[0, 0, 0..$] == [1,1]);

	assert (x.front == 6);
	assert (x.map!(q => q*2) == [12, 12, 12]);

	auto z = 9.repeat (infinity!int);
	auto w = 9.repeat (infinity);

	assert (z.length == w.length);

	assert (z[0..10] == 9.repeat (10));
	assert (z[0..$].limit!0.width.is_infinite);

	auto u = 2.repeat (3, infinity);

	assert (u[1, 0..$].limit!0.width.is_infinite);
	assert (u[0..$, 1].limit!0.width.not!is_infinite);

	assert (u.map!(x => x + 7)[0, 0..999] == w[0..999]);
}
