import std.file;
import std.conv;
import std.stdio;
import std.process;
import std.algorithm;
import std.array;
import std.string;

import evx.math;

mixin(FunctionalToolkit!());

import deps;

void comment_line (ref string line)
	{/*...}*/
		line = `//` ~line;
	}
void uncomment_line (ref string line)
	{/*...}*/
		if (line.startsWith (`//`))
			line = line[2..$];
	}						

version (cull_unnecessary_imports) void main (string[] args)
	{/*...}*/
		if (args.length > 1)
			{/*...}*/
				assert (args[1] == `earlyexit`);

				File (`ok`, "w").write (``);

				return;
			}

		auto modules = dependency_graph (`./source/`);

		foreach (mod; modules)
			{/*...}*/
				writeln (`generalizing module ` ~mod.name);

				auto source = File (mod.path, "r").byLine.map!(to!string).array;

				auto remaining = source;

				while ((remaining = remaining.find!(str => str.strip.startsWith (`import`))).not!empty)
					{/*...}*/
						auto old_line = remaining.front;

						auto new_line = old_line;

						while (1)
							{/*...}*/
								foreach (i; new_line.length..old_line.length)
									if (old_line[i] == '.')
										new_line = old_line[0..i] ~ `;`;
									else if (i+1 == old_line.length)
										{/*...}*/
											remaining_front = old_line;
											break;
										}

								remaining.front = new_line;

								File (mod.path, "w").write (source.joiner ("\n"));

								executeShell (`dub --build=unittest -- earlyexit;`);

								if (`ok`.exists)
									{/*...}*/
										std.file.remove (`ok`);

										if (modules.find_minimal_cycle.empty)
											writeln (`generalized import ` ~old_line~ ` to ` ~remaining.front~ ` in ` ~mod.name);
										else remaining.front = old_line;
									}
								else remaining.front = old_line;
							}

						remaining.popFront;
					}

				File (mod.path, "w").write (source.joiner ("\n"));
			}

		writeln (`finished`);
	}
