module evx.type.classification;

private {/*imports}*/
	import std.traits;

	import evx.math.logic;
	import evx.math.algebra;
}

/* test if a symbol is a type 
*/
enum is_type (T...) = is (T[0]);

/* test if a symbol is a class  
*/
enum is_class (T...) = is(T[0] == class);

/* test if a symbol is a template  
*/
enum is_template (T...) = __traits(isTemplate, T[0]);

/* test if a type is a builtin integral type
*/
alias is_integral = isIntegral;

/* test if a type is a builtin floating point type
*/
alias is_floating_point = isFloatingPoint;

/* test if a type is implicitly convertible to another
*/
alias is_implicitly_convertible = isImplicitlyConvertible;

/* test if a type defines an identity
*/
enum has_identity (T...) = is (typeof(identity (T[0]))); // BUG ANOTHER UFCS FAILURE!!!!

/* test if an expression can be made into an enum
*/
enum is_enumerable (T...) = is (typeof((){enum x = T[0];}()));

/* test if a template argument is an aliased symbol 
*/
template is_alias (T...)  // TODO deprecate
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
enum is_numerical_param (T...) = __traits(compiles, T[0] == 0);

/* test if a template argument is a string 
*/
template is_string_param (T...)
	if (T.length == 1)
	{/*...}*/
		static if (__traits(compiles, typeof(T[0])))
				enum is_string_param = isSomeString!(typeof(T[0]));
		else enum is_string_param = false;
	}

/* test if a type is a tuple 
*/
enum is_tuple (T...)= is(typeof(τ(T[0].init.tupleof)) == T[0]);

/* generate a predicate to test if a given type matches another 
*/
template is_type_of (T)
	{/*...}*/
		enum is_type_of (U) = is (T == U);
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

/* test the arity of a function 
*/
template is_n_ary_function (size_t n, U...)
	if (U.length == 1)
	{/*...}*/
		static if (isSomeFunction!(U[0]))
			{/*...}*/
				alias Function = U[0];
				alias Params = ParameterTypeTuple!Function;

				static if (Params.length == n)
					enum is_n_ary_function = true;
				else enum is_n_ary_function = false;
			}
		else enum is_n_ary_function = false;
	}
template is_nullary_function (U...)
	{/*...}*/
		enum is_nullary_function = is_n_ary_function!(0, U);
	}
template is_unary_function (U...)
	{/*...}*/
		enum is_unary_function = is_n_ary_function!(1, U);
	}
template is_binary_function (U...)
	{/*...}*/
		enum is_binary_function = is_n_ary_function!(2, U);
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
				return All!(isPointer, ParameterTypeTuple!func);
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
