module evx.meta.transformation;

private {/*import}*/
	import std.typecons;
	import evx.meta.resolution;
	import evx.meta.traits;
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

template Pair () 
	{/*...}*/
		template First (alias predicate)
			{/*...}*/
				alias First (alias pair) = predicate!(pair.first);
			}

		template Second (alias predicate)
			{/*...}*/
				alias Second (alias pair) = predicate!(pair.second);
			}

		template Both (alias predicate)
			{/*...}*/
				alias Both (alias pair) = predicate!(pair.first, pair.second);
			}
	}
template Pair (T...)
	if (T.length == 2)
	{/*...}*/
		static if (is_enumerable!(T[0]))
			enum first = T[0];
		else alias first = T[0];
		
		static if (is_enumerable!(T[1]))
			enum second = T[1];
		else alias second = T[1];
	}
