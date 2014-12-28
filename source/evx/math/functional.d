module evx.math.functional;
 // TODO redocument
private {/*imports}*/
	import std.conv;
	import std.traits;
	import std.typecons;
	import std.typetuple;

	import evx.type;
	import evx.range;

	import evx.math.logic;
	import evx.math.algebra;
	import evx.math.intervals;
	import evx.math.ordinal;
	import evx.math.space;
	import evx.operators.slice;
	import evx.operators.range;

	import evx.misc.tuple;
	import evx.misc.patch;
}

public {/*map}*/
	/* apply a given function to the elements in a range 
	*/

	struct Mapped (Domain, alias f, Parameters...)
		{/*...}*/
			Domain domain;
			Parameters parameters;

			auto opIndex (Args...)(Args args)
				{/*...}*/
					auto slice_all ()() if (Args.length == 0) {return domain;}
					auto get_point ()() {return domain[args];}
					auto get_space ()() {return domain.opIndex (args);}
					auto get_range ()() if (Args.length == 1) {return domain[args[0].left..args[0].right];}

					auto subdomain = Match!(slice_all, get_point, get_space, get_range);

					auto map_point ()() {return apply (subdomain);}
					auto map_tuple ()() {return apply (subdomain.expand);}
					auto map_space ()() {return remap (subdomain);}

					static if (not (is (typeof( Match!(map_point, map_tuple, map_space)))))
						map_point;
					return Match!(map_point, map_tuple, map_space);
				}
			auto opSlice (size_t d, Args...)(Args args)
				{/*...}*/
					auto multi ()() {return TEMPdomain.opSlice!d (args);}
					auto single ()() if (d == 0) {return TEMPdomain.opSlice (args);}
					CommonType!Args[2] index ()() {return [args];}

					return Match!(multi, single, index);
				}
			auto opDollar (size_t d)()
				{/*...}*/
					auto multi ()() {return domain.opDollar!d;}
					auto single ()() if (d == 0) {return domain.opDollar;}
					auto length ()() if (d == 0) {return domain.length;}

					return Match!(multi, single, length);
				}
			auto opEquals (S)(S that)
				{/*...}*/
					return this.equal (that);
				}

			@property:

			auto front ()()
				{/*...}*/
					auto single_front ()() {return apply (domain.front);}
					auto tuple_front  ()() {return apply (domain.front.expand);}

					return Match!(single_front, tuple_front);
				}
			auto back ()()
				{/*...}*/
					auto single_back ()() {return apply (domain.back);}
					auto tuple_back  ()() {return apply (domain.back.expand);}

					return Match!(single_back, tuple_back);
				}
			auto popFront ()()
				{/*...}*/
					domain.popFront;
				}
			auto popBack ()()
				{/*...}*/
					domain.popBack;
				}
			auto empty ()()
				{/*...}*/
					return domain.empty;
				}
			auto save ()()
				{/*...}*/
					return this;
				}
			auto length ()() const
				{/*...}*/
					return domain.length;
				}
			auto limit (size_t d)() const
				{/*...}*/
					return domain.limit!d;
				}
			auto limit ()() const
				{/*...}*/
					 return domain.limit;
				}

			private {/*...}*/
				auto apply (Point...)(Point point)
					if (is (Point == Cons!(Element!Domain)) || is (Tuple!Point == Element!Domain)) // REVIEW
					{/*...}*/
						return f (point, parameters);
					}
				auto remap (Subdomain...)(Subdomain subdomain)
					{/*...}*/
						return Mapped!(Subdomain, f, Parameters)(subdomain, parameters);
					}
				void context ()
					{/*...}*/
						template Dimensions (size_t i = 0)
							{/*...}*/
								static if (is (typeof(Domain.limit!i)))
									alias Dimensions = Cons!(i, Dimensions!(i+1));
								else alias Dimensions = Cons!();
							}

						alias Coord (int i) = ElementType!(typeof(Domain.limit!i.identity));

						static if (is (typeof(domain.limit!0)))
							auto subdomain = domain[Map!(Coord, Dimensions!()).init];
						else static if (is (typeof(domain.front)))
							auto subdomain = domain.front;
						else static assert (0, `map error: `
							~ Domain.stringof ~ ` is not a range (no front) or a space (no limit!i)`
						);

						static if (is (typeof (f (subdomain))))
							cast(void) f (subdomain);
						else static if (is (typeof (f (subdomain.expand))))
							cast(void) f (subdomain.expand);

						assert (0, `this function exists only to force the compiler`
							` to capture the context of local functions`
							` or functions using local symbols,`
							` and is not meant to be invoked`
						);
					}
			}
		}

	template map (alias f)
		{/*...}*/
			auto map (Domain, Parameters...)(Domain domain, Parameters parameters)
				{/*...}*/
					return Mapped!(Domain, f, Parameters)(domain, parameters);
				}
		}
		unittest {/*...}*/
			int[8] x = [1,2,3,4,5,6,7,8];

			{/*ranges}*/
				auto y = x[].map!(i => 2*i);

				assert (y.length == 8);

				assert (x[0] == 1);
				assert (y[0] == 2);

				assert (x[$-1] == 8);
				assert (y[$-1] == 16);

				assert (x[0..4] == [1, 2, 3, 4]);
				assert (y[0..4] == [2, 4, 6, 8]);

				assert (x[] == [1, 2, 3, 4, 5, 6, 7, 8]);
				assert (y[] == [2, 4, 6, 8, 10, 12, 14, 16]);

				assert (x.length == 8);
				assert (y.length == 8);

				foreach (i; y)
					assert (i);
			}
			{/*spaces}*/
				static struct Basic
					{/*...}*/
						int[] data = [1,2,3,4];

						auto access (size_t i) {return data[i];}
						auto length () const {return data.length;}

						mixin SliceOps!(access, length, RangeOps);
					}
				auto z = Basic()[].map!(i => 2*i);

				assert (z[].limit == [0,4]);
				assert (z[] == [2,4,6,8]);

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
				auto m = MultiDimensional()[];
				auto w = MultiDimensional()[].map!(i => 2*i);

				assert (m[].limit!0 == [0,3]);
				assert (m[].limit!1 == [0,3]);
				assert (w[].limit!0 == [0,3]);
				assert (w[].limit!1 == [0,3]);

				assert (m[0,0] == 1);
				assert (w[0,0] == 2);
				assert (m[2,2] == 9);
				assert (w[2,2] == 18);

				assert (w[0..$, 0] == [2, 8, 14]);
				assert (w[0, 0..$] == [2, 4, 6]);

				assert (m[0..$, 1].map!(x => x*x) == [4, 25, 64]);
				assert (w[0..$, 1].map!(x => x*x) == [16, 100, 256]);

				static struct FloatingPoint
					{/*...}*/
						auto access (double x)
							{/*...}*/
								return x;
							}

						enum double length = 1;

						mixin SliceOps!(access, length);
					}
				auto sq = FloatingPoint()[].map!(x => x*x);
				assert (sq[0.5] == 0.25);
			}
			{/*local}*/
				static static_variable = 7;
				assert (x[].map!(i => i + static_variable)[0..4] == [8,9,10,11]);

				static static_function (int x) {return x + 2;}
				assert (x[].map!static_function[0..4] == [3,4,5,6]);

				static static_template (T)(T x) {return 3*x;}
				assert (x[].map!static_template[0..4] == [3,6,9,12]);

				auto local_variable = 9;
				assert (x[].map!(i => i + local_variable)[0..4] == [10,11,12,13]);

				auto local_function (int x) {return x + 1;}
				assert (x[].map!local_function[0..4] == [2,3,4,5]);

				auto local_function_local_variable (int x) {return x * local_variable;}
				assert (x[].map!local_function_local_variable[0..4] == [9,18,27,36]);

				auto local_template (T)(T x) {return 3*x;}
				// assert (x[].map!local_template[0..4] == [3,6,9,12]); BUG cannot capture context pointer for local template
			}
			{/*ctfe}*/
				static ctfe_func (int x) {return x + 2;}

				enum a = [1,2,3].map!(i => i + 100);
				enum b = [1,2,3].map!ctfe_func;

				static assert (a == [101, 102, 103]);
				static assert (b == [3, 4, 5]);
				static assert (typeof(a).sizeof == (int[]).sizeof + (void*).sizeof); // template lambda makes room for the context pointer but doesn't save it... weird.
				static assert (typeof(b).sizeof == (int[]).sizeof); // static function omits context pointer
			}
			{/*params}*/
				static r () @nogc {return only (1,2,3).map!((a,b,c) => a + b + c)(3, 2);}

				assert (r == [6,7,8]);
			}
			{/*alias}*/
				alias fmap = map!(x => x*x);

				assert (fmap ([1,2]) == [1,4]);

				auto f2 (int x) {return x - 1;}
				alias gmap = map!f2;

				assert (gmap ([1,2]) == [0,1]);
			}
			{/*compose}*/
				auto a = x[].map!(x => x*x);
				auto b = a.map!(x => x*x);

				foreach (i; a)
					assert (i);

				foreach (i; b)
					assert (i);

				assert (b == [1, 16, 81, 256, 625, 1296, 2401, 4096]);
			}
		}
}
public {/*reduce}*/
	/* accumulate a value over a range using a binary function 
	*/
	template reduce (functions...)
		if (functions.length > 0)
		{/*...}*/
			template Accumulator (R)
				{/*...}*/
					static if (functions.length == 1)
						alias Accumulator = Unqual!(typeof(functions[0] (R.init.front, R.init.front)));
					else {/*alias Accumulator}*/
						string generate_accumulator ()
							{/*...}*/
								string code;

								foreach (i, f; functions)
									code ~= q{Unqual!(typeof(functions[} ~i.text~ q{] (R.init.front, R.init.front))), };

								return q{Tuple!(} ~code[0..$-2]~ q{)};
							}

						mixin(q{
							alias Accumulator = } ~generate_accumulator~ q{;
						});
					}
				}

			auto reduce (R)(R range)
				if (is_input_range!R)
				in {/*...}*/
					assert (not (range.empty), `cannot reduce empty ` ~R.stringof~ ` without seed`);
				}
				body {/*...}*/
					Accumulator!R seed;

					static if (functions.length == 1)
						seed = range.front;
					else foreach (i, f; functions)
						seed[i] = range.front;

					range.popFront;

					return reduce (range, seed);
				}

			auto reduce (R, T = Accumulator!R)(R range, T seed)
				if (is_input_range!R)
				{/*...}*/
					// FUTURE static if (isRandomAccess) try to block and parallelize... or foreach (x; parallel(r))?
					auto accumulator = seed;

					for (; not (range.empty); range.popFront)
						static if (functions.length == 1)
							accumulator = functions[0] (accumulator, range.front);
						else foreach (i, f; functions)
							accumulator[i] = functions[i] (accumulator[i], range.front);

					return accumulator;
				}
		}
		unittest {/*...}*/
			alias τ = std.typecons.tuple;

			auto a = [1, 2, 3];

			assert (a.reduce!((a,b) => a + b) == 6);
			assert (a.reduce!(
				(a,b) => a * b,
				(a,b) => a - b,
				(a,b) => a / b,
			) == τ(6, -4, 0));
		}
}
public {/*filter}*/
	/* traverse the subrange consisting only of elements which match a given criteria 
	*/

	struct Filtered (R, alias match = identity)
		{/*...}*/
			R range;
			enum is_n_ary_function = is(typeof(match (range.front.expand)));

			auto ref front ()
				{/*...}*/
					return range.front;
				}
			void popFront ()
				{/*...}*/
					range.popFront;
					seek_front;
				}
			bool empty ()
				{/*...}*/
					return range.empty;
				}

			static assert (is_input_range!Filtered);

			static if (is_forward_range!R)
				{/*...}*/
					@property save ()
						{/*...}*/
							return this;
						}

					static assert (is_forward_range!Filtered);
				}

			static if (is_bidirectional_range!R)
				{/*...}*/
					auto ref back ()
						{/*...}*/
							return range.back;
						}
					void popBack ()
						{/*...}*/
							range.popBack;
							seek_back;
						}

					static assert (is_bidirectional_range!Filtered);
				}

			this (R range)
				{/*...}*/
					this.range = range;

					seek_front;

					static if (is_bidirectional_range!R)
						seek_back;
				}

			private {/*seek}*/
				void seek_front ()
					{/*...}*/
						static if (is_n_ary_function)
							while (not (empty || match (front.expand)))
								range.popFront;
						else while (not (empty || match (front)))
							range.popFront;
					}

				static if (is_bidirectional_range!R)
					void seek_back ()
						{/*...}*/
							static if (is_n_ary_function)
								while (not (empty || match (back.expand)))
									range.popBack;
							else while (not (empty || match (back)))
								range.popBack;
						}
			}
		}

	template filter (alias match)
		{/*...}*/
			auto filter (R)(R range)
				if (is_input_range!R)
				{/*...}*/
					return Filtered!(R, match)(range);
				}
		}
		unittest {/*...}*/
			import std.algorithm: equal;

			auto a = [1, 2, 3, 4];

			auto b = a.filter!(x => x % 2);

			auto c = b.filter!(x => x > 1);

			assert (b.equal ([1, 3]));
			assert (c.equal ([3]));
		}
}
public {/*zip}*/
	/* join several ranges together transverse-wise, 
		into a range of tuples of the elements of the original ranges 
	*/

	struct Zipped (Spaces...)
		{/*...}*/
			Spaces spaces;
			this (Spaces spaces) {this.spaces = spaces;}

			auto opIndex (Args...)(Args args)
				{/*...}*/
					auto point (size_t i)() {return spaces[i].map!identity[args];}

					auto tuple ()() 
						{return τ(Map!(point, Count!Spaces));}

					auto zipped ()() if (Any!(λ!q{(T) = is (T == U[2], U)}, Args)) 
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

			static if (not (Contains!(void, Map!(ElementType, Spaces)))) // TEMP HACK foreach tuple expansion causes compiler segfault on template range ops, opApply is workaround
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

					return τ(Map!(get, Count!Spaces));
				}
			auto back ()()
				{/*...}*/
					auto get (size_t i)() {return spaces[i].back;}

					return τ(Map!(get, Count!Spaces));
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
					return spaces[0].length; // REVIEW get the space that has a length, might not be the first one
				}
			auto limit (size_t i)() const
				{/*...}*/
					return spaces[0].limit!i; // REVIEW get the space that has a limit, might not be the first one
				}
			auto limit ()() const
				{/*...}*/
					 return spaces[0].limit; // REVIEW get the space that has a limit, might not be the first one
				}

			invariant ()
				{/*...}*/
					import std.algorithm: find, replace;

					mixin LambdaCapture;

					alias Dimensionalities = Map!(dimensionality, Spaces);

					static assert (All!(λ!q{(int d) = d == Dimensionalities[0]}, Dimensionalities),
						`zip error: dimension mismatch! ` 
						~ Interleave!(Spaces, Dimensionalities)
							.stringof[`tuple(`.length..$-1]
							.replace (`),`, `):`)
					);

					foreach (d; Iota!(Dimensionalities[0]))
						foreach (i; Count!Spaces)
							{/*bounds check}*/
								enum no_measure_error (int i) = `zip error: `
									~ Spaces[i].stringof
									~ ` does not define length or limit (const)`;

								static if (is (typeof(spaces[0].limit!d)))
									auto base = spaces[0].limit!d;

								else static if (d == 0 && is (typeof(spaces[0].length)))
									size_t[2] base = [0, spaces[0].length];

								else static assert (0, no_measure_error!i);


								static if (is (typeof(spaces[i].limit!d)))
									auto lim = spaces[i].limit!d;

								else static if (d == 0 && is (typeof(spaces[i].length)))
									size_t[2] lim = [0, spaces[i].length];

								else static assert (0, no_measure_error!i);


								assert (base == lim, `zip error: `
									`mismatched limits! ` ~ lim.text ~ ` != ` ~ base.text
									~ ` in ` ~ Spaces[i].stringof
								);
							}
				}
		}

	auto zip (Spaces...)(Spaces spaces)
		{/*...}*/
			return Zipped!Spaces (spaces);
		}
		unittest {/*...}*/
			import evx.misc.test;

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
			{/*TODO various indices}*/
				
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
}
public {/*by}*/
	struct Product (Spaces...)
		{/*...}*/
			struct Base
				{/*...}*/
					alias Offsets = Scan!(Sum, Map!(dimensionality, Spaces));

					Spaces spaces;

					auto limit (size_t d)() const
						{/*...}*/
							mixin LambdaCapture;

							alias LimitOffsets = Offsets[0..$ - Filter!(λ!q{(int i) = d < i}, Offsets).length + 1];
								
							enum i = LimitOffsets.length - 1;
							enum d = LimitOffsets[0] - 1;

							size_t[2] get_length ()() if (d == 0) {return [0, spaces[i].length];}
							auto get_limit ()() {return spaces[i].limit!d;}

							return Match!(get_limit, get_length);
						}

					auto access (Map!(Coords, Spaces) point)
						in {/*...}*/
							static assert (typeof(point).length >= Spaces.length,
								`could not deduce coordinate type for ` ~ Spaces.stringof
							);
						}
						body {/*...}*/
							template projection (size_t i)
								{/*...}*/
									auto π_i ()() {return spaces[i][point[0..Offsets[i]]];}
									auto π_n ()() {return spaces[i][point[Offsets[i-1]..Offsets[i]]];}

									alias projection = Match!(π_i, π_n);
								}

							Map!(Λ!q{(alias π) = typeof(π.identity)}, 
								Map!(projection, Count!Spaces)
							) mapped;

							foreach (i; Count!Spaces)
								mapped[i] = projection!i;

							union Cast
								{/*...}*/
									typeof(mapped.tuple) input;

									Tuple!(RepresentationTypeTuple!(typeof(input)))
										flattened;
								}

							return Cast (mapped.tuple).flattened;
						}
				}

			mixin Patch!(Base, 13860);
		}

	auto by (S,R)(S left, R right)
		{/*...}*/
			static if (is (S == Product!T, T...))
				return Product!(T,R)(left.spaces, right);

			else return Product!(S,R)(left, right);
		}
		unittest {/*...}*/
			import evx.math; 

			int[3] x = [1,2,3];
			int[3] y = [4,5,6];

			auto z = x[].by (y[]);

			assert (z.access (0,1) == tuple (1,5));
			assert (z.access (1,1) == tuple (2,5));
			assert (z.access (2,1) == tuple (3,5));

			auto w = z[].map!((a,b) => a * b);

			assert (w[0,0] == 4);
			assert (w[1,1] == 10);
			assert (w[2,2] == 18);

			auto p = w[].by (z[]);

			assert (p[0,0,0,0] == tuple (4,1,4));
			assert (p[1,1,0,1] == tuple (10,1,5));
			assert (p[2,2,2,1] == tuple (18,3,5));
		}
}
public {/*select}*/
	/* perform a self-referencing operation on a range 
		if possible, n-ary ops applied to a range of tuples 
			will disperse the range into tuple element ranges, 
			and pass these to the op
	*/
	auto select (alias op, R)(R range)
		{/*...}*/
			auto tuple ()() {return op (range.disperse.expand);}
			auto apply ()() {return op (range);}

			return Match!(tuple, apply);
		}
		unittest {/*...}*/
			import std.algorithm: equal;

			auto a = [1, 2, 3];
			auto b = [`a`,`b`,`c`];

			assert (a.select!(x => x.length + x[0]) == 4);
			assert (zip (a,b).select!((x,y) => x.reduce!max.to!string ~ y[0..2].join.to!string) == `3ab`);
		}
}
public {/*transform}*/
	/* modify a range in-place if possible, 
		otherwise apply a self-referencing operation 
	*/
	auto ref transform (alias op, R)(auto ref R range)
		{/*...}*/
			auto ref self_transform ()() {range[] = select!op (range); return range;}
			auto ref select_op ()() {return select!op (range);}

			return Match!(self_transform, select_op);
		}
}
public {/*extract}*/
	/* from a range of elements, extract a range of element members 
	*/
	auto extract (string field, R)(R range)
		{/*...}*/
			mixin(q{
				return range.map!(x => x.} ~field~ q{);
			});
		}
}
public {/*disperse}*/
	/* split a range of tuples, transverse-wise, 
		into a tuple of ranges 
	*/
	auto disperse (Spaces...)(Zipped!Spaces zipped)
		{/*...}*/
			return zipped.spaces.tuple;
		}
		unittest {/*...}*/
			import std.algorithm: equal;

			auto a = [1,2,3];
			auto b = [4,5,6];

			assert (zip (a,b).disperse[0].equal (a));
			assert (zip (a,b).disperse[1].equal (b));
		}
}
