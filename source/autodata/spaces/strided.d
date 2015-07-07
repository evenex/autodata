module autodata.spaces.strided;

private {/*import}*/
	import std.conv: to;
	import std.range.primitives: front, back, popFront, popBack, empty;
	import autodata.operators;
	import autodata.spaces.sequence;
	import autodata.traits;
	import autodata.functor.tuple;
	import evx.meta;
	import evx.interval;
}

/* reindex a space to skip over a fixed width in the given dimensions
*/
struct Stride (S, uint[] strided_dims, Widths...)
{
	S space;
	private Widths widths;

	auto access (Repeat!(dimensionality!S, size_t) point)
	{
		auto coordinate (uint i)()
		{
			auto stride ()() {return widths[strided_dims.count_until (i)];}
			auto stable ()() {return 1;}

			return point[i] * Match!(stride, stable);
		}

		return space[Map!(coordinate, Iota!(dimensionality!S)).tuple.expand];
	}
	auto limit (uint i)() const
	{
		auto stride ()() {return interval (1, widths[strided_dims.count_until (i)]);}
		auto stable ()() {return 1;}

		return space.limit!i / Match!(stride, stable);
	}

	mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!S)), RangeExt);

	static if (dimensionality!S == 1)
	{//range ops
		auto length ()() const if (dimensionality!S == 1)
		{
			return limit!0.width;
		}
		void popFront ()()
		{
			foreach (_; 0..widths[0])
				space.popFront;
		}
		void popBack ()()
		{
			foreach (_; 0..widths[0])
				space.popBack;
		}

		mixin RangeOps!(space, length, widths);
	}
}
auto stride (uint[] strided_dims = [], S, Widths...)(S space, Widths widths)
in {
	static assert (Widths.length == strided_dims.length || strided_dims.length == 0, 
		`number of strided dimensions does not match number of stride widths given`
	);
}
body {
	static if (strided_dims.empty)
		enum d = [Iota!(dimensionality!S)];
	else alias d = strided_dims;

	return Stride!(S, d, Widths)(space, widths);
}
unittest {
	import autodata.morphism;
	import autodata.spaces.sequence;
	import autodata.spaces.product;

	assert ([1,2,3,4,5,6,7,8,9].stride (3) == [1,4,7]);

	auto x = Nat[0..100].by (Nat[0..100]).stride (4, 20);

	assert (x[~$..$, 0].map!(x => x[0]) == [0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96]);
	assert (x[0, ~$..$].map!(x => x[1]) == [0, 20, 40, 60, 80]);

	auto y = Nat[0..100].by (Nat[0..100]).stride!([1])(20);

	assert (y[~$..$, 0].map!(x => x[0]) == Nat[0..100]);
	assert (y[0, ~$..$].map!(x => x[1]) == [0, 20, 40, 60, 80]);

	static assert (not (is (typeof(Nat[0..100].by (Nat[0..100]).stride!([1])(20, 4)))));
}
