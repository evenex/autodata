module autodata.spaces.take_drop;

private {/*import}*/
	import autodata.meta;
	import autodata.core;
	import autodata.operators;
}

struct Take (R, T...)
	{/*...}*/
		R space;
		T lengths;

		auto access (CoordinateType!R coord)
			{/*...}*/
				return space[coord];
			}

		mixin SliceOps!(access, lengths, RangeExt);

		static if (T.length == 1)
			{/*range ops}*/
				auto popFront ()()
					{/*...}*/
						space.popFront;
						--lengths[0];
					}
				auto back ()()
					{/*...}*/
						return space[lengths[0]-1];
					}
				auto popBack ()()
					{/*...}*/
						--lengths[0];
					}
				auto length ()() const
					{/*...}*/
						return lengths[0];
					}

				mixin RangeOps!(space, length, lengths);
			}
	}
struct Drop (R, T...)
	{/*...}*/
		R space;
		T offsets;

		auto access (CoordinateType!R coord)
			{/*...}*/
				return space[offsets[0] + coord[0]];
			}
		auto limit (uint d)() const
			{/*...}*/
				return interval (0, space.limit!d.right - offsets[d]);
			}

		mixin SliceOps!(access, Map!(limit, Ordinal!T), RangeExt);

		static if (T.length == 1)
			{/*range ops}*/
				auto front ()()
					{/*...}*/
						return space[offsets[0]];
					}
				auto popFront ()()
					{/*...}*/
						++offsets[0];
					}
				auto length ()() const
					{/*...}*/
						return limit!0.width;
					}

				mixin RangeOps!(space, length, offsets);
			}
	}
auto take (R, T...)(R space, T lengths)
	{/*...}*/
		return Take!(R, Map!(Unqual, T))(space, lengths);
	}
auto drop (R, T...)(R space, T offsets)
	{/*...}*/
		return Drop!(R, Map!(Unqual, T))(space, offsets);
	}
