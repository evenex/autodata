module evx.math.analysis.intervals;

import std.traits;
import std.conv;

import evx.math.analysis.core;
import evx.math.algebra;
import evx.math.logic;
import evx.math.vectors;

/* generic interval type 
*/
struct Interval (Index)
	{/*...}*/
		const @property toString ()
			{/*...}*/
				return `[` ~min.text~ `..` ~max.text~ `]`;
			}

		pure:
		static if (is_continuous!Index)
			alias measure = size;
		else alias length = size;

		const @property empty ()
			{/*...}*/
				return end - start == zero!Index;
			}

		const @property start ()
			{/*...}*/
				return bounds[0];
			}
		const @property end ()
			{/*...}*/
				return bounds[1];
			}

		@property start ()(Index i)
			{/*...}*/
				bounds[0] = i;
			}
		@property end ()(Index i)
			{/*...}*/
				bounds[1] = i;
			}

		const @property size ()
			{/*...}*/
				return end - start;
			}

		alias min = start;
		alias max = end;

		this (Index start, Index end)
			{/*...}*/
				bounds = [start, end];
			}
		this (Index[2] bounds)
			{/*...}*/
				this.bounds = bounds;
			}
		this (R)(R range)
			{/*...}*/
				this.bounds = range.vector!2.array;
			}

		auto tuple ()
			{/*...}*/
				return bounds.vector.tuple;
			}

		bool is_infinite ()
			{/*...}*/
				return start.is_infinite || end.is_infinite;
			}

		private:
		Index[2] bounds = [zero!Index, zero!Index];

		invariant (){/*...}*/
			assert (bounds[0] <= bounds[1], `bounds inverted`);
		}
	}
	pure {/*interval comparison predicates}*/
		bool ends_before_end (T)(const Interval!T a, const Interval!T b)
			{/*...}*/
				return a.end < b.end;
			}
		bool ends_before_start (T)(const Interval!T a, const Interval!T b)
			{/*...}*/
				return a.end < b.start;
			}
		bool starts_before_end (T)(const Interval!T a, const Interval!T b)
			{/*...}*/
				return a.start < b.end;
			}
		bool starts_before_start (T)(const Interval!T a, const Interval!T b)
			{/*...}*/
				return a.start < b.start;
			}
	}
	unittest {/*...}*/
		auto x = interval (-10, 10);
		auto y = interval (-infinity, 10);
		auto z = interval (-10, infinity);

		assert (x.is_finite);
		assert (y.is_infinite);
		assert (z.is_infinite);
	}

/* convenience constructor 
*/
auto interval (T,U)(T start, U end)
	if (not(is(CommonType!(T,U) == void)))
	{/*...}*/
		return Interval!(CommonType!(T,U)) (start, end);
	}
auto interval (T)(T[2] bounds)
	{/*...}*/
		return Interval!T (bounds);
	}
	unittest {/*...}*/
		import std.exception: assertThrown;

		auto A = interval (0, 10);
		assert (A.length == 10);

		A.start = 9;
		assert (A.length == 1);

		//assertThrown!Error (A.end = 8); XXX running noboundscheck testing makes this fail
		A.bounds[1] = 10;

		assert (not (A.empty));
		A.end = 9;
		assert (A.empty);
		assert (A.length == 0);
	}

/* test if two intervals overlap 
*/
bool overlaps (T)(const Interval!T A, const Interval!T B)
	{/*...}*/
		if (A.starts_before_start (B))
			return B.starts_before_end (A);
		else return A.starts_before_end (B);
	}
	unittest {/*...}*/
		auto A = interval (0, 10);

		auto B = interval (11, 13);

		assert (A.starts_before_start (B));
		assert (A.ends_before_start (B));

		assert (not (A.overlaps (B)));
		A.end = 11;
		assert (not (A.overlaps (B)));
		A.end = 12;
		assert (A.overlaps (B));
		B.start = 13;
		assert (not (A.overlaps (B)));
	}

/* test if an interval is contained within another 
*/
bool is_contained_in (T)(Interval!T A, Interval!T B)
	{/*...}*/
		return A.start >= B.start && A.end <= B.end;
	}
	unittest {/*...}*/
		auto A = interval (0, 10);
		auto B = interval (1, 5);
		auto C = interval (10, 11);
		auto D = interval (9, 17);

		assert (not (A.is_contained_in (B)));
		assert (not (A.is_contained_in (C)));
		assert (not (A.is_contained_in (D)));

		assert (B.is_contained_in (A));
		assert (not (B.is_contained_in (C)));
		assert (not (B.is_contained_in (D)));

		assert (not (C.is_contained_in (A)));
		assert (not (C.is_contained_in (B)));
		assert (C.is_contained_in (D));

		assert (not (D.is_contained_in (A)));
		assert (not (D.is_contained_in (B)));
		assert (not (D.is_contained_in (C)));
	}

/* test if a point is contained within an interval 
*/
bool is_contained_in (T)(T x, Interval!T I)
	{/*...}*/
		return x.between (I.start, I.end);
	}

