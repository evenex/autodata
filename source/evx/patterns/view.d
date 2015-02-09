module evx.patterns.view;

private {/*import}*/
	import evx.math;
	import evx.type;
}

// REVIEW this is very OOP, better to use FRP. probably kill this when i figure out how

mixin template View (alias target, Invalidators, Refreshers)
	if (is (Invalidators: InvalidateOn!T, T...) && is (Refreshers: RefreshOn!U, U...))
	{/*...}*/
		static assert (is(typeof(target.refresh)));

		static code ()
			{/*...}*/
				string code = q{bool is_invalidated = true;};

				foreach (invalidator; Invalidators.list)
					code ~= q{
						auto } ~invalidator~ q{ (Args...)(Args args)
							}`{`q{
								this.is_invalidated = true;

								static if (Args.length)
									return target.} ~invalidator~ q{ (args);
								else return target.} ~invalidator~ q{;
							}`}`q{
					};

				foreach (refresher; Refreshers.list)
					code ~= q{
						auto } ~refresher~ q{ (Args...)(Args args)
							}`{`q{
								if (this.is_invalidated)
									target.refresh;

								this.is_invalidated = false;

								static if (Args.length)
									return target.} ~refresher~ q{ (args);
								else return target.} ~refresher~ q{;
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
