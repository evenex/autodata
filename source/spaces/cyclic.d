module autodata.spaces.cyclic;

import std.range: cycle; // TEMP
import std.math;
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

version (none):

import autodata.meta;
import autodata.operators;
import autodata.core;
		import std.stdio;

struct Cycle (R, Dims...)
	{/*...}*/
		enum is_boundary_pack (T) = is (typeof(T.Unpack) == Cons!(int, bool, bool));
		static assert (All!(is_boundary_pack, Dims));

		alias cyclic_dimensions = Map!(λ!q{(T) = T[0]}, Dims);

		//////////

		template Bounds (size_t i)
			{/*...}*/
				alias InfinityType (size_t j) = Select!(
					Dims[IndexOf!(i, cyclic_dimensions)].Unpack[j],
					Infinity, CoordinateType!R[i]
				);

				static if (Contains!(i, cyclic_dimensions))
					alias Bounds = Tuple!(Map!(InfinityType, 1, 2));
				else alias Bounds = CoordinateType!R[i][2];
			}

		Map!(Bounds, Iota!(dimensionality!R)) bounds;

		//////////

		R space;

		auto limit (size_t d)() const
			{/*...}*/
			//	static if (Contains!(d, cyclic_dimensions))
			//		return;
				//else return space[].limit!d;
				return space[].limit!d;
			}
		auto length ()() const
			if (Dims.length == 1)
			{/*...}*/
				static if (Contains!(0, cyclic_dimensions))
					return;
				return space.length;
			}

		//////////

		struct Infinity {}

		struct Limit (size_t dim)
			{/*...}*/
				static if (is (Dims[IndexOf!(dim, cyclic_dimensions)] == T, T))
					{/*...}*/
						static if (T.Unpack[1])
							enum left = Infinity ();
						else CoordinateType!R[dim] left;

						static if (T.Unpack[2])
							enum right = Infinity ();
						else CoordinateType!R[dim] right;

						auto opUnary (string op : `~`)()
							{/*...}*/
								return left;
							}

						this (typeof(left) left, typeof(right) right)
							{/*...}*/
								void assign_left ()() {this.left = left;}
								void assign_right ()() {this.right = right;}
								void no_op ()(){}

								Match!(assign_left, no_op);
								Match!(assign_right, no_op);
							}
					}
				else {/*...}*/
					autodata.operators.limit.Limit!(CoordinateType!R[dim])
						limit;
					alias limit this;
				}
			}

		auto opDollar (size_t dim)() const
			{/*...}*/
				return Limit!dim (bounds[dim].expand);
			}

		//////////

		template is_valid_slice (size_t dim)
			{/*...}*/
				enum is_valid_slice (T) = is (T == CoordinateType!R[dim]) || is (T == Limit!dim);
			}

		auto opSlice (size_t dim, T,U)(T left, U right)
			//if (All!(is_valid_slice!dim, T, U))
			in {/*...}*/
				static if (is (T == Infinity!dim))
					assert (left.is_negative);

				static if (is (U == Infinity!dim))
					assert (right.is_positive);
			}
			body {/*...}*/
				static if (is (T == U) && is (T == CoordinateType!R[dim]))
					return interval (left, right);
				else return tuple (left, right);
			}

		auto opIndex (T...)(T indices)
			{/*...}*/
				static if (T.length == 0)
					return this;
				//else
			}
	}
auto cycle (S)(S space)
	{/*...}*/
		return Cycle!(S, Pack!(0,true,true))(space);
	}

void main ()
	{/*...}*/
		import autodata.spaces.array;
		auto x = Cycle!(Array!(int,2), Pack!(0,false,true))();
		auto y = Cycle!(int[], Pack!(0,false,true))();

	//	pragma(msg, typeof(x.limit!0), typeof(x.limit!1));
	//	pragma(msg, dimensionality!(typeof(x)), CoordinateType!(typeof(x)));
	//	pragma(msg, dimensionality!(typeof(y)), CoordinateType!(typeof(y)));

	//	y[~$..$];

	//	assert ([1,2,3].cycle[5..10] == [2,3,1,2,3]);

		writeln (is(typeof(float(real.infinity))));
	}//
