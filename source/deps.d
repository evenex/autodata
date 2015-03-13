version(none):
private {/*imports}*/
	import std.stdio;
	import std.range;
	import std.process;
	import std.conv;
	import std.array;
	import std.string;
	import std.random;
	import std.algorithm;
	import std.file;

	import evx.graphics;
	import evx.patterns;
	import evx.misc.string;
	import evx.misc.utils;
	import evx.range;
	import evx.math;

	alias enumerate = evx.range.enumerate;
	alias map = evx.math.functional.map;
	alias zip = std.range.zip;
	alias reduce = evx.math.functional.reduce;
	alias filter = evx.math.functional.filter;
	alias sum = evx.math.arithmetic.sum;
}

// TODO flags (uses builder) struct... also status mixins, with conditions like traits
struct Flags {mixin Builder!(typeof(null), `_`);}
struct Status (string name, string condition, Etc...) {}

alias count = evx.range.traversal.count;
alias join = std.algorithm.joiner;
alias array = std.array.array;
alias memoize = std.functional.memoize;

///////////////////

Module[] path_to_root_package (Module mod)
	{/*...}*/
		Module[] path;

		while ((mod = mod.enclosing_package) !is null)
			path ~= mod;

		return path;
	}

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

		@property dot ()
			{/*...}*/
				return Dot ()
					.node (`m`~ id.to!string.extract_number)
					.label (`[label="` ~name~ `"]`)
					.shape (this.is_package? `[shape=ellipse]`:`[shape=box]`)
					.color (`[fillcolor="` ~color.to!string~ `"]`)
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

				this.id = Id ();

				foreach (import_name; source.imports)
					if (this.imports.contains (import_name))
						continue;
					else this.imports ~= import_name;

				color = grey (0.5);
			}

		bool opEquals (Module that) const
			{/*...}*/
				return this.id == that.id;
			}

		override string toString ()
			{/*...}*/
				return name ~ "\n"
					~ `(` ~ path ~ `)` "\n"
					~ this.path_to_root_package
						.map!(pkg => pkg.name)
						.join (` → `).text ~ "\n";
			}
	}
bool is_package (Module mod)
	{/*...}*/
		return mod.path.contains (`package`);
	}
bool has_cyclic_dependencies (Module root)
	{/*...}*/
		foreach (cycle; cycles)
			if (cycle.contains (root))
				return true;

		return root.find_minimal_cycle.not!empty;
	}
Module[] find_minimal_cycle (Module node, Module[] path = [])
	{/*...}*/
		if (path.contains (node))
			{/*...}*/
				cycles ~= path;

				return path;
			}

		foreach (mod; node.imported_modules)
			{/*...}*/
				auto cycle = mod.find_minimal_cycle (path ~ node);

				if (cycle.not!empty)
					return cycle;
			}

		return [];
	}
string connect_to (Module from, Module to, string append)
	{/*...}*/
		return "\t" ~from.dot.node~ ` -> ` ~to.dot.node~ append~ `;`"\n";
	}

auto module_name (File file)
	{/*...}*/
		auto module_decl = file.byLine.front.to!string;

		if (module_decl.not!startsWith (`module`))
			return file.name.retro.findSplitBefore (`/`)[0].text.retro.text;
		else return module_decl
			.findSplitAfter (`module `)[1]
			.findSplitBefore (`;`)[0]
			.to!string;
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
bool is_package (File file)
	{/*...}*/
		return file.name.contains (`package`);
	}

auto source_files (string root_directory)
	{/*...}*/
		return dirEntries (root_directory, SpanMode.depth)
			.map!(entry => entry.name)
			.filter!(name => name.endsWith (`.d`));
	}
auto dependency_graph (string root_directory)
	{/*...}*/
		Module[] modules;

		auto files = source_files (root_directory).array;
		files.randomShuffle;

		foreach (path; files)
			modules ~= new Module (File (path, "r"));
			
		foreach (mod; modules)
			{/*connect imports}*/
				foreach (name; mod.imports)
					mod.imported_modules ~= modules.filter!(m => name == m.name).array;

				 // BUG mod.not!is_package doesn't work, why?
				mod.enclosing_package = modules
					.filter!(mdl => mdl.is_package && mdl !is mod)
					.filter!(pkg => mod.name.contains (pkg.name))
					.select!(
						modules => modules.empty? null
						: modules.reduce!((a,b) => a.name.length > b.name.length? a:b)
					);
			}

		return modules;
	}

auto topological_sort (Module[] set)
	in {/*...}*/
		assert (set.map!(mod => mod.find_minimal_cycle).all!empty);
	}
	body {/*...}*/
		Module[] r;

		auto s = set.filter!(mod => mod.imported_modules.empty).array;

		while (s.not!empty)
			{/*...}*/
				auto n = s.front;
				s = s[1..$];
				r ~= n; 

				foreach (m; set.filter!(m => m.imported_modules.contains (n)))
					{/*...}*/
						auto i = m.imported_modules.countUntil (n);

						m.imported_modules = m.imported_modules.remove (i);

						if (set.filter!(l => m.imported_modules.contains (l)).empty)
							s ~= m;
					}
			}

		return r;
	}

///////////////////

auto shortest (R,S)(R r, S s) // REFACTOR
	if (All!(hasLength, R, S))
	{/*...}*/
		return r.length < s.length? r:s;
	}

auto concatenate (R,S)(R r, S s) // REFACTOR
	if (All!(isInputRange, R, S))
	{/*...}*/
		return r ~ s;
	}

///////////////////

Module[][] cycles;

version (generate_dependency_graph) void main ()
	{/*...}*/
		auto modules = dependency_graph (`./source/`);

		{/*assign colors}*/
			auto paths = modules.map!(mod => mod.path_to_root_package)
				.filter!(path => path.not!empty)
				.array; // BUG sort can't be chained to array because LENGTH IS NOT CALLABLE USING A CONST OBJECT you sons of bitches

			paths.sort!((a,b) => a.back.id < b.back.id);

			auto root_packages = paths.map!(path => path.back).uniq;

			foreach (root, color; lockstep (root_packages, rainbow (root_packages.count)))
				{/*...}*/
					root.color = color (0.5);

					auto sub_packages = paths.filter!(path => path.length > 1 && path.back is root)
						.map!(path => path[0..$-1])
						.join.uniq;

					if (sub_packages.empty)
						continue;

					auto shades = (sub_packages.count + 3).shades_of (root.color)[0..$-2];
					auto nearest = shades.reduce!((a,b) => (a.hsv - root.color.hsv).squared[].sum < (b.hsv - root.color.hsv).squared[].sum? a:b);

					foreach (pkg, shade; zip (sub_packages, shades.filter!(c => c != nearest)))
						pkg.color = shade;
				}
				
			foreach (mod; modules
				//.filter!(mod => mod.not!is_package) // BUG 
				.filter!(mod => not (mod.is_package))
				.filter!(mod => mod.enclosing_package !is null)
			)
				mod.color = mod.enclosing_package.color;
		}
		{/*write .dot file}*/
			string dot_file = `digraph dependencies {`"\n";

			dot_file ~= `bgcolor = "#ffffff"`;
			dot_file ~= `node [fontname = "DejaVuSans"]`;

			foreach (mod; modules)
				{/*...}*/
					std.stdio.stderr.writeln (`analyzing module ` ~ mod.name);

					void write_node_property (string property)
						{/*...}*/
							dot_file ~= "\t" ~mod.dot.node ~ property~ `;` "\n";
						}

					with (mod.dot)
						{/*...}*/
							write_node_property (label);
							write_node_property (color);
							write_node_property (style);
							write_node_property (shape);
						}

					foreach (dep; mod.imported_modules)
						{/*...}*/
							std.stdio.stderr.writeln ("\t"`processing dependency ` ~ dep.name);

							if (dep.memoize!has_cyclic_dependencies)
								dot_file ~= dep.connect_to (mod, `[color="#ff000044"]`);
							else dot_file ~= dep.connect_to (mod, `[color="` ~dep.color.value (0.5).text~ `", penwidth=4, arrowsize=2]`);
						}
				}

			std.stdio.stderr.writeln (`marking cycles`);

			dot_file ~= (cycles.empty? [] : cycles.reduce!shortest)
				.adjacent_pairs.map!((a,b) => a.connect_to (b, `[color="#ff0000", penwidth=10]`))
				.array.reduce!concatenate (``);
			
			dot_file ~= `}`;

			std.stdio.stderr.writeln (`done`);

			File (`temp.dot`, `w`).write (dot_file);
		}
		{/*view graph}*/
			executeShell (`dot -Tpdf temp.dot -o dependencies.pdf`);
			executeShell (`rm temp.dot`);
			executeShell (`zathura dependencies.pdf`);
			//executeShell (`rm dependencies.pdf`);
		}
	}

version (generate_package_files) void main ()
	{/*...}*/
		auto source = dependency_graph (`./source/`);

		foreach (pkg; source.filter!is_package)
			{/*...}*/
				auto package_directory = pkg.path.retro.find (`/`).retro;

				File (pkg.path, "w").write (
					q{module } ~ pkg.name ~ q{;}"\n"
					
					q{public:}"\n"

					~ package_directory.dirEntries (SpanMode.shallow)
						.filter!(entry => entry.name.File (`r`).is_package.not) // BUG not
						.map!(entry => entry.isDir? 
							((entry.name ~ `/package.d`).exists? (entry.name ~ `/package.d`).File (`r`).module_name : `unknown`)
							: entry.name.File (`r`).module_name
						)
						.filter!(name => name != `package.d`)
						.map!(name => q{import } ~name~ q{;})
						.join ("\n").text
				);
			}
	}

version (generate_cleanroom_sequence) void main ()
	{/*...}*/
		File (`build_order`, `w`).write (
			dependency_graph (`./source/`)
				.topological_sort
				.map!(mod => mod.path)
				.join ("\n")
		);
	}
