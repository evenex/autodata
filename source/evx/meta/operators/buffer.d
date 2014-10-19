module evx.operators.buffer;

import evx.operators.transfer;
import evx.traits.concepts;

struct BufferTraits (Buffer)
	{/*...}*/
		static {/*alias}*/
			private Buffer buffer = Buffer.init;

			alias Element = TransferTraits!Buffer.Element;
		}

		mixin Traits!(
			`can_set_length`, q{buffer.length = size_t.min;},
			`can_resize`,  q{buffer.resize (size_t.max);},

			`has_dynamic_length`, q{static assert (can_set_length || can_resize);},
			`can_clear`,   q{buffer.clear ();},

			`can_reserve`,    q{buffer.reserve (size_t.max);}, // XXX unused
			`can_append`,     q{buffer.append (Element[].init.map!identity); buffer.append (Element.init);}, // XXX unused
		);
	}

mixin template BufferOps (alias buffer)
	{/*...}*/
		import evx.operators.transfer;

		static {/*analysis}*/
			alias BufferTraits = evx.operators.buffer.BufferTraits!(typeof(buffer));

			mixin template require (string trait) // TODO will this conflict
				{/*...}*/
					alias require = BufferTraits.require!(typeof(this), trait, BufferOps);
				}

			mixin require!`has_dynamic_length`;
		}
		public {/*dependencies}*/
			mixin TransferOps!buffer;
		}

		@property length ()
			{/*...}*/
				return buffer.length;
			}
		@property length (size_t new_length)
			{/*...}*/
				static if (BufferTraits.can_resize)
					buffer.resize (new_length);
				else static if (BufferTraits.can_set_length)
					buffer.length = new_length;
				else static assert (0);
			}

		this (R)(R range)
			{/*...}*/
				this = range;
			}

		auto opAssign (R)(R range)
			{/*...}*/
				enum range_has_length = .TransferTraits!R.has_length;

				this = null;

				static if (range_has_length)
					this.length = range.length;
				else foreach (item; range)
					this.length = this.length + 1;

				this[] = range;
			}
		auto opAssign (typeof(null))
			{/*...}*/
				static if (BufferTraits.can_clear)
					buffer.clear;
				else static if (BufferTraits.can_resize)
					buffer.resize (0);
				else static if (BufferTraits.can_set_length)
					buffer.length = 0;
				else static assert (0);
			}

		auto opOpAssign (string op : `~`, R)(R range)
			{/*...}*/
				auto start = this.length;

				this.length = this.length + range.length;

				this[start..$] = range;
			}
		auto opOpAssign (string op : `~`)(TransferTraits.Element element)
			{/*...}*/
				this.length = this.length + 1;

				this[$-1] = element;
			}
		auto opOpAssign (string op : `-`)(size_t count)
			in {/*...}*/
				assert (count < length);
			}
			body {/*...}*/
				this.length = this.length - count;
			}

		auto opUnary (string op : `--`)()
			{/*...}*/
				this -= 1;
			}
	}
	unittest {/*...}*/
		struct Test
			{/*...}*/
				int[] buffer;

				mixin BufferOps!buffer;
			}
		struct Test_ii
			{/*...}*/
				struct Buffer
					{/*...}*/
						import std.c.stdlib;

						int* ptr;
						size_t length;

						void resize (size_t length)
							{/*...}*/
								clear;

								ptr = cast(int*) malloc (length * int.sizeof);
							}

						auto ref access (size_t i)
							{/*...}*/
								return ptr[i];
							}

						auto pull (R)(R range, size_t i, size_t j)
							{/*...}*/
								
							}

						auto clear ()
							{/*...}*/
								if (ptr)
									free (ptr);
							}

						~this ()
							{/*...}*/
								clear;
							}
					}

				Buffer buffer;

				mixin BufferOps!buffer;
			}

		void test (T)()
			{/*...}*/
				T t;

				assert (t.length == 0);

				t = [1,2,3];

				assert (t[] == [1,2,3]);
				assert (t[$-1] == 3);

				t = [6,7,8,9];
				--t;

				assert (t[] == [6,7,8]);

				t -= 2;

				assert (t[] == [6]);

				t = null;

				assert (t[] == []);
			}

		test!Test;
	}
