module evx.math.analysis.calculus;

private {/*imports}*/
	import std.traits; 
	import std.conv; 

	import evx.math.analysis;
	import evx.math.arithmetic;
	import evx.math.ordinal;
	import evx.math.functional;
	import evx.math.algebra;
	import evx.math.overloads;

	mixin(FunctionalToolkit!());
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
						return (domain.measure / Δx).round.to!size_t + 1;
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
