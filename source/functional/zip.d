module autodata.functional.zip;

private {//import
	import std.typecons: Tuple, tuple;
	import std.range.primitives: front, back, popFront, popBack, empty;
	import std.conv: text;
	import std.algorithm: equal;
	import evx.interval;
	import evx.meta;
	import autodata.functional.iso;
	import autodata.traits;
}

enum LengthPolicy {strict, trunc}

/* join several spaces together transverse-wise, 
	into a space of tuples of the elements of the original spaces 
*/
struct Zipped (LengthPolicy length_policy, Spaces...)
{
	Spaces spaces;
	this (Spaces spaces) {this.spaces = spaces;}

	auto opIndex (Args...)(Args args)
	{
		auto point (uint i)() 
			{return spaces[i].map!identity[args];}

		auto tuple ()() 
			{return .tuple (Map!(point, Ordinal!Spaces));}

		auto zipped ()() if (
			Any!(is_interval, Args)
			|| Args.length == 0
		)
			{return Zipped!(length_policy, ExprType!(tuple).Types)(tuple.expand);}

		return Match!(zipped, tuple);
	}
	auto opSlice (uint d, Args...)(Args args)
	{
		template attempt (uint i)
		{
			auto attempt ()()
			{
				auto multi ()() {return domain.opSlice!d (args);}
				auto single ()() if (d == 0) {return domain.opSlice (args);}

				return Match!(multi, single);
			}
		}
		auto array ()() {return interval (args);}

		return Match!(Map!(attempt, Ordinal!Spaces), array);
	}
	auto opDollar (uint d)()
	{
		template attempt (uint i)
		{
			auto attempt ()()
			{
				auto multi  ()() {return spaces[i].opDollar!d;}
				auto single ()() if (d == 0) {return spaces[i].opDollar;}
				auto length ()() if (d == 0) {return spaces[i].length;}

				return Match!(multi, single, length);
			}
		}

		return Match!(Map!(attempt, Ordinal!Spaces));
	}
	auto opEquals (S)(S that)
	{
		return this.equal (that);
	}

	static if (
		not (Contains!(void, Map!(ElementType, Spaces)))
		&& is (typeof(length.identity) : size_t)
	) // HACK foreach tuple expansion causes compiler segfault on template range ops, opApply is workaround
		int opApply (int delegate(Map!(ElementType, Spaces)) f)
		{
			int result = 0;

			for (auto i = 0; i < length; ++i)
				{/*...}*/
					int expand ()() {return result = f(this[i].expand);}
					int closed ()() {return result = f(this[i]);}

					if (Match!(expand, closed))
						break;
				}

			return result;
		}

	@property:

	auto front ()()
	{
		auto get (uint i)() {return spaces[i].front;}

		return tuple (Map!(get, Ordinal!Spaces));
	}
	auto back ()()
	{
		auto get (uint i)() {return spaces[i].back;}

		return tuple (Map!(get, Ordinal!Spaces));
	}
	auto popFront ()()
	{
		foreach (ref space; spaces)
			space.popFront;
	}
	auto popBack ()()
	{
		foreach (ref space; spaces)
			space.popBack;
	}
	auto empty ()()
	{
		return spaces[0].empty;
	}
	auto save ()()
	{
		return this;
	}
	auto length ()() const
	{
		template get_length (uint i)
		{
			auto get_length ()()
			{
				return spaces[i].length;
			}
		}

		alias lengths = Map!(get_length, Ordinal!Spaces);

		auto trunc ()() if (length_policy == LengthPolicy.trunc) 
			{return min (MatchAll!lengths);}
		auto strict ()() if (length_policy == LengthPolicy.strict) 
			{return Match!lengths;}

		return Match!(trunc, strict);
	}
	auto limit (uint i)() const
	{
		template get_limit (uint j)
		{
			auto get_limit ()()
			{
				return spaces[j].limit!i;
			}
		}

		alias limits = Map!(get_limit, Ordinal!Spaces);

		auto shortest ()() if (length_policy == LengthPolicy.trunc)
		{
			return reduce!((a,b) => a.width < b.width? a:b)
				(MatchAll!limits)
				;
		}
		auto first ()() if (length_policy == LengthPolicy.strict)
		{
			return Match!limits;
		}

		return Match!(shortest, first);
	}

	invariant () {
		import std.algorithm: find;
		import std.array: replace;

		alias Dimensionalities = Map!(dimensionality, Spaces);

		enum same_dimensionality (int d) = d == Dimensionalities[0];

		static assert (All!(same_dimensionality, Dimensionalities),
			`zip error: dimension mismatch! ` 
			~Interleave!(Spaces, Dimensionalities)
				.stringof[`tuple(`.length..$-1]
				.replace (`),`, `):`)
		);
	}
}

/* zip, assuming all of the spaces have equal limits
*/
auto strict_zip (Spaces...)(Spaces spaces)
in {
	alias Dimensionalities = Map!(dimensionality, Spaces);

	foreach (d; Iota!(Dimensionalities[0]))
		foreach (i; Ordinal!Spaces)
			{//bounds check
				enum no_measure_error (int i) = `zip error: `
					~Spaces[i].stringof
					~ ` does not define limit or integral length (const)`;


				static if (is (typeof(spaces[0].limit!d)))
					auto base = spaces[0].limit!d;
				else static if (d == 0 && is (ExprType!(spaces[0].length) : size_t))
					size_t[2] base = [0, spaces[0].length];
				else static assert (0, no_measure_error!i);


				static if (is (typeof(spaces[i].limit!d)))
					auto lim = spaces[i].limit!d;
				else static if (d == 0 && is (ExprType!(spaces[i].length) : size_t))
					size_t[2] lim = [0, spaces[i].length];
				else static assert (0, no_measure_error!i);


				assert (base == lim, `zip error: `
					`mismatched limits! ` ~lim.text~ ` != ` ~base.text
					~ ` in ` ~Spaces[i].stringof
				);
			}
}
body {
	return Zipped!(LengthPolicy.strict, Spaces)(spaces);
}

/* zip, taking the limit of the intersection of the zipped spaces
*/
auto trunc_zip (Spaces...)(Spaces spaces)
{
	return Zipped!(LengthPolicy.trunc, Spaces)(spaces);
}

/* default zip
*/
alias zip = strict_zip;
unittest {
	import std.exception;
	import autodata.operators;

	auto error (T)(lazy T stmt) {assertThrown!Error (stmt);}
	auto no_error (T)(lazy T stmt) {assertNotThrown!Error (stmt);}

	int[4] x = [1,2,3,4], y = [4,3,2,1];

	auto z = zip (x[], y[]);

	assert (z.length == 4);

	assert (z[0] == tuple (1,4));
	assert (z[$-1] == tuple (4,1));
	assert (z[0..$] == [
		tuple (1,4),
		tuple (2,3),
		tuple (3,2),
		tuple (4,1),
	]);

	{/*bounds check}*/
		error (zip (x[], [1,2,3]));
		error (zip (x[], [1,2,3,4,5]));
	}
	{/*multidimensional}*/
		static struct MultiDimensional
			{/*...}*/
				double[9] matrix = [
					1, 2, 3,
					4, 5, 6,
					7, 8, 9,
				];

				auto ref access (size_t i, size_t j)
					{/*...}*/
						return matrix[3*i + j];
					}

				enum size_t rows = 3, columns = 3;

				mixin SliceOps!(access, rows, columns, RangeExt);
			}

		auto a = MultiDimensional();
		auto b = MultiDimensional()[].map!(x => x*2);

		auto c = zip (a[], b[]);

		assert (c[1, 1] == tuple (5, 10));

		error (zip (a[1..$, ~$..$], b[~$..$, ~$..$]));
		error (zip (a[~$..$, 1..$], b[~$..$, ~$..$]));

		error (zip (a[0, ~$..$], x[]));

		no_error (zip (a[0, ~$..$], x[0..3], y[0..3], z[0..3]));
	}
	{/*non-integer indices}*/
		static struct FloatingPoint
			{/*...}*/
				auto access (double x)
					{/*...}*/
						return x;
					}

				enum double length = 1;

				mixin SliceOps!(access, length);
			}

		FloatingPoint a, b;

		auto q = zip (a[], b[]);

		assert (q[0.5] == tuple (0.5, 0.5));
		assert (q[$-0.5] == tuple (0.5, 0.5));
		assert (q[0..$/2].limit!0 == [0.0, 0.5]);

		error (q[0..1.01]);
		error (q[-0.1..$]);
	}
	{/*map tuple expansion}*/
		static tuple_sum (T)(T t){return t[0] + t[1];}
		static binary_sum (T)(T a, T b){return a + b;}

		assert (z.map!tuple_sum == [5,5,5,5]);
		assert (z.map!binary_sum == [5,5,5,5]);
		assert (z.map!(t => t[0] + t[1]) == [5,5,5,5]);
		assert (z.map!((a,b) => a + b) == [5,5,5,5]);
	}
	{/*foreach tuple expansion}*/
		foreach (a,b; z)
			assert (1);
	}
}

/* split a zipped range into a tuple of spaces 
*/
auto unzip (T...)(Zipped!T zipped)
{
	return zipped.spaces.tuple;
}
unittest {
	import std.algorithm: equal;

	auto a = [1,2,3];
	auto b = [4,5,6];

	assert (zip (a,b).unzip[0].equal (a));
	assert (zip (a,b).unzip[1].equal (b));
}
