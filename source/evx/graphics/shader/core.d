module evx.graphics.shader.core;

private {/*imports}*/
	import std.typecons: Tuple; // XXX removal pending http://wiki.dlang.org/DIP32
	import std.conv: to, text;
	import std.ascii: isWhite;
	import std.string: strip;

	import evx.type;
	import evx.math;
	import evx.range;
	import evx.misc.memory;
	import evx.misc.utils;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.texture;
}

alias vertex_shader (Decl...) = generate_shader!(Stage.vertex, Decl);
alias fragment_shader (Decl...) = generate_shader!(Stage.fragment, Decl);

template generate_shader (Stage stage, Decl...)
	{/*...}*/
		static assert (
			All!(is_string_param, Decl[0..$-1])
			|| (
				All!(is_type, Deinterleave!(Decl[0..$-1])[0..$/2])
				&& All!(is_string_param, Deinterleave!(Decl[0..$-1])[$/2..$])
			),
			`shader declarations must either all be explicitly typed (T, "a", U, "b"...)`
			` or auto typed ("a", "b"...) and cannot be mixed`
		);

		auto generate_shader (Input...)(auto ref Input input)
			{/*...}*/
				template ResolvedSymbols ()
					{/*...}*/
						enum code = Decl[$-1];
						alias DeclTypes = Filter!(is_type, Decl[0..$-1]);
						alias Identifiers = Filter!(is_string_param, Decl[0..$-1]);

						static if (is (Input[0] == Shader!S, S...))
							alias ExistingSymbols = Shader!S.Symbols;
						else alias ExistingSymbols = Cons!();

						template Params ()
							{/*...}*/
								template Expand (T)
									{/*...}*/
										static if (is (T == Tuple!Data, Data...))
											alias Expand = Data;
										else static if (is (T == Shader!Sym, Sym...))
											alias Expand = Cons!();
										else alias Expand = T;
									}

								alias Params = Map!(Expand, Input);
							}
						template Lookup (string identifier)
							{/*...}*/
								enum identifier_match (V) = is (V == Variable!(U, Identifiers[i]), U...);

								alias Lookup = Filter!(identifier_match, ExistingSymbols)[0];
							}

						template ParsedVars ()
							{/*...}*/
								alias ParsedVars = Map!(Variable, Identifiers);
							}
						template TypedVars ()
							{/*...}*/
								static if (is (DeclTypes[0]))
									{/*...}*/
										alias Assign (V, T) = V.set_base_type!T;
										alias Retain (V, T) = V.set_source_type!T;

										alias TypedVars = Map!(Pair!().Both!Retain,
											Zip!(
												Map!(Pair!().Both!Assign, 
													Zip!(ParsedVars!(), DeclTypes)
												),
												Cons!(
													Repeat!(ParsedVars!().length - Params!().length, Unknown),
													Params!()
												)
											)
										);

										static if (is (Params!()[0]))
											static assert (
												All!(Map!(Pair!().Both!(λ!q{(T, U) = is (U : T)}), 
													Zip!(
														DeclTypes[$-Params!().length..$],
														Params!()
													)
												)), `error: argument type does not match declaration type`
											);
									}
								else static if (stage is Stage.vertex)
									{/*...}*/
										alias BaseType (T) = Select!(is_range!T, Element!T, T);

										alias Deduce (V, T) = V.set_source_type!T.set_base_type!(BaseType!T);

										alias TypedVars = Map!(Pair!().Both!Deduce, Zip!(ParsedVars!(), Params!()));
									}
								else static assert (not (stage is Stage.fragment),
									`Fragment shaders do not yet support automatic type deduction, and currently can only use a typed declaration list.`
								);
							}
						template QualifiedVars ()
							{/*...}*/
								template Assign (V)
									{/*...}*/
										static if (stage is Stage.vertex)
											{/*...}*/
												static if (is_range!(V.SourceType))
													alias Assign = V.set_storage_class!(StorageClass.vertex_input);

												else alias Assign = V.set_storage_class!(StorageClass.uniform);
											}
										else static if (stage is Stage.fragment)
											{/*...}*/
												static if (not (is (V.SourceType == Unknown)))
													alias Assign = V.set_storage_class!(StorageClass.uniform);

												else static if (is (Lookup!(V.identifier) == W, W))
													alias Assign = V.set_storage_class!(W.storage_class);

												else alias Assign = V.set_storage_class!(StorageClass.vertex_fragment);
											}
										else static assert (0);
									}

								alias QualifiedVars = Map!(Assign, TypedVars!());
							}

						enum is_resolved (V) = not (is (V.BaseType == Unknown) || V.storage_class is StorageClass.unknown);

						template Resolve (V)
							{/*...}*/
								static if (is (Lookup!(V.identifier) == Existing, Existing))
									{/*...}*/
										static assert (is (V.BaseType == Existing.BaseType),
											`cannot redeclare ` ~ Existing.stringof ~ ` as ` ~ V.BaseType.stringof
										);

										alias Resolve = Cons!();
									}
								else alias Resolve = V;

								static assert (is_resolved!V,
									V.stringof ~ ` could not be resolved`
								);
							}

						alias ResolvedSymbols = Cons!(
							ExistingSymbols,
							Function!(stage, code),
							Map!(Resolve, QualifiedVars!())
						);
					}
				template FramedArgs ()
					{/*...}*/
						static if (is (Input[0] == Shader!Sym, Sym...))
							{/*...}*/
								static if (is (Input[1]))
									alias FramedArgs = Cons!(Input[0].Args, Map!(GPUType, Input[1..$]));
								else alias FramedArgs = Cons!(Input[0].Args);
							}
						else static if (is (Input[0] == Tuple!Data, Data...)) // XXX removal pending http://wiki.dlang.org/DIP32
							{/*...}*/
								static if (is (Input[1]))
									alias FramedArgs = Map!(GPUType, Cons!(Data, Input[1..$]));
								else alias FramedArgs = Map!(GPUType, Data);

								static assert (stage != Stage.fragment, 
									`tuple arg not valid for fragment shader`
								);
							}
						else {/*...}*/
							alias FramedArgs = Map!(GPUType, Input);

							static assert (stage != Stage.fragment, 
								`fragment shader must be attached to vertex shader`
							);
						}
					}

				alias S = Shader!(
					ResolvedSymbols!(),
					FramedArgs!()
				);
				
				auto shader 	 ()() {return S (input[0].args);}
				auto shader_etc  ()() {return S (input[0].args, input[1..$]);}
				auto tuple 		 ()() {return S (input[0].expand);}
				auto tuple_etc 	 ()() {return S (input[0].expand, input[1..$]);}
				auto forward_all ()() {return S (input);}

				static if(not(is(typeof(Match!(shader_etc, shader, tuple_etc, tuple, forward_all)))))
					tuple_etc;// tuple, forward_all)))))
				return Match!(shader_etc, shader, tuple_etc, tuple, forward_all);
			}
	}

private:

/* Shader Template Compilation Process Specification

	upon instantiation of template:

	1) Parsing
		
		The last template parameter must be a string containing the body of the shader main function.
		The preceding parameters form the declaration list.
		These declarations may consist of interleaved types and identifier strings (a typed declaration list)
			or the set of identifier strings on their own (an auto declaration list)
		Fragment shaders do not yet support automatic type deduction, and currently can only use a typed declaration list.

		Parsed variables contain information about their storage class, type, and identifier.
		Identifiers are always known. Types are known immediately if they are given in a typed declaration list,
		otherwise they are automatically deduced in the next compilation stage.
		Storage class is always deduced automatically in the next compilation stage.

	upon invocation of the eponymous function:

	2a) Resolution

		If the type of a variable is unknown, then the compilation target must be the vertex stage. 
		Type deduction rules are as follows:
			If the identifier can be found in the existing symbol table, the variable is resolved.
			Otherwise the declared variables take the type (or element type, if a range) of the given input argument.

		Once the type of a variable is known, the storage class deduction rules are as follows:
			If the identifier can be found in the symbol table, the variable is resolved (after verifying type match, if it is given in the declaration list)
			If the compilation target is the vertex shader stage, then ranges become vertex_input class while PODs become uniform.
			If the compilation target is the fragment shader stage, then declared variables are split into two lists:
				The last n variables (where n is the number of function arguments) become uniform.
				The remaining variables are looked up in the symbol table. If they are not found, they become vertex_fragment.
				
	2b) Framing

		Resolved symbols with vertex_input or uniform storage classes are in an ordered, one-to-one correspondence with runtime input arguments.
		The shader will create member variables to hold each argument, and upload them to the GPU upon activation.
		These member variables may differ from the type of the given input argument:
			Ranges will become GPUArrays,
			GPUArrays, Textures, and other existing GPU resources will become Borrowed,
			PODs will retain their original type.

	upon initial activation of the shader:

	3) Linking 

		Variables, with their type and storage class known, are linked after shader compilation,
			and the variable location indices are permanently saved in a global lookup table.

	upon subsequent activations of the shader:

	4) Passing

		The shader uploads its input data (converting from given arguments if necessary) using the global linked variable indices.
*/

private {/*symbol construction}*/
	struct Unknown {}
	enum StorageClass {unknown, vertex_input, vertex_fragment, uniform}
	enum Stage {vertex = GL_VERTEX_SHADER, fragment = GL_FRAGMENT_SHADER}

	struct Variable (
		string identifier_arg,
		BaseTypeArg = Unknown,
		SourceTypeArg = Unknown,
		StorageClass storage_class_arg = StorageClass.unknown
	)
		{/*...}*/
			enum identifier = identifier_arg;
			alias BaseType = BaseTypeArg;
			alias SourceType = SourceTypeArg;
			enum StorageClass storage_class = storage_class_arg;

			alias set_base_type (T) = Variable!(identifier, T, SourceType, storage_class);
			alias set_source_type (T) = Variable!(identifier, BaseType, T, storage_class);
			alias set_storage_class (StorageClass sc) = Variable!(identifier, BaseType, SourceType, sc);

			template declare (Stage stage)
				{/*...}*/
					static if (storage_class is StorageClass.uniform)
						{/*...}*/
							enum qualifier = q{uniform};
						}
					else static if (storage_class is StorageClass.vertex_input)
						{/*...}*/
							static if (stage is Stage.vertex)
								enum qualifier = q{in};

							else static assert (0);
						}
					else static if (storage_class is StorageClass.vertex_fragment)
						{/*...}*/
							static if (stage is Stage.vertex)
								enum qualifier = q{out};

							else static if (stage is Stage.fragment)
								enum qualifier = q{in};

							else static assert (0);
						}
					else static assert (0);

					static if (is (BaseType == Vector!(n, T), uint n, T))
						{/*...}*/
							enum base = is (T == float)?
								`` : T.stringof[0].to!string;

							enum type = base ~ q{vec} ~ n.text;
						}
					else static if (is (BaseType == Texture))
						{/*...}*/
							enum type = q{sampler2D};
						}
					else static if (not (is (BaseType == Unknown)))
						{/*...}*/
							enum type = BaseType.stringof;
						}
					else static assert (0);

					enum declare = [qualifier, type, identifier].join (` `).to!string ~ `;`;
				}
		}

	struct Function (Stage stage, string code) {}
}
private {/*shader program database}*/
	__gshared GLuint[string] shader_ids;
}
private {/*parameter framing}*/
	// PODs → PODs, Subspaces → Subspaces, Arrays → GPUArrays, Resources → Borrowed!Resources
	template GPUType (T)
		{/*...}*/
			static if (is (T == GLBuffer!U, U...) || is (T == Texture))
				alias GPUType = Borrowed!T;

			else static if (is (typeof(T.init[].source) == GLBuffer!U, U...))
				alias GPUType = T;

			else static if (is (typeof(T.init.gpu_array) == U, U))
				alias GPUType = U;

			else alias GPUType = T;
		}
}
package {/*generator/compiler/linker}*/
	struct Shader (Parameters...)
		{/*...}*/
			alias Symbols = Filter!(or!(is_variable, is_function), Parameters);
			alias Args = Filter!(not!(or!(is_variable, is_function)), Parameters);

			alias vertex_code = shader_code!(Stage.vertex);
			alias fragment_code = shader_code!(Stage.fragment);

			static {/*codegen}*/
				enum is_variable (T) = is (T == Variable!V, V...);
				enum is_function (T) = is (T == Function!U, U...);

				alias Variables = Filter!(is_variable, Symbols);
				alias Functions = Filter!(is_function, Symbols);

				static string shader_code (Stage stage)()
					{/*...}*/
						string[] code = [q{#version 440}];

						foreach (V; Variables)
							static if (is (typeof (V.declare!stage)))
								code ~= V.declare!stage;

						code ~= [q{void main ()}, `{`];

						foreach (F; Functions)
							static if (is (F == Function!(stage, definition), string definition))
								code ~= "\t" ~ definition;

						code ~= `}`;

						return code.join ("\n").to!string;
					}
			}
			static {/*runtime}*/
				__gshared:
				GLuint program_id = 0;
				GLint[Variables.length] variable_locations;

				void initialize ()
					in {/*...}*/
						assert (not (gl.IsProgram (program_id)));
					}
					out {/*...}*/
						assert (gl.IsProgram (program_id) && program_id != 0, // BUG the shader ID is still in the global table from a prior context, but is no longer a valid program
							`shader failed to initialize program ` ~ program_id.text
						);
					}
					body {/*...}*/
						auto key = [vertex_code, fragment_code].join.filter!(not!isWhite).to!string;

						if (auto id = key in shader_ids)
							{/*...}*/
								program_id = *id;

								if (gl.IsProgram (program_id))
									return;
							}

						build_program;

						shader_ids[key] = program_id;
					}
				void build_program ()
					{/*...}*/
						program_id = gl.CreateProgram ();

						auto vert = compile_shader (vertex_code, Stage.vertex);
						auto frag = compile_shader (fragment_code, Stage.fragment);

						gl.AttachShader (program_id, vert);
						gl.AttachShader (program_id, frag);

						gl.LinkProgram (program_id);

						if (auto error = gl.verify!`Program` (program_id))
							assert (0, error);

						link_variables;

						gl.DeleteShader (vert);
						gl.DeleteShader (frag);
						gl.DetachShader (program_id, vert);
						gl.DetachShader (program_id, frag);
					}
				auto compile_shader (string code, Stage stage)
					{/*...}*/
						auto source = code.to_c[0];

						auto shader = gl.CreateShader (stage);
						gl.ShaderSource (shader, 1, &source, null);
						gl.CompileShader (shader);
						
						if (auto error = gl.verify!`Shader` (shader))
							{/*...}*/
								auto line_number = error.dup
									.after (`:`)
									.after (`:`)
									.after (`:`)
									.before (`:`)
									.strip.to!uint;

								auto line = code;
								while (--line_number)
									line = line.after ("\n");
								line = line.before ("\n").strip;

								assert (0, [``, line, error].join ("\n").text);
							}

						return shader;
					}
				void link_variables ()
					{/*...}*/
						foreach (i, Var; Variables)
							{/*...}*/
								static if (Var.storage_class is StorageClass.uniform)
									auto bound = variable_locations[i] = gl.GetUniformLocation (program_id, Var.identifier);

								else static if (Var.storage_class is StorageClass.vertex_input)
									auto bound = variable_locations[i] = gl.GetAttribLocation (program_id, Var.identifier.to_c.expand);

								else static if (Var.storage_class is StorageClass.vertex_fragment)
									variable_locations[i] = -1;

								else static assert (0);

								static if (is (typeof(bound)))
									assert (bound >= 0, Var.identifier ~ ` was not found in the shader (possibly optimized out due to non-use)`);
							}
					}
			}
			public {/*runtime}*/
				Args args;

				this (T...)(auto ref T input)
					{/*...}*/
						foreach (i, ref arg; args)
							static if (is (Args[i] == T[i]) || is (Args[i] == Borrowed!(T[i])))
								arg = input[i];
							else arg = input[i].gpu_array;
					}

				void activate ()()
					in {/*...}*/
						static assert (Args.length == Filter!(or!(is_uniform, is_vertex_input), Variables).length,
							Args.stringof ~ ` does not match ` ~ Filter!(or!(is_uniform, is_vertex_input), Variables).stringof
						);
					}
					body {/*...}*/
						if (program_id == 0)
							initialize;

						gl.program = this;

						foreach (i, ref arg; args)
							{/*...}*/
								alias T = Filter!(or!(is_uniform, is_vertex_input), Variables)[i];

								static if (is_texture!T)
									{/*...}*/
										int texture_unit = IndexOf!(T, Filter!(is_texture, Variables));

										gl.uniform (texture_unit, variable_locations[IndexOf!(T, Variables)]);

										arg.bind (texture_unit);
									}
								
								else static if (is_vertex_input!T)
									arg.bind (variable_locations[IndexOf!(T, Variables)]);

								else static if (is_uniform!T)
									gl.uniform (arg, variable_locations[IndexOf!(T, Variables)]);

								else static assert (0);
							}
					}

				enum is_uniform (V) = V.storage_class is StorageClass.uniform;
				enum is_vertex_input (V) = V.storage_class is StorageClass.vertex_input;
				enum is_texture (V) = is (V.BaseType == Texture);
			}
		}
}
unittest {/*codegen}*/
	alias TestShader = Shader!(
		Variable!`foo`
			.set_base_type!bool
			.set_storage_class!(StorageClass.vertex_input),
		Variable!`bar`
			.set_base_type!vec
			.set_storage_class!(StorageClass.vertex_fragment),
		Variable!`baz`
			.set_base_type!(Vector!(4, float))
			.set_storage_class!(StorageClass.uniform),

		Function!(Stage.vertex, q{glPosition = foo;}),
		Function!(Stage.fragment, q{glFragColor = baz * vec2 (bar, 0, 1);}),

		Variable!`ar`
			.set_base_type!fvec
			.set_storage_class!(StorageClass.uniform),

		Function!(Stage.vertex, q{glPosition *= ar;}),
	);

	static assert (
		TestShader.fragment_code == [
			`#version 440`,
			`in dvec2 bar;`,
			`uniform vec4 baz;`,
			`uniform vec2 ar;`,
			`void main ()`,
			`{`,
			`	glFragColor = baz * vec2 (bar, 0, 1);`,
			`}`
		].join ("\n").text,
		TestShader.fragment_code
	);

	static assert (
		TestShader.vertex_code == [
			`#version 440`,
			`in bool foo;`,
			`out dvec2 bar;`,
			`uniform vec4 baz;`,
			`uniform vec2 ar;`,
			`void main ()`,
			`{`,
			`	glPosition = foo;`,
			`	glPosition *= ar;`,
			`}`,
		].join ("\n").text,
		TestShader.vertex_code
	);
}
