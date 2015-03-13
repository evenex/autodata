version(none):
private {/*imports}*/
	import std.file;
	import std.conv;
	import std.stdio;
	import std.process;
	import std.algorithm;
	import std.array;
	import std.string;

	import evx.math;

	alias map = evx.math.functional.map;

	import deps;
}

void comment_line (ref string line)
	{/*...}*/
		line = `//` ~line;
	}
void uncomment_line (ref string line)
	{/*...}*/
		if (line.startsWith (`//`))
			line = line[2..$];
	}						

version (generalize_imports)
	enum import_ops_version;
else version (cull_imports)
	enum import_ops_version;

static if (is(import_ops_version)) void main (string[] args)
	{/*...}*/
		if (args.length > 1)
			{/*...}*/
				assert (args[1] == `earlyexit`);

				File (`ok`, "w").write (``);

				return;
			}

		auto modules = dependency_graph (`./source/`);

		version (generalize_imports)
			auto report = File (`generalization_report`, `w`);
		else version (cull_imports)
			auto report = File (`cull_report`, `w`);

		foreach (mod; modules)
			{/*...}*/
				version (generalize_imports)
					{/*...}*/
						writeln (`generalizing module ` ~mod.name);
						report.writeln (`generalizing module ` ~mod.name);
						report.flush;
					}

				auto source = File (mod.path, "r").byLine.map!(to!string).array;

				auto remaining = source;

				while ((remaining = remaining.find!(str => str.strip.startsWith (`import`))).not!empty)
					{/*...}*/
						auto old_line = remaining.front;

						string new_line;

						enum {terminate_loop = -1, goto_next_line = 1, continue_looping = 0}
						int processing_pass ()
							{/*...}*/
								version (generalize_imports)
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
													return terminate_loop;
												}

										remaining.front = new_line ~ `//` ~old_line;
									}
								else version (cull_imports)
									comment_line (remaining.front);

								File (mod.path, "w").write (source.joiner ("\n"));

								executeShell (`dub --build=unittest -- earlyexit;`);

								if (`ok`.exists)
									{/*...}*/
										std.file.remove (`ok`);

										version (generalize_imports)
											{/*...}*/
												if (all (dependency_graph (`./source/`).map!(mod => mod.find_minimal_cycle.empty)))
													{/*...}*/
														auto note = old_line~ ` → ` ~new_line;
														report.writeln (note);
														writeln (note);
														report.flush;
														return goto_next_line;
													}
												else remaining.front = old_line;
												
											}
										else version (cull_imports)
											report.writeln (`culled `, old_line, ` from `, mod.name);
									}
								else {/*...}*/
									version (generalize_imports) 
										remaining.front = old_line;
									else version (cull_imports)
										uncomment_line (remaining.front);
								}

								return continue_looping;
							}

						version (generalize_imports)
							{/*...}*/
								while (old_line.length > new_line.length)
									if (processing_pass != continue_looping)
										break;
							}
						else version (cull_imports)
							processing_pass;

						remaining.popFront;
					}

				File (mod.path, "w").write (source.joiner ("\n"), "\n");
			}

		writeln (`finished`);
	}
