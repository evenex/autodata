module evx.patterns.library;
version(none):

/* generate a member load_library function which automatically looks up member extern (C) function pointer identifiers in linked C libraries  
	due to the way dmd processes mixins, function pointers must be declared above the mixin.
	if the function is not found, the program will halt. otherwise, the function pointer is set to the library function
*/
mixin template DynamicLibrary ()
	{/*...}*/
		static assert (is(typeof(this)), `mixin requires host struct`);

		import evx.type;
		import evx.math.logic;
		import std.traits;

		static private {/*code generation}*/
			string generate_library_loader ()
				{/*...}*/
					string signature = q{
						void load_library (Args...)(Args file_names)
							if (All!(isSomeString, Args))
					};

					string code = q{
						import std.c.linux.linux;
						import evx.misc.utils;

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

				static if (__traits(compiles, mixin(q{Parameters!(} ~op~ q{)})))
					{/*enum error}*/
						mixin(q{
							alias Params = Parameters!(} ~op~ q{);
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
