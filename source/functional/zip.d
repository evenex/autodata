module spacecadet.functional.zip;

private {/*import}*/
	import std.typecons: Tuple, tuple;
	import std.range.primitives: front, back, popFront, popBack, empty;
	import std.conv: text;
	import std.algorithm: equal;
	import spacecadet.core;
	import spacecadet.meta;
	import spacecadet.functional.iso;
}

/* join several spaces together transverse-wise, 
	into a space of tuples of the elements of the original spaces 
*/
auto zip (Spaces...)(Spaces spaces)
	{/*...}*/
		return Zipped!Spaces (spaces);
	}
struct Zipped (Spaces...)
	{/*...}*/
		Spaces spaces;
		this (Spaces spaces) {this.spaces = spaces;}

		auto opIndex (Args...)(Args args)
			{/*...}*/
				auto point (size_t i)() 
					{return spaces[i].map!identity[args];}

				auto tuple ()() 
					{return .tuple (Map!(point, Count!Spaces));}

				auto zipped ()() if (
					Any!(λ!q{(T) = is (T == U[2], U)}, Args)
					|| Args.length == 0
				)
					{return Zipped!(typeof(tuple.identity).Types)(tuple.expand);}

				return Match!(zipped, tuple);
			}
		auto opSlice (size_t d, Args...)(Args args)
			{/*...}*/
				template attempt (uint i)
					{/*...}*/
						auto attempt ()()
							{/*...}*/
								auto multi ()() {return domain.opSlice!d (args);}
								auto single ()() if (d == 0) {return domain.opSlice (args);}

								return Match!(multi, single);
							}
					}
				CommonType!Args[2] array ()() {return [args];}

				return Match!(Map!(attempt, Count!Spaces), array);
			}
		auto opDollar (size_t d)()
			{/*...}*/
				template attempt (uint i)
					{/*...}*/
						auto attempt ()()
							{/*...}*/
								auto multi  ()() {return spaces[i].opDollar!d;}
								auto single ()() if (d == 0) {return spaces[i].opDollar;}
								auto length ()() if (d == 0) {return spaces[i].length;}

								return Match!(multi, single, length);
							}
					}

				return Match!(Map!(attempt, Count!Spaces));
			}
		auto opEquals (S)(S that)
			{/*...}*/
				return this.equal (that);
			}

		static if (
			not (Contains!(void, Map!(ElementType, Spaces)))
			&& is (typeof(length) : size_t)
		) // HACK foreach tuple expansion causes compiler segfault on template range ops, opApply is workaround
			int opApply (int delegate(Map!(ElementType, Spaces)) op)
				{/*...}*/
					int result = 0;

					for (auto i = 0; i < length; ++i)
						{/*...}*/
							int expand ()() {return result = op (this[i].expand);}
							int closed ()() {return result = op (this[i]);}

							if (Match!(expand, closed))
								break;
						}

					return result;
				}

		@property:

		auto front ()()
			{/*...}*/
				auto get (size_t i)() {return spaces[i].front;}

				return tuple (Map!(get, Count!Spaces));
			}
		auto back ()()
			{/*...}*/
				auto get (size_t i)() {return spaces[i].back;}

				return tuple (Map!(get, Count!Spaces));
			}
		auto popFront ()()
			{/*...}*/
				foreach (ref space; spaces)
					space.popFront;
			}
		auto popBack ()()
			{/*...}*/
				foreach (ref space; spaces)
					space.popBack;
			}
		auto empty ()()
			{/*...}*/
				return spaces[0].empty;
			}
		auto save ()()
			{/*...}*/
				return this;
			}
		auto length ()() const
			{/*...}*/
				template get_length (uint i)
					{/*...}*/
						auto get_length ()()
							{/*...}*/
								return spaces[i].length;
							}
					}

				return Match!(Map!(get_length, Count!Spaces));
			}
		auto limit (size_t i)() const
			{/*...}*/
				template get_limit (uint j)
					{/*...}*/
						auto get_limit ()()
							{/*...}*/
								return spaces[j].limit!i;
							}
					}

				return Match!(Map!(get_limit, Count!Spaces));
			}
		auto limit ()() const
			{/*...}*/
				template get_limit (uint j)
					{/*...}*/
						auto get_limit ()()
							{/*...}*/
								return spaces[j].limit;
							}
					}

				return Match!(Map!(get_limit, Count!Spaces));
			}

		invariant ()
			{/*...}*/
				import std.algorithm: find;
				import std.array: replace;

				mixin LambdaCapture;

				alias Dimensionalities = Map!(dimensionality, Spaces);

				static assert (All!(λ!q{(int d) = d == Dimensionalities[0]}, Dimensionalities),
					`zip error: dimension mismatch! ` 
					~Interleave!(Spaces, Dimensionalities)
						.stringof[`tuple(`.length..$-1]
						.replace (`),`, `):`)
				);

				foreach (d; Iota!(Dimensionalities[0]))
					foreach (i; Count!Spaces)
						{/*bounds check}*/
							enum no_measure_error (int i) = `zip error: `
								~Spaces[i].stringof
								~ ` does not define limit or integral length (const)`;

							static if (is (typeof(spaces[0].limit!d)))
								auto base = spaces[0].limit!d;

							else static if (d == 0 && is (typeof(spaces[0].length) : size_t))
								size_t[2] base = [0, spaces[0].length];

							else static assert (0, no_measure_error!i);


							static if (is (typeof(spaces[i].limit!d)))
								auto lim = spaces[i].limit!d;

							else static if (d == 0 && is (typeof(spaces[i].length) : size_t))
								size_t[2] lim = [0, spaces[i].length];

							else static assert (0, no_measure_error!i);


							assert (base == lim, `zip error: `
								`mismatched limits! ` ~lim.text~ ` != ` ~base.text
								~ ` in ` ~Spaces[i].stringof
							);
						}
			}
	}
	unittest {/*...}*/
		import spacecadet.meta.test;
		import spacecadet.operators;

		int[4] x = [1,2,3,4], y = [4,3,2,1];

		auto z = zip (x[], y[]);

		assert (z.length == 4);

		assert (z[0] == tuple (1,4));
		assert (z[$-1] == tuple (4,1));
		assert (z[0..$] == [
			tuple (1,4),
			tuple (2,3),
			tuple (3,2),
			tuple (4,1),
		]);

		{/*bounds check}*/
			error (zip (x[], [1,2,3]));
			error (zip (x[], [1,2,3,4,5]));
		}
		{/*multidimensional}*/
			static struct MultiDimensional
				{/*...}*/
					double[9] matrix = [
						1, 2, 3,
						4, 5, 6,
						7, 8, 9,
					];

					auto ref access (size_t i, size_t j)
						{/*...}*/
							return matrix[3*i + j];
						}

					enum size_t rows = 3, columns = 3;

					mixin SliceOps!(access, rows, columns, RangeOps);
				}

			auto a = MultiDimensional();
			auto b = MultiDimensional()[].map!(x => x*2);

			auto c = zip (a[], b[]);

			assert (c[1, 1] == tuple (5, 10));

			error (zip (a[1..$, ~$..$], b[~$..$, ~$..$]));
			error (zip (a[~$..$, 1..$], b[~$..$, ~$..$]));

			error (zip (a[0, ~$..$], x[]));

			no_error (zip (a[0, ~$..$], x[0..3], y[0..3], z[0..3]));
		}
		{/*non-integer indices}*/
			static struct FloatingPoint
				{/*...}*/
					auto access (double x)
						{/*...}*/
							return x;
						}

					enum double length = 1;

					mixin SliceOps!(access, length);
				}

			FloatingPoint a, b;

			auto q = zip (a[], b[]);

			assert (q[0.5] == tuple (0.5, 0.5));
			assert (q[$-0.5] == tuple (0.5, 0.5));
			assert (q[0..$/2].limit!0 == [0.0, 0.5]);

			error (q[0..1.01]);
			error (q[-0.1..$]);
		}
		{/*map tuple expansion}*/
			static tuple_sum (T)(T t){return t[0] + t[1];}
			static binary_sum (T)(T a, T b){return a + b;}

			assert (z.map!tuple_sum == [5,5,5,5]);
			assert (z.map!binary_sum == [5,5,5,5]);
			assert (z.map!(t => t[0] + t[1]) == [5,5,5,5]);
			assert (z.map!((a,b) => a + b) == [5,5,5,5]);
		}
		{/*foreach tuple expansion}*/
			foreach (a,b; z)
				assert (1);
		}
	}

/* split a zipped range into a tuple of spaces 
*/
auto unzip (Spaces...)(Zipped!Spaces zipped)
	{/*...}*/
		return zipped.spaces.tuple;
	}
	unittest {/*...}*/
		import std.algorithm: equal;

		auto a = [1,2,3];
		auto b = [4,5,6];

		assert (zip (a,b).unzip[0].equal (a));
		assert (zip (a,b).unzip[1].equal (b));
	}