import std.stdio;
import std.range;
import std.process;
import std.conv;
import std.array;
import std.string;
import std.random;
import std.algorithm;
import std.file;

import evx.graphics.colors; // REVIEW
import evx.math.logic; // REVIEW
import evx.patterns.id; // REVIEW
import evx.patterns.builder; // REVIEW
import evx.misc.string; // REVIEW
import evx.math.sequence;
import evx.range.traversal;
import evx.math.functional;

mixin(FunctionalToolkit!());
alias count = evx.range.traversal.count; // TODO make count like std.algorithm count except by default it takes TRUE and just counts up all the elements

class Module
	{/*...}*/
		mixin TypeUniqueId;

		Id id;

		mixin Builder!(
			string, `path`,
			string, `name`,
			bool, `is_package`,
			Color, `color`,
		);

		string[] imports;
		Module[] imported_modules;
		Module enclosing_package;

		__gshared Module[string] database;

		@property dot ()
			{/*...}*/
				return Dot ()
					.node (`m`~ id.to!string.extract_number)
					.label (`[label="` ~name~ `"]`)
					.shape (this.is_package? `[shape=ellipse]`:`[shape=box]`)
					.color ((){/*...})*/
						if (this.is_package) 
							return `[fillcolor="#` ~color.alpha (0.6).to_hex~ `"]`;
						else if (this.enclosing_package is null)
							return ``;
						else return `[fillcolor="#`~enclosing_package.color.alpha (0.3).to_hex~`"]`;
					}())
					.style (`[style=filled]`)
					;
			}

		struct Dot
			{/*...}*/
				mixin Builder!(
					string, `node`,
					string, `label`,
					string, `shape`,
					string, `color`,
					string, `style`,
				);
			}

		this (File source)
			{/*...}*/
				this.path (source.name)
					.name (source.module_name)
					.is_package (source.is_package);

				this.id = Id.create;

				database[name] = this;

				foreach (import_name; source.imports)
					if (this.imports.canFind (import_name))
						continue;
					else this.imports ~= import_name;
			}
	}

Module[][] cycles;


bool is_cyclic (Module from, Module[] seen = [])
	{/*...}*/
		if (seen.map!(m => m.dot.node).canFind (from.dot.node))
			{/*...}*/
				if (cycles.canFind!(c => seen.canFind (c)))
					cycles.find!(c => seen.canFind (c))[0].swap (cycles.back);
				else cycles ~= seen;

				return true;
			}

		foreach (imp; from.imported_modules)
			if (imp.is_cyclic (seen ~ from))
				return true;

		return false;
	}


string connected_to (Module from, Module to, string append)
	{/*...}*/
		return "\t" `m` ~from.dot.node~ ` -> m` ~to.dot.node~ append~ `;`"\n";
	}

auto source_filepaths ()
	{/*...}*/
		return dirEntries (`./source/`, SpanMode.depth)
			.map!(entry => entry.name)
			.filter!(name => name.endsWith (`.d`));
	}

auto imports (File file)
	{/*...}*/
		string tabs;
		string[] imports;
		bool in_unittest_block = false;

		foreach (line; file.byLine)
			{/*...}*/
				if (not!in_unittest_block && line.canFind (`unittest`))
					{/*...}*/
						in_unittest_block = true;
						tabs = line.findSplitBefore (`in_unittest`)[0].to!string;
					}
				else if (in_unittest_block)
					{/*...}*/
						if (line.canFind (tabs~ `}`))
							{/*...}*/
								tabs = ``;
								in_unittest_block = false;
							}
					}
				else if (line.canFind (`import `))
					imports ~= line
						.findSplitAfter (`import`)[1]
						.findSplitBefore (`;`)[0]
						.findSplitBefore (`:`)[0]
						.strip
						.to!string;
			}
		
		return imports;
	}

auto module_name (File file)
	{/*...}*/
		auto module_decl = file.byLine.front.to!string;

		if (module_decl.not!startsWith (`module`))
			return `???`;
		else return module_decl
			.findSplitAfter (`module `)[1]
			.findSplitBefore (`;`)[0]
			.to!string;
	}

bool is_package (File file)
	{/*...}*/
		return file.name.canFind (`package`);
	}
bool is_package (Module mod)
	{/*...}*/
		return mod.path.canFind (`package`);
	}

auto rainbow (size_t length)
	{/*...}*/
		return ℕ[0..length]
			.map!(i => i * 360.0/length)
			.map!(hue => Color.from_hsv (hue, 1.0, 1.0));
	}

void connect_import_tree ()
	{/*...}*/
		foreach (mod; Module.database)
			{/*...}*/
				foreach (name; mod.imports)
					if (auto imp = name in Module.database)
						mod.imported_modules ~= *imp;
			}
	}

void build_module_tree ()
	{/*...}*/
		auto files = source_filepaths.array;

		files.randomShuffle;

		foreach (path; files)
			new Module (File (path, "r"));
			
		connect_import_tree;
	}


void main ()
	{/*...}*/
		build_module_tree;
		{/*assign colors}*/
			auto packages = Module.database.byValue.filter!(mod => mod.is_package);
			auto n_colors = packages.count;

			foreach (pkg, color; zip (packages, rainbow (n_colors)))
				pkg.color = color;
		}
		{/*write .dot file}*/
			string dot_file = `digraph dependencies {`"\n";

			foreach (mod; Module.database)
				{/*...}*/
					void write_node_property (string property)
						{/*...}*/
							dot_file ~= "\t" `m` ~node ~ property~ `;` "\n";
						}

					with (mod.dot)
						{/*...}*/
							write_node_property (label);
							write_node_property (color);
							write_node_property (style);
							write_node_property (shape);
						}

					foreach (dep; mod.imported_modules)
						if (dep.is_cyclic)
							dot_file ~= dep.connected_to (mod, `[color="#88000066"]`);
						else dot_file ~= dep.connected_to (mod, `[color="#000000"]`);
				}

			cycles.sort!((a,b) => a.length < b.length);
			if (cycles.not!empty)
				foreach (i; 0..cycles.front.length)
					{/*...}*/
						dot_file ~= cycles.front[(i+1)%cycles.front.length].connected_to (cycles.front[i], `[color="#ff0000", penwidth=6]`);
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
