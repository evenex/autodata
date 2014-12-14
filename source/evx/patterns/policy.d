module evx.patterns.policy;

private {/*imports}*/
	import std.typetuple;

	import evx.codegen;
	import evx.type;
	import evx.math;
}

/* group a set of policy names with their default values 
*/
struct DefaultPolicies (NamesAndDefaults...)
	{/*...}*/
		mixin ParameterSplitter!(
			q{PolicyNames}, is_string_param, 
			q{PolicyDefaults}, not!(or!(is_type, is_string_param)),
			NamesAndDefaults
		);

		alias PolicyTypes = staticMap!(type_of, PolicyDefaults);
	}

/* declare a list of policies from the union of assigned policy values and default policies,
	where the assigned values override the defaults

	this template allows the specification of default policies, based on policy enum type, without regard to template parameter order
*/
mixin template PolicyAssignment (DefaultPolicies, AssignedPolicies...)
	{/*...}*/
		static assert (is(typeof(this)), `mixin requires host struct`);

		static string generate_policy_assignments ()
			{/*...}*/
				import std.typetuple: 
					staticMap, staticIndexOf;

				import evx.type: 
					type_of;

				alias AssignedTypes = staticMap!(type_of, AssignedPolicies);

				string code;

				with (DefaultPolicies) foreach (i,_; PolicyNames)
					{/*...}*/
						import std.conv;

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
			{mixin PolicyAssignment!(DefaultPolicies!(`policy`, Policy.A), Args);}

		static assert (Test!().policy == Policy.A);
		static assert (Test!(Policy.A).policy == Policy.A);
		static assert (Test!(Policy.B).policy == Policy.B);
	}
