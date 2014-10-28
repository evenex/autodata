import std.stdio;
import std.range;
import std.process;
import std.conv;
import std.array;
import std.algorithm;
import std.functional;
import std.string;
import std.file;

import evx.graphics.colors; // REVIEW
alias map = std.algorithm.map;

class Module
	{/*...}*/
		string name;
		bool is_package;
		string node_id;
		string[] import_names;
		Import[] imports;
		string package_color;

		this (bool is_package, int id, string name)
			{/*...}*/
				this.is_package = is_package;
				this.node_id = id.to!string;
				this.name = name;
			}
	}

Module[][] cycles;

class Import
	{/*...}*/
		this (Module mod)
			{/*...}*/
				this.mod = mod;
			}

		Module mod;
		alias mod this;

		bool is_cyclic (Module[] seen = [])
			{/*...}*/
				if (seen.map!(m => m.node_id).canFind (mod.node_id))
					{/*...}*/
						if (cycles.canFind!(c => seen.canFind (c)))
							cycles.find!(c => seen.canFind (c))[0].swap (cycles.back);
						else cycles ~= seen;
						return true;
					}

				foreach (imp; mod.imports)
					if (imp.is_cyclic (seen ~ mod))
						return true;

				return false;
			}
	}

Module[string] modules;

string draw_edge (Module from, Module to, string append)
	{/*...}*/
		return "\t" `m` ~from.node_id~ ` -> m` ~to.node_id~ append~ `;`"\n";
	}

void main ()
	{/*...}*/
		{/*populate module tree}*/
			auto files = dirEntries (`./source/`, SpanMode.depth)
				.map!(entry => entry.name)
				.filter!(name => name.endsWith (`.d`))
				.array;

			import std.random;

			files.randomShuffle;

			foreach (path; files)
				{/*read source}*/
					auto file = File (path, "r");

					auto module_decl = file.byLine.front.to!string;

					if (module_decl.not!startsWith (`module`))
						continue;

					auto module_name = module_decl
						.findSplitAfter (`module `)[1]
						.findSplitBefore (`;`)[0]
						.to!string;

					static int id = 0;
					modules[module_name] = new Module (path.canFind (`package`), id++, module_name);

					bool unittest_mode = false;
					string tabs;
					string[] imports;
					foreach (line; file.byLine)
						{/*...}*/
							if (!unittest_mode && line.canFind (`unittest`))
								{/*...}*/
									unittest_mode = true;
									tabs = line.findSplitBefore (`unittest`)[0].to!string;
									continue;
								}
							else if (unittest_mode && !line.canFind (tabs~ `}`))
								continue;
							else if (unittest_mode) 
								{/*...}*/
									tabs = ``;
									unittest_mode = false;
									continue;
								}

							if (line.canFind (`import `))
								imports ~= line
									.findSplitAfter (`import`)[1]
									.findSplitBefore (`;`)[0]
									.findSplitBefore (`:`)[0]
									.strip
									.to!string;
						}

					foreach (name; imports)
						if (modules[module_name].import_names.canFind (name))
							continue;
						else modules[module_name].import_names ~= name;
				}

			foreach (mod; modules)
				{/*get imports}*/
					foreach (name; mod.import_names)
						if (auto imp = name in modules)
							mod.imports ~= new Import (*imp);
				}
		}
		{/*assign colors}*/
			auto package_list = modules.byKey.filter!(mod => modules[mod].is_package).array;

			import evx.math.ordinal: ℕ;
			string[] colors = ℕ[0..package_list.length]
				.map!(i => i * 360.0/package_list.length)
				.map!(hue => `#` ~Color.from_hsv (hue, 1.0, 0.9).alpha (0.4).to_hex)
				.array;

			import std.random;
			colors.randomShuffle;

			foreach (pack; package_list)
				{/*...}*/
					modules[pack].package_color = colors.back;

					colors.length--;
				}

			foreach (name; modules.byKey)
				{/*...}*/
					auto results = package_list.find!(pack => name.canFind (pack));

					if (results.not!empty)
						modules[name].package_color = modules[results.front].package_color;
				}
		}
		{/*write .dot file}*/
			string dot_file = `digraph dependencies {`"\n";

			foreach (name; modules.byKey)
				{/*...}*/
					auto mod = modules[name];

					dot_file ~= "\t" `m` ~mod.node_id~ ` [label="` ~name~ `"];` "\n";
					dot_file ~= "\t" `m` ~mod.node_id~ ` [fillcolor="` ~mod.package_color~ `"];` "\n";
					dot_file ~= "\t" `m` ~mod.node_id~ ` [style=filled];` "\n";
					dot_file ~= "\t" `m` ~mod.node_id~ ` [shape=box];` "\n";

					foreach (dep; mod.imports)
						if (dep.is_cyclic)
							dot_file ~= draw_edge (dep, mod, `[color="#88000066"]`);
						else dot_file ~= draw_edge (dep, mod, `[color="#000000"]`);
				}

			cycles.sort!((a,b) => a.length < b.length);
			foreach (i; 0..cycles.front.length)
				{/*...}*/
					dot_file ~= draw_edge (cycles.front[(i+1)%cycles.front.length], cycles.front[i], `[color="#ff0000", penwidth=6]`);
				}

			dot_file ~= `}`;

			File (`temp.dot`, `w`).write (dot_file);
		}
		{/*view graph}*/
			executeShell (`dot -Tpdf temp.dot -o dependencies.pdf`);
			executeShell (`rm temp.dot`);
			executeShell (`zathura dependencies.pdf`);
			//executeShell (`rm dependencies.pdf`);
		}
	}
