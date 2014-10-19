module evx.patterns.policy;

private {/*imports}*/
	import std.typetuple;

	import evx.codegen.declarations;
	import evx.traits.classification;
	import evx.type.processing;
	import evx.math.logic;
}

/* group a set of policy names with their default values 
*/
struct DefaultPolicies (NamesAndDefaults...)
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
mixin template PolicyAssignment (DefaultPolicies, AssignedPolicies...)
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
