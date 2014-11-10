module evx.patterns.wrapper;

mixin template Wrapped (T)
	{/*...}*/
		T wrapped;
		alias wrapped this;
	}
