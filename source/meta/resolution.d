module autodata.meta.resolution;

private {/*import}*/
	import std.conv;
	import std.range: join;

	import autodata.meta.lambda;
	import autodata.meta.list;
}

/* generic identity transform 
	resolves type of symbol whether template, function or value
*/
T identity (T)(T that)
	{/*...}*/
		return that;
	}

/* instantiate a zero-parameter template
*/
alias Instantiate (alias symbol) = symbol!();

/* given a set of zero-parameter templates, invoke the first which successfully compiles 
*/
template Match (patterns...)
	{/*...}*/
		alias Filtered = Filter!(λ!q{(alias pattern) = __traits(compiles, pattern!())}, patterns);

		static if (Filtered.length == 0)
			{/*...}*/
				import std.array: replace;

				static assert (0, 
					`none of ` ~patterns.stringof
					.replace (`()`, ``)
					~ ` could be matched`
				);
			}
		else alias Match = Instantiate!(Filtered[0]);
	}
template Try (uint pattern_to_force_on_failure, patterns...)
	{/*...}*/
		alias fallback = patterns[pattern_to_force_on_failure];

		static if (!(is(typeof(Match!(patterns)))))
			alias Try = fallback!();
		else alias Try = Match!patterns;
	}

/* mixin overload priority will route calls to the given symbol 
		to the first given mixin alias which can complete the call
	useful for controlling mixin overload sets
*/

/* mixin a variadic overload function 
*/
string function_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{auto } ~symbol~ q{ (Args...)(Args args)}
			`{` 
				~attempt_overloads!(symbol ~ q{(args)}, MixinAliases) ~ 
			`}`;
	}

/* mixin a variadic overload template 
*/
string template_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{template } ~symbol~ q{ (Args...)}
			`{` 
				~attempt_overloads!(symbol ~ q{!Args}, MixinAliases)
					.replace (q{return}, q{alias } ~ symbol ~ q{ = }) ~ 
			`}`;
	}

/* mixin a variadic overload template function
*/
string template_function_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{template } ~symbol~ q{ (CTArgs...)}
			`{` 
				q{auto } ~symbol~ q{ (RTArgs...)(RTArgs args)}
					`{` 
						~attempt_overloads!(symbol ~ q{!CTArgs (args)}, MixinAliases) ~ 
					`}`
			`}`;
	}

private {/*impl}*/
	static string attempt_overloads (string call, MixinAliases...)()
		{/*...}*/
			string[] attempts;

			foreach (Alias; MixinAliases)
				attempts ~= q{
					static if (is (typeof(} ~ __traits(identifier, Alias) ~ q{.} ~ call ~ q{)))
						return } ~ __traits(identifier, Alias) ~ q{.} ~ call ~ q{;
				};

			attempts ~= q{static assert (0, typeof(this).stringof~ `: no overloads for `}`"` ~call~ `"`q{` found`);};

			return join (attempts, q{else }).to!string;
		}
}
