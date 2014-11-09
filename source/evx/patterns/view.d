module evx.patterns.view;

private {/*import}*/
	import evx.math;
	import evx.traits;
}

mixin template View (alias target, Invalidators, Refreshers)
	if (is (Invalidators: InvalidateOn!T, T...) && is (Refreshers: RefreshOn!U, U...))
	{/*...}*/
		static assert (is(typeof(target.refresh)));

		static code ()
			{/*...}*/
				string code = q{bool is_invalidated;};

				foreach (invalidator; Invalidators.list)
					code ~= q{
						auto } ~invalidator~ q{ (Args...)(Args args)
							}`{`q{
								this.is_invalidated = true;

								return target.} ~invalidator~ q{ (args);
							}`}`q{
					};

				foreach (refresher; Refreshers.list)
					code ~= q{
						auto } ~refresher~ q{ (Args...)(Args args)
							}`{`q{
								if (this.is_invalidated)
									target.refresh;

								this.is_invalidated = false;

								return target.} ~refresher~ q{ (args);
							}`}`q{
					};

				return code;
			}

		mixin(code);
	}

struct InvalidateOn (T...)
	if (All!(is_string_param, T))
	{/*...}*/
		enum list = T;
	}
struct RefreshOn (T...)
	if (All!(is_string_param, T))
	{/*...}*/
		enum list = T;
	}
