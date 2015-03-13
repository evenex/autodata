module evx.meta.predicate;

private {/*imports}*/
	import std.typetuple;
}

alias And = templateAnd;
alias Or  = templateOr;

static template Not (alias predicate)
	{/*...}*/
		enum Not (Args...) = !predicate!Args;
	}
