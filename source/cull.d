import std.file;
import std.conv;
import std.stdio;
import std.process;
import std.algorithm;
import std.array;
import std.string;

import evx.range;
import evx.math;

mixin(FunctionalToolkit!());

import deps;

void main (string[] args)
	{/*...}*/
		if (args.length > 1)
			{/*...}*/
				assert (args[1] == `earlyexit`);

				File (`ok`, "w").write (``);

				return;
			}

		auto modules = dependency_graph (`./source/`);

		size_t imports_removed = 0;

		foreach (mod; modules)
			{/*...}*/
				size_t imports_removed_here = 0;

				auto source = File (mod.path, "r").byLine.map!(to!string).array;

				auto remaining = source;

				while ((remaining = remaining.find!(str => str.strip.startsWith (`import`))).not!empty)
					{/*...}*/
						remaining.front = `//` ~remaining.front;

						File (mod.path, "w").write (source.joiner ("\n"));

						executeShell (`dub --build=unittest -- earlyexit`);

						if (`ok`.exists)
							{/*...}*/
								++imports_removed_here;
								std.file.remove (`ok`);
							}
						else remaining.front = remaining.front[2..$];

						remaining = remaining[1..$];
					}

				File (mod.path, "w").write (source.joiner ("\n"));

				writeln (`cull report: ` ~mod.name~ ` culled ` ~imports_removed_here.text~ ` imports`);
				imports_removed += imports_removed_here;
			}

		writeln (`report: ` ~imports_removed.text~ ` total imports removed`);
	}
