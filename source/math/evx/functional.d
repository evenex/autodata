module evx.functional;

private {/*imports}*/
	private {/*std}*/
		import std.range;
		import std.conv;
		import std.typetuple;
		import std.typecons;
		import std.traits;
	}
	private {/*evx}*/
		import evx.meta;
		import evx.logic;
		import evx.algebra;
		import evx.analysis;
		import evx.traits;
		import evx.utils;
		import evx.range;
	}
}

/* aliasable template lambda function 
*/
template λ (alias F) {alias λ = F;}

public {/*map}*/
	/* replacement for std.algorithm.MapResult 
	*/
	struct Mapped (R, alias func)
		{/*...}*/
			alias Index = IndexTypes!R[0];
			enum is_n_ary_function = __traits(compiles, func (range.front.expand));
			
			static if (is_indexable!(R, Index))
				{/*...}*/
					auto ref opIndex (Index i)
						in {/*...}*/
							static if (is_continuous!Index)
								assert (i < range.measure, `index out of bounds`);
							else static if (hasLength!R)
								assert (i < range.length, `index out of bounds`);
							else static assert (0);
						}
						body {/*...}*/
							static if (is_n_ary_function)
								return func (range[i].expand);
							else return func (range[i]);
						}
				}

			auto opSlice ()
				{/*...}*/
					return this;
				}

			static if (is_sliceable!(R, Index))
				{/*...}*/
					auto opSlice (Index i, Index j)
						in {/*...}*/
							static if (is_continuous!Index)
								assert (j.between (i, measure));
							else static if (hasLength!R)
								assert (j.between (i, length));
						}
						body {/*...}*/
							return Mapped (range[i..j]);
						}
				}

			@property:
			static if (isInputRange!R)
				{/*...}*/
					auto ref front ()
						{/*...}*/
							static if (is_n_ary_function)
								return func (range.front.expand);
							else return func (range.front);
						}
					void popFront ()
						{/*...}*/
							range.popFront;
						}
					bool empty ()
						{/*...}*/
							return range.empty;
						}

					static assert (isInputRange!Mapped);
				}
			static if (isForwardRange!R)
				{/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!Mapped);
				}
			static if (isBidirectionalRange!R)
				{/*...}*/
					auto ref back ()
						{/*...}*/
							static if (is_n_ary_function)
								return func (range.back.expand);
							else return func (range.back);
						}
					void popBack ()
						{/*...}*/
							range.popBack;
						}

					static assert (isBidirectionalRange!Mapped);
				}
			static if (hasLength!R)
				{/*...}*/
					@property length () const
						{/*...}*/
							return this.range.length; // REVIEW need 'this' in 2.066.. only for const methods?
						}

					static if (is(ReturnType!(R.length) == DollarType!R))
						alias opDollar = length;

					static assert (hasLength!Mapped);
				}
			static if (is_continuous_range!R)
				{/*...}*/
					@property measure () const
						{/*...}*/
							return range.measure;
						}

					static if (is(ReturnType!(R.measure) == DollarType!R))
						alias opDollar = measure;

					static assert (is_continuous_range!Mapped);
				}

			private:
			R range;
		}

	/* replacement for std.algorithm.map 
	*/
	template map (alias func)
		{/*...}*/
			auto map (R)(R range)
				{/*...}*/
					return Mapped!(R, func)(range);
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
	/* replacement for std.range.Zip 
	*/
	struct Zipped (Ranges...)
		{/*...}*/
			static if (not(is(CommonIndex == void)))
				{/*...}*/
					auto ref opIndex (CommonIndex i)
						in {/*...}*/
							static if (is_continuous!CommonIndex)
								assert (i < measure);
							else static if (hasLength!Zipped)
								assert (i < length);
						}
						body {/*...}*/
							return zip_with!`[args[0]]`(i);
						}

					static assert (is_indexable!(Zipped, CommonIndex));

					auto opSlice ()
						{/*...}*/
							return this;
						}
					auto opSlice ()(CommonIndex i, CommonIndex j)
						if (allSatisfy!(is_sliceable, Ranges))
						{/*...}*/
							Zipped copy = this;

							foreach (r, ref range; copy.ranges)
								range = this.ranges[r][i..j];
							
							return copy;
						}
				}

			static if (allSatisfy!(isInputRange, Ranges))
				@property {/*...}*/
					auto ref front ()
						{/*...}*/
							return zip_with!`.front`;
						}
					void popFront ()
						{/*...}*/
							foreach (ref range; ranges)
								range.popFront;
						}
					bool empty ()
						{/*...}*/
							foreach (range; ranges)
								if (range.empty)
									return true;

							return false;
						}

					static assert (isInputRange!Zipped);
				}
			static if (allSatisfy!(isForwardRange, Ranges))
				@property {/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!Zipped);
				}
			static if (allSatisfy!(isBidirectionalRange, Ranges))
				@property {/*...}*/
					auto ref back ()
						{/*...}*/
							return zip_with!`.back`;
						}
					void popBack ()
						{/*...}*/
							foreach (ref range; ranges)
								range.popBack;
						}

					static assert (isBidirectionalRange!Zipped);
				}
			static if (allSatisfy!(isOutputRange, Ranges))
				@property {/*...}*/
					void put ()(auto ref ZipTuple element)
						{/*...}*/
							foreach (i, ref range; ranges)
								range.put (element[i]);
						}

					static assert (.isOutputRange!(Zipped, ZipTuple));
				}
			static if (allSatisfy!(hasLength, Ranges))
				@property {/*...}*/
					auto length () const
						out (result) {/*...}*/
							foreach (range; ranges)
								assert (result == range.length);
						}
						body {/*...}*/
							return ranges[0].length;
						}

					static if (is(ReturnType!(Ranges[0].length) == CommonDollar))
						alias opDollar = length;

					static assert (hasLength!Zipped);
				}
			static if (allSatisfy!(is_continuous_range, Ranges))
				@property {/*...}*/
					auto measure () const
						out (result) {/*...}*/
							foreach (range; ranges)
								assert (result == range.measure);
						}
						body {/*...}*/
							return ranges[0].measure;
						}

					static if (is(ReturnType!(Ranges[0].measure) == CommonDollar))
						alias opDollar = measure;

					static assert (is_continuous_range!Zipped);
				}

			alias CommonIndex = CommonType!(staticMap!(IndexTypes, Ranges));
			alias CommonDollar = CommonType!(staticMap!(DollarType, Ranges));

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
						static if (allSatisfy!(hasLength, Ranges))
							{/*...}*/
								auto length = ranges[0].length;

								foreach (range; ranges)
									assert (range.length == length, 
										typeof(range).stringof~ ` length (` ~range.length.text~ `) does not match`
										` length ` ~length.text~ ` (established by ` ~typeof(ranges[0]).stringof~ `)`
									);
							}
					}
					body {/*...}*/
						this.ranges = ranges;
					}
			}
			private {/*data}*/
				Ranges ranges;
			}
		}

	/* replacement for std.range.zip 
	*/
	auto zip (Ranges...)(Ranges ranges)
		{/*...}*/
			return Zipped!Ranges (ranges);
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
public {/*filter}*/
	struct Filtered (R, alias match)
		{/*...}*/
			R range;

			auto ref front ()
				{/*...}*/
					return range.front;
				}
			void popFront ()
				{/*...}*/
					range.popFront;

					while (not (empty || match (front)))
						range.popFront;
				}
			bool empty ()
				{/*...}*/
					return range.empty;
				}

			static assert (isInputRange!Filtered);

			static if (isForwardRange!R)
				{/*...}*/
					@property save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!Filtered);
				}

			static if (isBidirectionalRange!R)
				{/*...}*/
					auto ref back ()
						{/*...}*/
							return range.back;
						}
					void popBack ()
						{/*...}*/
							while (not (empty || match (back)))
								range.popBack;
						}

					static assert (isBidirectionalRange!Filtered);
				}

			this (R range)
				{/*...}*/
					this.range = range;
					
					if (not (empty || match (range.front)))
						popFront;

					static if (isBidirectionalRange!R)
						if (not (empty || match (range.back)))
							popBack;
				}
		}

	/* replacement for std.algorithm.filter 
	*/
	template filter (alias match)
		{/*...}*/
			auto filter (R)(R range)
				if (isInputRange!R)
				{/*...}*/
					return Filtered!(R, match)(range);
				}
		}
		unittest {/*...}*/
			import std.range: equal;

			auto a = [1, 2, 3, 4];

			auto b = a.filter!(x => x % 2);

			auto c = b.filter!(x => x > 1);

			assert (b.equal ([1, 3]));
			assert (c.equal ([3]));
		}
}
public {/*reduce}*/
	/* replacement for std.algorithm.reduce 
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
			public {/*[i]}*/
				auto opIndex (size_t i)
					in {/*...}*/
						assert (i < length);
						assert (i != infinity);
					}
					body {/*...}*/
						return T(func (initial, i + start));
					}

				static assert (is_indexable!Sequence);
			}
			public {/*[i..j]}*/
				auto opSlice ()
					{/*...}*/
						return this;
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (i != infinity);

						if (j != infinity)
							assert (j.between (i, length));
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
						return this[0];
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
						return this[$-1];
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
			invariant (){/*}*/
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

			for (auto i = 0; i < 10; ++i)
				assert (ℕ[0..10][i] == i);
		}
}
