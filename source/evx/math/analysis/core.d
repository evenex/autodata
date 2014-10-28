module evx.math.analysis.core;

private {/*imports}*/
	import std.algorithm; 
	import std.typetuple; 
	import std.traits; 
	import std.range;
	import std.conv;

	import evx.math.logic;
	import evx.math.algebra;
	import evx.math.vectors;
	import evx.math.ordinal;
	import evx.math.units.overloads;
	import evx.meta;

	import evx.math.analysis.traits;

	mixin(FunctionalToolkit!());
}

public {/*comparison}*/
	enum standard_relative_tolerance = 1e-5;

	/* test if a number or range is approximately equal to another 
	*/
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (allSatisfy!(isInputRange, T, U) && allSatisfy!(not!is_vector_like, T, U)) // REVIEW
		{/*...}*/
			foreach (x,y; zip (a,b))
				if (x.approx (y, relative_tolerance))
					continue;
				else return false;

			return true;
		}
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (anySatisfy!(is_vector_like, T, U) && allSatisfy!(Or!(is_vector_like, isInputRange), T, U)) // REVIEW
		{/*...}*/
			return approx (a[], b[]);
		}
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (not (anySatisfy!(isInputRange, T, U)) && not (anySatisfy!(is_vector_like, T, U))) // TODO try allSat (not!is)
		{/*...}*/
			alias V = CommonType!(T,U);

			auto abs_a = abs (a);
			auto abs_b = abs (b);

			if ((abs_a + abs_b).to!double < relative_tolerance)
				return true;

			auto ε = max (abs_a, abs_b) * relative_tolerance;

			return abs (a-b) < ε;			
		}

	/* a.approx (b) && b.approx (c) && ...
	*/
	bool all_approx_equal (Args...)(Args args)
		if (Args.length > 1)
		{/*...}*/
			foreach (i,_; args[0..$-1])
				if (not (args[i].approx (args[i+1])))
					return false;
			return true;
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
					import std.conv;
					import evx.traits;

					alias This = typeof(this);

					debug foreach (member; __traits(allMembers, This))
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
		version (releasemode_conditional_compilation) // TODO
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
		}

}
