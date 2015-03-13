module evx.math.logic;
version(none):

private {/*imports}*/
	import std.typetuple;
}

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

static template Not (alias predicate)
	{/*...}*/
		bool Not (Args...)(Args args)
			if (is(typeof(predicate (args) == true)))
			{/*...}*/
				return !(predicate (args));
			}

		bool Not (Args...)()
			if (is(typeof(predicate == true)))
			{/*...}*/
				return !predicate;
			}

		bool Not (Args...)()
			if (__traits(compiles, {enum x = predicate!Args;}))
			{/*...}*/
				return !(predicate!Args);
			}
	}
 // TODO template instance pred!(length) cannot use local 'length' as parameter to non-global template not(alias predicate)
 // TODO Not can be merged with not once this compiler bug is fixed ^^

alias and = templateAnd;
alias or  = templateOr;

alias All = allSatisfy;
alias Any = anySatisfy;
