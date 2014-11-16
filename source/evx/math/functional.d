module evx.math.functional;

private {/*imports}*/
	import std.range;
	import std.conv;
	import std.traits;

	import evx.type;

	import evx.math.logic;
	import evx.math.continuity;
	import evx.math.intervals;
}

/* aliasable template lambda function 
*/
template λ (alias F) {alias λ = F;}

public {/*map}*/
	/* replacement for std.algorithm.MapResult 
	*/
	struct Mapped (R, alias func)
		{/*...}*/
			alias Index = IndexType!R;
			enum is_n_ary_function = is(typeof(func (range.front.expand)));

			static if (is(IndexType!R))
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

			auto opSlice ()()
				{/*...}*/
					return this;
				}

			auto opSlice ()(Index i, Index j)
				if (is(typeof(range[Index.init..Index.init])))
				in {/*...}*/
					static if (is_continuous!Index)
						assert (i < j && j <= measure);
					else static if (hasLength!R)
						assert (i < j && j <= length, `attempted to slice [` ~i.text~ `, ` ~j.text~ `] with length ` ~length.text);
				}
				body {/*...}*/
					return Mapped (range[i..j]);
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
							return range.length;
						}

					static if (is(DollarType!R == size_t))
						alias opDollar = length;

					static assert (hasLength!Mapped);
				}
			static if (is_continuous_range!R)
				{/*...}*/
					@property measure () const
						{/*...}*/
							return range.measure;
						}

					static if (not(is(DollarType!R == size_t)))
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

					static assert (is(IndexType!Zipped == CommonIndex));

					auto opSlice ()()
						{/*...}*/
							return this;
						}
					auto opSlice ()(CommonIndex i, CommonIndex j)
						if (All!(can_slice, Ranges))
						{/*...}*/
							Zipped copy = this;

							foreach (r, ref range; copy.ranges)
								range = this.ranges[r][i..j];
							
							return copy;
						}
				}

			static if (All!(isInputRange, Ranges))
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
			static if (All!(isForwardRange, Ranges))
				@property {/*...}*/
					auto save ()
						{/*...}*/
							return this;
						}

					static assert (isForwardRange!Zipped);
				}
			static if (All!(isBidirectionalRange, Ranges))
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
			static if (All!(isOutputRange, Ranges))
				@property {/*...}*/
					void put ()(auto ref ZipTuple element)
						{/*...}*/
							foreach (i, ref range; ranges)
								range.put (element[i]);
						}

					static assert (.isOutputRange!(Zipped, ZipTuple));
				}
			static if (All!(hasLength, Ranges))
				@property {/*...}*/
					auto length () const
						out (result) {/*...}*/
							foreach (range; ranges)
								assert (result == range.length);
						}
						body {/*...}*/
							return ranges[0].length;
						}

					static if (is(CommonDollar == size_t))
						alias opDollar = length;

					static assert (hasLength!Zipped);
				}
			static if (All!(is_continuous_range, Ranges))
				@property {/*...}*/
					auto measure () const
						out (result) {/*...}*/
							foreach (range; ranges)
								assert (result == range.measure);
						}
						body {/*...}*/
							return ranges[0].measure;
						}

					static if (not(is(CommonDollar == size_t)))
						alias opDollar = measure;

					static assert (is_continuous_range!Zipped);
				}

			alias CommonIndex = CommonType!(staticMap!(IndexType, Ranges));
			alias CommonDollar = CommonType!(staticMap!(DollarType, Ranges));

			private:
			private {/*defs}*/
				alias ZipTuple = Tuple!(staticMap!(Unqual, staticMap!(ElementType, Ranges)));

				static if (is(CommonIndex == void))
					alias Indices = Interval!size_t;
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

				template can_slice (R)
					{/*...}*/
						enum can_slice = is(R.init[CommonIndex.init..CommonIndex.init]);
					}
			}
			private {/*ctor}*/
			this (Ranges ranges)
					in {/*...}*/
						static if (is_continuous!CommonIndex)
							{/*...}*/
								auto measure = ranges[0].measure;

								foreach (range; ranges)
									assert (range.measure == measure, `range measure mismatch: `
										~typeof(range).stringof~ ` ` ~range.measure.text~ 
										` vs `
										~typeof(ranges[0]).stringof~ ` ` ~measure.text
									);
							}
						static if (All!(hasLength, Ranges))
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
			alias τ = std.typecons.tuple;

			auto a = [1,2,3];
			auto b = [`a`, `b`, `c`];

			auto c = zip (a,b);

			assert (c.equal ([τ(1, `a`), τ(2, `b`), τ(3, `c`)]));
		}
}
public {/*filter}*/
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
							range.popBack;
							seek_back;
						}

					static assert (isBidirectionalRange!Filtered);
				}

			this (R range)
				{/*...}*/
					this.range = range;

					seek_front;

					static if (isBidirectionalRange!R)
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

				static if (isBidirectionalRange!R)
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
				if (isInputRange!R)
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
				if (isInputRange!R)
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
public {/*transform}*/
	/* modify a range in-place 
	*/
	auto transform (alias op, R)(R range)
		{/*...}*/
			range[] = op (range);
		}
}
public {/*select}*/
	/* perform a self-referencing operation on a range 
	*/
	auto select (alias op, R)(R range)
		{/*...}*/
			return op (range);
		}
}
public {/*extract}*/
	auto extract (string field, R)(R range)
		{/*...}*/
			mixin(q{
				return range.map!(x => x.} ~field~ q{);
			});
		}
}
