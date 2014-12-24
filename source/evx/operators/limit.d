module evx.operators.limit;

/* generate $ and ~$ right and left limit operators
*/
template LimitOps (limits...)
	{/*...}*/
		private {/*imports}*/
			import std.traits;

			import evx.type;
			import evx.range;

			import evx.math.logic;
			import evx.math.algebra;
		}

		static assert (All!(is_const_function, Filter!(is_function, limits)),
			`LimitOps: limit functions must be const`
		);

		auto opDollar (size_t i)()
			{/*...}*/
				alias T = Element!(typeof(limits[i].identity));

				static if (is (typeof(limits[i].identity) == T[2]))
					return Limit!T (limits[i]);

				else return Limit!T ([zero!T, limits[i]]);
			}
	}
struct Limit (T)
	{/*...}*/
		union {/*limit}*/
			T[2] limit;
			struct {T left, right;}
		}

		alias right this;

		auto opUnary (string op)()
			{/*...}*/
				static if (op is `~`)
					return left;
				else return mixin(op ~ q{right});
			}
	}
