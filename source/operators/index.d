module autodata.operators.index;

/* generate an indexing operator from an access function and a set of index limits

	Requires:
		LimitOps requirements (the type of the evaluated limit symbol (or its element type, whichever applies) is referred to as the measure type).
		Access must be a non-template function which returns a non-void value.
		The measure types must match the access parameter types in order.
*/
template IndexOps (alias access, limits...)
	{/*...}*/
		private {/*imports}*/
			import autodata.operators.limit;
			import autodata.meta;
			import autodata.core;
		}

		auto ref Codomain!access opIndex (Domain!access selected)
			in {/*...}*/
				import std.conv: text;

				version (all)
					{/*error messages}*/
						enum error_header = typeof(this).stringof~ `: `;

						enum element_type_error = error_header~ `access primitive must return a non-void value`;

						enum array_error = error_header~ `limit types must be singular or arrays of two`
						`: ` ~Map!(ExprType, limits).stringof;

						enum type_error = error_header~ `limit base types must match access parameter types`
						`: ` ~Map!(ExprType, limits).stringof
						~ ` !→ ` ~Domain!access.stringof;

						auto out_of_bounds_error (Arg, Lim)(Arg arg, Lim limit) 
							{return error_header~ `bounds exceeded! ` ~arg.text~ ` not in ` ~limit.text;}
					}

				static assert (not (is (Codomain!access == void)), 
					element_type_error
				);

				foreach (i, limit; limits)
					{/*type check}*/
						static assert  (limits.length == Domain!access.length,
							type_error
						);

						static if (is (ExprType!limit == LimitType[n], LimitType, size_t n))
							static assert (n == 2, 
								array_error
							);

						static if (is (LimitType))
							static assert (is (Domain!access[i] == LimitType),
								type_error
							);

						else static assert (
							is (Domain!access[i] == Unqual!(ExprType!limit))
							|| is (Domain!access[i] == ElementType!(Unqual!(ExprType!limit))),
							type_error
						);
					}

				foreach (i, limit; limits)
					{/*bounds check}*/
						static if (is (ElementType!(ExprType!limit) == void))
							auto bounds = interval (ExprType!limit(0), limit);
						else auto bounds = interval (limit);

						assert (
							selected[i].is_contained_in (bounds),
							out_of_bounds_error (selected[i], bounds)
						);
					}
			}
			body {/*...}*/
				return access (selected);
			}

		mixin LimitOps!limits
			limit_ops;
	}
	unittest {/*...}*/
		import autodata.meta.test;

		static struct Basic
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length = 100;

				mixin IndexOps!(access, length);
			}
		assert (Basic()[40]);
		error (Basic()[101]);
		assert (Basic()[$-1]);
		assert (Basic()[~$]);
		error (Basic()[$]);

		static struct RefAccess
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				mixin IndexOps!(access, length);
			}
		RefAccess ref_access;

		assert (ref_access[0] == 0);
		ref_access[0] = 1;
		assert (ref_access[0] == 1);

		static struct LengthFunction
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length () const {return 100;}

				mixin IndexOps!(access, length);
			}
		assert (LengthFunction()[40]);
		error (LengthFunction()[101]);
		assert (LengthFunction()[$-1]);
		assert (LengthFunction()[~$]);
		error (LengthFunction()[$]);

		static struct NegativeIndex
			{/*...}*/
				auto access (int) {return true;}

				int[2] bounds = [-99, 100];

				mixin IndexOps!(access, bounds);
			}
		assert (NegativeIndex()[-25]);
		error (NegativeIndex()[-200]);
		assert (NegativeIndex()[$-25]);
		assert (NegativeIndex()[~$]);
		error (NegativeIndex()[$]);

		static struct FloatingPointIndex
			{/*...}*/
				auto access (float) {return true;}

				float[2] bounds = [-1,1];

				mixin IndexOps!(access, bounds);
			}
		assert (FloatingPointIndex()[0.5]);
		error (FloatingPointIndex()[-2.0]);
		assert (FloatingPointIndex()[$-0.5]);
		assert (FloatingPointIndex()[~$]);
		error (FloatingPointIndex()[$]);

		version (none)
			{/*...}*/
				static struct StringIndex
					{/*...}*/
						auto access (string) {return true;}

						string[2] bounds = [`aardvark`, `zebra`];

						mixin IndexOps!(access, bounds);
					}
				assert (StringIndex()[`monkey`]);
				error (StringIndex()[`zzz`]);
				assert (StringIndex()[$[1..$]]);
				assert (StringIndex()[~$]);
				error (StringIndex()[$]);
			}

		static struct MultiIndex
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				mixin IndexOps!(access_one, bounds_one) A;
				mixin IndexOps!(access_two, length_two) B;

				mixin(function_overload_priority!(
					`opIndex`, B, A)
				);

				alias opDollar = B.opDollar; // TODO until MultiLimit is ready, have to settle for a manual $ selection
			}
		assert (MultiIndex()[5]);
		assert (MultiIndex()[-1.0]);
		assert (MultiIndex()[$-1]);
		error (MultiIndex()[$-1.0]);
		assert (MultiIndex()[~$]);
		error (MultiIndex()[$]);

		static struct LocalOverload
			{/*...}*/
				auto access (size_t) {return true;}

				size_t length = 100;

				mixin IndexOps!(access, length) 
					mixed_in;

				auto opIndex () {return true;}

				mixin(function_overload_priority!(
					`opIndex`, mixed_in)
				);
			}
		assert (LocalOverload()[]);
		assert (LocalOverload()[1]);
		assert (LocalOverload()[$-1]);
		error (LocalOverload()[$]);

		static struct MultiDimensional
			{/*...}*/
				auto access (size_t, size_t) {return true;}

				size_t rows = 3;
				size_t columns = 3;

				mixin IndexOps!(access, rows, columns);
			}
		assert (MultiDimensional()[1,2]);
		assert (MultiDimensional()[$-1, 2]);
		assert (MultiDimensional()[1, $-2]);
		assert (MultiDimensional()[$-1, $-2]);
		assert (MultiDimensional()[~$, ~$]);
		error (MultiDimensional()[$, 2]);
		error (MultiDimensional()[1, $]);
		error (MultiDimensional()[$, $]);
	}
