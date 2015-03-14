module evx.meta.traits;

private {/*import}*/
	import std.traits;
	import evx.meta.resolution;
	import evx.meta.list;
}

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
		enum yes () = Contains!(q{const}, __traits(getFunctionAttributes, T[0]));
		enum no () = false;

		enum is_const_function = Match!(yes, no);
	}

/* test if a type supports comparison operators <, <=, >, >= 
*/
enum is_comparable (T...) = is (typeof((){auto x = T[0].init; return x < x? x > x? x <= x : x >= x : true;}));

/* test if a type is implicitly convertible to another 
*/
alias is_implicitly_convertible = isImplicitlyConvertible;

/* test if an expression can be made into an enum 
*/
enum is_enumerable (T...) = is (typeof((){enum x = T[0];}()));
