module autodata.meta.traits;

private {/*import}*/
	import std.range.primitives: front;
	import std.traits;
	import std.typetuple;

	import autodata.meta.resolution;
}

/* test if identity transform is defined for a type 
*/
enum has_identity (T...) = is (typeof(T[0].identity));

// of symbols
/* test if a symbol is a type 
*/
enum is_type (T...) = is (T[0]);

/* test if a symbol is a class  
*/
enum is_class (T...) = is(T[0] == class);

/* test if a symbol is a template  
*/
enum is_template (T...) = __traits(isTemplate, T[0]);

/* test if a symbol refers to a function 
*/
template is_function (T...)
	{/*...}*/
		enum func () = isSomeFunction!(T[0]);
		enum temp () = isSomeFunction!(Instantiate!(T[0]));

		enum is_function = Match!(func, temp);
	}

/* test if a function is const 
*/
template is_const_function (T...)
	{/*...}*/
		enum yes () = staticIndexOf!(q{const}, __traits(getFunctionAttributes, T[0])) >= 0;
		enum no () = false;

		enum is_const_function = Match!(yes, no);
	}

/* test if a symbol has a numeric type 
*/
template has_numeric_type (T...)
	{/*...}*/
		static if (is (typeof(T[0]) == U, U))
			enum has_numeric_type = is_numeric!U;
		else enum has_numeric_type = false;
	}

/* test if a symbol has a string type
*/
template has_string_type (T...)
	{/*...}*/
		static if (is (typeof(T[0]) == U, U))
			enum has_string_type = is_string!U;
		else enum has_string_type = false;
	}

/* test if a variable has static storage class 
*/
template is_static_variable (T...)
	{/*...}*/
		static if (is (typeof(T[0]) == function))
			enum is_static_variable = false;
		else enum is_static_variable = is (typeof((){static f () {return &(T[0]);}}));
	}

// of types
/* test if a type supports comparison operators <, <=, >, >= 
*/
enum is_comparable (T...) = is (typeof(T[0].init < T[0].init) == bool);

/* test if a type is implicitly convertible to another 
*/
alias is_implicitly_convertible = isImplicitlyConvertible;

/*
	test if a type is a string 
*/
alias is_string = isSomeString;

/*
	test if a type is numeric 
*/
alias is_numeric = isNumeric;

/* test if a type is a builtin floating point type 
*/
alias is_floating_point = isFloatingPoint;

/* test if a type is a builtin integral type 
*/
alias is_integral = isIntegral;

/* test if a type is unsigned 
*/
alias is_unsigned = isUnsigned;

/* test if a type is signed 
*/
alias is_signed = isSigned;

/* test if a type is a range 
*/
enum is_range (R) = is (typeof(R.init.front.identity));

/* test if a range belongs to a given range category 
*/
alias is_input_range = std.range.isInputRange;
alias is_output_range = std.range.isOutputRange;
alias is_forward_range = std.range.isForwardRange;
alias is_bidirectional_range = std.range.isBidirectionalRange;
alias is_random_access_range = std.range.isRandomAccessRange;
alias has_length = std.range.hasLength;
