module indirect;

import utils;

/* 
	indexed, read-only, type-uniform indirection mechanism

	an IndirectRead can be set to read from the following types of sources:
		a unary static or member function taking an Index parameter
		a pointer
		a D slice, indexed by an Index parameter

	if the Index cannot be used to index into a D array (i.e. it does not convert to size_t)
	then setting the IndirectRead to a slice is statically disallowed.

	to read the redirected value with get(), an Index must be supplied even if the source type is a pointer
	(which would make the returned value independent of the supplied index)
*/
struct IndirectRead (T, Index)
	{/*...}*/
		public:
		public {/*getter}*/
			T get (Index index)
				in {/*...}*/
					assert (init, `IndirectRead uninitialized`);
				}
				body {/*...}*/
					switch (read_mode)
						{/*...}*/
							static if (can_index_arrays!Index)
								{/*...}*/
									case ReadMode.array:
										return passive[index];
								}
							case ReadMode.pointer:
								return *passive;
							default:
								return active (index);
						}
				}
		}
		public {/*read_from}*/
			void read_from (F)(F functor)
				if (is (F == T delegate(U), U : Index) 
				 || is (F == T function(U), U : Index))
				out {/*...}*/
					with (ReadMode)
					assert (read_mode != pointer && read_mode != array);
				}
				body {/*...}*/
					import std.functional;
					active = toDelegate (functor);
					debug init = true;
				}

			void read_from ()(T* pointer)
				{/*...}*/
					read_mode = ReadMode.pointer;
					passive = pointer;
					debug init = true;
				}

			void read_from ()(T[] array)
				if (can_index_arrays!Index)
				{/*...}*/
					read_mode = ReadMode.array;
					passive = array.ptr;
					debug init = true;
				}
		}
		private:
		private {/*data}*/
			union {/*...}*/
				T delegate(Index) active;
				struct {/*...}*/
					T* passive;
					ReadMode read_mode;
				}
			}
			enum ReadMode {pointer = 0x0, array = 0x1}
			debug bool init;

			static assert (ReadMode.sizeof + (T*).sizeof <= (T delegate(Index)).sizeof);
		}
		public debug {/*...}*/
			bool has_array ()
				{/*...}*/
					return read_mode == ReadMode.array;
				}
			bool has_pointer ()
				{/*...}*/
					return read_mode == ReadMode.pointer;
				}
			bool has_functor ()
				{/*...}*/
					return not (has_array || has_pointer);
				}
		}
	}
unittest
	{/*demo}*/
		import std.exception;
		struct NotIndex {}
		IndirectRead!(int, NotIndex) non_indexable;
		IndirectRead!(int, int) indexable;

		with (IndirectRead!(int,int).ReadMode)
			{/*...}*/
				static int test (int i) {return 0;}
				int x = 1;
				int[] y = [2,3,4];

				indexable.source (&test);
				assert (indexable.read_mode != pointer);
				assert (indexable.read_mode != array);
				assert (indexable.get (0) == 0);
				assert (indexable.get (1) == 0);

				indexable.source (&x);
				assert (indexable.read_mode == pointer);
				assert (indexable.get (0) == 1);
				assert (indexable.get (1) == 1);

				indexable.source (y);
				assert (indexable.read_mode == array);
				assert (indexable.get (0) == 2);
				assert (indexable.get (1) == 3);
				assert (indexable.get (2) == 4);
			}
		with (IndirectRead!(int,NotIndex).ReadMode)
			{/*...}*/
				static int test_ni (NotIndex i) {return 0;}
				int x = 1;
				int[] y = [2,3,4];

				non_indexable.source (&test_ni);
				assert (non_indexable.read_mode != pointer);
				assert (non_indexable.read_mode != array);
				assert (non_indexable.get (NotIndex.init) == 0);

				non_indexable.source (&x);
				assert (non_indexable.read_mode == pointer);
				assert (non_indexable.get (NotIndex.init) == 1);

				static assert (not(__traits(compiles, non_indexable.set (y))));
			}
	}

/*
	extend a host struct with a set of IndirectReads indexed by a common index
	and, for read-only access, syntactically indistinguishable from member fields
*/
mixin template Look (alias index, Args...)
	{/*...}*/
		mixin DeclarationSplitter!Args;
		alias Index = typeof(index);

		static string declarations ()
			{/*...}*/
				import std.conv;

				string code;

				foreach (i, name; Names)
					code ~= q{
						IndirectRead!(Types[} ~i.text~ q{], Index) _} ~name~ q{;
					};

				return code;
			}
		static string getters ()
			{/*...}*/
				string code;

				foreach (name; Names)
					code ~= q{
						@property auto } ~name~ q{ () }`{`q{
							return _} ~name~ q{.get (index);
						}`}`q{
					};

				return code;
			}
		static string setters ()
			{/*...}*/
				string code;

				foreach (name; Names)
					code ~= q{
						@property void read_} ~name~ q{_from (T)(T arg) }`{`q{
							_} ~name~ q{.read_from (arg);
						}`}`q{
					};

				return code;
			}

		mixin(declarations);
		mixin(getters);
		mixin(setters);
	}
unittest
	{/*demo}*/
		mixin(report_test!`look`);

		struct MyLook
			{/*...}*/
				int index;
				mixin Look!(index, 
					int, 	`a`, 
					ulong, 	`b`, 
					string, `c`,
				);
			}

		MyLook look;

		int a = -1;
		ulong b (int i) {return i;}
		string[] c = [`one`, `two`, `three`];

		look.set_a (&a);
		look.set_b (&b);
		look.set_c (c);

		look.index = 2;

		assert (look.a == -1);
		assert (look.b == 2);
		assert (look.c == `three`);
	}
