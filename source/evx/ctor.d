module evx.ctor; // TEMP

/* recursively attempt to construct an instance of type T with a set of constant arguments 
*/
template recursive_constructor (args...)
	{/*...}*/
		auto of_type (T)()
			{/*...}*/
				alias U = Unqual!T;

				auto element ()() {return U (args);}
				auto recurse ()() {return U (Map!(recursive_constructor, FieldTypes!U));}
				auto s_array ()()
					{/*...}*/
						Unqual!U array;

						array[] = recursive_constructor!(ElementType!U); // REVIEW ET

						return array;
					}

				return Match!(element, s_array, recurse);
			}
	}
