version (generate_project_info) void main ()
	{/*...}*/
		import std.stdio;
		import std.file;
		import std.algorithm;
		import std.functional;
		import std.range;
		import std.conv;

		struct Module
			{/*...}*/
				string name;
				size_t lines;
			}
		Module[] modules;
		string[] packages;

		foreach (file; `./source/`.dirEntries (SpanMode.depth).filter!(file => file.name.endsWith (`.d`)))
			{/*...}*/
				auto first_line = File (file.name, "r").byLine.front;

				if (first_line.not!startsWith (`module`))
					continue;

				auto module_name = first_line.findSplitAfter (`module `)[1].findSplitBefore (`;`)[0];

				if (file.name.endsWith (`package.d`))
					packages ~= module_name.to!string;
				else modules ~= Module (module_name.to!string, File (file.name, "r").byLine.walkLength);
			}

		auto line_count = modules[].map!(m => m.lines).sum;

		writeln (line_count, ` lines across `, modules.length, ` modules in `, packages.length, ` packages`);

		writeln (`packages:`);
		packages.sort ();
		foreach (p; packages)
			writeln ("\t", p);

		writeln (`modules:`);
		auto module_names = modules.map!(m => m.name).array;
		module_names.sort ();
		foreach (m; module_names)
			writeln ("\t", m);
	}
