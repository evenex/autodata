module evx.type.extraction;

private {/*imports}*/
	import std.traits;
	import std.typetuple;
	import std.range;

	import evx.math.logic;
	import evx.math.algebra;
	import evx.type.classification;
	import evx.type.introspection;
	import evx.type.processing;
}

/* extract an array of identifiers for members of T which match the given UDA tag 
*/
template collect_members (T, alias attribute)
	{/*...}*/
		static string[] collect_members ()
			{/*...}*/
				immutable string[] collect (members...) ()
					{/*...}*/
						static if (members.length == 0)
							return [];
						else static if (members[0] == "this")
							return collect!(members[1..$]);
						else static if (has_attribute!(T, members[0], attribute))
							return members[0] ~ collect!(members[1..$]);
						else return collect!(members[1..$]);
					}

				return collect!(__traits (allMembers, T));
			}
	}
	unittest {/*...}*/
		enum Tag;
		struct Test {@Tag int x; @Tag int y; int z;}

		static assert (collect_members!(Test, Tag) == [`x`, `y`]);
	}

template ExprType (alias symbol)
	{/*...}*/
		 alias Identity  () = typeof(symbol.identity);
		 alias Resolved  () = typeof(symbol ());
		 alias Forwarded () = typeof(symbol);

		 alias ExprType = Match!(Identity, Resolved, Forwarded);
	}

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

alias Parameters = std.traits.ParameterTypeTuple;
alias ReturnType = std.traits.ReturnType;

// TODO DEPRECATE:

