module evx.patterns.builder;

// REFACTOR
import evx.patterns.policy;

enum ChainBy {reference, address}

/* generate getters and chainable setters for a set of member declarations 
	if parameterless function pointers or delegates are given,
		this is treated as a dynamic property;
		meaning, the getters for them will invoke the function or delegate
			and pass along its return value
			instead of returning the function or delegate itself
*/
mixin template Builder (Args...)
	{/*...}*/
		import evx.math;

		static assert (is(typeof(this)), `mixin requires host struct`);

		private {/*import std}*/
			import std.traits:
				isDelegate, isFunctionPointer;
		}
		private {/*import evx}*/
			import evx.type;
		}

		alias Types = Filter!(is_type, Args);
		alias Names = Filter!(is_string_param, Args);

		static assert (is (Types == Cons!(Deinterleave!Args[0..$/2])) && Names == Deinterleave!Args[$/2..$],
			`Builder args must be in the form of a declaration list, not ` ~ Args.stringof
		);

		mixin PolicyAssignment!(DefaultPolicies!(`chain_by`, ChainBy.reference), Args);

		mixin(builder_property_declaration);
		mixin(builder_data_declaration);

		static {/*code generation}*/
			string return_this ()
				{/*...}*/
					static if (chain_by is ChainBy.reference)
						return q{return this;};
					else static if (chain_by is ChainBy.address)
						return q{return &this;};
				}
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
										} ~return_this~ q{
									}`}`q{
							};

							static if (not (isSomeFunction!Type))
								setter ~= q{
									auto ref } ~name~ q{ (Args...)(Args args)
										}`{`q{
											_}~ name ~q{ = } ~Type.stringof~ q{ (args);
											} ~return_this~ q{
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
					import evx.type: Map;

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
