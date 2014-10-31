module evx.math.sequence;

import std.conv;
import std.range;

import evx.traits;
import evx.range.traits;
import evx.math.logic;
import evx.math.algebra;
import evx.math.ordinal;

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
					return func (initial, i + start).to!T;
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
			auto empty ()
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
//		import std.range: equal;

		assert (ℕ[0..10].equal ([0,1,2,3,4,5,6,7,8,9]));
		assert (ℕ[4..9].equal ([4,5,6,7,8]));
		assert (ℕ[4..9][1..4].equal ([5,6,7]));
		assert (ℕ[4..9][1..4][1] == 6);

		for (auto i = 0; i < 10; ++i)
			assert (ℕ[0..10][i] == i);
	}

/* the set¹ of natural numbers 
	1. actually a subset of cardinality 2⁶⁴
*/
static ℕ () {return zero!size_t.sequence!((n,i) => n + i);}
