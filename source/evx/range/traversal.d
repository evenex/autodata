module evx.range.traversal; // REFACTOR construction and traversal or adaptors or something

private {/*imports}*/
	import std.range;
	import std.algorithm;
	import std.conv;
	import std.array;

	import evx.range.classification;
	import evx.range.primitives;

	import evx.math.sequence;
	import evx.math.logic;
	import evx.math.overloads;
	import evx.math.fields.nats;
}

/* cache a range in a D array
*/
alias cache = std.array.array;

/* construct a range from a repeated value 
*/
alias repeat = std.range.repeat;

/* construct a range from a set of values 
*/
alias only = std.range.only;

/* chain a tuple of ranges into a single range 
*/
alias chain = std.range.chain;

/* iterate a range in reverse 
*/
alias retro = std.range.retro;

/* split a range length-wise into subranges in which adjacent elements satisfy some relation 
*/
struct Group (R, alias relation)
	{/*...}*/
		R range;

		struct Sub
			{/*...}*/
				R range;
				ElementType!R prev;
				bool terminated;

				this (R range)
					{/*...}*/
						this.range = range;

						if (not (range.empty))
							prev = range.front;
					}

				auto front ()
					{/*...}*/
						return range.front;
					}
				auto popFront ()
					{/*...}*/
						prev = front;

						range.popFront;

						if (this.empty || not (relation (prev, front)))
							this.terminated = true;
					}
				bool empty ()
					{/*...}*/
						return this.terminated || range.empty;
					}							
			}

		this (R range)
			{/*...}*/
				this.range = range;
			}

		auto ref front ()
			{/*...}*/
				return Sub (range);
			}
		void popFront ()
			{/*...}*/
				range = range[front.count..$];
			}
		bool empty ()
			{/*...}*/
				return range.empty;
			}
	}
auto group (alias relation = (a,b) => a == b, R)(R range)
	{/*...}*/
		return Group!(R, relation)(range);
	}
	unittest {/*...}*/
		import std.algorithm: equal;
		import evx.math.overloads;

		foreach (pair; zip (
			[0,1,3,4,5,7,8].group!((a,b) => (a-b).abs < 2),
			[[0,1], [3,4,5], [7,8]]
		))
			assert (pair[0].equal (pair[1]));
	}

/* join a range of ranges into a single range 
*/
struct Join (R)
	{/*...}*/
		public:
		@property {/*range}*/
			const length ()
				{/*...}*/
					import std.traits;
					auto s = cast(Unqual!R)ranges; // HACK to shed constness so that sum can operate
					return s.map!(r => r.length).sum + separator.length * max(0, ranges.length - 1);
				}

			auto ref front ()
				{/*...}*/
					while (ranges[j].empty)
						if (empty)
							assert (0);
						else popFront;

					if (at_separator)
						return separator[i];
					else return ranges[j][i];
				}
			void popFront ()
				{/*...}*/
					if (at_separator)
						{/*...}*/
							if (++i >= separator.length)
								{/*...}*/
									i = 0;

									at_separator = false;
								}
						}
					else if (++i >= ranges[j].length)
						{/*...}*/
							do ++j; while (j < ranges.length && ranges[j].empty);

							i = 0;

							if (not (separator.empty || this.empty))
								at_separator = true;
						}
				}
			auto empty ()
				{/*...}*/
					return j >= ranges.length;
				}

			auto save ()
				{/*...}*/
					return this;
				}
			alias opIndex = save;
		}
		private:
		private {/*data}*/
			R ranges;
			ElementType!R separator;
			size_t i, j;
			bool at_separator;
		}
	}
auto join (R, S = ElementType!R)(R ranges, S separator = S.init)
	{/*...}*/
		return Join!R (ranges, separator.to!(ElementType!R));
	}
	unittest {/*join}*/
		int[2] x = [1,2];
		int[2] y = [3,4];
		int[2] z = [5,6];

		int[][] A = [x[], y[], z[]];

		assert (A.join.equal ([1,2,3,4,5,6]));
		assert (A.join ([0]).equal ([1, 2, 0, 3, 4, 0, 5, 6]));

		int[] u = [1,2,3];
		int[] v = [];
		int[] w = [4,5];

		assert ([u,v,w].join.equal ([1,2,3,4,5]));
	}

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
			return typeof(range.cycle[0..0]).init;

		auto i = positions.sgn * (positions + n) % n;
		
		return range.cycle[i..n+i];
	}

/* pair each element with its successor in the range, and the last element with the first 
*/
auto adjacent_pairs (R)(R range)
	{/*...}*/
		return evx.math.functional.zip (range, range.rotate_elements);
	}

/* generate a foreach index for a custom range 
	this exploits the automatic tuple foreach index unpacking trick which is obscure and under controversy
	reference: https://issues.dlang.org/show_bug.cgi?id=7361
*/
auto enumerate (R)(R range)
	if (is_input_range!R && has_length!R)
	{/*...}*/
		return evx.math.functional.zip (ℕ[0..range.length], range);
	}

/* iterate over a range, skipping a fixed number of elements each iteration 
*/
struct Stride (R)
	{/*...}*/
		R range;

		private size_t width;

		this (R range, size_t width)
			{/*...}*/
				this.range = range;
				this.width = width;
			}

		const @property length ()
			{/*...}*/
				return range.length / width;
			}

		static if (is_input_range!R)
			{/*...}*/
				auto ref front ()
					{/*...}*/
						return range.front;
					}
				void popFront ()
					{/*...}*/
						foreach (_; 0..width)
							range.popFront;
					}
				bool empty () const
					{/*...}*/
						return range.length < width;
					}

				static assert (is_input_range!Stride);
			}
		static if (is_forward_range!R)
			{/*...}*/
				@property save ()
					{/*...}*/
						return this;
					}

				static assert (is_forward_range!Stride);
			}
		static if (is_bidirectional_range!R)
			{/*...}*/
				auto ref back ()
					{/*...}*/
						return range.back;
					}
				void popBack ()
					{/*...}*/
						foreach (_; 0..width)
							range.popBack;
					}

				static assert (is_bidirectional_range!Stride);
			}


		invariant() {/*}*/
			assert (width != 0, `width must be nonzero`);
		}
	}
auto stride (R,T)(R range, T stride)
	{/*...}*/
		return Stride!R (range, stride.to!size_t);
	}
