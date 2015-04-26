module autodata.spaces.along;

import autodata;

import std.conv;
import std.stdio;

struct Along (uint axis, S)
	{/*...}*/
		S space;

		auto access (ElementType!(ExprType!(space[].limit!axis)) index)
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

		mixin SliceOps!(access, limit!0);
	}
auto along (uint axis, S)(S space)
	{/*...}*/
		return Along!(axis, S)(space);
	}
	unittest {/*...}*/
		auto x = ℕ[8..12].map!(x => 2*x)
			.by (ℕ[10..13].map!(x => x/2));

		assert (x.along!1[0].map!((a,b) => a) == [16, 18, 20, 22]);
		assert (x.along!0[0].map!((a,b) => b) == [5, 5, 6]);
	}
