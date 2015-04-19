module autodata.meta.transformation;

private {/*import}*/
	import std.typecons;
	import autodata.meta.resolution;
	import autodata.meta.traits;
}

alias Identity (T...) = T[0]; 

alias Select = std.typecons.Select;

template ExprType (alias symbol)
	{/*...}*/
		 alias Identity  () = typeof(symbol.identity);
		 alias Resolved  () = typeof(symbol ());
		 alias Forwarded () = typeof(symbol);

		 alias ExprType = Match!(Identity, Resolved, Forwarded);
	}

alias Unqual = std.traits.Unqual;

template Unwrapped (T)
	{/*...}*/
		static if (is (T == W!U, alias W, U))
			alias Unwrapped = U;
		else alias Unwrapped = T;
	}
	unittest {/*...}*/
		static struct T {}
		static struct U (T) {}

		alias V = U!T;
		alias W = U!(U!T);

		static assert (is (Unwrapped!T == T));
		static assert (is (Unwrapped!V == T));
		static assert (is (Unwrapped!W == V));
		static assert (is (Unwrapped!(Unwrapped!W) == T));
	}

template InitialType (T)
	{/*...}*/
		static if (is (T == W!U, alias W, U))
			alias InitialType = InitialType!U;
		else alias InitialType = T;
	}
	unittest {/*...}*/
		static struct T {}
		static struct U (T) {}

		alias V = U!T;
		alias W = U!(U!T);

		static assert (is (InitialType!T == T));
		static assert (is (InitialType!V == T));
		static assert (is (InitialType!W == T));
	}

alias CommonType = std.traits.CommonType;

template Compose (Templates...)
	{/*...}*/
		static if (Templates.length > 1)
			{/*...}*/
				alias T = Templates[0];
				alias U = Compose!(Templates[1..$]);

				alias Compose (Args...) = T!(U!(Args));
			}
		else alias Compose = Templates[0];
	}
	unittest {/*...}*/
		alias ArrayOf (T) = const(T[]);

		alias C0 = Compose!(ElementType, ArrayOf, Unqual);
		alias C1 = Compose!(Unqual, ArrayOf, ElementType);

		static assert (is (C0!(int[5]) == int[5]));
		static assert (is (C1!(int[5]) == int[]));
	}
