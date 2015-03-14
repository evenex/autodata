module evx.operators.multilimit;

private {/*imports}*/
	import std.algorithm: swap;

	import evx.meta;
	import evx.interval;
	import evx.logic;
	import evx.algebra;
}

/* WARNING experimental -- 
	will probably only be usable with multiple alias this
	https://github.com/D-Programming-Language/dmd/pull/3998 
	and strict index type segregation
*/
template MultiLimitOps (size_t dim, limits...)
	{/*...}*/
		mixin LambdaCapture;

		auto opDollar (size_t i: dim)()
			{/*...}*/
				alias Limits = Map!(Λ!q{(T...) = typeof(T[0].identity)}, limits);

				MultiLimit!(
					Map!(ElementType,
						Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])},
							Limits
						)
					)
				) multilimit;

				foreach (i, Lim; Limits)
					static if (is (Lim == T[2], T))
						multilimit.limits[i] = limits[i];
					else multilimit.limits[i] = [Lim(0), limits[i]];

				return multilimit;
			}
	}
struct MultiLimit (T...)
	{/*...}*/
		Map!(Λ!q{(U) = U[2]}, T)
			limits;

		alias alt = opCast!(T[0]);
		alias alt this;

		U opCast (U)()
			in {/*...}*/
				static assert (Contains!(U,T),
					`cannot cast ` ~ typeof(this).stringof ~ ` to ` ~ U.stringof
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
					U.stringof ~ ` does not convert to any ` ~ T.stringof
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
					swap (limit.left, limit.right);

				return this;
			}
	}
