module autodata.core.tuple;

private {/*import}*/
	import std.typecons;
	import autodata.meta;
}

alias Tuple = std.typecons.Tuple;
alias tuple = std.typecons.tuple;

template Flatten (T...)
	{/*...}*/
		static if (is (T[0] == Tuple!U, U...))
			alias Flatten = Cons!(Flatten!U, Flatten!(T[1..$]));

		else static if (is (T[0] == U, U))
			alias Flatten = Cons!(U, Flatten!(T[1..$]));

		else alias Flatten = Cons!();
	}
auto flatten (T)(T x)
	{/*...}*/
		return (*cast(Tuple!(Flatten!T)*)&x);
	}
