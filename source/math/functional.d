module evx.functional; // TODO this is more like evx.range... but map and reduce are sorta functional

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
		isNumeric, isFloatingPoint, isIntegral, isUnsigned;
}
private {/*import evx}*/
	import evx.utils:
		not,
		slice_within_bounds;

	import evx.meta:
		is_indexable, is_sliceable;
}

pure nothrow:

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
					auto opSlice ()()
						{/*...}*/
							return save;
						}
					auto opSlice ()(size_t i, size_t j)
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
					auto ref opIndex (size_t i)
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
								assert (slice_within_bounds (i, j, length));
						}
						body {/*...}*/
							auto zip_result = ZipResult ();

							foreach (r, range; ranges)
								zip_result.ranges[r] = range[i..j];
						}

					static assert (is_sliceable!ZipResult);
				}

			@property:
			static if (allSatisfy!(isInputRange, Ranges))
				{/*...}*/
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
					bool empty ()
						{/*...}*/
							return ranges[0].empty;
						}

					static assert (isInputRange!ZipResult);
				}
			static if (allSatisfy!(isForwardRange, Ranges))
				{/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!ZipResult);
				}
			static if (allSatisfy!(isBidirectionalRange, Ranges))
				{/*...}*/
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
				{/*...}*/
					void put ()(auto ref ZipTuple element)
						{/*...}*/
							foreach (i, ref range; ranges)
								range.put (element[i]);
						}

					static assert (.isOutputRange!(ZipResult, ZipTuple));
				}
			static if (allSatisfy!(hasLength, Ranges))
				{/*...}*/
					@property length () const
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
			}
			private {/*data}*/
				Ranges ranges;
			}
			private {/*defs}*/
				alias ZipTuple = Tuple!(staticMap!(ElementType, Ranges)); 

				auto zip_with (string op, Args...)(Args args)
					{/*...}*/
						auto zip_tuple = ZipTuple ();

						foreach (r, ref range; ranges) mixin(q{
							zip_tuple[r] = range} ~op~ q{;
						});

						return zip_tuple;
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

							template can_zero_init (T...)
								if (T.length == 1)
								{/*...}*/
									enum can_zero_init = __traits(compiles, zero_init (accumulator));
								}

							void zero_init (T)(ref T element)
								{element = 0;}

							void front_init (T)(ref T element)
								{element = range.front;}

							static if (functions.length == 1)
								{/*init value}*/
									static if (can_zero_init!Accumulator)
										zero_init (accumulator);
									else {/*front_init}*/
										front_init (accumulator);
										range.popFront;
									}
								}
							else {/*init tuple}*/
								static if (allSatisfy!(can_zero_init, Accumulator))
									foreach (i, f; functions)
										zero_init (accumulator[i]);
								else {/*front_init}*/
									foreach (i, f; functions)
										front_init (accumulator[i]);
									range.popFront;
								}
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
	/* TODO */
	struct Sequence (alias func, T)
		if (isNumeric!T)
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
						++initial;
					}
				auto front () inout
					{/*...}*/
						return func (initial, 0);
					}
				enum empty = false;

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

	/* TODO */
	struct FiniteSequence (alias func, T)
		if (isNumeric!T)
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
	
	/* TODO */
	auto sequence (alias func, T)(T initial)
		{/*...}*/
			return Sequence!(func, T)(initial);
		}
		unittest {/*...}*/
			import evx.ordering: ℕ;
			import std.range: equal;

			assert (ℕ[0..10].equal ([0,1,2,3,4,5,6,7,8,9]));
			assert (ℕ[4..9].equal ([4,5,6,7,8]));
			assert (ℕ[4..9][1..4].equal ([5,6,7]));
			assert (ℕ[4..9][1..4][1] == 6);
		}
}
