module spacecadet.spaces.array;

private {/*import}*/
	import std.typecons;
	import std.range.primitives: front, back, popFront, popBack, empty;

	import spacecadet.core;
	import spacecadet.meta;
	import spacecadet.functional;
	import spacecadet.operators;
	import spacecadet.sequence;
}

struct Array (T, uint dimensions = 1)
	{/*...}*/
		T[] data;

		inout ptr () {return data.ptr;}

		Repeat!(dimensions, size_t) lengths;

		auto length ()() const
			if (dimensions == 1)
			{/*...}*/
				return length!0;
			}
		auto length (uint d)() const
			{/*...}*/
				return lengths[d];
			}
		ref access (Repeat!(dimensions, size_t) index)
			{/*...}*/
				size_t offset = 0;
				size_t stride = 1;

				foreach (i; Iota!dimensions)
					{/*...}*/
						offset += index[i] * stride;
						stride *= length!i;
					}

				return data[offset];
			}
		void pull (S, U...)(S space, U region)
			if (U.length == dimensions)
			{/*...}*/
				alias open = Map!(λ!q{(T) = is (T == U[2], U)}, U);

				Repeat!(dimensions, size_t[2]) bounds;
				{/*init}*/
					foreach (i; Iota!dimensions)
						static if (open[i])
							bounds[i] = region[i].to!(size_t[2]);
						else bounds[i] = [region[i], region[i]+1].to!(size_t[2]);
				}

				size_t[dimensions] stride;
				{/*init}*/
					foreach (i; Iota!dimensions[1..$])
						stride[i] = length!(i-1);
					stride[0] = 1;
				}

				size_t[dimensions] index;

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
								auto get_index (size_t i)()
									{/*...}*/
										return index[i];
									}

								data[offset] = space[
									Map!(get_index,
										Map!(Pair!().First!Identity,
											Filter!(Pair!().Second!Identity,
												Indexed!open
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
		void allocate (Repeat!(dimensions, size_t) lengths)
			{/*...}*/
				data = new T[lengths.product];
				this.lengths = lengths;
			}

		mixin BufferOps!(allocate, pull, access, Map!(length, Iota!dimensions), RangeOps);
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

/* allocate an array from data 
*/
auto array (S)(S space)
	in {/*...}*/
		static assert (dimensionality!S > 0,
			S.stringof ~ ` has 0 dimensions; if it is a container, try passing a slice [] instead`
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
