module evx.logic;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.typetuple;
	}
}

pure nothrow:

bool not (T)(const T value)
	{/*...}*/
		return !value;
	}
	
bool not (alias predicate, Args...)(const Args args)
	if (isSomeFunction!predicate)
	{/*...}*/
		return not (predicate (args));
	}

alias And = templateAnd;
alias Or  = templateOr;
alias Not = templateNot;
