module evx.codegen.declarations;

private {/*imports}*/
	import std.typetuple;
	import std.conv;
	import std.algorithm;
	import std.traits;
	import std.range;

	import evx.traits;
}

/* declare variables according to format (see unittest) 
*/
string autodeclare (Params...)() 
	if (Params.length > 0)
	{/*...}*/
		alias Types = Filter!(is_type, Params);
		alias fixes = Filter!(is_string_param, Params);

		static if (fixes.length == 0)
			{/*...}*/
				const string prefix = ``;
				const string suffix = `; `;
			}
		else static if (fixes.length == 1)
			{/*...}*/
				template is_punctuation (c...) if (c.length == 1)
					{/*...}*/
						import std.ascii: isPunctuation;
						const bool is_punctuation = c[0][0].isPunctuation;
					}
				static if (anySatisfy!(is_punctuation, fixes[0].array))
					{/*suffix}*/
						const string prefix = ``;
						const string suffix = fixes[0];
					}
				else {/*prefix}*/
						const string prefix = fixes[0];
						const string suffix = `; `;
				}
			}
		else static if (fixes.length == 2)
			{/*...}*/
				const string prefix = fixes[0];
				const string suffix = fixes[1];
			}
		else static assert (0);

		string code;

		foreach (i, T; Types)
			code ~= T.stringof~` `~prefix~`_`~i.text~suffix;

		return code;
	}
	unittest {/*demo}*/
		// declarations are formatted by prefixes and suffixes and numbered by parameter order
		static assert (autodeclare!(int, byte, `x`)			== q{int x_0; byte x_1; });

		// suffixes are distinguished from prefixes by the presence of punctuation marks
		static assert (autodeclare!(int, byte, `x`, `, `) 	== q{int x_0, byte x_1, });
		static assert (autodeclare!(int, byte, char, `:: `)	== q{int _0:: byte _1:: char _2:: });
	}

/* generate variable declaration from a list of types and a list of names 
*/
string declare (Variables...)(dchar delim = ';')
	{/*...}*/
		struct Args
			{/*...}*/
				mixin ParameterSplitter!(
					`Types`, is_type,
					`Names`, is_string_param,
					Variables
				);
			}

		string code;

		with (Args) foreach (i,_; Types)
			static if (staticIndexOf!(Names[i], Names) == i)
				code ~= Types[i].stringof~ q{ } ~Names[i]~delim.text~ "\n";

		return code;
	}
	unittest {/*...}*/
		static assert (declare!(int, `a`, char, `b`, byte, `c`) == q{int a;}"\n"q{char b;}"\n"q{byte c;}"\n");
	}

/* separate Types and Names into eponymous TypeTuples 
*/
mixin template ParameterSplitter (string first, alias first_pred, string second, alias second_pred, Args...)
	{/*...}*/
		private import std.typetuple: Filter;

		mixin(q{
			alias } ~first~ q{ = Filter!(first_pred, Args);
			alias } ~second~ q{ = Filter!(second_pred, Args);
			static assert (} ~first~ q{.length == } ~second~ q{.length, }`"` ~first~`/`~second~ ` length mismatch"`q{);
			static assert (} ~first~ q{.length + } ~second~ q{.length == Args.length, `extraneous template parameters`);
		});
	}

/* build a filterable declaration list (types interleaved with identifier strings) 
	Let automatically filters out duplicate listings, making it useful for merging declaration lists
	Let.OnlyWithTypes and Let.OnlyWithNames are templates that return a filtered declaration list based on the given predicate
	the .be_listed member template generates a raw declaration list which can be passed into other templates
	the .be_declared member generates a compile-time code string which declares the items in the list
*/
struct Let (Decls...)
	{/*...}*/
		mixin ParameterSplitter!(
			`Types`, is_type,
			`Names`, is_string_param,
			DeclarationList.UniqueListings
		);

		alias be_declared = declarations;

		mixin(q{
			alias be_listed = TypeTuple!(} ~listings~ q{);
		});

		template FilterBy (string key, alias pass)
			{/*...}*/
				static code ()
					{/*...}*/
						mixin(q{
							alias Keys = } ~key~ q{s;
						});

						string code;

						foreach (i, Key; Keys)
							static if (pass!Key)
								code ~= listing!i;

						return code[0..$ - min(2,$)];
					}

				mixin(q{
					alias FilterBy = Let!(} ~code~ q{);
				});
			}

		template OnlyWithTypes (alias criterion)
			{/*...}*/
				alias OnlyWithTypes = FilterBy!(`Type`, criterion);
			}
		template OnlyWithNames (alias criterion)
			{/*...}*/
				alias OnlyWithNames = FilterBy!(`Name`, criterion);
			}

		private {/*code gen}*/
			struct DeclarationList
				{/*...}*/
					mixin ParameterSplitter!(
						`Types`, is_type,
						`Names`, is_string_param,
						Decls
					);

					static {/*code gen}*/
						string listings ()
							{/*...}*/
								string code;

								foreach (i,_; Types)
									static if (staticIndexOf!(Names[i], Names) == i)
										code ~= q{Types[} ~i.text~ q{], Names[} ~i.text~ q{], };

								return code[0..$ - min(2,$)];
							}
					}

					mixin(q{
						alias UniqueListings = TypeTuple!(} ~listings~ q{);
					});
				}

			static declarations ()
				{/*...}*/
					string code;

					foreach (i,_; Types)
						code ~= declaration!i;

					return code;
				}
			static listings ()
				{/*...}*/
					string code;

					foreach (i,_; Types)
						code ~= listing!i;

					return code[0..$ - min (2,$)];
				}

			static declaration (size_t i)()
				{/*...}*/
					return Types[i].stringof ~` `~ Names[i] ~`; `;
				}
			static listing (size_t i)()
				{/*...}*/
					return q{Types[} ~i.text~ q{], Names[} ~i.text~ q{], };
				}
		}
	}

/* generate a parenthesized, comma separated parameter list from a set of compile-time values 
*/
auto ct_values_as_parameter_string (Args...)()
	{/*...}*/
		foreach (Arg; Args)
			{/*...}*/
				static assert (is(typeof(Arg)));
				static assert (isBuiltinType!(typeof(Arg)));
			}

		return Args.tuple.text.retro.findSplitAfter (`(`)[0].text.retro.text;
	}
