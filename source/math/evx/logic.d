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
		bool not (Args...)(Args args)
			{/*...}*/
				static if (__traits(compiles, predicate (args)))
					return !(predicate (args));
				else return !predicate;
			}
	}

alias And = templateAnd;
alias Or  = templateOr;
alias Not = templateNot;
