module autodata.patterns.builder;

// REFACTOR - this came from evx, needs to be updated for autodata

/* generate getters and chainable setters for a set of member declarations 
	if parameterless function pointers or delegates are given,
		this is treated as a dynamic property;
		meaning, the getters for them will invoke the function or delegate
			and pass along its return value
			instead of returning the function or delegate itself
*/
mixin template Builder (Args...)
	{/*...}*/
		static assert (is(typeof(this)), `mixin requires host struct`);

		private {/*import}*/
			import std.traits:
				isDelegate, isFunctionPointer;
			import autodata.meta;
			import autodata.core;
		}

		alias Types = Filter!(is_type, Args);
		alias Names = Filter!(has_string_type, Args);

		static assert (is (Types == Cons!(Deinterleave!Args[0..$/2])) && Names == Deinterleave!Args[$/2..$],
			`Builder args must be in the form of a declaration list, not ` ~ Args.stringof
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
					import std.typecons: alignForSize;

					template underscored (string name)
						{enum underscored = `_`~name;}

					return alignForSize!Types ([Map!(underscored, Names)]);
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
