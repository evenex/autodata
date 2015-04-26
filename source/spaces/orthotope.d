module autodata.spaces.orthotope;

private {/*imports}*/
	import autodata.meta;
	import autodata.core;
	import autodata.operators;
}
struct Orthotope (Intervals...)
	{/*...}*/
		Intervals bounds;

		auto access (Map!(ElementType, Intervals) args)
			{/*...}*/
				return args.tuple;
			}

		auto limit (uint i)() const
			{/*...}*/
				return bounds[i];
			}

		mixin SliceOps!(access, Map!(limit, Ordinal!Intervals), RangeExt);
	}
auto orthotope (Intervals...)(Intervals intervals)
	{/*...}*/
		return Orthotope!Intervals (intervals);
	}
	unittest {/*...}*/
		import autodata.functional;

		assert (
			ortho (interval (3.9, 10.9), interval (10, 14))[5.6, ~$..$]
				.map!(x => [x.expand])
			== [[5.6, 10], [5.6, 11], [5.6, 12], [5.6, 13]]
		);

	}

alias ortho = orthotope;
