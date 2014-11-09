module evx.adaptors.wrapper;

mixin template Wrapped (T)
	{/*...}*/
		T wrapped;
		alias wrapped this;
	}
