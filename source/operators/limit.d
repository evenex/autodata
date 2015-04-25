module autodata.operators.limit;

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
			import autodata.meta;
			import autodata.core.interval: Interval;
		}

		struct Verification
			{/*...}*/
				mixin LambdaCapture;

				static assert (All!(is_const_function, Filter!(is_function, limits)),
					full_name!(typeof(this))~ ` LimitOps: limit functions must be const`
				);
				static assert (
					All!(is_comparable, 
						Map!(Λ!q{(T) = Select!(
							is (ElementType!T == void),
							T, ElementType!T
						)}, 
							Map!(ExprType, limits)
						)
					),
					full_name!(typeof(this))~ ` LimitOps: limit types must support comparison (<. >, <=, >=)`
				);
			}

		auto opDollar (size_t i)() // const REVIEW source/operators/limit.d(35): Error: incompatible types for ((0) : (this.bounds)): 'int' and 'const(int[2])'
			{/*...}*/
				alias T = Unqual!(ExprType!(limits[i]));

				static if (is (ElementType!T == void))
					auto limit ()() {return interval (Finite!T(0), limits[i]);}
				else auto limit ()() {return interval (limits[i]);}

				return Limit!(typeof(limit.left), typeof(limit.right))(limit);
			}
	}
struct Limit (T,U)
	{/*...}*/
		private {/* import}*/
			import autodata.meta;
			import autodata.core.interval;
			import autodata.core.infinity;
		}

		Interval!(T,U) limit;

		auto left () {return limit.left;}
		auto right () {return limit.right;}

		alias right this;

		auto opUnary (string op)()
			{/*...}*/
				static if (op is `~`)
					return left;
				else return mixin(op ~ q{right});
			}
	}
