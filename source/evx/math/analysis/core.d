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
	import evx.math.overloads;
	import evx.meta;
}

public {/*∞}*/
	template infinite (T)
		if (is_continuous!T)
		{/*...}*/
			alias infinite = identity_element!(real.infinity).of_type!T;
		}
	alias infinity = infinite!real;

	/* test whether a value is infinite 
	*/
	bool is_infinite (T)(T value)
		if (not(isInputRange!T))
		{/*...}*/
			static if (__traits(compiles, infinite!T))
				return value.abs == infinite!T;
			else return false;
		}
	bool is_finite (T)(T value)
		{/*...}*/
			return not (is_infinite (value));
		}
		unittest {/*...}*/
			assert (infinite!real.is_infinite);
			assert (infinite!double.is_infinite);
			assert (infinite!float.is_infinite);

			assert ((-infinite!real).is_infinite);
			assert ((-infinite!double).is_infinite);
			assert ((-infinite!float).is_infinite);

			assert (not (zero!real.is_infinite));
			assert (not (zero!double.is_infinite));
			assert (not (zero!float.is_infinite));

			import evx.math.units;
			assert (infinite!Meters.is_infinite);
			assert (infinite!Seconds.is_infinite);
			assert (infinite!Kilograms.is_infinite);
			assert (infinite!Amperes.is_infinite);

			assert ((-infinite!Meters).is_infinite);
			assert ((-infinite!Seconds).is_infinite);
			assert ((-infinite!Kilograms).is_infinite);
			assert ((-infinite!Amperes).is_infinite);

			assert (not (zero!Meters.is_infinite));
			assert (not (zero!Seconds.is_infinite));
			assert (not (zero!Kilograms.is_infinite));
			assert (not (zero!Amperes.is_infinite));
		}
}
public {/*continuity}*/
	/* test whether a type has a floating point representation
	*/
	template is_continuous (T)
		{/*...}*/
			enum is_continuous = allSatisfy!(isFloatingPoint, RepresentationTypeTuple!T);
		}

	/* test whether a range can represent a floating point function 
	*/
	template is_continuous_range (T)
		{/*...}*/
			static if (hasMember!(T, `opIndex`))
				enum has_continuous_domain = anySatisfy!(is_continuous, IndexTypes!T);
			else enum has_continuous_domain = true;

			static if (hasMember!(T, `measure`))
				enum is_measurable = __traits(compiles, {auto μ = T.init.measure; static assert (is_continuous!(typeof(μ)));});
			else enum is_measurable = false;

			enum is_continuous_range = isInputRange!T && has_continuous_domain && is_measurable;
		}
	version (unittest) {/*functional compatibility}*/
		import evx.math.functional;
		mixin(FunctionalToolkit!());

		unittest {/*...}*/
			struct T
				{/*...}*/
					float measure;

					auto opIndex (float i)
						{return i;}

					auto opSlice (float i, float j)
						{return this;}

					auto front ()
						{/*...}*/
							return measure;
						}

					void popFront ()
						{/*...}*/
							
						}

					enum empty = true;
				}

			static assert (is_continuous_range!T);

			auto x = T(1);
			auto y = T(1);
			auto z = zip(x,y);
			auto w = z.map!(t => t);
		}
	}
}
public {/*comparison}*/
	enum standard_relative_tolerance = 1e-5;

	/* test if a number or range is approximately equal to another 
	*/
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (allSatisfy!(isInputRange, T, U))
		{/*...}*/
			foreach (x,y; zip (a,b))
				if (x.approx (y, relative_tolerance))
					continue;
				else return false;

			return true;
		}
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (allSatisfy!(is_vector_like, T, U))
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

	/* test if t0 <= t <= t1 
	*/
	bool between (T, U, V) (T t, U t0, V t1) 
		{/*...}*/
			return t0 <= t && t <= t1;
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
