module spacecadet.patterns.library;

/* generate a member load_library function which automatically looks up member extern (C) function pointer identifiers in linked C libraries  
	due to the way dmd processes mixins, function pointers must be declared above the mixin.
	if the function is not found, the program will halt. otherwise, the function pointer is set to the library function
*/
mixin template DynamicLibrary ()
	{/*...}*/
		static private {/*code generation}*/
			string generate_library_loader ()
				{/*...}*/
					enum signature = q{
						shared static this ()
					};
					
					string code = q{
						import std.c.linux.linux;
					};

					foreach (symbol; __traits (allMembers, typeof(this)))
						static if (is_static_C_function!symbol)
							code ~= q{
								} ~symbol~ q{ = cast(typeof(} ~symbol~ q{)) dlsym (lib, } `"`~symbol~`"` q{);

								assert (} ~symbol~ q{ !is null, "couldn't load C library function "} `"`~symbol~`"` q{);
							};

					return signature~ `{` ~code~ `}`;
				}
		}

		mixin(generate_library_loader);

		static void verify_function_call (string op, CArgs...)(CArgs c_args)
			{/*...}*/
				import spacecadet.meta: Domain;

				enum generic_error = `call to ` ~op~ ` (` ~CArgs.stringof~ `) failed to compile`;

				static if (__traits(compiles, mixin(q{Domain!(} ~op~ q{)})))
					{/*enum error}*/
						mixin(q{
							alias Params = Domain!(} ~op~ q{);
						});

						static if (not (is (CArgs == Params)))
							enum error = `cannot call ` ~op~ ` ` ~Params.stringof~ ` with ` ~CArgs.stringof;
						else enum error = generic_error;
					}
				else enum error = generic_error;

				static assert (__traits(compiles, mixin(op~ q{ (c_args)})), error);
			}

		template is_static_C_function (string name)
			{/*...}*/
				import std.range: empty;

				import std.traits: 
					isFunctionPointer, functionLinkage;

				alias subject = Cons!(__traits(getMember, typeof(this), name));

				static if (name.empty)
					enum is_static_C_function = false;
				else static if (isFunctionPointer!subject)
					enum is_static_C_function = is_static_variable!subject && functionLinkage!subject == "C";
				else enum is_static_C_function = false;
			}
	}
