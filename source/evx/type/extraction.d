module evx.type.extraction;

private {/*imports}*/
	import std.traits;
	import std.typetuple;
	import std.range;

	import evx.math.logic;
	import evx.math.algebra;
	import evx.type.classification;
	import evx.type.introspection;
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

static alias ExprType (alias symbol) = typeof(symbol.identity);

// TODO DEPRECATE:

