module evx.containers.array;

private {/*import}*/
	import std.typecons;

	import evx.type;
	import evx.operators;
	import evx.math;
	import evx.range;
}

struct Array (T, uint dimensions = 1)
	{/*...}*/
		struct Base // BUG https://issues.dlang.org/show_bug.cgi?id=13860
			{/*...}*/
				T[] data;

				Repeat!(dimensions, size_t) lengths;

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
			}

		Base base;
		alias base this;

		auto ref array () {return this;} // REVIEW HACK, to get around some kind of builtin .array thing that conflicts with UFCS array
		auto ptr () {return base.data.ptr;}

		auto length (size_t d = 0)()
			{/*...}*/
				return base.length!d;
			}
		ref access (Repeat!(dimensions, size_t) point)
			{/*...}*/
				return base.access (point);
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

						foreach (i, length; base.lengths)
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
						auto get_index (size_t i)()
							{/*...}*/
								return index[i];
							}

						base.data[offset] = space[
							Map!(get_index,
								Map!(Pair!().First!Identity,
									Filter!(Pair!().Second!Identity,
										Indexed!open
									)
								)
							).tuple.expand
						];

						advance;
					}
			}
		void allocate (Repeat!(dimensions, size_t) lengths)
			{/*...}*/
				base.data = new T[only (lengths).product];
				base.lengths = lengths;
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

		assert (y.base.data == [
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
			0, 0, 0, 0, 0,
		]);

		y[0..$, 0] = [1,2,3,4,5];
		y[0, 0..$] = [1,2,3,4,5];

		assert (y.base.data == [
			1, 2, 3, 4, 5,
			2, 0, 0, 0, 0,
			3, 0, 0, 0, 0,
			4, 0, 0, 0, 0,
			5, 0, 0, 0, 0,
		]);

		auto z = Array!(int, 2)(y[0..2, 0..2]);

		y[2..4, 2..4] = z[];

		assert (y.base.data == [
			1, 2, 3, 4, 5,
			2, 0, 0, 0, 0,
			3, 0, 1, 2, 0,
			4, 0, 2, 0, 0,
			5, 0, 0, 0, 0,
		]);
	}

auto array (S)(S space)
	{/*...}*/
		return Array!(Element!S, dimensionality!S)(space);
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
