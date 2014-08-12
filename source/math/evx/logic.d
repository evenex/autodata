module evx.logic;

private {/*import std}*/
	import std.traits:
		isSomeFunction;

	import std.typetuple:
		templateAnd, templateOr, templateNot;
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
