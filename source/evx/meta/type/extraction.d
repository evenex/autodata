module evx.type.extraction;

private {/*imports}*/
	import std.traits;
	import std.typetuple;
	import std.range;

	import evx.math.logic;
	import evx.traits.classification;
	import evx.traits.introspection;
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

/* build a TypeTuple of all nested struct and class definitions within T 
*/
template get_substructs (T)
	{/*...}*/
		private template get_substruct (T)
			{/*...}*/
				template get_substruct (string member)
					{/*...}*/
						immutable name = q{T.} ~member;

						static if (member.empty)
							enum get_substruct = 0;
						
						else static if (mixin(q{is (} ~name~ q{)})
							&& is_accessible!(T, member)
							&& not (mixin(q{is (} ~name~ q{ == T)}))
						) mixin(q{
							alias get_substruct = T.} ~member~ q{;
						});
						else enum get_substruct = 0;
					}
			}

		alias get_substructs = Filter!(Not!is_numerical_param, 
			staticMap!(get_substruct!T, __traits(allMembers, T))
		);
	}
	unittest {/*...}*/
		struct Test {enum a = 0; int b = 0; struct InnerStruct {} class InnerClass {}}

		foreach (i, T; TypeTuple!(Test.InnerStruct, Test.InnerClass))
			static assert (staticIndexOf!(T, get_substructs!Test) == i);
	}

/* build a string tuple of all assignable members of T 
*/
template get_assignable_members (T)
	{/*...}*/
		private template is_assignable (T)
			{/*...}*/
				template is_assignable (string member)
					{/*...}*/
						enum is_assignable = __traits(compiles,
							(T type) {/*...}*/
								mixin(q{
									type.} ~member~ q{ = typeof(type.} ~member~ q{).init;
								});
							}
						);
					}
			}

		alias get_assignable_members = Filter!(is_assignable!T, __traits(allMembers, T));
	}
	unittest {/*...}*/
		struct Test {int a; const int b; immutable int c; enum d = 0; int e (){return 1;}}

		static assert (get_assignable_members!Test == TypeTuple!`a`);
	}

template IndexTypes (R)
	{/*...}*/
		static if (hasMember!(R, `opIndex`))
			alias IndexTypes = staticMap!(FirstParameter, __traits(getOverloads, R, `opIndex`));
		else static if (__traits(compiles, R.init[0]))
			alias IndexTypes = TypeTuple!size_t;
		else alias IndexTypes = void;
	}

/* get the type of a function's first parameter 
*/
template FirstParameter (alias func)
	{/*...}*/
		static if (ParameterTypeTuple!func.length > 0)
			alias FirstParameter = ParameterTypeTuple!func[0];
		else alias FirstParameter = void;
	}

template DollarType (R)
	{/*...}*/
		static if (__traits(compiles, R.init[$]))
			{/*...}*/
				static if (hasMember!(R, `opDollar`))
					alias DollarType = Unqual!(ReturnType!(R.opDollar));
				else alias DollarType = size_t;
			}
		else alias DollarType = void;
	}