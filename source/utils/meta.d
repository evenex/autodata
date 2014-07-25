import std.traits;
import std.typetuple;
import std.range;

import utils;

public {/*traits}*/
	/* test if type has a field */
	template has_field (T, field_T, string name)
		{/*...}*/
			const bool has_field ()
				{/*...}*/
					static if (hasMember!(T, name))
						{/*...}*/
							mixin(q{alias Field = typeof (T.}~name~q{);});
							return is (field_T : Field);
						}
					else return false;
				}
		}
	/* for each of reference_T's fields, test if Type has a compatible field */
	template has_fields (Type, reference_T)
		{/*...}*/
			const bool has_fields ()
				{/*...}*/
					foreach (member; __traits (allMembers, reference_T))
						{/*...}*/
							const bool is_function = isSomeFunction!(mixin(`reference_T.`~member));
							static if (is_function)
								continue;
							else {/*...}*/
								const bool has_no_type = !is (typeof (mixin(`reference_T.`~member)));
								static if (has_no_type)
									continue;
								else {/*...}*/
									alias Field = typeof (mixin(`reference_T.`~member));
									static if (has_field!(Type, Field, member))
										continue;
									else return false;
								}
							}

						}
					return true;
				}
		}
	/* test if a member has an attribute */
	template has_attribute (T, string member, alias attribute)
		{/*...}*/
			const bool has_attribute ()
				{/*...}*/
					foreach (type; mixin(q{__traits (getAttributes, T.}~member~q{)}))
						static if (is (type == attribute))
							return true;
					return false;
				}
		}
	/* test if function takes only pointer arguments */
	template takes_pointer (alias func)
		{/*...}*/
			const bool takes_pointer ()
				{/*...}*/
					return allSatisfy!(isPointer, ParameterTypeTuple!func);
				}
		}
	/* test if a template argument is a number  */
	template is_numerical_param (T...) if (T.length == 1)
		{/*...}*/
			const bool is_numerical_param = __traits(compiles, T[0] == 0);
		}
	/* test if a template argument is a string  */
	template is_string_param (T...) if (T.length == 1)
		{/*...}*/
			static if (__traits(compiles, typeof(T[0])))
					const bool is_string_param = isSomeString!(typeof(T[0]));
			else const bool is_string_param = false;
		}
	/* test if a template argument is a type  */
	template is_type (T...) if (T.length == 1)
		{/*...}*/
			const bool is_type = is (T[0]);
		}
	/* test if a template argument is an aliased symbol */
	template is_alias (T...) if (T.length == 1)
		{/*...}*/
			const bool is_alias = __traits(compiles, typeof (T[0])) 
				&& not (
					is_numerical_param!(T[0])
					|| is_string_param!(T[0])
				);
		}
	/* test if a function behaves syntactically as a comparison */
	template is_comparison_function (U...)
		if (U.length == 1)
		{/*...}*/
			static if (isSomeFunction!(U[0]))
				{/*...}*/
					alias Function = U[0];
					alias Params = ParameterTypeTuple!(U[0]);

					static if (Params.length == 2)
						{/*...}*/
							alias T = Params[0];
							static if (is (T == Params[1]))
								{/*...}*/
									alias Return = ReturnType!Function;
									static if (is (bool: Return) || is (Return: bool))
										enum is_comparison_function = true;
									else enum is_comparison_function = false;
								}
							else enum is_comparison_function = false;
						}
					else enum is_comparison_function = false;
				}
			else enum is_comparison_function = false;
		}
	/* test if a type is comparable using the < operator */
	template is_comparable (T...)
		if (T.length == 1)
		{/*...}*/
			static if (is (T[0]))
				{/*...}*/
					const T[0] a, b;
					enum is_comparable = __traits(compiles, a < b);
				}
			else enum is_comparable = false;
		}
	/* test if a range has slicing, more permissive than std.range.hasSlicing */
	template is_sliceable (R)
		{/*...}*/
			enum is_sliceable = __traits(compiles, R.init[0..1]);
		}
	/* test if a range is indexable */
	template is_indexable (R)
		{/*...}*/
			enum is_indexable = __traits(compiles, R.init[0]);
		}
	/* test if T is a member function */
	template is_member_function (T...)
		{/*...}*/
			static if (T.length == 1)
				enum is_member_function = isSomeFunction!(T[0])
					&& not (isFunctionPointer!(T[0])
						|| isDelegate!(T[0])
					);
			else enum is_member_function = false;
		}
	/* test if a type can index D's built-in arrays and slices */
	template can_index_arrays (T)
		{/*...}*/
			enum can_index_arrays = __traits(compiles, T[].init[T.init]);
		}
	/* test if a member of T is publicly accessible */
	template is_accessible (T, string member)
		{/*...}*/
			enum is_accessible = mixin(q{__traits(compiles, T.} ~member~ q{)});
		}
}
public {/*mixins}*/
	/* a unique (up to the host type) identifier */
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
	/* separate Types and Names into eponymous TypeTuples */
	mixin template DeclarationSplitter (Args...)
		{/*...}*/
			private import std.typetuple: Filter;

			alias Types = Filter!(is_type, Args);
			alias Names = Filter!(is_string_param, Args);
			static assert (Types.length == Names.length, `type/name mismatch`);
			static assert (Types.length + Names.length == Args.length, `extraneous template parameters`);
		}
	/* generate getters and this-returning setters for a set of declared fields */
	mixin template Command (Args...)
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
	/* forward opApply (foreach) */
	mixin template IterateOver (alias range)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);
			alias Applied = typeof(range[0]);

			int opApply (scope int delegate(ref Applied) op)
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
			int opApply (scope int delegate(size_t, ref Applied) op)
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
			int opApply (scope int delegate(ref const Applied) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(ref Applied)) op);
				}
			int opApply (scope int delegate(const size_t, ref const Applied) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(size_t, ref Applied)) op);
				}
		}
	/* forward opCmp (<,>,<=,>=) */
	mixin template CompareBy (alias member)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			public {/*opCmp}*/
				int opCmp (ref const typeof(this) that) const nothrow
					{/*...}*/
						const string name = __traits(identifier, member);
						mixin(q{
							return compare (this.} ~name~ q{, that.} ~name~ q{);
						});
					}
				int opCmp (const typeof(this) that) const nothrow
					{/*...}*/
						const string name = __traits(identifier, member);
						mixin(q{
							return compare (this.} ~name~ q{, that.} ~name~ q{);
						});
					}
			}
		}
	/* apply an array interface over a pointer and length variable */
	mixin template ArrayInterface (alias pointer, alias length)
		{/*...}*/
			public {/*assertions}*/
				static assert (is_indexable!(typeof(pointer)),
					`backing struct must support indexing`
				);
				static assert (is_sliceable!(typeof(pointer)),
					`backing struct must support slicing`
				);
			}
			public:
			public {/*[┄]}*/
				ref auto opIndex (size_t i) inout
					in {/*...}*/
						assert (i < length);
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
			public {/*iteration}*/
				mixin IterateOver!opSlice;
			}
			public {/*text}*/
				auto toString () const
					{/*...}*/
						import std.conv;
						import std.range;

						static if (__traits(compiles, pointer[0..length].text))
							return pointer[0..length].text;
						else return `[` ~ElementType!(typeof(pointer)).stringof~ `...]`;
					}
				auto text () const
					{/*...}*/
						return toString;
					}
			}
		}
	/* enable mixin load_dynamic_library!"libname" */
	/* which attempts to link all member extern (C) function pointers with the specified lib */
	/* when mixed into a member function (typically the constructor) of a type */
	mixin template DynamicLibraryLoader ()
		{/*...}*/
			static const string load_dynamic_library (string library) ()
				{/*...}*/
					return `mixin(load_dynamic_symbols!(typeof (this), "`~library~`"));`;
				}
			static const string load_dynamic_symbols (caller_T, string library) () // TODO platform independence
				{/*...}*/
					string command = '{'~`
						import std.c.linux.linux;
						void* library = dlopen ("`~library~`", RTLD_NOW);
					`;
					foreach (symbol; __traits (allMembers, caller_T))
						{/*...}*/
							const string load_symbol = `mixin(load_dynamic_symbol!"`~symbol~`");`;
							const string enforce_symbol = `enforce (`~symbol~`, "couldn't load symbol `~symbol~` from library `~library~`");`;

							static if (isFunctionPointer!(__traits (getMember, caller_T, symbol)))
								static if (functionLinkage!(__traits (getMember, caller_T, symbol)) == "C")
									command ~= load_symbol ~ enforce_symbol;
						}
					return command ~ '}';
				}
			static const string load_dynamic_symbol (string symbol) ()
				{/*...}*/
					return symbol~` = cast (typeof (`~symbol~`)) dlsym (library, "`~symbol~`");`;
				}
		}
}
public {/*wrappers}*/
	/* forward all member functions of some object via pointer 
	*/
	struct Forwarded (T)
		{/*...}*/
			public mixin(forward_members);

			private:

			T* command;
			static string forward_members ()
				{/*...}*/
					string code;

					foreach (member; __traits(allMembers, T))
						{/*...}*/
							static if (member.empty || member == `__ctor`)
								continue;
							else {/*...}*/
								string forward = q{command.} ~member~ q{ (args)};

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

	/* apply dynamic array functionality over any type which supports array semantics 
		· the length of the backing array sets the capacity of the dynamic array
		· if the backing array defines a constructor, the dynamic array inherits it
		· element destruction can be controlled through the Destruction policy
	*/
	struct Dynamic (Array, Destruction destruction = Destruction.deferred)
		if (hasLength!Array && is_indexable!Array && is_sliceable!Array)
		{/*...}*/
			alias T = ElementType!Array;
			public:
			public {/*[┄]}*/
				ref auto opIndex (size_t i) inout
					in {/*...}*/
						import std.conv;
						assert (i < length,
							i.text ~ ` exceeds Dynamic!(` ~Array.stringof~ `) length ` ~length.text
						);
					}
					body {/*...}*/
						return array[i];
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (i <= j && j <= length);
					}
					body {/*...}*/
						return array[i..j];
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
			public {/*~=}*/
				auto opOpAssign (string op: `~`)(ref T item)
					{/*...}*/
						++length;
						this[$-1] = item;
					}
				auto opOpAssign (string op: `~`)(lazy T item)
					{/*...}*/
						++length;
						this[$-1] = item;
					}
				auto opOpAssign (string op: `~`, R)(R range)
					if (isForwardRange!R)
					{/*...}*/
						auto save = range.save;
						auto start = this.length;
						this.length += save.length;
						range.copy (this[start..$]);
					}
			}
			public {/*range}*/
				ref auto front ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						return array.front;
					}
				ref auto back ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						return array[length - 1];
					}
			}
			public @property {/*}*/
				auto capacity () const
					{/*...}*/
						return array.length;
					}
			}
			public {/*clear}*/
				auto clear ()
					{/*...}*/
						static if (destruction == Destruction.immediate)
							foreach (ref item; this)
								item.destroy;
							
						length = 0;
					}
			}
			public {/*iteration}*/
				mixin IterateOver!opSlice;
			}
			public {/*ctor}*/
				static if (__traits(hasMember, Array, `__ctor`))
					this (ParameterTypeTuple!(Array.__ctor) args)
						{/*...}*/
							array = Array (args);
						}
			}
			public {/*text}*/
				auto toString () const
					{/*...}*/
						import std.conv;

						static if (__traits(compiles, array[0..length].text))
							return array.array[0..length].text;
						else return `[` ~T.stringof~ `...]`;
					}
				auto text () const
					{/*...}*/
						return toString;
					}
			}
			public {/*data}*/
				size_t length = 0;
			}
			private:
			private {/*data}*/
				Array array;
			}
			invariant () {/*...}*/
				import std.conv;
				assert (this.length <= array.length,
					`Dynamic!(` ~T.stringof~ `) of length ` ~this.length.text~ ` exceeded capacity ` ~array.length.text
				);
			}
		}

	/* specify when elements in Dynamic arrays are destroyed
	*/
	enum Destruction 
		{/*...}*/
			/* clearing the array calls the destructor for all elements */ // TODO popEnd method?
			immediate,
			/* elements are destroyed only if they are overwritten and reassignment is destructive */
			deferred
		}

	unittest
		{/*dynamic array}*/
			mixin(report_test!`dynamic array`);
			import std.exception;

			auto S = Array!int (10);

			[0,1,2,3,4,5,6,7,8,9].copy (S[]);

			foreach (j, i; S)
				assert (i == j);

			auto D = Dynamic!(Array!int) (10);
			auto E = Dynamic!(int[10])();

			assert (E.length == 0 && D.length == 0);
			D ~= 1;
			assert (D.length == 1);
			E ~= [1,2,3];
			assert (E.length == 3);

			assert (D[].equal ([1]));
			assert (E[].equal ([1,2,3]));

			D.clear;
			assert (D.length == 0);

			D ~= S[];
			assert (D[].equal (S[]));
			assertThrown!Error (D ~= S[]);
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
