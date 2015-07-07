module autodata.spaces.completed;

private {//imports
	import evx.meta;
	import evx.interval;
	import autodata.functor.maybe;
	import autodata.traits;
	import autodata.operators;
	import autodata.morphism;
	import std.range.primitives: front, back;
	import std.algorithm: max, min;
	import std.traits: KeyType, ValueType;
}

auto minimal_increment (T)(T value)
{
	import std.math;

	T float_up ()() {return std.math.nextUp (value);}
	T func_float_up ()() {mixin(namespace_of!T); return value.fmap!(std.math.nextUp);}
	T int_up ()() {return value + T(1);}

	return Match!(float_up, func_float_up, int_up);
}

/*
	turns a sparse space of T into a dense space of Maybe!T
*/
struct Completed (Space)
{
	Space space;

	Maybe!(ValueType!Space) access (KeyType!Space index)
	{
		if (auto item = index in space)
			return typeof(return)(*item);
		else return typeof(return)(null);
	}

	auto limit (uint i : 0)() const
	out (result) {
		assert (result.left == space.keys[].reduce!min);
		assert (result.right == space.keys[].reduce!max.minimal_increment);
	}
	body {
		return interval (space.keys[].back, space.keys[].front.minimal_increment);
	}

	mixin SliceOps!(access, limit!0, RangeExt);
}

auto complete (S)(S space)
{
	return Completed!S (space);
}

private void TODO ()
{
	string[int] x = [1: `one`, 4: `four`, 2: `two`];
	import std.stdio;
	auto y = x.complete;
	writeln (y.limit!0);
	//writeln (y[0]);
	writeln (y[1]);
	writeln (y[2]);
	writeln (y[3]);
	writeln (y[4]);
	//writeln (y[5]);
	writeln (dimensionality!(string[int]));
	writeln (CoordinateType!(typeof(y[0..10])).stringof);

	alias T = Maybe!string;
	writeln (y[~$..$] == [T(`one`), T(`two`), T(null), T(`four`)]);
}
