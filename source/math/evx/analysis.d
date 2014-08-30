module evx.analysis;

private {/*imports}*/
	private {/*std}*/
		import std.algorithm; 
		import std.math; 
		import std.typetuple; 
		import std.traits; 
		import std.range;
		import std.conv;
	}
	private {/*evx}*/
		import evx.functional;
		import evx.logic;
		import evx.algebra;
		import evx.arithmetic;
		import evx.ordinal;
		import evx.traits;
		import evx.meta;
		import evx.functional;
	}

	alias zip = evx.functional.zip;
	alias map = evx.functional.map;
	alias reduce = evx.functional.reduce;
}

template infinite (T)
	if (is_continuous!T)
	{/*...}*/
		alias infinite = identity_element!(real.infinity).of_type!T;
	}

alias infinity = infinite!real;

pure:
public {/*comparison}*/
	enum standard_relative_tolerance = 1e-5;

	/* test if a type overloads approximate equality comparison 
	*/
	template overloads_approx (T)
		{/*...}*/
			enum overloads_approx = hasMember!(T, `approx`);
		}
	
	/* test if a number or range is approximately equal to another 
	*/
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (allSatisfy!(isInputRange, T, U) && allSatisfy!(Or!(isNumeric, overloads_approx), CommonType!(staticMap!(ElementType, T, U))))
		{/*...}*/
			alias C = CommonType!(staticMap!(ElementType, T, U));

			foreach (τ; zip (a,b))
				if (τ[0].approx (τ[1], relative_tolerance))
					continue;
				else return false;

			return true;
		}
	auto approx (T,U)(T a, U b, real relative_tolerance = standard_relative_tolerance)
		if (allSatisfy!(isNumeric, T, U))
		{/*...}*/
			alias V = CommonType!(T,U);

			auto abs_a = abs (a);
			auto abs_b = abs (b);

			if (abs_a + abs_b < relative_tolerance)
				return true;

			auto ε = max (abs_a, abs_b) * relative_tolerance;

			return abs (a-b) < ε;			
		}

	/* a.approx (b) && b.approx (c) && ...
	*/
	bool all_approx_equal (Args...)(Args args)
		if (Args.length > 1 && allSatisfy!(Or!(isNumeric, overloads_approx), Args))
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
			const @property toString ()
				{/*...}*/
					return `interval (` ~min.text~ `..` ~max.text~ `)`;
				}

			pure:
			static if (is_continuous!Index)
				alias measure = size;
			else alias length = size;

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

			@property start ()(Index i)
				{/*...}*/
					bounds[0] = i;
				}
			@property end ()(Index i)
				{/*...}*/
					bounds[1] = i;
				}

			const @property size ()
				{/*...}*/
					return end - start;
				}

			alias min = start;
			alias max = end;

			this (Index start, Index end)
				{/*...}*/
					bounds = [start, end];
				}

			private:
			Index[2] bounds = [zero!Index, zero!Index];

			invariant (){/*...}*/
				assert (bounds[0] <= bounds[1], `bounds inverted`);
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

	/* convenience constructor 
	*/
	auto interval (T,U)(T start, U end)
		if (not(is(CommonType!(T,U) == void)))
		{/*...}*/
			return Interval!(CommonType!(T,U)) (start, end);
		}
		unittest {/*...}*/
			import std.exception: assertThrown;

			auto A = interval (0, 10);
			assert (A.length == 10);

			A.start = 9;
			assert (A.length == 1);

			static if (0)
			try assertThrown!Error (A.end = 8); // OUTSIDE BUG assertThrown is no longer suppressing the assertion failure
			catch (Exception) assert (0);
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

	/* test if an interval is contained within another 
	*/
	bool is_contained_in (T)(Interval!T A, Interval!T B)
		{/*...}*/
			return A.start >= B.start && A.end <= B.end;
		}
		unittest {/*...}*/
			auto A = interval (0, 10);
			auto B = interval (1, 5);
			auto C = interval (10, 11);
			auto D = interval (9, 17);

			assert (not (A.is_contained_in (B)));
			assert (not (A.is_contained_in (C)));
			assert (not (A.is_contained_in (D)));

			assert (B.is_contained_in (A));
			assert (not (B.is_contained_in (C)));
			assert (not (B.is_contained_in (D)));

			assert (not (C.is_contained_in (A)));
			assert (not (C.is_contained_in (B)));
			assert (C.is_contained_in (D));

			assert (not (D.is_contained_in (A)));
			assert (not (D.is_contained_in (B)));
			assert (not (D.is_contained_in (C)));
		}

	/* test if a point is contained within an interval 
	*/
	bool is_contained_in (T)(T x, Interval!T I)
		{/*...}*/
			return x.between (I.start, I.end);
		}

	/* test whether an interval is infinite 
	*/
	bool is_infinite (T)(Interval!T I)
		{/*...}*/
			return I.start.is_infinite || I.end.is_infinite;
		}
		unittest {/*...}*/
			auto x = interval (-10, 10);
			auto y = interval (-infinity, 10);
			auto z = interval (-10, infinity);

			assert (x.is_finite);
			assert (y.is_infinite);
			assert (z.is_infinite);
		}
}
public {/*calculus}*/
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
	unittest {/*functional compatibility}*/
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

	/* test whether a value is infinite 
	*/
	bool is_infinite (T)(T value)
		if (not(is(T == Interval!U, U) || isInputRange!T))
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

			import evx.units;
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

	/* compute the derivative of a function at some point 
	*/
	real derivative (alias f)(real x, real Δx = 1e-6)
		if (isCallable!f)
		{/*...}*/
			return (f(x)-f(x-Δx))/Δx;
		}

	/* compute the integral of a function over some boundary 
	*/
	auto integrate (alias func, T)(Interval!T boundary, T differential = identity_element!(1e-6).of_type!T)
		{/*...}*/
			static if (isCallable!func)
				alias f = func;
			else alias f = func!real;

			immutable domain = boundary;
			immutable Δx = differential;

			if (domain.is_finite)
				{/*...}*/
					size_t n_partitions ()
						{/*...}*/
							try return (domain.measure / Δx).round.to!size_t + 1;
							catch (Exception) assert (0);
						}

					return Σ (ℕ[0..n_partitions]
						.map!(i => domain.min + i*Δx)
						.map!(x => f(x)*Δx)
					);
				}
			else assert (0, `integration over infinite domain unimplemented`);
		}
		unittest {/*...}*/
			assert (integrate!(x => x)(interval (0.0, 1.0)).approx (1./2));
			assert (integrate!(x => x)(interval (-1.0, 1.0)).approx (0));

			assert (integrate!(x => x^^2)(interval (0.0, 1.0)).approx (1./3));
			assert (integrate!(x => x^^2)(interval (-1.0, 1.0)).approx (2./3));
		}

	/* flag a functor as being integrable with respect to some differential measure 
	*/
	deprecated mixin template Integrability (alias Δμ)
		{/*...}*/
			enum is_integrable;
			alias differential_measure = Δμ;
		}

	/* test if a functor is integrable according to the definition of Integrability 
	*/
	deprecated template is_integrable (T)
		{/*...}*/
			enum is_integrable = is(T.is_integrable == enum) && is(typeof(T.differential_measure));
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

					try debug foreach (member; __traits(allMembers, This))
						{/*...}*/
							immutable string error_msg = `"` ~member~ ` is not normalized ("` ` ~` ~member~ `.text~ ")"`;
							
							static if (has_attribute!(This, member, Normalized.full) || has_attribute!(This, member, Normalized)) mixin(q{
								assert (} ~member~ q{.between (-1.0, 1.0),} ~error_msg~ q{);
							});
							else static if (has_attribute!(This, member, Normalized.positive)) mixin(q{
								assert (} ~member~ q{.between (0.0, 1.0),} ~error_msg~ q{);
							});
						}
					catch (Exception) assert (0);
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
