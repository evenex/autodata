module evx.patterns.builder;

/* generate getters and chainable setters for a set of member declarations 
*/
mixin template Builder (Args...)
	{/*...}*/
		import evx.math;//		import evx.math.logic;

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
