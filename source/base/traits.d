module evx.traits;

private {/*import std}*/
	import std.typetuple:
		allSatisfy, anySatisfy;

	import std.traits:
		isSomeFunction, isSomeString,
		hasMember,
		ParameterTypeTuple, ReturnType;
}
private {/*import evx}*/
	import evx.logic:
		not;
}

public {/*type identification}*/
	/* test if a template argument is a type 
	*/
	template is_type (T...) if (T.length == 1)
		{/*...}*/
			enum is_type = is (T[0]);
		}

	/* test if a template argument is an aliased symbol 
	*/
	template is_alias (T...) if (T.length == 1)
		{/*...}*/
			enum is_alias = __traits(compiles, typeof (T[0])) 
				&& (
					not (
						is_numerical_param!(T[0])
						|| is_string_param!(T[0])
					) || __traits(compiles, &T[0])
				);
		}
		unittest {/*...}*/
			static assert (not (is_alias!int));
			static assert (not (is_alias!`hello`));
			static assert (not (is_alias!666));

			int x;
			static assert (is_alias!x);

			int y () {return 1;}
			static assert (is_alias!y);
		}

	/* test if a template argument is a number 
	*/
	template is_numerical_param (T...) if (T.length == 1)
		{/*...}*/
			enum is_numerical_param = __traits(compiles, T[0] == 0);
		}

	/* test if a template argument is a string 
	*/
	template is_string_param (T...) if (T.length == 1)
		{/*...}*/
			static if (__traits(compiles, typeof(T[0])))
					enum is_string_param = isSomeString!(typeof(T[0]));
			else enum is_string_param = false;
		}

	/* test if a given type matches another 
	*/
	template is_type_of (T)
		{/*...}*/
			template is_type_of (U)
				{/*...}*/
					enum is_type_of = is (T == U);
				}
		}

	/* test if type has a field with a given type and name
	*/
	template has_field (T, Field, string name)
		{/*...}*/
			static if (hasMember!(T, name))
				enum has_field = is (Field : typeof(__traits(getMember, T, name)));
			else enum has_field = false;
		}

	/* test if a member has an attribute 
	*/
	template has_attribute (T, string member, Attribute...)
		if (Attribute.length == 1)
		{/*...}*/
			static if (member == `this`)
				enum has_attribute = false;
			else const bool has_attribute ()
				{/*...}*/

					static if (is_type!(Attribute[0]))
						alias query = Attribute[0];
					else immutable query = Attribute[0];

					foreach (attribute; __traits (getAttributes, __traits(getMember, T, member)))
						{/*...}*/
							static if (allSatisfy!(is_type, attribute, query))
								return is (query == attribute);
							else static if (not (anySatisfy!(is_type, attribute, query)))
								return query == attribute;
							else continue;
						}

					return false;
				}
		}
		unittest {/*...}*/
			enum Tag;
			immutable value = 666;

			static struct Test
				{/*...}*/
					@Test int x;
					@(`test`) int y;
					@Tag int z;

					@(666) int u;
					@value int v;
				}

			static assert (has_attribute!(Test, `x`, Test));
			static assert (has_attribute!(Test, `y`, `test`));
			static assert (has_attribute!(Test, `z`, Tag));

			// value-types compare by value, not label
			static assert (has_attribute!(Test, `u`, 666));
			static assert (has_attribute!(Test, `u`, value));
			static assert (has_attribute!(Test, `v`, 666));
			static assert (has_attribute!(Test, `v`, value));
		}

	/* for each of T's fields, test if U has a compatible field 
	*/
	template is_embeddable_in (T, U)
		{/*...}*/
			const bool is_embeddable_in ()
				{/*...}*/
					foreach (member; __traits (allMembers, T))
						{/*...}*/
							static if (isSomeFunction!(__traits(getMember, T, member)))
								continue;
							else {/*...}*/
								static if (not (is (typeof (__traits(getMember, T, member)))))
									continue;
								else {/*...}*/
									alias Field = typeof (__traits(getMember, T, member));

									static if (has_field!(U, Field, member))
										continue;
									else return false;
								}
							}

						}
					return true;
				}
		}
		unittest {/*...}*/
			struct T1 {int x; int y; int z;}
			struct T2 {int x; int y; int z;}
			struct T3 {long x; long y; long z;}

			static assert (is_embeddable_in!(T1, T2));
			static assert (is_embeddable_in!(T1, T3));
			static assert (not (is_embeddable_in!(T3, T1)));
		}
}
public {/*type capabilities}*/
	/* test if a type is comparable using the < operator 
	*/
	template is_comparable (T...)
		if (T.length == 1)
		{/*...}*/
			static if (is (T[0]))
				{/*...}*/
					const T[0] a, b;
					enum is_comparable = __traits(compiles, a < b);
				}
			else enum is_comparable = false;
		}

	/* test if a type has slicing, more permissive than std.range.hasSlicing 
	*/
	template is_sliceable (T)
		{/*...}*/
			enum is_sliceable = __traits(compiles, T.init[0..1]);
		}

	/* test if a type is indexable 
	*/
	template is_indexable (T)
		{/*...}*/
			enum is_indexable = __traits(compiles, T.init[0]);
		}

	/* test if a type can index D's built-in arrays and slices 
	*/
	template can_index_arrays (T)
		{/*...}*/
			enum can_index_arrays = __traits(compiles, T[].init[T.init]);
		}
}
public {/*function characterization}*/
	/* test if a function is unary 
	*/
	template is_unary_function (U...)
		if (U.length == 1)
		{/*...}*/
			static if (isSomeFunction!(U[0]))
				{/*...}*/
					alias Function = U[0];
					alias Params = ParameterTypeTuple!Function;

					static if (Params.length == 1)
						enum is_unary_function = true;
					else enum is_unary_function = false;
				}
			else enum is_unary_function = false;
		}

	/* test if a function is binary 
	*/
	template is_binary_function (U...)
		if (U.length == 1)
		{/*...}*/
			static if (isSomeFunction!(U[0]))
				{/*...}*/
					alias Function = U[0];
					alias Params = ParameterTypeTuple!Function;

					static if (Params.length == 2)
						enum is_binary_function = true;
					else enum is_binary_function = false;
				}
			else enum is_binary_function = false;
		}

	/* test if T is a member function 
	*/
	template is_member_function (T...)
		{/*...}*/
			static if (T.length == 1)
				enum is_member_function = isSomeFunction!(T[0])
					&& not (isFunctionPointer!(T[0])
						|| isDelegate!(T[0])
					);
			else enum is_member_function = false;
		}

	/* test if function takes only pointer arguments 
	*/
	template takes_pointer (alias func)
		{/*...}*/
			const bool takes_pointer ()
				{/*...}*/
					return allSatisfy!(isPointer, ParameterTypeTuple!func);
				}
		}

	/* test if a function behaves syntactically as a hash 
	*/
	template is_hashing_function (T)
		{/*...}*/
			template is_hashing_function (U...)
				if (U.length == 1)
				{/*...}*/
					static if (is_unary_function!(U[0]))
						{/*...}*/
							alias Function = U[0];

							enum is_hashing_function = 
								is (ParameterTypeTuple!Function == TypeTuple!T)
								&& is_comparable!(ReturnType!Function);
						}
					else enum is_hashing_function = false;
				}
		}

	/* test if a function behaves syntactically as a comparator 
	*/
	template is_comparison_function (U...)
		if (U.length == 1)
		{/*...}*/
			static if (is_binary_function!(U[0]))
				{/*...}*/
					alias Function = U[0];
					alias Params = ParameterTypeTuple!Function;

					static if (is (Params[0] == Params[1]))
						{/*...}*/
							alias Return = ReturnType!Function;

							static if (is (bool: Return) || is (Return: bool))
								enum is_comparison_function = true;
							else enum is_comparison_function = false;
						}
					else enum is_comparison_function = false;
				}
			else enum is_comparison_function = false;
		}
}
public {/*program structure}*/
	/* test if a member of T is publicly accessible 
	*/
	template is_accessible (T, string member)
		{/*...}*/
			enum is_accessible = mixin(q{__traits(compiles, T.} ~member~ q{)});
		}
}
