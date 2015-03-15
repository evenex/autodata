module spacecadet.meta.introspection;

private {/*import}*/
	import std.traits;
	import std.range;

	import spacecadet.meta.list;
}

/* get the domain (parameter) types of a function 
*/
alias Domain = std.traits.ParameterTypeTuple;

/* get the codomain (return) type of a function 
*/
alias Codomain = std.traits.ReturnType;

/* get the underlying types of the fields of a type 
*/
alias FieldTypes = std.traits.FieldTypeTuple;

/* get the common implictly convertible type, if any, among several types 
*/
alias CommonType = std.traits.CommonType;

/* get the element type, which a space contains 
*/
template ElementType (S)
	{/*...}*/
		static if (is (typeof(S.init[CoordinateType!S.init]) == T, T))
			alias ElementType = T;

		else alias ElementType = std.range.ElementType!S;
	}

/* get the coordinate type of a space, which can be used to index into the space 
*/
template CoordinateType (S)
	{/*...}*/
		template Coord (size_t i)
			{/*...}*/
				static if (is (typeof(S.opIndex ().limit!i[0]) == T, T))
					alias Coord = T;

				else static if (i == 0 && is (typeof(S.init[0])))
					alias Coord = size_t;

				else alias Coord = void;
			}

		alias CoordinateType = Map!(Coord, Iota!(dimensionality!S));
	}

/* get the number of dimensions of a space 
*/
template dimensionality (S)
	{/*...}*/
		template count (size_t d = 0)
			{/*...}*/
				static if (is (typeof(S.init[].limit!d)))
					enum count = 1 + count!(d+1);

				else static if (d == 0 && is (typeof(S.init[].length)))
					enum count = 1;

				else enum count = 0;
			}

		enum dimensionality = count!();
	}

/* get the fully qualified name of a type, including its containing module 
*/
alias full_name = fullyQualifiedName;
