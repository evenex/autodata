module evx.math.geometry.traits;
version(none):

private {/*imports}*/
	import std.range;
	import evx.math.vector;
}

/* test if a type can be used by this library 
*/
template is_geometric (T)
	{/*...}*/
		enum is_geometric = is_vector!(ElementType!T);
	}

/* test if a type can be used as a vector 
*/
template is_vector (T)
	{/*...}*/
		enum is_vector = is(VectorTraits!T.VectorType == T);
	}
