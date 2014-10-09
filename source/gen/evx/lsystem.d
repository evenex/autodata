module evx.lsystem;

import std.typecons;
import std.algorithm;
import std.conv;
import std.range;
import evx.math;
import evx.utils;
import evx.set;

mixin(MathToolkit!());

struct LSystem (LSymbol)
	{/*...}*/
		alias Symbol = LSymbol;
		alias Rule = Tuple!(Axiom, `predecessor`, Axiom, `successor`);

		alias Alphabet = Set!Symbol;
		alias Axiom = Symbol[];
		alias Rules = Set!Rule;

		struct Grammar 
			{/*...}*/
				Tuple!(Alphabet, `alphabet`, Axiom, `axiom`, Rules, `rules`) definition;
				Axiom state;

				this (Alphabet alphabet, Axiom initial, Rules production)
					{/*...}*/
						definition = typeof(definition)(alphabet, initial, production);
						state = initial;
					}

				auto update ()
					{/*...}*/
						return state = rewrite (state);
					}

				Axiom rewrite (Axiom substate)
					{/*...}*/
						foreach (rule; definition.rules)
							{/*...}*/
								auto found = substate.findSplit (rule.predecessor);

								auto before = found[0];
								auto match  = found[1];
								auto after  = found[2];

								if (match.not!empty)
									return rewrite (before) ~rule.successor~ rewrite (after);
								else continue;
							}

						return substate;
					}

				auto toString ()
					{/*...}*/
						return state.text;
					}
			}
	}

void main ()
	{/*...}*/
		with (LSystem!dchar) {/*...}*/
			enum: Symbol {a = 'A', b = 'B'}

			auto A = Alphabet (a,b);
			auto P = Rules (
				Rule ([a], [a,b]),
				Rule ([b], [a]),
			);

			auto algae = Grammar (A, [a], P);

			assert (algae.text == `A`);
			assert (algae.update.text == `AB`);
			assert (algae.update.text == `ABA`);
			assert (algae.update.text == `ABAAB`);
			assert (algae.update.text == `ABAABABA`);
			assert (algae.update.text == `ABAABABAABAAB`);
			assert (algae.update.text == `ABAABABAABAABABAABABA`);
			assert (algae.update.text == `ABAABABAABAABABAABABAABAABABAABAAB`);

			/* source: http://en.wikipedia.org/wiki/L-system#Example_1:_Algae */
		}
	}
