module evx.meta;

// REFACTOR
import std.traits;
import std.typetuple;
import std.range;

import evx.utils; // REVIEW
import evx.traits; // REVIEW

public {/*mixins}*/
	/* a unique (up to the host type) identifier 
	*/
	mixin template TypeUniqueId (uint bit = 64)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			struct Id
				{/*...}*/
					static auto create () nothrow
						{/*...}*/
							return typeof(this) (++generator);
						}
					private {/*data}*/
						static if (bit == 64)
							ulong id;
						else static if (bit == 32)
							uint id;
						else static if (bit == 16)
							ushort id;
						else static if (bit == 8)
							ubyte id;
						else static assert (0);
						__gshared typeof(id) generator;
					}
					mixin CompareBy!id;
				}
		}

	/* separate Types and Names into eponymous TypeTuples 
	*/
	mixin template DeclarationSplitter (Args...)
		{/*...}*/
			private import std.typetuple: Filter;

			alias Types = Filter!(is_type, Args);
			alias Names = Filter!(is_string_param, Args);
			static assert (Types.length == Names.length, `type/name mismatch`);
			static assert (Types.length + Names.length == Args.length, `extraneous template parameters`);
		}

	/* generate getters and this-returning setters for a set of declared fields 
	*/
	mixin template Builder (Args...)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			mixin DeclarationSplitter!Args;

			mixin(command_property_declaration);
			mixin(command_data_declaration);

			private {/*code generation}*/
				static string command_property_declaration ()
					{/*...}*/
						static string command_getter_setter (string name)()
							{/*...}*/
								import std.typetuple;

								alias Type = Types[staticIndexOf!(name, Names)];
								return q{
									@property auto ref }~name~q{ (}~Type.stringof~q{ value)
										}`{`q{
											_}~name~q{ = value;
											return this;
										}`}`q{
									@property auto ref }~name~q{ ()
										}`{`q{
											return _}~name~q{;
										}`}`q{
								};
							}

						string code;
						foreach (name; Names)
							code ~= command_getter_setter!name;
						return code;
					}
				static string command_data_declaration ()
					{/*...}*/
						import std.typecons;

						template prepend_underscore (string name)
							{enum prepend_underscore = `_`~name;}
						return alignForSize!Types ([staticMap!(prepend_underscore, Names)]);
					}
			}
		}

	/* forward opApply (foreach) 
	*/
	mixin template IterateOver (alias range)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);
			alias Applied = typeof(range[0]);

			/* so these are all templated, so they don't block the compilation of pure structs
				but will still generate a compiler error if foreach is attempted on it
				which is kind of shitty.. after all, if i can do it with a for-loop, and opApply
				itself doesn't modify anything, then the only thing stopping me is the fact that
				the delegate is modifying some variable in its scope. that should still be considered pure,
				somehow
			*/
			int opApply ()(scope int delegate(auto ref Applied) op)
				{/*...}*/
					int result;

					foreach (ref element; range)
						{/*...}*/
							result = op (element);

							if (result) 
								break;
						}

					return result;
				}
			int opApply ()(scope int delegate(size_t, auto ref Applied) op)
				{/*...}*/
					int result;

					foreach (i, ref element; range)
						{/*...}*/
							result = op (i, element);

							if (result) 
								break;
						}

					return result;
				}
			int opApply ()(scope int delegate(const auto ref Applied) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(ref Applied)) op);
				}
			int opApply ()(scope int delegate(const size_t, const auto ref Applied) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(size_t, ref Applied)) op);
				}
		}
	unittest {/*...}*/ // REVIEW
		struct Test {int[4] x; mixin IterateOver!x;}

		static assert (isIterable!Test);

		auto t = Test ([1,2,3,4]);

		auto sum = 0;
		foreach (i; t)
			sum += i;

		assert (sum == 10);

		foreach (ref i; t)
			i = sum;

		assert (Test == Test ([10, 10, 10, 10]));
	}

	/* forward opCmp (<,>,<=,>=) 
	*/
	mixin template CompareBy (alias member)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			int opCmp ()(auto ref const typeof(this) that) const
				{/*...}*/
					enum name = __traits(identifier, member);
					mixin(q{
						return compare (this.} ~name~ q{, that.} ~name~ q{);
					});
				}
		}
	unittest {/*...}*/
		struct Test {int x; mixin CompareBy!x;}

		assert (Test(1) < Test(2));
		assert (Test(1) <= Test(2));
		assert (not (Test(1) > Test(2)));
		assert (not (Test(1) >= Test(2)));

		assert (not (Test(1) < Test(1)));
		assert (not (Test(1) > Test(1)));
		assert (Test(1) <= Test(1));
		assert (Test(1) >= Test(1));
	}

	/* apply an array interface over a pointer and length variable 
	*/
	mixin template ArrayInterface (alias pointer, alias length)
		if (is_sliceable!(typeof(pointer)))
		{/*...}*/
			public:
			public {/*[┄]}*/
				ref auto opIndex (size_t i)
					in {/*...}*/
						assert (i < length, `access out of bounds`);
					}
					body {/*...}*/
						return pointer[i];
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (i <= j && j <= length);
					}
					body {/*...}*/
						return pointer[i..j];
					}
				auto opSlice ()
					{/*...}*/
						return this[0..$];
					}
				auto opDollar () const
					{/*...}*/
						return length;
					}
			}
			public {/*range}*/
				ref auto front ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						import std.range;
						return this[].front;
					}
				ref auto back ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						import std.range;
						return this[].back;
					}
			}
			const {/*[┄]}*/
				ref auto opIndex (size_t i)
					{/*...}*/
						return (cast()this)[i];
					}
				auto opSlice (size_t i, size_t j)
					{/*...}*/
						return (cast()this)[i..j];
					}
				auto opSlice ()
					{/*...}*/
						return (cast()this)[0..$];
					}
			}
			const {/*range}*/
				ref auto front ()
					{/*...}*/
						import std.range;
						return (cast()this)[].front;
					}
				ref auto back ()
					{/*...}*/
						import std.range;
						return (cast()this)[].back;
					}
			}
			public {/*iteration}*/
				static if (is(IterateOver)) // REVIEW does this work?
					mixin IterateOver!opSlice;
			}
			const {/*text}*/
				auto toString ()
					{/*...}*/
						import std.conv: text;
						import std.range: empty, ElementType;
						import std.traits: PointerTarget;

						static if (__traits(compiles, this[].text))
							return this[].text;
						else static if (__traits(compiles, this[0].text))
							{/*...}*/
								string output;

								foreach (element; 0..length)
									output ~= element.text ~ `, `;

								if (output.empty)
									return `[]`;
								else return `[` ~output[0..$-2]~ `]`;
							}
						else static if (is (typeof(pointer) == T*, T))
							return `[` ~PointerTarget!(typeof(pointer)).stringof~ `...]`;
						else return `[` ~ElementType!(typeof(pointer)).stringof~ `...]`;
					}
				auto text ()
					{/*...}*/
						return toString;
					}
			}
		}

	/* generate a member function auto_initialize () which automatically initializes all fields tagged Initialize
	*/
	mixin template AutoInitialize ()
		{/*...}*/
			void auto_initialize ()
				{/*...}*/
					alias This = typeof(this);
					foreach (member; __traits(allMembers, This))
						static if (__traits(compiles, __traits(getMember, This, member)))
							static if (not (is_type!(__traits(getMember, This, member))))
								foreach (Attribute; __traits(getAttributes, __traits(getMember, This, member)))
									static if (__traits(compiles, Attribute.is_initializer))
										{/*...}*/
											static if (is (typeof(__traits(getMember, This, member)) == class))
												__traits(getMember, This, member) = new typeof(__traits(getMember, This, member))(Attribute.Args);
											else static if (is (typeof(__traits(getMember, This, member)) == struct))
												__traits(getMember, This, member) = typeof(__traits(getMember, This, member))(Attribute.Args);
											else static assert (0);
										}
				}
		}

	/* specify field constructor parameters at the point of field declaration 
	*/
	struct Initialize (CtorArgs...)
		{/*...}*/
			alias Args = CtorArgs;
			enum is_initializer;
		}

	/* enable mixin load_dynamic_library!"libname"
		which attempts to link all member extern (C) function pointers with the specified lib
		when mixed into a member function (typically the constructor) of a type 
	*/
	mixin template DynamicLibraryLoader () // REFACTOR
		{/*...}*/
			static const string load_dynamic_library (string library) ()
				{/*...}*/
					return `mixin(load_dynamic_symbols!(typeof (this), "`~library~`"));`;
				}
			static const string load_dynamic_symbols (caller_T, string library) ()
				{/*...}*/
					string command = q{
						import std.c.linux.linux;
						void* library = dlopen ("`~library~`", RTLD_NOW);
					};

					foreach (symbol; __traits (allMembers, caller_T))
						{/*...}*/
							const string load_symbol = q{mixin(load_dynamic_symbol!}`"` ~symbol~ `"`q{);};
							const string enforce_symbol = `enforce (`~symbol~`, "couldn't load symbol `~symbol~` from library `~library~`");`;

							static if (isFunctionPointer!(__traits (getMember, caller_T, symbol)))
								static if (functionLinkage!(__traits (getMember, caller_T, symbol)) == "C")
									command ~= load_symbol ~ enforce_symbol;
						}
					return `{` ~command~ `}`;
				}
			static const string load_dynamic_symbol (string symbol) ()
				{/*...}*/
					return symbol~` = cast (typeof (`~symbol~`)) dlsym (library, "`~symbol~`");`;
				}
		}

	/* forward constructor calls to recipient
	*/
	mixin template ForwardConstructor (alias recipient)
		{/*...}*/
			import std.traits: hasMember;
			static if (hasMember!(typeof(recipient), `__ctor`))
				this (Args...)(Args args)
					{/*...}*/
						recipient = typeof(recipient)(args);
					}
			else this (T)(T value)
					{/*...}*/
						recipient = value;
					}
		}
}
public {/*wrappers}*/
	/* forwards function calls via pointer and returns itself for chaining
	*/
	struct ChainForward (T)
		{/*...}*/
			public mixin(forward_members);

			private:

			T* to_build;
			static string forward_members ()
				{/*...}*/
					string code;

					foreach (member; __traits(allMembers, T))
						{/*...}*/
							static if (member.empty || member == `__ctor`)
								continue;
							else {/*...}*/
								string forward = q{to_build.} ~member~ q{ (args)};

								code ~= q{
									auto } ~member~ q{ (Args...)(scope lazy Args args)
										}`{`q{
											static if (__traits(compiles, } ~forward~ q{))
												}`{`q{
													} ~forward~ q{;
													return this;
												}`}`q{
											else static assert (0, } `"`~member~ ` cannot be forwarded"`q{);
										}`}`q{
								};
							}
						}

					return code;
				}
		}
}
public {/*type processing}*/
	template pointer_to (T)
		{/*...}*/
			alias pointer_to = T*;
		}
	template array_of (T)
		{/*...}*/
			alias array_of = T[];
		}
	/* create a tuple of all members of a type that have a given alias attribute tag */
	template collect_members (T, alias attribute)
		{/*...}*/
			immutable string[] collect_members ()
				{/*...}*/
					immutable string[] collect (members...) ()
						{/*...}*/
							static if (members.length == 0)
								return [];
							else static if (members[0] == "this")
								return collect!(members[1..$]);
							else static if (has_attribute!(T, members[0], attribute))
								return members[0] ~ collect!(members[1..$]);
							else return collect!(members[1..$]);
						}
					return collect!(__traits (allMembers, T));
				}
		}
	/* convert any kind of tuple to its corresponding TypeTuple */
	template types_of (T...)
		{/*...}*/
			static if (__traits(compiles, typeof(T)))
				alias types_of = typeof(T);
			else alias types_of = T;
		}
	/* build a TypeTuple of all nested structs and classes defined within T */
	template get_substructs (T)
		{/*...}*/
			private template get_substruct (T)
				{/*...}*/
					template get_substruct (string member)
						{/*...}*/
							import std.range;
							static immutable name = q{T.} ~member;

							static if (member.empty)
								enum get_substruct = 0;
							
							else static if (mixin(q{is (}~name~q{)})
								&& is_accessible!(T, member)
								&& not (mixin(q{is (}~name~q{ == T)}))
							) mixin(q{
								alias get_substruct = T.} ~member~ q{;
							});
							else enum get_substruct = 0;
						}
				}

			alias get_substructs = Filter!(Not!is_numerical_param, 
				staticMap!(get_substruct!T, __traits(allMembers, T))
			);
		}
	/* build a string tuple of all assignable members of T */
	template assignable_members (T)
		{/*...}*/
			private template is_assignable (T)
				{/*...}*/
					template is_assignable (string member)
						{/*...}*/
							enum is_assignable = isAssignable!(typeof(__traits(getMember, T, member)));
						}
				}

			alias assignable_members = Filter!(is_assignable!T, __traits(allMembers, T));
		}
	/* perform search and replace on a typename */
	string rewrite_type (Type, Find, ReplaceWith)()
		{/*...}*/
			import std.algorithm: findSplit;

			string type = Type.stringof;
			string find = Find.stringof;
			string repl = ReplaceWith.stringof;

			string left  = findSplit (type, find)[0];
			string right = findSplit (type, find)[2];

			return left ~ repl ~ right;
		}
}
public {/*code generation}*/
	/* declare variables according to format (see unittest) */
	static string autodeclare (Params...)() 
		if (Params.length > 0)
		{/*...}*/
			alias Types = Filter!(is_type, Params);
			alias fixes = Filter!(is_string_param, Params);

			static if (fixes.length == 0)
				{/*...}*/
					const string prefix = ``;
					const string suffix = `; `;
				}
			else static if (fixes.length == 1)
				{/*...}*/
					template is_punctuation (c...) if (c.length == 1)
						{/*...}*/
							import std.ascii: isPunctuation;
							const bool is_punctuation = c[0][0].isPunctuation;
						}
					static if (anySatisfy!(is_punctuation, fixes[0].array))
						{/*suffix}*/
							const string prefix = ``;
							const string suffix = fixes[0];
						}
					else {/*prefix}*/
							const string prefix = fixes[0];
							const string suffix = `; `;
					}
				}
			else static if (fixes.length == 2)
				{/*...}*/
					const string prefix = fixes[0];
					const string suffix = fixes[1];
				}
			else static assert (0);

			string code;
			foreach (i, T; Types)
				code ~= T.stringof~` `~prefix~`_`~to!string(i)~suffix;
			return code;
		}
		unittest {/*autodeclare}*/
			static assert (autodeclare!(int, byte, `x`)			== q{int x_0; byte x_1; });
			static assert (autodeclare!(int, byte, `x`, `, `) 	== q{int x_0, byte x_1, });
			static assert (autodeclare!(int, byte, char, `:: `)	== q{int _0:: byte _1:: char _2:: });
		}
	/* apply a predicate to a series of rvalues */
	static string apply_to_each (string op, Names...)()
		if (allSatisfy!(is_string_param, Names))
		{/*...}*/
			string code;

			foreach (name; Names)
				code ~= q{
					} ~ name ~ q{.} ~ op ~ q{;
				};

			return code;
		}
}
