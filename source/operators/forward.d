module autodata.operators.forward;

template DispatchOps (alias target)
	{/*...}*/
		auto ref opDispatch (string op, Args...)(Args args)
			{/*...}*/
				import autodata.meta;

				auto ref as_val ()() if (Args.length == 0) {return mixin(q{target.} ~op);}
				auto ref as_func ()() {return mixin(q{target.} ~op~ q{ (args)});}

				return Match!(as_val, as_func);
			}
	}
template DispatchExt ()
	{/*...}*/
		mixin DispatchOps!source;
	}
template AliasThisExt ()
	{/*...}*/
		alias source this;
	}
