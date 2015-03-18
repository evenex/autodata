module autodata.functional.cata;

private {/*import}*/
	import std.typecons: Tuple, tuple;
	import std.range.primitives: front, back, popFront, popBack, empty;
	import std.conv: text;
	import std.algorithm: equal;
	import autodata.core;
	import autodata.meta;
}

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
								code ~= q{Unqual!(typeof(functions[} ~ i.text ~ q{] (R.init.front, R.init.front))), };

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
		auto a = [1, 2, 3];

		assert (a.reduce!((a,b) => a + b) == 6);
		assert (a.reduce!(
			(a,b) => a * b,
			(a,b) => a - b,
			(a,b) => a / b,
		) == tuple(6, -4, 0));
	}

/* traverse the subrange consisting only of elements which match a given criteria 
*/
template filter (alias match)
	{/*...}*/
		auto filter (R)(R range)
			if (is_input_range!R)
			{/*...}*/
				return Filtered!(R, match)(range);
			}
	}
struct Filtered (R, alias match)
	{/*...}*/
		R range;
		enum is_n_ary_function = is (typeof(match (range.front.expand)));

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
	unittest {/*...}*/
		auto a = [1, 2, 3, 4];

		auto b = a.filter!(x => x % 2);

		auto c = b.filter!(x => x > 1);

		assert (b.equal ([1, 3]));
		assert (c.equal ([3]));
	}
