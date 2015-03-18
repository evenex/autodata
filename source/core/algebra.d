module autodata.core.logic;

private {/*import}*/
	import autodata.meta;
}

/* named logical inversion operator 
*/
template not ()
	{/*...}*/
		bool not (T)(T value)
			{/*...}*/
				return !value;
			}
	}
template not (alias predicate)
	{/*...}*/
		bool not (Args...)(Args args)
			if (is(typeof(predicate (args) == true)))
			{/*...}*/
				return !(predicate (args));
			}

		bool not (Args...)()
			if (is(typeof(predicate == true)))
			{/*...}*/
				return !predicate;
			}

		bool not (Args...)()
			if (__traits(compiles, {enum x = predicate!Args;}))
			{/*...}*/
				return !(predicate!Args);
			}
	}
