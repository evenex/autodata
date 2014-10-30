import std.file;
import std.stdio;
import std.array;

import evx.range;
import evx.math;

mixin(FunctionalToolkit!());

import deps;

void main (string[] args)
	{/*...}*/
		if (args.length > 1)
			{/*...}*/
				File (`ok`, "w").write (``);
				return;
			}

		auto modules = dependency_graph (`./source/`);

		foreach (mod; modules)
			{/*...}*/
				auto source = mod.path.readText;

				

				// for each import
					// comment it out and attempt dub --unittest
					// if file "ok" doesn't exist, add that line back in
					// else leave it out
			}
	}
