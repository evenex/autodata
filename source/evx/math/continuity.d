module evx.math.continuity;

import evx.type;
import evx.range.classification;

import std.typetuple;
import std.traits;

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
			enum has_continuous_domain = is_continuous!(IndexType!T);
		else enum has_continuous_domain = true;

		static if (hasMember!(T, `measure`))
			enum is_measurable = __traits(compiles, {auto μ = T.init.measure; static assert (is_continuous!(typeof(μ)));});
		else enum is_measurable = false;

		enum is_continuous_range = is_input_range!T && has_continuous_domain && is_measurable;
	}
version (unittest) {/*functional compatibility}*/
	import evx.math;//	import evx.math.functional;

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
