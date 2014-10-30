module evx.traits.classification;

private {/*imports}*/
	import std.traits;

	import evx.math.logic;
}

/* test if a template argument is a type 
*/
template is_type (T...) 
	if (T.length == 1)
	{/*...}*/
		enum is_type = is (T[0]);
	}

/* test if a template argument is an aliased symbol 
*/
template is_alias (T...) 
	if (T.length == 1)
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
template is_numerical_param (T...) 
	if (T.length == 1)
	{/*...}*/
		enum is_numerical_param = __traits(compiles, T[0] == 0);
	}

/* test if a template argument is a string 
*/
template is_string_param (T...)  // TODO belongs (along with its ilk) in META
	if (T.length == 1)
	{/*...}*/
		static if (__traits(compiles, typeof(T[0])))
				enum is_string_param = isSomeString!(typeof(T[0]));
		else enum is_string_param = false;
	}

/* test if a type is a tuple 
*/
template is_tuple (T...)
	if (T.length == 1)
	{/*...}*/
		enum is_tuple = is(typeof(τ(T[0].init.tupleof)) == T[0]);
	}

/* generate a predicate to test if a given type matches another 
*/
template is_type_of (T)
	{/*...}*/
		template is_type_of (U)
			{/*...}*/
				enum is_type_of = is (T == U);
			}
	}

/* generate a predicate to test if a type defines a given enum 
*/
template has_trait (string trait)
	{/*...}*/
		template has_trait (T...)
			if (T.length == 1)
			{/*...}*/
				static if (is_type!(T[0]))
					{/*...}*/
						alias U = T[0];

						mixin(q{
							enum has_trait = is (U.} ~trait~ q{ == enum);
						});
					}
				else enum has_trait = false;

			}
	}

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
