module evx.math.algebra;
version(none):

private {/*...}*/
	import std.conv;
	import std.traits;
	import std.range;

	import evx.type;
}

// TODO update style
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
				else static if (__traits(compiles, U(Map!(of_group, FieldTypeTuple!U))))
					return U(Map!(of_group, FieldTypeTuple!U));
				else static if (isStaticArray!U)
					{/*...}*/
						Unqual!U array;

						array[] = of_group!(ElementType!U);

						return array;
					}
				else {/*}*/
				pragma(msg, Map!(of_group, FieldTypeTuple!U));
					
				static assert (0, `can't compute ` ~ element.text ~ ` for ` ~ U.stringof);
				}
			}
	}

	/// REVIEW REVIEW REVIEW this whole module needs work

auto coset (G)(G.Element element, G group)
	{/*...}*/
		return map!((g,h) => h*g)
			(group[], element)
			.underlying_set;
	}
auto coset (G)(G group, G.Element element)
	{/*...}*/
		return map!((g,h) => g*h)
			(group[], element)
			.underlying_set;
	}
auto coset (G,H)(G g, H h)
	{/*...}*/
		return outer_product (g,h).along!0.map!underlying_set;
	}

// REVIEW this is more of a general thing
auto outer_product (R,S)(R r, S s)
	{/*...}*/
		return r.by (s)
			.map!((x,y) => x*y);
	}
auto underlying_set (R)(R r)
	{/*...}*/
		return r.unique.sort.unique;
	}

struct QuotientGroup (G, alias classification)
	{/*...}*/
		this (G group)
			out {/*...}*/
				assert (equivalence_classes.values == group.coset (equivalence_classes[G.Element.identity_element]));
				// REVIEW maybe not range equivalence like this but set equivalence at least
			}
			body {/*...}*/
				this.equivalence_classes = group[]
					.map!(adjoin!(
						classification,
						identity
					));
					// TODO the type of equivalence classes
					// should put (a,z),(a,y),(b,x),(c,w)
					// into [a:[z,y], b:[x], c[w]]

				this.group = typeof(group)(equivalence_classes.keys);
			}

		G.Element[][typeof(classification (G.Element.init))] equivalence_classes;
		Group!(G.Element, G.operation) group;
	}
auto quotient_group (G, alias classification)(G group)
	{/*...}*/
		return QuotientGroup!(G, classification)(group);
	}
