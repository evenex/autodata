module autodata.spaces.array;

private {/*import}*/
	import std.range.primitives: front, back, popFront, popBack, empty;
	import std.conv: to;

	import autodata.core;
	import autodata.meta;
	import autodata.functional;
	import autodata.operators;
	import autodata.sequence;
}

struct Array (T, uint dimensions = 1)
	{/*...}*/
		T[] data;

		Repeat!(dimensions, size_t) lengths;

		void allocate (Repeat!(dimensions, size_t) lengths)
			{/*...}*/
				data = new T[lengths.product];
				this.lengths = lengths;
			}

		mixin MemoryBackedStore!(data, lengths);
		mixin BufferOps!(allocate, pull, access, lengths, RangeExt);
	}
	unittest {/*...}*/
		auto x = Array!int ();

		x = [1,2,3];
		assert (x[] == [1,2,3]);

		x[] = [4,5,6];
		assert (x[] == [4,5,6]);

		auto y = Array!(int, 2)();
		y.allocate (5,5);

		assert (y.data == [
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
		]);

		y[0..$, 0] = [1,2,3,4,5];
		y[0, 0..$] = [1,2,3,4,5];

		assert (y.data == [
			1, 2, 3, 4, 5,
			2, 0, 0, 0, 0,
			3, 0, 0, 0, 0,
			4, 0, 0, 0, 0,
			5, 0, 0, 0, 0,
		]);

		auto z = Array!(int, 2)(y[0..2, 0..2]);

		y[2..4, 2..4] = z[];

		assert (y.data == [
			1, 2, 3, 4, 5,
			2, 0, 0, 0, 0,
			3, 0, 1, 2, 0,
			4, 0, 2, 0, 0,
			5, 0, 0, 0, 0,
		]);
	}

struct StaticArray (T, sizes...)
	{/*...}*/
		T[product (sizes)] data;

		alias data this; // TODO improve multidim support - revealing the raw, flattened data is not correct for 2+ dim case

		alias lengths = Reverse!(Map!(λ!q{(size_t i) = i}, sizes));

		ref opAssign (S)(S space)
			{/*...}*/
				this[] = space;

				return this;
			}
		this (S)(S space)
			{/*...}*/
				this = space;
			}

		mixin MemoryBackedStore!(data, lengths);
		mixin TransferOps!(pull, access, lengths, RangeExt);
	}
auto static_array (uint[] dims, S)(S space)
	{/*...}*/
		template ArrayToCons (uint[] arr)
			{/*...}*/
				static if (arr.empty)
					alias ArrayToCons = Cons!();
				else alias ArrayToCons = Cons!(arr[0], ArrayToCons!(arr[1..$]));
			}

		return StaticArray!(ElementType!S, ArrayToCons!dims)(space);
	}
	unittest {/*...}*/
		import std.range: only;

		StaticArray!(int, 2) x;

		assert (x[] == [0, 0]);

		x[0..2] = only (5, 6);

		assert (x[] == [5, 6]);

		x[] += 5;

		assert (x[] == [10, 11]);

		StaticArray!(int, 4) y = [1,2,3,4];

		assert (y[] == [1, 2, 3, 4]);

		auto z = [9,8,7].static_array!([3]);

		assert (z[] == [9, 8, 7]);
	}

/* allocate an array from data 
*/
auto array (S)(S space)
	in {/*...}*/
		static assert (dimensionality!S > 0,
			S.stringof~ ` has 0 dimensions; if it is a container, try passing a slice [] instead`
		);
	}
	body {/*...}*/
		static if (is (typeof(S == Array!(ElementType!S, dimensionality!S))))
			return space;

		else return Array!(ElementType!S, dimensionality!S)(space);
	}
	unittest {/*...}*/
		auto x = [1,2,3].array;
		assert (x[] == [1,2,3]);

		auto y = Array!(int, 3)();
		y.allocate (3,3,3);

		assert (y[0,0,0] == 0);
		y[] = y[].map!(i => 1);
		assert (y[0,0,0] == 1);

		auto z = y[2,0..$,1..$].array;
		assert (z[0,0..$] == [1,1]);
	}

/* create an array over a pointer, without allocation 
*/
auto array_view (T, U...)(T* ptr, U dims)
	{/*...}*/
		Array!(T, U.length) array;

		array.data = ptr[0..dims.product];
		array.lengths = dims;

		return array;
	}

private {/*impl}*/
	template MemoryBackedStore (alias data, lengths...)
		{/*...}*/
			inout ptr () {return data.ptr;}

			auto length ()() const
				if (lengths.length == 1)
				{/*...}*/
					return length!0;
				}
			auto length (uint d)() const
				{/*...}*/
					return lengths[d];
				}
			ref access (typeof(lengths) index)
				{/*...}*/
					size_t offset = 0;
					size_t stride = 1;

					foreach (i; Ordinal!(typeof(lengths)))
						{/*...}*/
							offset += index[i] * stride;
							stride *= length!i;
						}

					return data[offset];
				}
			void pull (S, U...)(S space, U region)
				if (U.length == lengths.length)
				{/*...}*/
					auto boundary (uint i)()
						{/*...}*/
							auto open ()() if (is_interval!(U[i])) {return region[i];}
							auto closed ()() {return interval (region[i], region[i]+1);}

							return Match!(open, closed);
						}

					auto bounds = Map!(boundary, Ordinal!lengths).tuple.expand;

					size_t[lengths.length] index;

					size_t offset ()
						{/*...}*/
							size_t offset = 0;
							size_t stride = 1;

							foreach (i, length; lengths)
								{/*...}*/
									offset += (bounds[i].left + index[i]) * stride;
									stride *= length;
								}

							return offset;
						}
					void advance (uint i = 0)()
						{/*...}*/
							if (++index[i] >= bounds[i].width)
								static if (i+1 < index.length)
									{/*...}*/
										index[i] = 0;
										advance!(i+1);
									}
						}

					while (index[$-1] < bounds[$-1].width)
						{/*...}*/
							void indexed ()()
								{/*...}*/
									auto get_index (uint i)()
										{/*...}*/
											return index[i].to!(CoordinateType!S[i]);
										}

									data[offset] = space[
										Map!(get_index,
											Map!(First,
												Filter!(Second,
													Enumerate!(Map!(is_interval, U))
												)
											)
										).tuple.expand
									];
								}
							void input_range ()()
								{/*...}*/
									data[offset] = space.front;
									space.popFront;
								}

							Match!(indexed, input_range);

							advance;
						}
				}
		}
}
