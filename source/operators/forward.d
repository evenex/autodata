module autodata.operators.forward;

template DispatchThisExt ()
	{/*...}*/
		auto ref opDispatch (string op, Args...)(Args args)
			{/*...}*/
				import autodata.meta;

				auto ref as_val ()() if (Args.length == 0) {return mixin(q{source.} ~op);}
				auto ref as_func ()() {return mixin(q{source.} ~op~ q{ (args)});}

				return Match!(as_val, as_func);
			}
	}
template AliasThisExt ()
	{/*...}*/
		alias source this;
	}
