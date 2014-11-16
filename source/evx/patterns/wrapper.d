module evx.patterns.wrapper;

private {/*imports}*/
	import std.traits;

	import evx.range;
	import evx.math;
}

template exists_ref_overload (T, string func)
	{/*...}*/
		static code ()()
			{/*...}*/
				string code = `false`;

				foreach (overload; __traits(getOverloads, T, func))
					static if (mixin(q{returns_ref!(T.} ~func~ q{)}))
						code = `true`;

				return q{enum exists_ref_overload = } ~code~ q{;};
			}

		static if (mixin(q{isSomeFunction!(T.} ~func~ q{)}))
			mixin(code);
		else enum exists_ref_overload = false;
	}
template returns_ref (alias func)
	{/*...}*/
		enum returns_ref = __traits(getFunctionAttributes, func)[].contains ("ref");
	}

mixin template Wrapped (T)
	{/*...}*/
		static {/*dependencies}*/
			import std.traits;
			import evx.range;
		}

		T wrapped;
		alias wrapped this;

		static wrapper_code ()
			{/*...}*/
				string[] code;

				foreach (member; __traits(allMembers, T))
					static if (`opAssign` `__ctor`.contains (member))
						continue;
					else static if (exists_ref_overload!(T, member))
						{/*...}*/
							foreach (overload; __traits(getOverloads, T, member))
								{/*...}*/
									enum signature = q{auto ref } ~member~ q{ (} ~ParameterTypeTuple!overload.stringof[1..$-1]~ q{ args)}; // TODO autodecl

									static if (returns_ref!overload)
										code ~= q{
											} ~signature~ q{
												}`{`q{
													wrapped.} ~member~ q{ (args);

													return this;
												}`}`q{
										};
									else code ~= q{
										} ~signature~ q{
											}`{`q{
												return wrapped.} ~member~ q{ (args);
											}`}`q{
									};
								}
						}

				return code.join.to!string;
			}

		//mixin(wrapper_code); // BUG thrashes overload set - apparently these declared functions qualify for UFCS?

		//pragma(msg, wrapper_code);
	}
