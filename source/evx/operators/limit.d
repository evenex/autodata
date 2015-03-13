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
			import evx.meta;
		}

		static assert (All!(is_const_function, Filter!(is_function, limits)),
			full_name!(typeof(this)) ~ ` LimitOps: limit functions must be const`
		);
		static assert (All!(is_comparable, Map!(Codomain, Filter!(is_function, limits)), Filter!(Not!is_function, limits)),
			full_name!(typeof(this)) ~ ` LimitOps: limit types must support comparison (<. >, <=, >=)`
		);

		auto opDollar (size_t i)()
			{/*...}*/
				alias Element () = typeof(limits[i][0]);
				alias Identity () = typeof(limits[i].identity);

				alias T = Match!(Element, Identity);

				static if (is (typeof(limits[i].identity) == T[2]))
					return Limit!T (limits[i]);

				else return Limit!T ([T(0), limits[i]]);
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
