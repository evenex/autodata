module autodata.functional.iso;

private {//import
	import std.range.primitives: front, back, popFront, popBack, empty;
	import std.algorithm: equal;
	import evx.interval;
	import evx.meta;
	import autodata.traits;
}

/* apply a given function to the elements in a space 
*/
template map (alias f)
{
	auto map (Domain, Parameters...)(Domain domain, Parameters parameters)
	in {
		static assert (not (is (ElementType!Domain == void)),
			(Domain.stringof)~` contains no elements to map`
		);
	}
	body {
		return Mapped!(Domain, f, Parameters)(domain, parameters);
	}
}
struct Mapped (Domain, alias f, Parameters...)
{
	Domain domain;
	Parameters parameters;

	auto opIndex (Args...)(Args args)
	{
		auto slice_all ()() if (Args.length == 0) {return domain;}
		auto get_space ()() {return domain.opIndex (args);}
		auto get_range ()() if (Args.length == 1) {return domain[args[0].left..args[0].right];}
		auto get_point ()() {return domain[args];}
		template error () {pragma (msg, Args, ` failed to index `, Domain);}

		alias subdomain = Match!(slice_all, get_space, get_range, get_point, error);

		auto apply ()() {return map_apply (subdomain);}
		auto remap ()() {return map_remap (subdomain);}

		return Match!(apply, remap);
	}
	auto opSlice (size_t d, Args...)(Args args)
	{
		auto multi ()() {return domain.opSlice!d (args);}
		auto single ()() if (d == 0) {return domain.opSlice (args);}
		auto index ()() {return interval (args);}

		return Match!(multi, single, index);
	}
	auto opDollar (size_t d)()
	{
		auto multi ()() {return domain.opDollar!d;}
		auto single ()() if (d == 0) {return domain.opDollar;}
		auto length ()() if (d == 0) {return domain.length;}

		return Match!(multi, single, length);
	}
	auto opEquals (S)(S that)
	{
		return this.equal (that);
	}

	@property:

	auto front ()()
	{
		return map_apply (domain.front);
	}
	auto back ()()
	{
		return map_apply (domain.back);
	}
	auto popFront ()()
	{
		domain.popFront;
	}
	auto popBack ()()
	{
		domain.popBack;
	}
	auto empty ()()
	{
		return domain.empty;
	}
	auto save ()()
	{
		return this;
	}
	auto length ()() const
	{
		return domain.length;
	}
	auto limit (size_t d)() const
	{
		return domain.limit!d;
	}

	private {
		auto map_apply (ElementType!Domain point)
		{
			auto tuple ()() {return f (point.expand, parameters);}
			auto value ()() {return f (point, parameters);}

			return Match!(tuple, value);
		}
		auto map_remap (Subdomain...)(Subdomain subdomain)
		{
			return Mapped!(Subdomain, f, Parameters)(subdomain, parameters);
		}
	}
}
unittest {
	import std.range: only;
	import autodata.operators;

	int[8] x = [1,2,3,4,5,6,7,8];

	{/*ranges}*/
		auto y = x[].map!(i => 2*i);

		assert (y.length == 8);

		assert (x[0] == 1);
		assert (y[0] == 2);

		assert (x[$-1] == 8);
		assert (y[$-1] == 16);

		assert (x[0..4] == [1, 2, 3, 4]);
		assert (y[0..4] == [2, 4, 6, 8]);

		assert (x[] == [1, 2, 3, 4, 5, 6, 7, 8]);
		assert (y[] == [2, 4, 6, 8, 10, 12, 14, 16]);

		assert (x.length == 8);
		assert (y.length == 8);

		foreach (i; y)
			assert (i);
	}
	{/*spaces}*/
		static struct Basic
		{
			int[] data = [1,2,3,4];

			auto access (size_t i) {return data[i];}
			auto length () const {return data.length;}

			mixin SliceOps!(access, length, RangeExt);
		}
		auto z = Basic()[].map!(i => 2*i);

		assert (z[].limit!0 == [0,4]);
		assert (z[] == [2,4,6,8]);

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
		auto m = MultiDimensional()[];
		auto w = MultiDimensional()[].map!(i => 2*i);

		assert (m[].limit!0 == [0,3]);
		assert (m[].limit!1 == [0,3]);
		assert (w[].limit!0 == [0,3]);
		assert (w[].limit!1 == [0,3]);

		assert (m[0,0] == 1);
		assert (w[0,0] == 2);
		assert (m[2,2] == 9);
		assert (w[2,2] == 18);

		assert (w[0..$, 0] == [2, 8, 14]);
		assert (w[0, 0..$] == [2, 4, 6]);

		assert (m[0..$, 1].map!(x => x*x) == [4, 25, 64]);
		assert (w[0..$, 1].map!(x => x*x) == [16, 100, 256]);

		static struct FloatingPoint
		{
			auto access (double x)
			{
				return x;
			}

			enum double length = 1;

			mixin SliceOps!(access, length);
		}
		auto sq = FloatingPoint()[].map!(x => x*x);
		assert (sq[0.5] == 0.25);
	}
	{/*local}*/
		static static_variable = 7;
		assert (x[].map!(i => i + static_variable)[0..4] == [8,9,10,11]);

		static static_function (int x) {return x + 2;}
		assert (x[].map!static_function[0..4] == [3,4,5,6]);

		static static_template (T)(T x) {return 3*x;}
		assert (x[].map!static_template[0..4] == [3,6,9,12]);

		auto local_variable = 9;
		assert (x[].map!(i => i + local_variable)[0..4] == [10,11,12,13]);

		auto local_function (int x) {return x + 1;}
		assert (x[].map!local_function[0..4] == [2,3,4,5]);

		auto local_function_local_variable (int x) {return x * local_variable;}
		assert (x[].map!local_function_local_variable[0..4] == [9,18,27,36]);

		auto local_template (T)(T x) {return 3*x;}
		// assert (x[].map!local_template[0..4] == [3,6,9,12]); BUG cannot capture context pointer for local template
	}
	{/*ctfe}*/
		static ctfe_func (int x) {return x + 2;}

		enum a = [1,2,3].map!(i => i + 100);
		enum b = [1,2,3].map!ctfe_func;

		static assert (a == [101, 102, 103]);
		static assert (b == [3, 4, 5]);
		static assert (typeof(a).sizeof == (int[]).sizeof + (void*).sizeof); // template lambda makes room for the context pointer but doesn't save it... weird.
		static assert (typeof(b).sizeof == (int[]).sizeof); // static function omits context pointer
	}
	{/*params}*/
		static r () @nogc {return only (1,2,3).map!((a,b,c) => a + b + c)(3, 2);}

		assert (r == [6,7,8]);
	}
	{/*alias}*/
		alias fmap = map!(x => x*x);

		assert (fmap ([1,2]) == [1,4]);

		auto f2 (int x) {return x - 1;}
		alias gmap = map!f2;

		assert (gmap ([1,2]) == [0,1]);
	}
	{/*compose}*/
		auto a = x[].map!(x => x*x);
		auto b = a.map!(x => x*x);

		foreach (i; a)
			assert (i);

		foreach (i; b)
			assert (i);

		assert (b == [1, 16, 81, 256, 625, 1296, 2401, 4096]);
	}
}

/*
	modify a space in place
*/
auto ref apply (alias op, S, Args...)(auto ref S space, Args args)
{
	void tuple ()() {op (space.unzip.expand, args);}
	void forward ()() {op (space, args);}

	Match!(tuple, forward);

	return space;
}

/* map a space of elements to a space of their named members
*/
auto lens (string member, S)(auto ref S space)
{
	static get (ElementType!S element)
	{
		return mixin(q{element.}~(member));
	}

	return space.map!get;
}
