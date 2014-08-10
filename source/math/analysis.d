module evx.analysis;

private {/*import std}*/
	import std.math: 
		approxEqual;

	import std.typetuple: 
		allSatisfy,
		staticMap;

	import std.traits: 
		isNumeric;

	import std.range:
		isForwardRange, hasLength,
		ElementType;

	import std.conv:
		text;
}
private {/*import evx}*/
	import evx.logic:
		not, And;

	import evx.algebra:
		zero;

	import evx.meta:
		is_indexable;
}

immutable infinity = real.infinity;

pure nothrow:
public {/*comparison}*/
	/* test if a type supports approximate equality comparison 
	*/
	template has_approximate_equality (T)
		{/*...}*/
			enum has_approximate_equality = __traits(compiles,
				T.init.approxEqual (T.init)
			);
		}

	/* test if a number or range is approximately equal to another 
	*/
	auto approx (T, U)(const T a, const U b)
		{/*...}*/
			return approxEqual (a,b);
		}

	/* a.approx (b) && b.approx (c) && ...
	*/
	bool all_approx_equal (Args...)(Args args)
		if (Args.length > 1 && allSatisfy!(has_approximate_equality, Args))
		{/*...}*/
			foreach (i,_; args[0..$-1])
				if (not (args[i].approx (args[i+1])))
					return false;
			return true;
		}

	/* test if t0 <= t <= t1 
	*/
	bool between (T, U, V) (T t, U t0, V t1) 
		{/*...}*/
			return t0 <= t && t <= t1;
		}
}
public {/*intervals}*/
	/* generic interval type 
	*/
	struct Interval (Index)
		{/*...}*/
			pure nothrow:
			const @property length ()
				{/*...}*/
					return end - start;
				}
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
			@property start (Index i)
				{/*...}*/
					bounds[0] = i;
				}
			@property end (Index i)
				{/*...}*/
					bounds[1] = i;
				}
			this (Index start, Index end)
				{/*...}*/
					this.start = start;
					this.end = end;
				}

			private:
			Index[2] bounds;
			invariant (){/*...}*/
				assert (bounds[0] <= bounds[1]);
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

	auto interval (T)(T start, T end)
		{/*...}*/
			return Interval!T (start, end);
		}
		unittest {/*...}*/
			import std.exception: assertThrown;

			auto A = interval (0, 10);
			assert (A.length == 10);

			A.start = 9;
			assert (A.length == 1);

			try assertThrown!Error (A.end = 8);
			catch (Exception) {}
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
}
public {/*calculus}*/
	/* compute the derivative of f at x 
	*/
	real derivative (alias f)(real x, real Δx = 1e-05)
		if (isCallable!f)
		{/*...}*/
			return (f(x)-f(x-Δx))/Δx;
		}
}
public {/*normalization}*/
	/* clamp a value between two other values 
	*/
	auto clamp (T, U, V)(T value, U min, V max)
		in {/*...}*/
			assert (min < max);
		}
		body {/*...}*/
			value = value < min? min: value;
			value = value > max? max: value;
			return value;
		}

	/* tags a floating point value as only holding normalized values
		and specifies the range for invariance checking */
	enum Normalized {positive, full}

	/* ensure that values tagged Normalized are indeed normalized 
		between -1.0 and 1.0 by default
		or 0.0 and 1.0 if Normalized.positive policy is specified
	*/
	mixin template NormalizedInvariance ()
		{/*...}*/
			invariant ()
				{/*...}*/
					import evx.meta: 
						has_attribute;

					alias This = typeof(this);

					foreach (member; __traits(allMembers, This))
						{/*...}*/
							immutable string error_msg = `"` ~member~ ` is not normalized ("` ` ~` ~member~ `.text~ ")"`;
							
							static if (has_attribute!(This, member, Normalized.full) || has_attribute!(This, member, Normalized)) mixin(q{
								assert (} ~member~ q{.between (-1.0, 1.0),} ~error_msg~ q{);
							});
							else static if (has_attribute!(This, member, Normalized.positive)) mixin(q{
								assert (} ~member~ q{.between (0.0, 1.0),} ~error_msg~ q{);
							});
						}
				}
		}
		unittest {/*...}*/
			debug {/*...}*/
				struct Test
					{/*...}*/
						float a;

						@(Normalized.full) 
						double b;

						@(Normalized.positive)
						real c;

						@Normalized
						real d;

						mixin NormalizedInvariance;

						void test (){}
					}


				auto t = Test (0.0, 0.0, 0.0, 0.0);

				bool thrown;

				void attempt (void delegate() action) nothrow
					{try {action(); t.test;} catch (Throwable) {thrown = true;}}

				attempt ({t.a = 9.0;});
				assert (not (thrown));

				attempt ({t.b = 1.0;});
				assert (not (thrown));

				attempt ({t.b = 1.1;});
				assert (thrown);
				thrown = false;

				attempt ({t.b = -1.0;});
				assert (not (thrown));

				attempt ({t.c = -1.0;});
				assert (thrown);
				thrown = false;

				attempt ({t.c = 1.0;});
				assert (not (thrown));

				attempt ({t.d = 1.01;});
				assert (thrown);
				thrown = false;

				attempt ({t.d = 1.0;});
				assert (not (thrown));

				attempt ({t.d = -1.0;});
				assert (not (thrown));
			}			
		}

}
