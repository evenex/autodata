module evx.traits.introspection;

private {/*imports}*/
	import std.range;
	import std.typetuple;

	import evx.math.logic;
	import evx.traits.classification;
}

/* test if type has a field with a given type and name 
*/
template has_field (T, Field, string name)
	{/*...}*/
		static if (hasMember!(T, name))
			enum has_field = is (Field : typeof(__traits(getMember, T, name)));
		else enum has_field = false;
	}

/* test if a member has an attribute 
*/
template has_attribute (T, string member, Attribute...)
	if (Attribute.length == 1)
	{/*...}*/
		static if (member.empty)
			enum has_attribute = false;
		else static if (member == `this` || not (is_accessible!(T, member)))
			enum has_attribute = false;
		else bool has_attribute ()
			{/*...}*/
				static if (is_type!(Attribute[0]))
					alias query = Attribute[0];
				else immutable query = Attribute[0];

				foreach (attribute; __traits (getAttributes, __traits(getMember, T, member)))
					{/*...}*/
						static if (allSatisfy!(is_type, attribute, query))
							return is (query == attribute);
						else static if (not (anySatisfy!(is_type, attribute, query)))
							return query == attribute;
						else continue;
					}

				return false;
			}
	}
	unittest {/*...}*/
		enum Tag;
		immutable value = 666;

		static struct Test
			{/*...}*/
				@Test int x;
				@(`test`) int y;
				@Tag int z;

				@(666) int u;
				@value int v;
			}

		static assert (has_attribute!(Test, `x`, Test));
		static assert (has_attribute!(Test, `y`, `test`));
		static assert (has_attribute!(Test, `z`, Tag));

		// value-types compare by value, not label
		static assert (has_attribute!(Test, `u`, 666));
		static assert (has_attribute!(Test, `u`, value));
		static assert (has_attribute!(Test, `v`, 666));
		static assert (has_attribute!(Test, `v`, value));
	}

/* test if a member of T is publicly accessible 
*/
template is_accessible (T, string member)
	{/*...}*/
		enum is_accessible = mixin(q{__traits(compiles, T.} ~member~ q{)});
	}
