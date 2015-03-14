module evx.algebra;

/* generic identity transform
*/
T identity (T)(T that)
	{/*...}*/
		return that;
	}

/* test if identity transform is defined for a type 
*/
enum has_identity (T...) = is (typeof(T[0].identity));
