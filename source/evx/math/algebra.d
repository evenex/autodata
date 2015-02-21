module evx.math.algebra;

private {/*...}*/
	import std.conv;
	import std.traits;
	import std.range;
}

/* generic identity operator
*/
T identity (T)(T that)
	{/*...}*/
		return that;
	}

/* generate unity (1) for a given type 
	if T cannot be constructed from 1, then unity recursively attempts to call a constructor with unity for all field types
*/
template unity (T)
	{/*...}*/
		alias unity = group_element!1.of_group!T;
	}

/* generate zero (0) for a given type 
	if T cannot be constructed from 0, then zero recursively attempts to call a constructor with zero for all field types
*/
template zero (T)
	{/*...}*/
		alias zero = group_element!0.of_group!T;
	}

/* generate an group element for a given type 
*/
template group_element (Element...) // TODO pattern matching
	if (Element.length == 1)
	{/*...}*/
		enum element = Element[0];

		auto of_group (T)()
			{/*...}*/
				alias U = Unqual!T;

				static if (__traits(compiles, U(element)))
					return U(element);
				else static if (__traits(compiles, U(staticMap!(of_group, FieldTypeTuple!U))))
					return U(staticMap!(of_group, FieldTypeTuple!U));
				else static if (isStaticArray!U)
					{/*...}*/
						Unqual!U array;

						array[] = of_group!(ElementType!U);

						return array;
					}
				else static assert (0, `can't compute ` ~ element.text ~ ` for ` ~ U.stringof);
			}
	}
