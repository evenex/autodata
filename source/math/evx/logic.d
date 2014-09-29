module evx.logic;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.typetuple;
	}
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
		bool not (T)(T value)
			if (__traits(compiles, predicate (value)))
			{/*...}*/
				return !(predicate (value));
			}
		bool not ()()
			{/*...}*/
				return !predicate;
			}
	}

alias And = templateAnd;
alias Or  = templateOr;
alias Not = templateNot;
