import std.stdio;
import std.range;
import std.process;
import std.conv;
import std.array;
import std.string;
import std.random;
import std.algorithm;
import std.file;

import evx.graphics.color; // REVIEW
import evx.math.logic; // REVIEW
import evx.patterns.id; // REVIEW
import evx.patterns.builder; // REVIEW
import evx.misc.string; // REVIEW
import evx.math.sequence;
import evx.range.traversal;
import evx.math.functional;

// TODO flags (uses builder) struct... also status mixins, with conditions like traits
struct Flags {mixin Builder!(typeof(null), `_`);}
struct Status (string name, string condition, Etc...) {}

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
							return `[fillcolor="#` ~color.alpha (0.5).to_hex~ `"]`;
						else if (this.enclosing_package is null)
							return ``;
						else return `[fillcolor="#`~enclosing_package.color.alpha (0.4).to_hex~`"]`;
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
					if (this.imports.contains (import_name))
						continue;
					else this.imports ~= import_name;
			}

		bool opEquals (Module that) const
			{/*...}*/
				return this.id == that.id;
			}
	}

bool has_cyclic_dependencies (Module root)
	{/*...}*/
		return root.find_minimal_cycle.not!empty;
	}

Module[] find_minimal_cycle (Module node, Module[] path = null)
	{/*...}*/
		if (path.contains (node))
			return path;

		else return node.imported_modules
			.map!(mod => mod.find_minimal_cycle (path ~ node))
			.array.filter!(not!empty) // TODO .buffer.filter... to say do this, then buffer it, then do that.. and someday, map!(...).parallel_buffer.filter!(...)
			.reduce!((c1, c2) => c1.length < c2.length? c1: c2);
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
				if (not!in_unittest_block && line.contains (`unittest`))
					{/*...}*/
						in_unittest_block = true;
						tabs = line.findSplitBefore (`in_unittest`)[0].to!string;
					}
				else if (in_unittest_block)
					{/*...}*/
						if (line.contains (tabs~ `}`))
							{/*...}*/
								tabs = ``;
								in_unittest_block = false;
							}
					}
				else if (line.contains (`import `))
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
		return file.name.contains (`package`);
	}
bool is_package (Module mod)
	{/*...}*/
		return mod.path.contains (`package`);
	}


void connect_import_tree ()
	{/*...}*/
		foreach (mod; Module.database)
			{/*...}*/
				foreach (name; mod.imports)
					if (auto imp = name in Module.database)
						mod.imported_modules ~= *imp;

				if (not (mod.is_package)) // TODO mod.not!is_package doesn't work, why?
					mod.enclosing_package = Module.database.values
						.filter!(mod => mod.is_package)
						.filter!(pack => mod.name.contains (pack.name))
						.reduce!((a,b) => a.name.length > b.name.length? a:b)
						;
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
			auto packages = Module.database.values.filter!(mod => mod.is_package);
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
							dot_file ~= "\t" `m` ~mod.dot.node ~ property~ `;` "\n";
						}

					with (mod.dot)
						{/*...}*/
							write_node_property (label);
							write_node_property (color);
							write_node_property (style);
							write_node_property (shape);
						}

					foreach (dep; mod.imported_modules)
						if (dep.has_cyclic_dependencies)
							dot_file ~= dep.connected_to (mod, `[color="#88000066"]`);
						else dot_file ~= dep.connected_to (mod, `[color="#000000"]`);
				}

			dot_file ~= Module.database.values.map!(mod => mod.find_minimal_cycle)
				.filter!(not!empty)
				.array.reduce!((c1,c2) => c1.length < c2.length? c1:c2)
				.adjacent_pairs.map!((a,b) => a.connected_to (b, `[color="#ff0000", penwidth=6]`))
				.reduce!((a,b) => a ~ b);
			
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
