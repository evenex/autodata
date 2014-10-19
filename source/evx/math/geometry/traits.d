module evx.math.geometry.traits;

private {/*imports}*/
	import std.range;

	import evx.math.arithmetic;
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
		static if (is(typeof(T.x) == typeof(T.y)))
			enum is_vector = supports_arithmetic!(typeof(T.x));
		else enum is_vector = false;
	}
