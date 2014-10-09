module evx.lsystem;

import std.typecons;
import std.algorithm;
import std.conv;
import std.range;
import evx.math;
import evx.utils;
import evx.set;

struct LSystem (LSymbol)
	{/*...}*/
		alias Symbol = LSymbol;
		alias Rule = Tuple!(Axiom, `predecessor`, Axiom, `successor`);

		alias Alphabet = Set!Symbol;
		alias Axiom = Symbol[];
		alias Rules = Set!Rule;

		this (Alphabet alphabet, Axiom initial, Rules production)
			{/*...}*/
				definition = typeof(definition)(alphabet, initial, production);
				state = initial;
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

		auto update ()
			{/*...}*/
				return state = rewrite (state);
			}
		auto toString ()
			{/*...}*/
				return state.text;
			}

		private:
		private {/*state}*/
			Tuple!(Alphabet, `alphabet`, Axiom, `axiom`, Rules, `rules`) definition;
			Axiom state;
		}
	}
	unittest {/*...}*/
		with (LSystem!dchar) {/*...}*/
			enum: Symbol {a = 'A', b = 'B'}

			auto A = Alphabet (a,b);
			auto P = Rules (
				Rule ([a], [a,b]),
				Rule ([b], [a]),
			);

			auto algae = LSystem!dchar (A, [a], P); // TODO helper ctor

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
