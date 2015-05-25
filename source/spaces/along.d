module autodata.spaces.along;

private {/*import}*/
	import autodata.sequence;
	import autodata.meta;
	import autodata.operators;
	import std.conv;
}

struct Along (uint axis, S)
	{/*...}*/
		S space;

		auto access (CoordinateType!S[axis] index)
			{/*...}*/
				enum coord (uint i) = i == axis? q{index} : q{~$..$};

				return mixin(q{
					space[} ~ [Map!(coord, Iota!(dimensionality!S))].join (`,`).to!string ~ q{]
				});
			}

		auto limit (uint i : 0)() const
			{/*...}*/
				return space.limit!axis;
			}

		mixin AdaptorOps!(access, limit!0, RangeExt);
	}
auto along (uint axis, S)(S space)
	{/*...}*/
		return Along!(axis, S)(space);
	}
	unittest {/*...}*/
		import autodata;

		auto x = Nat[8..12].map!(x => 2*x)
			.by (Nat[10..13].map!(x => x/2));

		assert (x.along!1[0].map!((a,b) => a) == [16, 18, 20, 22]);
		assert (x.along!0[0].map!((a,b) => b) == [5, 5, 6]);
	}
