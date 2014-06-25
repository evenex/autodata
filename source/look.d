import std.stdio;
import std.traits;
import std.typetuple;
import std.range;
import std.conv;
import std.string;
import utils;

struct Look (Type, Index...)
	if (not (anySatisfy!(is_string_param, Index)))
	{/*...}*/
		private {/*typedefs}*/
			private {/*link}*/
				alias Active = Type delegate(IndexTypes);

				static if (is_indexed)
					mixin(q{
						alias Passive = Type}~ array_type_suffix ~ q{;
					});
				else alias Passive = Type*;
			}
			private {/*index}*/
				enum is_indexed = Index.length > 0;

				alias IndexTypes =
					Replace!(0, ubyte, 
					Replace!(1, ushort, 
					Replace!(2, uint, 
					Replace!(3, ulong, 
					Index))));

				private {/*contract}*/
					static assert (allSatisfy!(under_4, Numbers));
					alias Numbers = Filter!(is_numerical_param, Index);
					template under_4 (n) {const bool under_4 = n < 4;}
				}
			}
		}

		public: alias get this; // TODO might look into making this a mixin for guaranteed control over aliasing
		@property {/*get}*/
			Type get ()
				in {/*...}*/
					assert (this.exists, `attempt to access nonexistent look`);
				}
				body {/*...}*/
					final switch (source)
						{/*...}*/
							case Source.active:
								mixin(q{
									return active }~ args ~ q{;
								});

							case Source.passive:
								static if (is_indexed) mixin(q{
									return passive }~ indices ~ q{;
								});
								else return *passive;

							case Source.none: assert (0);
						}
				}
		}
		pure nothrow {/*set}*/
			void opCall (typeof(null)_)
				{/*...}*/
					source = Source.none;
					active = null;
				}

			mixin (setter!`active`);
			mixin (setter!`passive`);
		}
		const pure @property nothrow {/*check}*/
			bool exists ()
				{/*...}*/
					final switch (source) 
						{/*...}*/
							case Source.active: 
								return this.active !is null;

							case Source.passive:
								return this.passive !is null;

							case Source.none:
								return false;
						}
				}
		}

		private:
		private {/*data}*/
			union {/*link}*/
				Active active;
				Passive passive;
			}
			auto source = Source.none;
			enum Source: byte {none, passive, active}
			mixin (stored_indices);
		}
		private {/*code generation}*/
			static string array_type_suffix ()
				{/*...}*/
					foreach (T; Index)
						static if (is_numerical_param!T)
							static assert (T > -1 && T < 4);

					string code;

					foreach (T; Reverse!Index)
						{/*...}*/
							static if (is_numerical_param!T)
								code ~= `[]`;
							else code ~= `[` ~ T.stringof ~ `]`;
						}

					return code;
				}
			static string stored_indices ()
				{/*...}*/
					string[] names;

					foreach (i, _; Index)
						names ~= `index_` ~ i.text;

					return std.typecons.alignForSize!(IndexTypes)(names);
				}
			static string indices ()
				{/*...}*/
					string code;
					foreach (i,_; Index)
						code ~= q{[index_} ~ i.text ~ q{]};
					return code;
				}
			static string args ()
				{/*...}*/
					string code;
					foreach (i,_; Index)
						code ~= q{index_} ~ i.text ~ q{, };

					static if (is_indexed)
						return `(` ~ code[0..$-2] ~ `)`;
					else return `()`;
				}
			static string set_indices ()
				{/*...}*/
					string code;

					foreach (i,_; Index)
						code ~= q{index_} ~ i.text ~ q{ = _} ~ i.text~ q{; };

					return code;
				}
			template setter (string source_type)
				{/*...}*/
					enum setter = q{
						void opCall (} ~ autodeclare!(IndexTypes, `,`) ~ q{ } ~ source_type.capitalize ~ q{ link)
							}`{`q{
								} ~ set_indices ~ q{
								source = Source.} ~ source_type ~ q{;
								} ~ source_type ~ q{ = link;
							}`}`
					;
				}
		}
	}

static if (0) // BUG compiler aliasing error
unittest {/*...}*/
	import std.exception;

	static assert (is (Look!int.Active == int delegate()));
	static assert (is (Look!int.Passive == int*));

	static assert (is (Look!(int, 1).Active == int delegate(ushort)));
	static assert (is (Look!(int, 1).Passive == int[]));

	static assert (is (Look!(int, byte).Active == int delegate(byte)));
	static assert (is (Look!(int, byte).Passive == int[byte]));

	static assert (is (Look!(int, int, 2, char).Active == int delegate(int,uint,char)));
	static assert (is (Look!(int, int, 2, char).Passive == int[char][][int]));

	Look!(int, 1) look;

	assert (look.exists.not);
	assertThrown!Error (look == 1);
	
	look (2, (ushort x) {return x + 1;});
	assert (look.exists);
	assert (look == 3);

	int[] ints;
	ints ~= 2;
	look (0, ints);
	assert (look.exists);
	assert (look == 2);

	look (null);
	assert (look.exists.not);
}
