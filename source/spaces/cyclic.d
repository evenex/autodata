module autodata.spaces.cyclic;

import std.range: cycle; // TEMP
import std.math;
import std.conv;
		import autodata.functional;

/* traverse a range with elements rotated left by some number of positions 
*/
auto rotate_elements (R)(R range, int positions = 1)
	in {/*...}*/
		auto n = range.length;

		if (n > 0)
			assert (positions.sgn * (positions + n) % n > 0);
	}
	body {/*...}*/
		auto n = range.length;

		if (n == 0)
			return std.array.array (typeof(range.cycle[0..0]).init); // TEMP std.array.array

		auto i = positions.sgn * (positions + n) % n;
		
		// TEMP cache to get dimensionality, need to do something about this later
		return std.array.array (range.cycle[i..n+i]);
	}

/* pair each element with its successor in the range, and the last element with the first 
*/
auto adjacent_pairs (R)(R range)
	{/*...}*/
		return zip (range, range.rotate_elements);
	}

import autodata.meta;
import autodata.operators;
import autodata.core;
		import std.stdio;

size_t[2] limit (uint d : 0, R)(R range)
	{/*...}*/
		return [0, range.length];
	}

struct Cycle (R, Dims...)
	{/*...}*/
		enum dimensionality = .dimensionality!R;
		alias CyclicDims = Cons!(Dims[0].Unpack);
		alias ModuloDims = Cons!(Dims[1].Unpack);

		alias Coord (uint d) = CoordinateType!R[d];
		alias Slice (uint d) = Coord!d[2];
		//////////

		R space;

		Map!(Coord, CyclicDims) offsets;
		Map!(Slice, ModuloDims) bounds;

		auto limit (size_t d)() const
			if (not (Contains!(d, CyclicDims)))
			{/*...}*/
				return space[].limit!d;
			}

		struct Infinity (size_t d)
			{/*...}*/
				auto opUnary (string op : `~`)()
					{/*...}*/
						return start;
					}

				CoordinateType!R[d] start;
			}

		auto opDollar (size_t d)()
			{/*...}*/
				static if (not (Contains!(d, CyclicDims)))
					{/*...}*/
						auto dollar ()() {return space.opDollar!d;}
						auto length ()() if (d == 0 && dimensionality == 1) 
							{return space.length;}

						return Match!(dollar, length);
					}
				else {/*...}*/
					auto dollar ()() {return ~space.opDollar!d;}
					auto zero ()() {return CoordinateType!R[d](0);}

					return Infinity!d (Match!(dollar, zero));
				}
			}

		auto opIndex (Selected...)(Selected selected)
			{/*...}*/
				static if (Selected.length == 0)
					{/*...}*/
						return this;
					}
				else static if (Any!(λ!q{(T) = is (T == U[2], U) || is (T.Types)}, Selected))
					{/*...}*/
						alias Dims (alias filter) = Map!(
							Pair!().First!Identity,
							Filter!(filter, Enumerate!Selected)
						);

						alias Modulo = Dims!(λ!q{(alias pair) = is (pair.second == U[2], U)});
						alias Cyclic = Dims!(λ!q{(alias pair) = is (pair.second.Types)});

						return Cycle!(R, Pack!Cyclic, Pack!Modulo)(space);
					}
				else {/*...}*/
					template get_point (uint i)
						{/*...}*/
							alias Coord = CoordinateType!R[i];

							auto divide ()() if (Contains!(i, Cons!(CyclicDims, ModuloDims)))
								in {/*...}*/
									assert (space[].limit!i.width != Coord (0),
										R.stringof~ ` has zero width along dimension ` ~i.text
									);
								}
								body {/*...}*/
									auto offset ()() if (Contains!(i, CyclicDims)) {return offsets[IndexOf!(i, CyclicDims)];}
									auto bound ()() if (Contains!(i, ModuloDims)) {return bounds[IndexOf!(i, ModuloDims)].left;}

									auto o = Match!(offset, bound);
									auto p = selected[i];
									auto w = space[].limit!i.width;

									if (p < space[].limit!i.left)
										return (o + p + w * (p/w + Coord (1))) % w;
									else return (o + p) % w;
								}
							auto pass ()() if (not (Contains!(i, Cons!(CyclicDims, ModuloDims))))
								{/*...}*/
									return selected[i];
								}
								
							alias get_point = Match!(divide, pass);
						}

					return space[Map!(get_point, Ordinal!Selected).tuple.expand];
				}
			}

		Slice!d opSlice (size_t d)(Repeat!(2, Coord!d) slice)
			{/*...}*/
				return [slice];
			}
		auto opSlice (size_t d)(Coord!d left, Infinity!d right)
			{/*...}*/
				return tuple (left, right);
			}
	}
auto cycle (S)(S space)
	{/*...}*/
		return Cycle!(S, Pack!(0,true,true))(space);
	}

import autodata.spaces.product;
version (autodata_devel)
void main ()
	{/*...}*/
		import autodata.spaces.array;
		import autodata.meta.test;
		auto a = [1,2,3].extrude ([4,5,6]).array;
		auto x = a.Cycle!(Array!(int,2), Pack!(0,1), Pack!());
		auto y = a.Cycle!(Array!(int,2), Pack!(0), Pack!());

	//	pragma(msg, typeof(x.limit!0), typeof(x.limit!1));
	//	pragma(msg, dimensionality!(typeof(x)), CoordinateType!(typeof(x)));
	//	pragma(msg, dimensionality!(typeof(y)), CoordinateType!(typeof(y)));

	//	y[~$..$];

	//	assert ([1,2,3].cycle[5..10] == [2,3,1,2,3]);

		no_error 	(a[2,2]);
		error 		(a[3,3]);

		no_error 	(x[2,2]);
		no_error 	(x[3,3]);

		no_error 	(y[3,2]);
		error 		(y[3,3]);

		auto z = [1,2,3].Cycle!(int[], Pack!(0), Pack!());

		pragma(msg, typeof(z[]));
		pragma(msg, typeof(z[2]));
		pragma(msg, typeof(z[3..4]));
		pragma(msg, typeof(z[0..$]));
	}//

static if (0)
void main ()
	{/*...}*/
		
	}
