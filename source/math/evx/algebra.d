module evx.algebra;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.range;
		import std.algorithm;
		import std.conv;
	}
}

pure nothrow:

/* generate unity (1) for a given type 
	if T cannot be constructed from 1, then unity recursively attempts to call a constructor with unity for all field types
*/
template unity (T)
	{/*...}*/
		alias unity = identity_element!1.of_type!T;
	}

/* generate zero (0) for a given type 
	if T cannot be constructed from 0, then zero recursively attempts to call a constructor with zero for all field types
*/
template zero (T)
	{/*...}*/
		alias zero = identity_element!0.of_type!T;
	}

/* generate an algebraic identity element for a given type 
*/
template identity_element (Element...)
	if (Element.length == 1)
	{/*...}*/
		enum element = Element[0];

		auto of_type (T)()
			{/*...}*/
				static if (__traits(compiles, T(element)))
					return T(element);
				else static if (isAggregateType!T)
					return T(staticMap!(of_type, FieldTypeTuple!T));
				else static if (isStaticArray!T)
					{/*...}*/
						Unqual!T array;

						array[] = of_type!(ElementType!T);

						return array;
					}
				else static assert (0, `can't compute ` ~element.text~ ` for ` ~T.stringof);
			}
	}
