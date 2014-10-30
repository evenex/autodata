module evx.range.traits;

/* test if a type is sliceable 
*/
template is_sliceable (R, T = size_t)
	{/*...}*/
		enum is_sliceable = __traits(compiles, {auto x = R.init[T.init..T.init];});
	}

/* test if a type is indexable 
*/
template is_indexable (R, T = size_t)
	{/*...}*/
		enum is_indexable = __traits(compiles, R.init[T.init]);
	}

struct NullInputRange (T) // REVIEW
	{/*...}*/
		enum front = T.init;
		void popFront (){}
		enum empty = true;
	}
