module evx.experimental.stream;
version(none):

import std.functional;
import evx.operators;
import evx.range;
import evx.type;
import evx.math;

// sampling frequency turns continuous index to discrete index
// interpolation turns continuous index to value over discrete indices
/*	
	;
*/
struct Stream (Sample, Bounds)
	{/*...}*/
		alias Index = Element!Bounds;

		Sample delegate(Index) source;
		Bounds delegate() bounds;

		const measure ()
			{/*...}*/
				return bounds ();
			}

		mixin SliceOps!(source, measure, RangeOps);
	}
auto stream_from (Source, Bounds)(Source source, Bounds bounds)
	{/*...}*/
		return Stream!(ReturnType!source, ReturnType!bounds)(source.toDelegate, bounds.toDelegate);
	}

auto s (T, uint n)(T[n] array)
	{/*...}*/
		return array;
	}

void xmain ()
	{/*...}*/
		auto f = (int x) => double (x).sqrt;
		auto b = () => [0, 100].s;

		auto stream = stream_from (f,b);

		import std.stdio;

		writeln (stream[0..12]);

		stdout.flush;
	}
