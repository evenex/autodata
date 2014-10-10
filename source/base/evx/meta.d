module evx.meta;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.typetuple;
		import std.typecons;
		import std.range;
		import std.conv;
	}
	private {/*evx}*/
		import evx.logic;
		import evx.utils;
		import evx.traits;
	}
}

pure:
public {/*forwarding}*/
	enum Iteration {constant, mutable}
	/* forward opApply (foreach) 
	*/
	mixin template IterateOver (alias container, Iteration iteration = Iteration.mutable)
		{/*...}*/
			import std.traits;

			static assert (is(typeof(this)), `mixin requires host struct`);

			static if (iteration is Iteration.mutable)
				{/*...}*/
					int opApply (scope int delegate(ref typeof(container[0])) op)
						{/*...}*/
							int result;

							foreach (ref element; container)
								{/*...}*/
									result = op (element);

									if (result) 
										break;
								}

							return result;
						}
					int opApply (scope int delegate(size_t, ref typeof(container[0])) op)
						{/*...}*/
							int result;

							foreach (i, ref element; container)
								{/*...}*/
									result = op (i, element);

									if (result) 
										break;
								}

							return result;
						}
				}
			else static if (iteration is Iteration.constant)
				{/*...}*/
					int opApply (scope int delegate(const ref typeof(container[0])) op) const
						{/*...}*/
							return (cast()this).opApply (cast(int delegate(ref typeof(container[0]))) op);
						}
					int opApply (scope int delegate(const size_t, const ref Unqual!(typeof(container[0]))) op) const
						{/*...}*/
							return (cast()this).opApply (cast(int delegate(size_t, ref Unqual!(typeof(container[0])))) op);
						}
				}
			else static assert (0);
		}
		unittest {/*...}*/
			import std.conv: to;

			debug struct Test {int[4] x; pure : mixin IterateOver!x;}

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

			auto opCmp ()(auto ref const typeof(this) that) const
				{/*...}*/
					import evx.ordinal: compare;

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
			debug static struct Test {int a; pure : this (int a) {this.a = -a;}}
			debug static struct Ctor {Test t; pure : mixin ForwardConstructor!t;}

			auto x = Ctor (12);
			assert (x.t.a == -12);
		}

	/* forward function calls via pointer and returns itself for chaining 
	*/
	struct ChainForwarding (T)
		{/*...}*/
			public pure :
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

					pure :
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
					import evx.traits;

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
					static struct Inner {int x, y; pure this (int x, int y) {this.x = x; this.y = y;}}
					static struct Malloced
						{/*...}*/
							int* mem; 

							pure :

							this (int size)
								{mem = cast(int*)malloc(size);}
							~this ()
								{/*...}*/
									if (mem) free (mem);
								}
						}

					pure :

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

			import evx.traits;
			import evx.logic;
			import std.traits: allSatisfy, isSomeString;

			static private {/*code generation}*/
				string generate_library_loader ()
					{/*...}*/
						string signature = q{
							void load_library (Args...)(Args file_names)
								if (allSatisfy!(isSomeString, Args))
						};

						string code = q{
							import std.c.linux.linux;
							import evx.utils: to_c;

							static if (Args.length > 0)
								void*[Args.length] libs;
							else void*[1] libs = [null];

							auto paths = file_names.to_c;

							foreach (i,_; Args)
								libs[i] = dlopen (paths[i], RTLD_LOCAL | RTLD_LAZY);
						};

						foreach (symbol; __traits (allMembers, typeof(this)))
							static if (is_C_function!symbol && not (mixin(q{is_type!} ~symbol)))
								code ~= q{
									foreach (lib; libs)
										}`{`q{
											} ~symbol~ q{ = cast(typeof(} ~symbol~ q{)) dlsym (lib, } `"`~symbol~`"` q{);

											if (} ~symbol~ q{ !is null)
												break;
										}`}`q{

									assert (} ~symbol~ q{ !is null, "couldn't load C library function "} `"`~symbol~`"` q{);
								};

						return signature~ `{` ~code~ `}`;
					}
			}

			mixin(generate_library_loader);

			void verify_function_call (string op, CArgs...)(CArgs c_args)
				{/*...}*/
					enum generic_error = `call to ` ~op~ ` (` ~CArgs.stringof~ `) failed to compile`;

					static if (__traits(compiles, mixin(q{ParameterTypeTuple!(} ~op~ q{)})))
						{/*enum error}*/
							mixin(q{
								alias Params = ParameterTypeTuple!(} ~op~ q{);
							});

							static if (not(is(CArgs == Params)))
								enum error = `cannot call ` ~op~ ` ` ~Params.stringof~ ` with ` ~CArgs.stringof;
							else enum error = generic_error;
						}
					else enum error = generic_error;

					static assert (__traits(compiles, mixin(op~ q{ (c_args)})), error);
				}

			template is_C_function (string name)
				{/*...}*/
					import std.range: empty;

					import std.traits: 
						isFunctionPointer, functionLinkage;

					static if (name.empty)
						enum is_C_function = false;
					else static if (isFunctionPointer!(__traits (getMember, typeof(this), name)))
						enum is_C_function = functionLinkage!(__traits (getMember, typeof(this), name)) == "C";
					else enum is_C_function = false;
				}
		}
		version (GSL) unittest {/*...}*/
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
					pure:

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
public {/*construction}*/
	/* generate Id, a unique (up to host type) identifier type 
	*/
	@imp mixin template TypeUniqueId (uint bit = 64)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			struct Id
				{/*...}*/
					static auto create ()
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

					pure mixin CompareBy!id;
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

			private {/*import std}*/
				import std.traits:
					isDelegate, isFunctionPointer;
			}
			private {/*import evx}*/
				import evx.traits:
					is_type, is_string_param;
				import evx.meta:
					ParameterSplitter;
			}

			mixin ParameterSplitter!(
				q{Types}, is_type, 
				q{Names}, is_string_param, 
				Args
			);

			mixin(builder_property_declaration);
			mixin(builder_data_declaration);

			static {/*code generation}*/
				string builder_property_declaration ()
					{/*...}*/
						static string builder_getter_setter (string name)()
							{/*...}*/
								import std.typetuple;
								import std.traits;

								alias Type = Types[staticIndexOf!(name, Names)];

								string setter = q{
									@property auto ref } ~name~ q{ (} ~Type.stringof~ q{ value)
										}`{`q{
											_}~ name ~q{ = value;
											return this;
										}`}`q{
								};

								static if (not (isSomeFunction!Type))
									setter ~= q{
										auto ref } ~name~ q{ (Args...)(Args args)
											}`{`q{
												_}~ name ~q{ = } ~Type.stringof~ q{ (args);
												return this;
											}`}`q{
									};

								static if (isDelegate!Type || isFunctionPointer!Type)
									string getter = q{
										inout @property } ~name~ q{ ()
											}`{`q{
												return _} ~name~ q{ ();
											}`}`q{
									};
								else string getter = q{
									inout @property } ~name~ q{ ()
										}`{`q{
											return _} ~name~ q{;
										}`}`q{
								};

								return getter ~ setter;
							}

						string code;

						foreach (name; Names)
							code ~= builder_getter_setter!name;

						return code;
					}
				string builder_data_declaration ()
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
					pure mixin Builder!(
						int, `a`,
						int, `b`,
						int, `c`,
						int delegate(), `d`,
					);
				}

			Test x;

			x	.a (1)
				.b (2)
				.c (3)
				.d (() => 4);

			assert (x.a == 1);
			assert (x.b == 2);
			assert (x.c == 3);
			assert (x.d == 4);
		}

	/* apply an array interface over a pointer and length variable 
	*/
	mixin template ArrayInterface (alias pointer, alias length_property)
		if (is_sliceable!(typeof(pointer)))
		{/*...}*/
			import evx.traits:
				is_indexable;

			public:
			public {/*[┄]}*/
				ref auto opIndex (size_t i)
					in {/*...}*/
						assert (i < length, `access (` ~i.text~ `) out of bounds (` ~length.text~ `) for ` ~typeof(this).stringof);
					}
					body {/*...}*/
						return pointer[i];
					}
				auto opSlice (size_t i, size_t j)
					in {/*...}*/
						assert (i <= j && j <= length,
							ElementType!(typeof(pointer)).stringof~ 
							` slice [` ~i.text~ `..` ~j.text~ `] exceeds length (` ~length.text~ `)`
						);
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
				auto length () const
					{/*...}*/
						return length_property;
					}
			}
			public {/*=}*/
				auto opSliceAssign (U)(auto ref U that, size_t i, size_t j)
					in {/*...}*/
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
				auto opSliceOpAssign (string op, U)(auto ref U that, size_t i, size_t j)
					in {/*...}*/
						import std.range: hasLength;

						static if (isInputRange!U && hasLength!U)
							assert (that.length == j-i, 
								`length mismatch for range op-assignment ` ~op~ `: `
								~U.stringof~ `:`~that.length.text~ ` vs ` ~(j-i).text
							);
					}
					body {/*...}*/
						static if (__traits(compiles, this.front = that))
							foreach (k, ref x; this[i..j])
								mixin(q{
									x } ~op~ q{= that;
								});
						else static if (is_indexable!U)
							foreach (k, ref x; this[i..j])
								mixin(q{
									x } ~op~ q{= that[k];
								});
						else static if (isInputRange!U)
							for (auto X = this[]; not (X.empty); X.popFront, that.popFront)
								mixin(q{
									X.front } ~op~ q{= that.front;
								});
					}
				auto opSliceOpAssign (string op, U)(auto ref U that)
					{/*...}*/
						mixin(q{
							return this[0..$] } ~op~ q{= that;
						});
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
						assert (length, `attempted to fetch back of empty array`);
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
				static if (is(IterateOver))
					mixin IterateOver!opSlice;
			}
			const {/*text}*/
				auto text (Args...)(Args args)
					{/*...}*/
						import std.traits;
						import std.range;

						static if (is (typeof(pointer) == T*, T))
							enum default_output = `[` ~PointerTarget!(typeof(pointer)).stringof~ `...]`;
						else enum default_output = `[` ~ElementType!(typeof(pointer)).stringof~ `...]`;

						debug {/*...}*/
							static if (__traits(compiles, this[0].toString (args)))
								{/*...}*/
									string output;

									foreach (element; this[])
										output ~= element.toString (args)~ `, `;

									if (output.empty)
										return `[]`;
									else return `[` ~output[0..$-2]~ `]`;
								}
							else static if (__traits(compiles, this[0].text))
								{/*...}*/
									string output;

									foreach (element; this[])
										output ~= element.text~ `, `;

									if (output.empty)
										return `[]`;
									else return `[` ~output[0..$-2]~ `]`;
								}
							else static if (__traits(compiles, this[].text))
								return this[].text;
							else return default_output;
						}
						else return default_output;
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
					pure mixin ArrayInterface!(mem, size);
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

			// since IterateOver is defined, the ArrayInterface is equipped with iteration
			foreach (x; a) {}
			foreach (x; b) {}
		}
}
public {/*extraction}*/
	/* extract an array of identifiers for members of T which match the given UDA tag 
	*/
	template collect_members (T, alias attribute)
		{/*...}*/
			static string[] collect_members ()
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
		unittest {/*...}*/
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

			foreach (i, T; TypeTuple!(Test.InnerStruct, Test.InnerClass))
				static assert (staticIndexOf!(T, get_substructs!Test) == i);
		}

	/* build a string tuple of all assignable members of T 
	*/
	template get_assignable_members (T)
		{/*...}*/
			private template is_assignable (T)
				{/*...}*/
					template is_assignable (string member)
						{/*...}*/
							enum is_assignable = __traits(compiles,
								(T type) {/*...}*/
									mixin(q{
										type.} ~member~ q{ = typeof(type.} ~member~ q{).init;
									});
								}
							);
						}
				}

			alias get_assignable_members = Filter!(is_assignable!T, __traits(allMembers, T));
		}
		unittest {/*...}*/
			struct Test {int a; const int b; immutable int c; enum d = 0; int e (){return 1;}}

			static assert (get_assignable_members!Test == TypeTuple!`a`);
		}

	template IndexTypes (R) // XXX currently 1 dimensional and use cases assume that slicing types and indexing types are the same. this is unlikely to change but if it does the code will not be robust to it
		{/*...}*/
			static if (hasMember!(R, `opIndex`))
				alias IndexTypes = staticMap!(FirstParameter, __traits(getOverloads, R, `opIndex`));
			else static if (__traits(compiles, R.init[0]))
				alias IndexTypes = TypeTuple!size_t;
			else alias IndexTypes = void;
		}

	/* get the type of a function's first parameter 
	*/
	template FirstParameter (alias func)
		if (ParameterTypeTuple!func.length > 0)
		{/*...}*/
			alias FirstParameter = ParameterTypeTuple!func[0];
		}

	template DollarType (R)
		{/*...}*/
			static if (__traits(compiles, R.init[$]))
				{/*...}*/
					static if (hasMember!(R, `opDollar`))
						alias DollarType = Unqual!(ReturnType!(R.opDollar));
					else alias DollarType = size_t;
				}
			else alias DollarType = void;
		}
}
public {/*processing}*/
	template type_of (T...)
		if (T.length == 1)
		{/*...}*/
			static if (is(T[0]))
				alias type_of = T[0];
			else alias type_of = typeof(T[0]);
		}

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

	/* perform search and replace on a typename 
	*/
	string replace_in_template (Type, Find, ReplaceWith)()
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
			alias T1 = Tuple!string;

			mixin(q{
				alias T2 = } ~replace_in_template!(T1, string, int)~ q{;
			});

			static assert (is (T2 == Tuple!int));
		}
}
public {/*code generation}*/
	/* declare variables according to format (see unittest) 
	*/
	string autodeclare (Params...)() 
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
				code ~= T.stringof~` `~prefix~`_`~i.text~suffix;

			return code;
		}
		unittest {/*demo}*/
			// declarations are formatted by prefixes and suffixes and numbered by parameter order
			static assert (autodeclare!(int, byte, `x`)			== q{int x_0; byte x_1; });

			// suffixes are distinguished from prefixes by the presence of punctuation marks
			static assert (autodeclare!(int, byte, `x`, `, `) 	== q{int x_0, byte x_1, });
			static assert (autodeclare!(int, byte, char, `:: `)	== q{int _0:: byte _1:: char _2:: });
		}

	/* apply a suffix operation to a series of identifiers 
	*/
	string apply_to_each (string op, Names...)()
		if (allSatisfy!(is_string_param, Names))
		{/*...}*/
			string code;

			foreach (name; Names)
				code ~= q{
					} ~name~ op ~ q{;
				};

			return code;
		}
		unittest {/*...}*/
			int a = 0, b = 1, c = 2, d = 3;

			mixin(apply_to_each!(`++`, `a`, `b`, `c`, `d`));

			assert (a == 1);
			assert (b == 2);
			assert (c == 3);
			assert (d == 4);

			mixin(apply_to_each!(`*= -1`, `a`, `b`, `c`, `d`));

			assert (a == -1);
			assert (b == -2);
			assert (c == -3);
			assert (d == -4);
		}

	/* separate Types and Names into eponymous TypeTuples 
	*/
	mixin template ParameterSplitter (string first, alias first_pred, string second, alias second_pred, Args...)
		{/*...}*/
			private import std.typetuple: Filter;

			mixin(q{
				alias } ~first~ q{ = Filter!(first_pred, Args);
				alias } ~second~ q{ = Filter!(second_pred, Args);
				static assert (} ~first~ q{.length == } ~second~ q{.length, }`"` ~first~`/`~second~ ` length mismatch"`q{);
				static assert (} ~first~ q{.length + } ~second~ q{.length == Args.length, `extraneous template parameters`);
			});
		}

	/* group a set of policy names with their default values 
	*/
	struct Policies (NamesAndDefaults...)
		{/*...}*/
			mixin ParameterSplitter!(
				q{PolicyNames}, is_string_param, 
				q{PolicyDefaults}, Not!(Or!(is_type, is_string_param)),
				NamesAndDefaults
			);

			alias PolicyTypes = staticMap!(type_of, PolicyDefaults);
		}

	/* declare a set of policies using a list of assignments, using defaults wherever a policy is not assigned 
		this template allows the setting and overriding of default policies, based on policy type, without regard to template parameter order
	*/
	mixin template PolicyAssignment (Policies, AssignedPolicies...)
		{/*...}*/
			static assert (is(typeof(this)), `mixin requires host struct`);

			static string generate_policy_assignments ()
				{/*...}*/
					import std.typetuple: 
						staticMap, staticIndexOf;

					import evx.meta: 
						type_of;

					alias AssignedTypes = staticMap!(type_of, AssignedPolicies);

					string code;

					with (Policies) foreach (i,_; PolicyNames)
						{/*...}*/
							static if (staticIndexOf!(PolicyTypes[i], AssignedTypes) >= 0)
								{/*...}*/
									immutable j  = staticIndexOf!(PolicyTypes[i], AssignedTypes);

									code ~= q{
										alias } ~PolicyNames[i]~ q{ = } ~PolicyTypes[i].stringof~`.`~AssignedPolicies[j].text~ q{;
									};
								}
							else code ~= q{
								alias } ~PolicyNames[i]~ q{ = } ~PolicyTypes[i].stringof~`.`~PolicyDefaults[i].text~ q{;
							};
						}

					return code;
				}

			mixin(generate_policy_assignments);
		}
		unittest {/*...}*/
			enum Policy {A, B}

			static struct Test (Args...)
				{mixin PolicyAssignment!(Policies!(`policy`, Policy.A), Args);}

			static assert (Test!().policy == Policy.A);
			static assert (Test!(Policy.A).policy == Policy.A);
			static assert (Test!(Policy.B).policy == Policy.B);
		}
}
