module evx.functional;

private {/*import std}*/
	import std.range:
		front, popFront, empty, back, popBack, put,
		isInputRange, isForwardRange, isBidirectionalRange, isOutputRange,
		hasLength,
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
		Unqual;
}
private {/*import evx}*/
	import evx.logic:
		not;

	import evx.algebra:
		unity;

	import evx.range:
		slice_within_bounds;

	import evx.traits:
		is_indexable, is_sliceable,
		is_binary_function;

	import evx.utils; // BUG doesnt like selective Indices import..
}

pure nothrow:
// REVIEW inout/const/etc AND UNITTEST

public {/*map}*/
	/* nothrow replacement for std.algorithm.MapResult 
	*/
	struct MapResult (alias func, R)
		{/*...}*/
			pure nothrow:
			static if (is_indexable!R)
				{/*...}*/
					auto ref opIndex (size_t i) inout
						in {/*...}*/
							static if (hasLength!R)
								assert (i < range.length);
						}
						body {/*...}*/
							return func (range[i]);
						}

					static assert (is_indexable!MapResult);
				}
			static if (is_sliceable!R)
				{/*...}*/
					auto opSlice ()
						{/*...}*/
							return save;
						}
					auto opSlice (size_t i, size_t j)
						in {/*...}*/
							static if (hasLength!R)
								assert (slice_within_bounds (i, j, length));
						}
						body {/*...}*/
							return MapResult (range[i..j]);
						}

					static assert (is_sliceable!MapResult);
				}

			@property:
			static if (isInputRange!R)
				{/*...}*/
					auto ref front () inout
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
					bool empty () inout
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
					auto ref back () inout
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
			static if (hasLength!R)
				{/*...}*/
					@property length () const
						{/*...}*/
							return range.length;
						}

					static assert (hasLength!MapResult);
				}

			private:
			R range;
		}

	/* nothrow replacement for std.algorithm.map 
	*/
	template map (alias func)
		{/*...}*/
			auto map (R)(lazy scope R range)
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
	struct ZipResult (Ranges...)
		{/*...}*/
			pure nothrow:
			static if (allSatisfy!(is_indexable, Ranges))
				{/*...}*/
					auto ref opIndex (size_t i) inout
						in {/*...}*/
							static if (hasLength!ZipResult)
								assert (i < length);
						}
						body {/*...}*/
							return zip_with!`[args[0]]`(i);
						}

					static assert (is_indexable!ZipResult);
				}
			static if (allSatisfy!(is_sliceable, Ranges))
				{/*...}*/
					auto opSlice ()
						{/*...}*/
							return save;
						}
					auto opSlice (size_t i, size_t j)
						in {/*...}*/
							static if (hasLength!ZipResult)
								assert (slice_within_bounds (slice.start + i, slice.start + j, slice.length));
						}
						body {/*...}*/
							return ZipResult (ranges, Indices (slice.start + i, slice.start + j));
						}

					static assert (is_sliceable!ZipResult);
				}

			static if (allSatisfy!(isInputRange, Ranges))
				@property {/*...}*/
					auto ref front () inout
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
					auto save () inout
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!ZipResult);
				}
			static if (allSatisfy!(isBidirectionalRange, Ranges))
				@property {/*...}*/
					auto ref back () inout
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
			static if (allSatisfy!(hasLength, Ranges))
				@property {/*...}*/
					auto length () const
						{/*...}*/
							return ranges[0].length;
						}

					static assert (hasLength!ZipResult);
				}

			private:
			private {/*ctor}*/
				this (Ranges ranges)
					in {/*...}*/
						auto length = ranges[0].length;

						foreach (range; ranges)
							assert (range.length == length);
					}
					body {/*...}*/
						this.ranges = ranges;
					}

				this (Ranges ranges, Indices slice) // XXX
					body {/*...}*/
						this (ranges);
						this.slice = slice;
					}
			}
			private {/*data}*/
				Ranges ranges;
				Indices slice;
			}
			private {/*defs}*/
				alias ZipTuple = Tuple!(staticMap!(Unqual, staticMap!(ElementType, Ranges))); 

				auto zip_with (string op, Args...)(Args args) inout
					{/*...}*/
						auto zip_copy = this;

						static code ()
							{/*...}*/
								string code;
// TODO instead of slicing all the ranges, we should just keep 1 or 2 iterators, and save all the range interaction for opIndex
								foreach (r; 0..Ranges.length)
									code ~= q{zip_copy.ranges[} ~r.text~ q{] } ~op~ q{, };

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

							template can_zero (T...)
								if (T.length == 1)
								{enum can_zero = __traits(compiles, zero!Accumulator);}

							static if (can_zero!Accumulator)
								accumulator = zero!Accumulator;
							else static if (functions.length == 1)
								{/*init value}*/
									accumulator = range.front;
									range.popFront;
								}
							else {/*init tuple}*/
								foreach (i, f; functions)
									accumulator[i] = range.front;
								range.popFront;
							}

							return accumulator;
						}

					// FUTURE static if (isRandomAccess) try to block and parallelize... or foreach (x; parallel(r))?
					auto accumulator = initialize;

					for (; not (range.empty); range.popFront)
						{/*accumulate}*/
							static if (functions.length == 1)
								accumulator = functions[0] (accumulator, range.front);
							else foreach (i, f; functions)
								accumulator[i] = functions[i] (accumulator[i], range.front);
						}

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
	/* an infinite sequence defined by a generating function of the form f(T, size_t) 
	*/
	struct Sequence (alias func, T)
		if (is_binary_function!(func!(int, int)))
		{/*...}*/
			pure nothrow:
			inout {/*[i]}*/
				auto opIndex (size_t i)
					{/*...}*/
						return func (initial, i);
					}

				static assert (is_indexable!Sequence);
			}
			inout {/*[i..j]}*/
				auto opSlice () inout
					{/*...}*/
						return save;
					}
				auto opSlice (size_t i, size_t j) inout
					{/*...}*/
						return FiniteSequence!(func, T)(initial, i, j);
					}
				static assert (is_sliceable!Sequence);
			}
			@property {/*InputRange}*/
				auto popFront ()
					{/*...}*/
						initial = initial + unity!T;
					}
				auto front () inout
					{/*...}*/
						return func (initial, 0);
					}
				enum empty = false;
				// TODO sequence needs to be revamped so we can take $ = inf so ℕ[x..$] will give us ℕ starting at x

				static assert (isInputRange!Sequence);
			}
			inout @property {/*ForwardRange}*/
				auto save ()
					{/*...}*/
						return this;
					}

				static assert (isForwardRange!Sequence);
			}

			private:
			private {/*ctor}*/
				this (T initial)
					{/*...}*/
						this.initial = initial;
					}
			}
			private {/*data}*/
				T initial;
			}
		}

	/* a finite subsequence of some Sequence 
	*/
	struct FiniteSequence (alias func, T)
		if (is_binary_function!(func!(int, int)))
		{/*...}*/
			pure nothrow:
			inout {/*[i]}*/
				auto opIndex (size_t i)
					in {/*...}*/
						assert (i + start < start + length);
					}
					body {/*...}*/
						return func (initial, i + start);
					}

				static assert (is_indexable!FiniteSequence);
			}
			inout {/*[i..j]}*/
				auto opSlice ()
					{/*...}*/
						return save;
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (slice_within_bounds (start + i, start + j, start + length));
					}
					body {/*...}*/
						return FiniteSequence (initial, start + i, start + j);
					}

				static assert (is_sliceable!FiniteSequence);
			}
			@property {/*InputRange}*/
				auto popFront ()
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						++start;
					}
				auto front () inout
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						return func (initial, start);
					}
				auto empty () inout
					{/*...}*/
						return this.length == 0;
					}
				static assert (isInputRange!FiniteSequence);

			}
			inout @property {/*ForwardRange}*/
				auto save ()
					{/*...}*/
						return this;
					}

				static assert (isForwardRange!FiniteSequence);
			}
			@property {/*BidirectionalRange}*/
				auto popBack ()
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						--end;
					}
				auto back () inout
					in {/*...}*/
						assert (not (empty));
					}
					body {/*...}*/
						return func (initial, end - 1);
					}

				static assert (isBidirectionalRange!FiniteSequence);
			}
			const @property {/*length}*/
				auto length () const
					{/*...}*/
						return end - start;
					}

				static assert (hasLength!FiniteSequence);
			}

			private:
			private {/*ctor}*/
				this (T initial, size_t start, size_t end)
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
			}
		}
	
	/* build an infinite sequence from an index-based generating function and an initial value 
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
		}
}
