module evx.patterns.aliasthis;

mixin template AliasThis (alias that)
	{/*...}*/
		mixin(q{
			alias } ~__traits(identifier, that)~ q{ this;
		});
	}
