module evx.meta;

private {/*import std}*/
	import std.traits:
		isIterable,
		isFunctionPointer, functionLinkage,
		Unqual;

	import std.range:
		empty;
}
private {/*import evx}*/
	import evx.utils:
		not,
		compare;

	import evx.traits:
		is_type, is_string_param,
		is_indexable, is_sliceable;
}

pure nothrow:
public {/*forwarding}*/
	/* forward opApply (foreach) 
	*/
	mixin template IterateOver (alias container)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			int opApply (scope int delegate(ref typeof(container[0])) op)
				{/*...}*/
					int result;

					try foreach (ref element; container)
						{/*...}*/
							result = op (element);

							if (result) 
								break;
						}
					catch (Exception) assert (0);

					return result;
				}
			int opApply (scope int delegate(size_t, ref typeof(container[0])) op)
				{/*...}*/
					int result;

					try foreach (i, ref element; container)
						{/*...}*/
							result = op (i, element);

							if (result) 
								break;
						}
					catch (Exception) assert (0);

					return result;
				}
			int opApply (scope int delegate(const ref typeof(container[0])) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(ref typeof(container[0]))) op);
				}
			int opApply (scope int delegate(const size_t, const ref Unqual!(typeof(container[0]))) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(size_t, ref Unqual!(typeof(container[0])))) op);
				}
		}
		unittest {/*...}*/
			import std.conv: to;

			debug struct Test {int[4] x; pure nothrow: mixin IterateOver!x;}

			static assert (isIterable!Test);

			auto t = Test ([1,2,3,4]);

			foreach (i; t)
				i = 0;

			assert (not (t == Test ([0,0,0,0])));

			auto sum = 0;
			foreach (i; t)
				sum += i;

			assert (sum == 10);

			foreach (ref i; t)
				i = sum;

			assert (t == Test ([10, 10, 10, 10]));

			foreach (i, ref j; t)
				j = i.to!int + 1;

			assert (t == Test([1,2,3,4]));
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
			debug struct Test {int x; mixin CompareBy!x;}

			assert (Test(1) < Test(2));
			assert (Test(1) <= Test(2));
			assert (not (Test(1) > Test(2)));
			assert (not (Test(1) >= Test(2)));

			assert (not (Test(1) < Test(1)));
			assert (not (Test(1) > Test(1)));
			assert (Test(1) <= Test(1));
			assert (Test(1) >= Test(1));
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
		unittest {/*...}*/
			debug static struct Test {int a; pure nothrow: this (int a) {this.a = -a;}}
			debug static struct Ctor {Test t; pure nothrow: mixin ForwardConstructor!t;}

			auto x = Ctor (12);
			assert (x.t.a == -12);
		}

	/* forward function calls via pointer and returns itself for chaining 
	*/
	struct ChainForwarding (T)
		{/*...}*/
			public pure nothrow:
			mixin(forward_members);

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
	
	/* convenience function for ChainForwarding 
	*/
	auto forward_to (T)(ref T lvalue)
		{/*...}*/
			return ChainForwarding!T (&lvalue);
		}
		unittest {/*...}*/
			debug static struct Test 
				{/*...}*/
					int _x, _y, _z; 

					pure nothrow:
					@property x (int x)
						{_x = x;}
					@property y (int y)
						{_y = y;}
					@property z (int z)
						{_z = z;}
				}

			Test t;

			forward_to (t)
				.x(1)
				.y(2)
				.z(3);

			assert (t._x == 1);
			assert (t._y == 2);
			assert (t._z == 3);
		}
}
public {/*initialization}*/
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
		unittest {/*...}*/
			import std.c.stdlib: 
				malloc, free;

			debug static struct Test
				{/*...}*/
					static struct Inner {int x, y; pure nothrow this (int x, int y) {this.x = x; this.y = y;}}
					static struct Malloced
						{/*...}*/
							int* mem; 

							pure nothrow:

							this (int size)
								{mem = cast(int*)malloc(size);}
							~this ()
								{/*...}*/
									if (mem) free (mem);
								}
						}

					pure nothrow:

					mixin AutoInitialize;
					@Initialize!(666, 42) Inner i1;
					@Initialize!(101, 99) Inner i2;
					@Initialize!(1024) Malloced m;

					this (typeof(null)){auto_initialize;}
				}

			auto t = Test (null);

			assert (t.i1.x == 666);
			assert (t.i1.y == 42);
			assert (t.i2.x == 101);
			assert (t.i2.y == 99);

			assert (t.m.mem !is null);
			*t.m.mem = 9001;
			assert (t.m.mem[0] == 9001);
		}

	/* generate a member load_library function which automatically looks up member extern (C) function pointer identifiers in linked C libraries  
		FUNCTION POINTERS MUST BE DECLARED ABOVE THE MIXIN (OUTSIDE BUG)
		if the function is not found, the program will halt. otherwise, the function pointer is set to the library function
	*/
	mixin template DynamicLibrary ()
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			static private {/*code generation}*/
				string generate_library_loader ()
					{/*...}*/
						string signature = q{
							void load_library ()
						};

						string code = q{
							import std.c.linux.linux;
						};

						foreach (symbol; __traits (allMembers, typeof(this)))
							static if (not (symbol.empty))
								static if (isFunctionPointer!(__traits (getMember, typeof(this), symbol)))
									static if (functionLinkage!(__traits (getMember, typeof(this), symbol)) == "C")
										code ~= q{
											} ~symbol~ q{ = cast (typeof (} ~symbol~ q{)) dlsym (null, } `"`~symbol~`"` q{);
											assert (} ~symbol~ q{, "couldn't load C library function "} `"`~symbol~`"` q{);
										};

						string nothrow_block = q{
							import std.conv: text;

							try }`{`q{
								} ~code~ q{
							}`}`q{
							catch (Exception ex) assert (0, ex.file ~ ex.line.text ~ ex.msg ~ ex.info.text);
						};

						return signature~ `{` ~nothrow_block~ `}`;
					}
			}

			mixin(generate_library_loader);
		}
		unittest {/*...}*/
			static struct GSLVector
				{/*...}*/
					size_t size = 3;
					size_t stride = 1;
					double* data = null;
					void* block = null;
					int owner = 0;
				}
			debug static struct Test
				{/*...}*/
					pure nothrow:

					extern (C) int function (GSLVector* a, const GSLVector* b) gsl_vector_add;

					mixin DynamicLibrary;

					this (typeof(null))
						{load_library;}
				}

			auto x = Test (null);

			double[3] 	v = [1,2,3],
						w = [4,5,6];

			GSLVector g_v, g_w;

			g_v.data = v.ptr;
			g_w.data = w.ptr;

			assert (x.gsl_vector_add !is null);
			x.gsl_vector_add (&g_v, &g_w);

			assert (v == [5,7,9]);
		}
}
public {/*type construction}*/
	enum IMPURE;
	/* generate Id, a unique (up to host type) identifier type 
	*/
	@IMPURE mixin template TypeUniqueId (uint bit = 64)
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

					pure nothrow mixin CompareBy!id;
				}
		}
		unittest {
			debug {/*TypeUniqueId.create cannot be made pure}*/
				struct Test { mixin TypeUniqueId; }

				auto x = Test.Id.create;

				assert (x == x);
				assert (x != Test.Id.create);
				assert (Test.Id.create != Test.Id.create);
			}
		}

	/* generate getters and chainable setters for a set of member declarations 
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
								import std.typetuple: staticIndexOf;

								alias Type = Types[staticIndexOf!(name, Names)];

								return q{
									@property auto ref } ~name~ q{ (} ~Type.stringof~ q{ value)
										}`{`q{
											_}~ name ~q{ = value;
											return this;
										}`}`q{
									@property auto ref } ~name~ q{ ()
										}`{`q{
											return _} ~name~ q{;
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
						import std.typecons:
							staticMap,
							alignForSize;

						template prepend_underscore (string name)
							{enum prepend_underscore = `_`~name;}

						return alignForSize!Types ([staticMap!(prepend_underscore, Names)]);
					}
			}
		}
		unittest {/*...}*/
			struct Test
				{/*...}*/
					pure nothrow mixin Builder!(
						int, `a`,
						int, `b`,
						int, `c`,
						int, `d`,
					);
				}

			Test x;

			x	.a (1)
				.b (2)
				.c (3)
				.d (4);

			assert (x.a == 1);
			assert (x.b == 2);
			assert (x.c == 3);
			assert (x.d == 4);
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
			public {/*=}*/
				auto opSliceAssign (U)(auto ref U that, size_t i, size_t j)
					in {/*...}*/
						import std.range: hasLength;

						static if (hasLength!U)
							assert (that.length == j-i, `length mismatch for range assignment`);
					}
					body {/*...}*/
						static if (is_indexable!U)
							foreach (k, ref x; this[i..j])
								x = that[k];
						else static if (isInputRange!U)
							for (auto X = this[]; not (X.empty); X.popFront, that.popFront)
								X.front = that.front;
					}
				auto opSliceAssign (U)(auto ref U that)
					{/*...}*/
						return this[0..$] = that;
					}
			}
			public {/*range}*/
				ref auto front ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						import std.range: front;
						return this[].front;
					}
				ref auto back ()
					in {/*...}*/
						assert (length);
					}
					body {/*...}*/
						import std.range: back;
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
						import std.range: front;
						return (cast()this)[].front;
					}
				ref auto back ()
					{/*...}*/
						import std.range: back;
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
							try return this[].text;
							catch (Exception) assert (0);
						else static if (__traits(compiles, this[0].text))
							{/*...}*/
								string output;

								try foreach (element; 0..length)
									output ~= element.text ~ `, `;
								catch (Exception) assert (0);

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
		unittest {/*...}*/
			import std.c.stdlib:
				malloc, free;

			import std.range:
				equal;

			debug struct Array
				{/*...}*/
					int* mem;
					int size;

					nothrow:

					this (int size)
						{/*...}*/
							this.size = size;
							this.mem = cast(int*)malloc (size * int.sizeof);
						}

					pure mixin ArrayInterface!(mem, size);
				}
			debug struct SArray
				{/*...}*/
					int[4] mem;
					enum size = 4;
					pure nothrow mixin ArrayInterface!(mem, size);
				}

			debug auto a = Array (4);
			SArray b;
			int[4] c;

			a[0] = 1;
			assert (a[0] == 1);

			a[1..4] = [2,3,4];
			assert (a[0..4].equal ([1,2,3,4]));
			assert (a[0..$].equal ([1,2,3,4]));
			assert (a[].equal ([1,2,3,4]));

			b[0..$] = a[];
			assert (b[0] == a[0]);
			assert (b[1] == a[1]);
			assert (b[2] == a[2]);
			assert (b[3] == a[3]);
			assert (b[0..1].equal (a[0..1]));
			assert (b[1..3].equal (a[1..3]));
			assert (b[2..$].equal (a[2..$]));
			assert (b[].equal (a[]));

			c[] = b[];
			assert (c[0] == a[0]);
			assert (c[1] == a[1]);
			assert (c[2] == a[2]);
			assert (c[3] == a[3]);
			assert (c[0..1].equal (a[0..1]));
			assert (c[1..3].equal (a[1..3]));
			assert (c[2..$].equal (a[2..$]));
			assert (c[].equal (a[]));
		}
}
public {/*type extraction}*/
	/* extract an array of identifiers for members of T which match the given UDA tag 
	*/
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
		void main () {/*...}*/
			enum Tag;
			struct Test {@Tag int x; @Tag int y; int z;}

			static assert (collect_members!(Test, Tag) == [`x`, `y`]);
		}

	/* build a TypeTuple of all nested struct and class definitions within T 
	*/
	template get_substructs (T)
		{/*...}*/
			private template get_substruct (T)
				{/*...}*/
					template get_substruct (string member)
						{/*...}*/
							immutable name = q{T.} ~member;

							static if (member.empty)
								enum get_substruct = 0;
							
							else static if (mixin(q{is (} ~name~ q{)})
								&& is_accessible!(T, member)
								&& not (mixin(q{is (} ~name~ q{ == T)}))
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
		unittest {/*...}*/
			struct Test {enum a = 0; int b = 0; struct InnerStruct {} class InnerClass {}}

			static assert (is (get_subtructs!T == TypeTuple!(Test.InnerStruct, Test.InnerClass)));
		}

	/* build a string tuple of all assignable members of T 
	*/
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
		unittest {/*...}*/
			struct Test {int a; const int b; immutable int c; enum d = 0; int e (){return 1;}}

			static assert (assignable_members!Test == TypeTuple!(`a`, `b`));
		}
}
public {/*type processing}*/
	/* T → T* 
	*/
	template pointer_to (T)
		{/*...}*/
			alias pointer_to = T*;
		}

	/* T → T[] 
	*/
	template array_of (T)
		{/*...}*/
			alias array_of = T[];
		}

	/* convert any kind of tuple to its corresponding TypeTuple 
	*/
	template types_of (T...)
		{/*...}*/
			static if (__traits(compiles, typeof(T)))
				alias types_of = typeof(T);
			else alias types_of = T;
		}
		unittest {/*...}*/
			import evx.utils: τ;

			alias T1 = TypeTuple!(int, int, int);
			alias T2 = Tuple!(short, ubyte);
			immutable x = τ(99, 'a');

			static assert (types_of!T1 == TypeTuple!(int, int, int));
			static assert (types_of!T2 == TypeTuple!(short, ubyte));
			static assert (types_of!x == TypeTuple!(int, char));
		}

	/* perform search and replace on a typename 
	*/
	string replace_template (Type, Find, ReplaceWith)()
		{/*...}*/
			import std.algorithm: findSplit;

			string type = Type.stringof;
			string find = Find.stringof;
			string repl = ReplaceWith.stringof;

			string left  = findSplit (type, find)[0];
			string right = findSplit (type, find)[2];

			return left ~ repl ~ right;
		}
		unittest {/*...}*/
			alias T1 = TypeTuple!string;

			mixin(q{
				alias T2 = replace_template!(T1, string, int);
			});

			static assert (is (T2 == TypeTuple!int));
		}
}
public {/*code generation}*/
	/* declare variables according to format (see unittest) 
	*/
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
		unittest {/*demo}*/
			// declarations are formatted by prefixes and suffixes and numbered by parameter order
			static assert (autodeclare!(int, byte, `x`)			== q{int x_0; byte x_1; });

			// suffixes are distinguished from prefixes by the presence of punctuation marks
			static assert (autodeclare!(int, byte, `x`, `, `) 	== q{int x_0, byte x_1, });
			static assert (autodeclare!(int, byte, char, `:: `)	== q{int _0:: byte _1:: char _2:: });
		}

	/* apply a dot predicate to a series of identifiers 
	*/
	static string apply_to_each (string op, Names...)()
		if (allSatisfy!(is_alias, Names))
		{/*...}*/
			string code;

			foreach (name; Names)
				code ~= q{
					} ~ __traits(identifier, name) ~ op ~ q{;
				};

			return code;
		}
		unittest {/*...}*/
			int a = 0, b = 1, c = 2, d = 3;

			mixin(apply_to_each!(`++`, a, b, c, d);

			assert (a == 1);
			assert (b == 2);
			assert (c == 3);
			assert (d == 4);

			mixin(apply_to_each!(`*= -1`, a, b, c, d));

			assert (a == -1);
			assert (b == -2);
			assert (c == -3);
			assert (d == -4);
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
}
