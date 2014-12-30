module evx.operators.limit;

/* generates left and right limit operators (~$ and $)

	Requires:
		n limit symbols, where n > 0.
		Each limit symbol evaluates either to some value which admits an ordering (i.e. <. <=, >, >= operators are supported),
		or to an static array of length 2 whose element type meets the aforementioned critieria.

	This mixin is for internal use; it does nothing on its own.
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
			fullyQualifiedName!(typeof(this)) ~ ` LimitOps: limit functions must be const`
		);
		static assert (All!(is_comparable, Map!(ReturnType, Filter!(is_function, limits)), Filter!(Not!is_function, limits)),
			fullyQualifiedName!(typeof(this)) ~ ` LimitOps: limit types must support comparison (<. >, <=, >=)`
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
