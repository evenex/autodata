module autodata.operators.multilimit;

private {/*imports}*/
	import std.algorithm: swap;

	import autodata.meta;
	import autodata.core;
}

/* WARNING experimental -- 
	will probably only be usable with multiple alias this
	https://github.com/D-Programming-Language/dmd/pull/3998 
	and strict index type segregation
*/
template MultiLimitOps (size_t dim, limits...)
	{/*...}*/
		auto opDollar (size_t i: dim)()
			{/*...}*/
				mixin LambdaCapture;

				alias Limits = Map!(ExprType, limits);

				MultiLimit!(
					Map!(ElementType,
						Map!(Λ!q{(T) 
							= Select!(is (T == Interval!U, U...) || is (T == U[2], U), ElementType!T, T)},
							Limits
						)
					)
				) multilimit;

				foreach (i, Lim; Limits)
					multilimit.limits[i] = limits[i].interval;

				return multilimit;
			}
	}
struct MultiLimit (T...)
	{/*...}*/
		mixin LambdaCapture;

		Map!(Λ!q{(U) = Interval!U}, T)
			limits;

		alias alt = opCast!(T[0]);
		alias alt this;

		U opCast (U)()
			in {/*...}*/
				static assert (Contains!(U,T),
					`cannot cast ` ~typeof(this).stringof~ ` to ` ~U.stringof
				);
			}
			body {/*...}*/
				return limits[IndexOf!(U, T)].right;
			}

		auto opBinary (string op, U)(U that)
			in {/*...}*/
				static assert (
					Any!(Pair!().Both!(λ!q{(T,U) = is (U : T)}),
						Zip!(T, Repeat!(T.length, U))
					),
					U.stringof~ ` does not convert to any ` ~T.stringof
				);
			}
			body {/*...}*/
				Map!(Pair!().First!Identity,
					Filter!(Pair!().Both!(λ!q{(T,U) = is (U : T)}),
						Zip!(T, Repeat!(T.length, U))
					)
				)[0] r = that;

				auto l = limits[IndexOf!(typeof(r), T)].right;

				return mixin(q{l} ~ op ~ q{r});
			}
		auto opUnary (string op)()
			{/*...}*/
				return mixin(op ~ q{limits[0].right});
			}
		auto opUnary (string op : `~`)()
			{/*...}*/
				foreach (ref limit; limits)
					limit.right = limit.left;

				return this;
			}
	}
