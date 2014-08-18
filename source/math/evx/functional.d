module evx.functional;

private {/*import std}*/
	import std.range:
		front, popFront, empty, back, popBack, put,
		isInputRange, isForwardRange, isBidirectionalRange, isOutputRange,
		ElementType;
		
	import std.conv:
		text;

	import std.typetuple:
		staticMap,
		allSatisfy;

	import std.typecons:
		Tuple;

	import std.traits:
		isNumeric, isFloatingPoint, isIntegral, isUnsigned,
		Unqual, CommonType;
}
private {/*import evx}*/
	import evx.meta:
		IndexTypes;

	import evx.logic:
		not;

	import evx.algebra:
		unity;

	import evx.analysis:
		is_continuous;

	import evx.range:
		slice_within_bounds;

	import evx.traits:
		is_indexable, is_sliceable, has_length,
		is_binary_function;

	import evx.utils; // BUG doesnt like selective Indices import..
}

//pure 
nothrow:
// REVIEW pure and nothrow
// REFACTOR made a mess of map and zip
public {/*map}*/
	/* nothrow replacement for std.algorithm.MapResult 
	*/
	struct MapResult (alias func, R)
		{/*...}*/
			alias Index = IndexTypes!R[0];
			
			nothrow:
			static if (is_indexable!(R, Index))
				{/*...}*/
					auto ref opIndex (Index i)
						in {/*...}*/
							static if (is_continuous!Index)
								assert (i < range.measure);
							else static if (has_length!R)
								assert (i < range.length);
							else static assert (0);
						}
						body {/*...}*/
							return func (range[i]);
						}
				}

			auto opSlice ()
				{/*...}*/
					return save;
				}

			static if (is_sliceable!(R, Index))
				{/*...}*/
					auto opSlice (Index i, Index j)
						in {/*...}*/
							static if (is_continuous!Index)
								assert (slice_within_bounds (i, j, measure));
							else static if (has_length!R)
								assert (slice_within_bounds (i, j, length));
						}
						body {/*...}*/
							return MapResult (range[i..j]);
						}
				}

			@property:
			static if (isInputRange!R)
				{/*...}*/
					auto ref front ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							return func (range.front);
						}
					void popFront ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							range.popFront;
						}
					bool empty () const
						{/*...}*/
							return range.empty;
						}

					static assert (isInputRange!MapResult);
				}
			static if (isForwardRange!R)
				{/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!MapResult);
				}
			static if (isBidirectionalRange!R)
				{/*...}*/
					auto ref back ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							return func (range.back);
						}
					void popBack ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							range.popBack;
						}

					static assert (isBidirectionalRange!MapResult);
				}
			static if (has_length!R)
				{/*...}*/
					@property length () const
						{/*...}*/
							return range.length;
						}

					alias opDollar = length;

					static assert (has_length!MapResult);
				}
			static if (is_continuous!Index)
				{/*...}*/
					@property measure () const
						{/*...}*/
							return range.measure;
						}

					alias opDollar = measure;

					//static assert (is_continuous!MapResult); // TODO, new trait: for something indexable, is the index continuous?
				}

			private:
			R range;
		}

	/* nothrow replacement for std.algorithm.map 
	*/
	template map (alias func)
		{/*...}*/
			auto map (R)(R range)
				{/*...}*/
					return MapResult!(func, R)(range);
				}
		}
		unittest {/*...}*/
			import std.range: equal;

			auto a = [1, 2, 3];

			auto b = a.map!(x => x + 1);

			auto c = b.map!(x => x * 2);

			assert (b.equal ([2, 3, 4]));
			assert (c.equal ([4, 6, 8]));
		}
}
public {/*zip}*/
	/* nothrow replacement for std.range.Zip 
	*/
	struct ZipResult (Ranges...) // TODO we are gonna have to keep a lot more indices
		{/*...}*/
			nothrow:

			static if (not(is(CommonIndex == void)))
				{/*...}*/
					auto ref opIndex (CommonIndex i)
						in {/*...}*/
							static if (is_continuous!CommonIndex)
								assert (i < measure);
							else static if (has_length!ZipResult)
								assert (i < length);
						}
						body {/*...}*/
							return zip_with!`[args[0]]`(i);
						}

					static assert (is_indexable!(ZipResult, CommonIndex));

					auto opSlice ()
						{/*...}*/
							return save;
						}
					auto opSlice /*()*/(CommonIndex i, CommonIndex j)
						//if (allSatisfy!(is_sliceable, Ranges)) REVIEW
						in {/*...}*/
							static if (is_continuous!CommonIndex)
								assert (slice_within_bounds (i, j, slice.measure));
							else static if (has_length!ZipResult)
								assert (slice_within_bounds (i, j, slice.length));
							else static assert (0);
						}
						body {/*...}*/
							return ZipResult (ranges, Indices (slice.start + i, slice.start + j));
						}
				}

			static if (allSatisfy!(isInputRange, Ranges))
				@property {/*...}*/
					auto ref front ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							return zip_with!`.front`;
						}
					void popFront ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							foreach (ref range; ranges)
								range.popFront;
						}
					bool empty () const
						{/*...}*/
							return ranges[0].empty;
						}

					static assert (isInputRange!ZipResult);
				}
			static if (allSatisfy!(isForwardRange, Ranges))
				@property {/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!ZipResult);
				}
			static if (allSatisfy!(isBidirectionalRange, Ranges))
				@property {/*...}*/
					auto ref back ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							return zip_with!`.back`;
						}
					void popBack ()
						in {/*...}*/
							assert (not (empty));
						}
						body {/*...}*/
							foreach (ref range; ranges)
								range.popBack;
						}

					static assert (isBidirectionalRange!ZipResult);
				}
			static if (allSatisfy!(isOutputRange, Ranges))
				@property {/*...}*/
					void put ()(auto ref ZipTuple element)
						{/*...}*/
							foreach (i, ref range; ranges)
								range.put (element[i]);
						}

					static assert (.isOutputRange!(ZipResult, ZipTuple));
				}
			static if (allSatisfy!(has_length, Ranges))
				@property {/*...}*/
					auto length () const
						{/*...}*/
							return ranges[0].length;
						}

					static assert (has_length!ZipResult);
				}
			static if (is_continuous!CommonIndex)
			//static if (allSatisfy!(is_continuous, Ranges)) // TODO 
				@property {/*...}*/
					auto measure () const
						{/*...}*/
							return ranges[0].measure;
						}

					//static assert (has_measure!ZipResult); TODO
				}

			alias CommonIndex = CommonType!(staticMap!(IndexTypes, Ranges));

			private:
			private {/*defs}*/
				alias ZipTuple = Tuple!(staticMap!(Unqual, staticMap!(ElementType, Ranges))); 

				static if (is(CommonIndex == void))
					alias Indices = .Indices;
				else alias Indices = Interval!CommonIndex;

				auto zip_with (string op, Args...)(Args args)
					{/*...}*/
						static code ()
							{/*...}*/
								string code;

								foreach (r; 0..Ranges.length)
									code ~= q{ranges[} ~r.text~ q{]} ~op~ q{, };

								return code;
							}

						mixin(q{
							return ZipTuple (} ~code[0..$-2]~ q{);
						});
					}

				template isOutputRange (R)
					{/*...}*/
						alias isOutputRange = .isOutputRange!(R, ElementType!R);
					}

				template is_sliceable (R)
					{/*...}*/
						alias is_sliceable = .is_sliceable!(R, CommonIndex);
					}
			}
			private {/*ctor}*/
				this (Ranges ranges)
					in {/*...}*/
						static if (is_continuous!CommonIndex)
							{/*...}*/
								auto measure = ranges[0].measure;

								foreach (range; ranges)
									assert (range.measure == measure);
							}
						static if (allSatisfy!(has_length, Ranges))
							{/*...}*/
								auto length = ranges[0].length;

								foreach (range; ranges)
									assert (range.length == length);
							}
					}
					body {/*...}*/
						this.ranges = ranges;
					}

				this (Ranges ranges, Indices slice)
					body {/*...}*/
						this (ranges);
						this.slice = slice;
					}
			}
			private {/*data}*/
				Ranges ranges;
				Indices slice;
			}
		}

	/* nothrow replacement for std.range.zip 
	*/
	auto zip (Ranges...)(Ranges ranges)
		{/*...}*/
			return ZipResult!Ranges (ranges);
		}
		unittest {
			import std.range: equal;
			import evx.utils: τ;

			auto a = [1,2,3];
			auto b = [`a`, `b`, `c`];

			auto c = zip (a,b);

			assert (c.equal ([τ(1, `a`), τ(2, `b`), τ(3, `c`)]));
		}
}
public {/*reduce}*/
	/* nothrow replacement for std.algorithm.reduce 
	*/
	template reduce (functions...)
		if (functions.length > 0)
		{/*...}*/
			auto reduce (R)(R range)
				if (isInputRange!R)
				{/*...}*/
					static if (functions.length == 1)
						alias Accumulator = typeof(functions[0] (range.front, range.front));
					else {/*alias Accumulator}*/
						string generate_accumulator ()
							{/*...}*/
								string code;

								foreach (i, f; functions)
									code ~= q{typeof(functions[} ~i.text~ q{] (range.front, range.front)), };

								return q{Tuple!(} ~code[0..$-2]~ q{)};
							}

						mixin(q{
							alias Accumulator = } ~generate_accumulator~ q{;
						});
					}

					auto initialize ()
						{/*...}*/
							Accumulator accumulator;

							static if (functions.length == 1)
								accumulator = range.front;
							else foreach (i, f; functions)
								accumulator[i] = range.front;

							range.popFront;

							return accumulator;
						}

					// FUTURE static if (isRandomAccess) try to block and parallelize... or foreach (x; parallel(r))?
					auto accumulator = initialize;

					for (; not (range.empty); range.popFront)
						static if (functions.length == 1)
							accumulator = functions[0] (accumulator, range.front);
						else foreach (i, f; functions)
							accumulator[i] = functions[i] (accumulator[i], range.front);

					return accumulator;
				}
		}
		unittest {/*...}*/
			import evx.utils: τ;

			auto a = [1, 2, 3];

			assert (a.reduce!((a,b) => a + b) == 6);
			assert (a.reduce!(
				(a,b) => a * b,
				(a,b) => a - b,
				(a,b) => a / b,
			) == τ(6, -4, 0));
		}
}
public {/*sequence}*/
	/* a sequence defined by a generating function of the form f(T, size_t) 
	*/
	struct Sequence (alias func, T)
		if (is_binary_function!(func!(T, size_t)))
		{/*...}*/
			nothrow:
			public {/*[i]}*/
				auto opIndex (size_t i)
					in {/*...}*/
						assert (i < length);
						assert (i != infinity);
					}
					body {/*...}*/
						return func (initial, i + start);
					}

				static assert (is_indexable!Sequence);
			}
			public {/*[i..j]}*/
				auto opSlice ()
					{/*...}*/
						return save;
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (i != infinity);

						if (j != infinity)
							assert (slice_within_bounds (i, j, length));
					}
					body {/*...}*/
						if (j == infinity)
							return Sequence (initial, start + i, infinity);
						else return Sequence (initial, start + i, start + j);
					}
			}
			@property {/*InputRange}*/
				auto popFront ()
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						++start;
					}
				auto front ()
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						return func (initial, start);
					}
				const empty ()
					{/*...}*/
						return this.length == 0;
					}

				static assert (isInputRange!Sequence);
			}
			@property {/*ForwardRange}*/
				auto save ()
					{/*...}*/
						return this;
					}

				static assert (isForwardRange!Sequence);
			}
			@property {/*BidirectionalRange}*/
				auto popBack ()
					in {/*...}*/
						assert (not (empty));
						assert (not (is_infinite));
					}
					body {/*...}*/
						--end;
					}
				auto back ()
					in {/*...}*/
						assert (not (empty));
						assert (not (is_infinite));
					}
					body {/*...}*/
						return func (initial, end - 1);
					}

				static assert (isBidirectionalRange!Sequence);
			}
			const @property {/*length}*/
				auto length ()
					{/*...}*/
						if (this.is_finite)
							return end - start;
						else return infinity;
					}
				alias opDollar = length;

				bool is_infinite ()
					{/*...}*/
						return this.end == this.infinity;
					}
				bool is_finite ()
					{/*...}*/
						return not (this.is_infinite);
					}
			}

			private:
			private {/*ctor}*/
				this (T initial, size_t start = 0, size_t end = infinity)
					{/*...}*/
						this.initial = initial;
						this.start = start;
						this.end = end;
					}
			}

			private {/*data}*/
				T initial;

				size_t start;
				size_t end;

				enum infinity = size_t.max;
			}
			invariant (){/*...}*/
				assert (start < infinity);
			}
		}
	
	/* build a sequence from an index-based generating function and an initial value 
	*/
	auto sequence (alias func, T)(T initial)
		{/*...}*/
			return Sequence!(func, T)(initial);
		}
		unittest {/*...}*/
			import evx.ordinal: ℕ;
			import std.range: equal;

			assert (ℕ[0..10].equal ([0,1,2,3,4,5,6,7,8,9]));
			assert (ℕ[4..9].equal ([4,5,6,7,8]));
			assert (ℕ[4..9][1..4].equal ([5,6,7]));
			assert (ℕ[4..9][1..4][1] == 6);

	//		foreach (i, n; ℕ[0..10]) // TODO
	//			assert (n == i);
		}
}
