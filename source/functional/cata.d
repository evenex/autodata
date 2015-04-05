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
		auto reduce (R)(R range)
			if (is_input_range!R)
			in {/*...}*/
				assert (not (range.empty), `cannot reduce empty ` ~R.stringof~ ` without seed`);
			}
			body {/*...}*/
				Repeat!(functions.length, ElementType!R) seed;

				foreach (i, f; functions)
					seed[i] = range.front;

				range.popFront;

				return reduce (range, seed);
			}

		auto reduce (R, T...)(R range, T seed)
			if (is_input_range!R && T.length > 0)
			{/*...}*/
				auto accumulator = seed.tuple;

				for (; not (range.empty); range.popFront)
					foreach (i, f; functions)
						accumulator[i] = functions[i] (accumulator[i], range.front);

				static if (accumulator.length == 1)
					return accumulator[0];
				else return accumulator;
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
