module evx.math.infinity;
version(none):

private {/*imports}*/
	import std.traits;

	import evx.math.algebra;
	import evx.math.logic;
	import evx.type;

	import evx.range.classification;
}

/* ∞ */
alias infinity = infinite!real;

template infinite (T)
	if (is_floating_point!(RepresentationTypeTuple!T))
	{/*...}*/
		alias infinite = group_element!(real.infinity).of_group!T;
	}

/* test whether a value is infinite 
*/
bool is_infinite (T)(T value)
	if (not(is_input_range!T))
	{/*...}*/
		static if (__traits(compiles, infinite!T))
			return value == infinite!T || value == -infinite!T;
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

		static if (__traits(compiles, {import evx.math.units;}))
			{/*...}*/
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

/* always-false test for infinite ranges, for ranges which do not define an is_infinite property 
*/
bool is_infinite (R)(R)
	if (is_input_range!R)
	{/*...}*/
		return false;
	}
