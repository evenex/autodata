module evx.analysis;

private {/*import evx}*/
	import evx.utils:
		not;
}

pure nothrow:

struct Interval (Index)
	{/*...}*/
		Index start;
		Index end;

		pure nothrow const:
		@property length ()
			{/*...}*/
				return end - start;
			}
		@property empty ()
			{/*...}*/
				return not (end - start);
			}
	}
pure {/*interval comparison functions}*/
	bool ends_before_end (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.end < b.end;
		}
	bool ends_before_start (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.end < b.start;
		}
	bool starts_before_end (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.start < b.end;
		}
	bool starts_before_start (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.start < b.start;
		}
}

/* compute the derivative of f at x 
*/
real derivative (alias f, real Δx = 0.01)(real x)
	if (isCallable!f)
	{/*...}*/
		return (f(x)-f(x-Δx))/Δx;
	}

/* test if t0 <= t <= t1 
*/
bool between (T, U, V) (T t, U t0, V t1) 
	{/*...}*/
		return t0 <= t && t <= t1;
	}

/* clamp a value between two other values 
*/
auto clamp (T, U, V)(T value, U min, V max)
	{/*...}*/
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

	void attempt (void delegate() action)
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
