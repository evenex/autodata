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

//version (cull_unnecessary_imports)
void main (string[] args)
	{/*...}*/
		if (args.length > 1)
			{/*...}*/
				assert (args[1] == `earlyexit`);

				File (`ok`, "w").write (``);

				return;
			}

		auto modules = dependency_graph (`./source/`);

		auto report = File (`generalization_report`, `w`);

		foreach (mod; modules)
			{/*...}*/
				writeln (`generalizing module ` ~mod.name);

				auto source = File (mod.path, "r").byLine.map!(to!string).array;

				auto remaining = source;

				while ((remaining = remaining.find!(str => str.strip.startsWith (`import`))).not!empty)
					{/*...}*/
						auto old_line = remaining.front;

						string new_line;

						while (old_line.length > new_line.length)
							{/*...}*/
								foreach (i; new_line.length..old_line.length)
									if (old_line[i] == '.')
										{/*...}*/
											new_line = old_line[0..i] ~ `;`;
											break;
										}
									else if (i+1 == old_line.length)
										{/*...}*/
											remaining.front = old_line;
											goto done;
										}

								remaining.front = new_line;

								File (mod.path, "w").write (source.joiner ("\n"));

								executeShell (`dub --build=unittest -- earlyexit;`);

								if (`ok`.exists)
									{/*...}*/
										std.file.remove (`ok`);

										if (all (dependency_graph (`./source/`).map!(mod => mod.find_minimal_cycle.empty)))
											{/*...}*/
												auto note = old_line~ ` → ` ~remaining.front;
												report.writeln (note);
												writeln (note);
												break;
											}
										else remaining.front = old_line;
									}
								else remaining.front = old_line;
							}

						done:

						remaining.popFront;
					}

				File (mod.path, "w").write (source.joiner ("\n"), "\n");
			}

		writeln (`finished`);
	}
