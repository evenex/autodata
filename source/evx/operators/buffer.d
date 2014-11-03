module evx.operators.buffer;

private {/*imports}*/
	import evx.operators.transfer;
	import evx.traits;
}

// TODO document
struct BufferTraits (Buffer)
	{/*...}*/
		static {/*alias}*/
			private Buffer buffer = Buffer.init;

			alias Element = TransferTraits!Buffer.Element;
		}

		mixin Traits!(
			`can_assign_length`, q{buffer.length = size_t.min;},

			`can_allocate`, q{buffer.allocate (size_t.max);},
			`can_free`,     q{buffer.free ();},

			`has_variable_length`, q{static assert (can_assign_length || can_allocate);},
			`is_nullable`, 		   q{static assert (can_assign_length || can_free);},
		);
	}

mixin template BufferOps (alias buffer)
	{/*...}*/
		static {/*analysis}*/
			alias BufferTraits = evx.operators.buffer.BufferTraits!(typeof(buffer));

			mixin template require (string trait)
				{/*...}*/
					alias require = BufferTraits.require!(typeof(this), trait, BufferOps);
				}

			mixin require!`has_variable_length`;
			mixin require!`is_nullable`;
		}
		public {/*dependencies}*/
			mixin TransferOps!buffer;
		}

		this (R)(R range)
			{/*...}*/
				this = range;
			}

		auto opAssign (R)(R range)
			{/*...}*/
				enum range_has_length = .TransferTraits!R.has_length;

				this = null;

				{/*reserve storage}*/
					static if (range_has_length)
						{/*reserve length}*/
							static if (BufferTraits.can_allocate)
								buffer.allocate (range.length);
							else static if (BufferTraits.can_assign_length)
								buffer.length = range.length;
							else static assert (0);
						}
					else static if (BufferTraits.can_assign_length)
						{/*grow and append}*/
							foreach (item; range)
								this.length = this.length + 1;
						}
					else static if (BufferTraits.can_allocate)
						{/*count length}*/
							buffer.allocate (range[].count);
						}
					else static assert (0);
				}

				this[] = range;
			}
		auto opAssign (typeof(null))
			{/*...}*/
				static if (BufferTraits.can_assign_length)
					buffer.length = 0;
				else static if (BufferTraits.can_free)
					buffer.free;
				else static assert (0);
			}

		static if (BufferTraits.can_assign_length)
			{/*length assignment}*/
				@property length ()
					{/*...}*/
						return buffer.length;
					}
				@property length (size_t new_length)
					{/*...}*/
						buffer.length = new_length;
					}
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
						import core.stdc.stdlib;

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
				t.length = 3;

				assert (t[] == [6,7,8]);

				t.length = 1;

				assert (t[] == [6]);

				t = null;

				assert (t[] == []);
			}

		test!Test;
	}
