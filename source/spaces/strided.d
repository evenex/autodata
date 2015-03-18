module autodata.spaces.strided;

private {/*import}*/
	import std.conv: to;
	import std.range.primitives: front, back, popFront, popBack, empty;
	import autodata.meta;
}

pragma(msg, dimensionality!(Stride!(int[])));
/* iterate over a range, skipping a fixed number of elements each iteration 
*/
struct Stride (R) // TODO multidimensional support
	{/*...}*/
		R range;

		private size_t width;

		this (R range, size_t width)
			{/*...}*/
				this.range = range;
				this.width = width;
			}

		const @property length ()
			{/*...}*/
				return range.length / width;
			}

		static if (is_input_range!R)
			{/*...}*/
				auto ref front ()
					{/*...}*/
						return range.front;
					}
				void popFront ()
					{/*...}*/
						foreach (_; 0..width)
							range.popFront;
					}
				bool empty () const
					{/*...}*/
						return range.length < width;
					}

				static assert (is_input_range!Stride);
			}
		static if (is_forward_range!R)
			{/*...}*/
				@property save ()
					{/*...}*/
						return this;
					}

				static assert (is_forward_range!Stride);
			}
		static if (is_bidirectional_range!R)
			{/*...}*/
				auto ref back ()
					{/*...}*/
						return range.back;
					}
				void popBack ()
					{/*...}*/
						foreach (_; 0..width)
							range.popBack;
					}

				static assert (is_bidirectional_range!Stride);
			}

		auto opIndex () // REVIEW necessary for dimensionality
			{/*...}*/
				return this;
			}

		invariant() {/*}*/
			assert (width != 0, `width must be nonzero`);
		}
	}
auto stride (R,T)(R range, T stride)
	{/*...}*/
		return Stride!R (range, stride.to!size_t);
	}
