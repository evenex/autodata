module evx.math.units.interop;

import evx.math.units.metric;
import evx.math.units.core;
import std.conv;

public {/*Time ↔ std.datetime.Duration}*/
	auto to_duration (Seconds time)
		{/*...}*/
			return std.datetime.nsecs ((time.to!Scalar * 1_000_000_000).to!long);
		}
	auto to_evx_time (std.datetime.Duration duration)
		{/*...}*/
			return duration.total!`nsecs`.nanoseconds;
		}
}
