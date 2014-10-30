module evx.traits.concepts;

private {/*imports}*/
	import std.typetuple;
	import evx.traits.classification;
}

/* bind a set of trait names to their definitions and mixin to produce a queryable Traits struct 
	the Traits struct can be queried for the definitions of each trait and whether or not a given trait is satisfied
	trait satisfied? => pragma(msg, TraitsStruct.trait)
	trait definition => pragma(msg, TraitsStruct.definition!"trait")

	a trait name is a string forming a valid D symbol
	a trait definition is a code snippet that compiles if and only if the trait is satisfied

	the convenience function "info" is defined to show all traits and their statuses via pragma(msg, TraitsStruct.info)

	trait requirements can be enforced by instantiating the "require" member template
*/
mixin template Traits (Defs...)
	if (allSatisfy!(is_string_param, Defs))
	{/*...}*/
		import std.typetuple;
		import evx.math.logic;

		static:
		public:
		public {/*interface}*/
			template definition (string trait)
				{/*...}*/
					enum definition = Definitions[staticIndexOf!(trait, Names)];
				}

			string info ()
				{/*...}*/
					string info;

					foreach (i, trait; Names)
						mixin(q{
							info ~= trait~ ` = ` ~(} ~trait~ q{? `true`:`false`)~ "\n";
						});

					return info;
				}

			template require (Host, string trait, alias for_interface)
				if (is_trait_name!trait)
				{/*...}*/
					mixin(q{
						static assert (} ~trait~ q{, 
							Host.stringof~ ` must support {` ~definition!trait~ `} to enable ` ~__traits(identifier, for_interface)~ `.`
						);
					});
				}
		}
		private:
		private {/*parsing}*/
			template is_trait_name (string trait)
				{/*...}*/
					enum is_trait_name = staticIndexOf!(trait, Defs) % 2 == 0;
				}
			alias is_trait_definition = not!is_trait_name;
				
			alias Names = Filter!(is_trait_name, Defs);
			alias Definitions = Filter!(is_trait_definition, Defs);
		}
		private {/*code gen}*/
			string code ()
				in {/*...}*/
					foreach (i, txt; Defs) 
						static assert (staticIndexOf!(txt, Defs) == i, `duplicate trait definitions in ` ~Defs.stringof);
				}
				body {/*...}*/
					string code;

					foreach (i, trait; Names) 
						code ~= q{
							enum } ~trait~ q{ = __traits(compiles, }`{` ~Definitions[i]~ `}`q{);
						};

					return code;
				}

			mixin(code);
		}
	}