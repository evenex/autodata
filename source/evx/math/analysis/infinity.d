module evx.math.analysis.infinity;

import evx.math.analysis.traits;
import evx.math.algebra;
import evx.math.logic;

import std.range;

/* ∞ */
alias infinity = infinite!real;

template infinite (T)
	if (is_continuous!T)
	{/*...}*/
		alias infinite = identity_element!(real.infinity).of_type!T;
	}

/* test whether a value is infinite 
*/
bool is_infinite (T)(T value)
	if (not(isInputRange!T))
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