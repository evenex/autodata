module evx.math.units.metric;

import evx.math.units.core;
import evx.math.units.overloads;
import std.traits;

public {/*mass}*/
	alias Kilograms = ReturnType!kilogram;
	alias kilograms = kilogram;
	alias grams = gram;

	auto kilogram (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Mass, 1)(scalar);
		}
	auto gram (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram/1000;
		}
}
public {/*space}*/
	alias Meters = ReturnType!meter;

	alias meters = meter;
	alias kilometers = kilometer;
	alias millimeters = millimeter;

	auto meter (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Space, 1)(scalar);
		}
	auto kilometer (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1000.meter;
		}
	auto millimeter (Scalar scalar = 1)
		{/*...}*/
			return scalar * 0.001.meter;
		}
}
public {/*time}*/
	alias Seconds = ReturnType!second;
	alias seconds = second;
	alias minutes = minute;
	alias hours = hour;
	alias milliseconds = millisecond;
	alias nanoseconds = nanosecond;

	auto second (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Time, 1)(scalar);
		}
	auto minute (Scalar scalar = 1)
		{/*...}*/
			return scalar * 60.seconds;
		}
	auto hour (Scalar scalar = 1)
		{/*...}*/
			return scalar * 60.minutes;
		}
	auto millisecond (Scalar scalar = 1)
		{/*...}*/
			return scalar * second/1000;
		}
	auto nanosecond (Scalar scalar = 1)
		{/*...}*/
			return scalar * second/1_000_000_000;
		}
}
public {/*current}*/
	alias Amperes = ReturnType!ampere;
	alias amperes = ampere;

	auto ampere (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Current, 1)(scalar);
		}
}
public {/*force}*/
	alias Newtons = ReturnType!newton;
	alias newtons = newton;

	auto newton (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram*meter/second/second;
		}
}
public {/*energy}*/
	alias Joules = ReturnType!joule;
	alias joules = joule;

	auto joule (Scalar scalar = 1)
		{/*...}*/
			return scalar * newton*meters;
		}
}
public {/*torque}*/
	alias NewtonMeters = ReturnType!newton_meter;
	alias newton_meters = newton_meter;

	alias newton_meter = joule;
}
public {/*frequency}*/
	alias Hertz = ReturnType!hertz;

	auto hertz (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1.0/second;
		}
	auto kilohertz (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1000.0/second;
		}
}
public {/*voltage}*/
	alias Volts = ReturnType!volt;
	alias volts = volt;

	auto volt (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram * meters.pow!2 * seconds.pow!(-3) * amperes.pow!(-1);
		}
}
