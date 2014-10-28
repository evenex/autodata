module evx.math.geometry.traits;

private {/*imports}*/
	import std.range;

	import evx.math.arithmetic;
	import evx.math.vectors;
}

/* test if a type can be used by this library 
*/
template is_geometric (T)
	{/*...}*/
		enum is_geometric = is_vector!(ElementType!T);
	}

/* test if a type can be used as a vector 
*/
version (none)
template is_vector (T)
	{/*...}*/
		enum is_vector = is(VectorTraits!T.VectorType == T);
	}
else template is_vector (T)
	{/*...}*/
		enum is_vector = __traits(compiles, {T a, b; auto c = a + b; auto d = a.x + b.y;}); // TEMP
	}
