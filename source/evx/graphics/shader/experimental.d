module evx.graphics.shader;

import evx.range;

import evx.math;
import evx.type;
import evx.containers;

import evx.misc.tuple;
import evx.misc.utils;
import evx.misc.memory;

import std.typecons;
import std.conv;
import std.string;
import std.ascii;

import evx.graphics.opengl;
import evx.graphics.buffer;
import evx.graphics.texture;
import evx.graphics.color;

alias array = evx.containers.array.array; // REVIEW how to exclude std.array.array
alias join = evx.range.join;

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

//////////////////////////////////////////
/// COMPILATION AND LINKING //////////////
//////////////////////////////////////////
private {/*symbol}*/
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
private {/*precompiled}*/
	__gshared GLuint[string] shader_ids;
}

// CONCATTING SHADER PROGRAM BACKEND
struct Shader (Parameters...)
	{/*...}*/
		alias Symbols = NoDuplicates!(Filter!(or!(is_variable, is_function), Parameters));
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
					assert (gl.IsProgram (program_id) && program_id != 0);
				}
				body {/*...}*/
					auto key = [vertex_code, fragment_code].join.filter!(not!isWhite).to!string;

					if (auto id = key in shader_ids)
						program_id = *id;
					else {/*...}*/
						build_program;

						shader_ids[key] = program_id;
					}
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
						{assert (0, error);}

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

//////////////////////////////////////////
// FRAMING ///////////////////////////////
//////////////////////////////////////////
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

//////////////////////////////////////////
// HELPER TRAITS ETC /////////////////////
//////////////////////////////////////////
// MAKE SURE ITS A ID LIST OR AN INTERLEAVED DECL LIST
template decl_format_verification (Decl...)
	{/*...}*/
		static assert (
			All!(is_string_param, Decl)
			|| (
				All!(is_type, Deinterleave!Decl[0..$/2])
				&& All!(is_string_param, Deinterleave!Decl[$/2..$])
			),
			`shader declarations must either all be explicitly typed (T, "a", U, "b"...)`
			` or auto typed ("a", "b"...) and cannot be mixed`
		);
	}
// DIFFERENTIATE RANGES FROM VECTORS
enum is_range (T) = not (is (T == Element!T) || is (T == Vector!V, V...));

//////////////////////////////////////////
// SHADER HELPER FUNCTIONS ///////////////
//////////////////////////////////////////
template generic_shader (Stage stage, Decl...)
	{/*...}*/
		auto generic_shader (Input...)(auto ref Input input)
			{/*...}*/
				mixin decl_format_verification!(Decl[0..$-1]);

				enum code = Decl[$-1];

				alias DeclTypes = Filter!(is_type, Decl[0..$-1]);
				alias Identifiers = Filter!(is_string_param, Decl[0..$-1]);

				template ResolvedSymbols ()
					{/*...}*/
						static if (is (Input[0] == Shader!Symbols, Symbols...))
							{}

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

								static if (is (Symbols))
									alias Lookup = Filter!(identifier_match, Symbols)[0];
								else static assert (0);
							}

						template InitialVars ()
							{/*...}*/
								alias InitialVars = Map!(Variable, Identifiers);
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
													Zip!(InitialVars!(), DeclTypes)
												),
												Cons!(
													Repeat!(InitialVars!().length - Params!().length, Unknown),
													Params!()
												)
											)
										);

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

										alias TypedVars = Map!(Pair!().Both!Deduce, Zip!(InitialVars!(), Params!()));
									}
								else static assert (not (stage is Stage.fragment),
									`Fragment shaders do not yet support automatic type deduction, and currently can only use a typed declaration list.`
								);
							}
						template StoredVars ()
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

								alias StoredVars = Map!(Assign, TypedVars!());
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

						alias ResolvedSymbols = Map!(Resolve, StoredVars!());
					}

				/////////////////////////////////////////////////////////////////

				static if (is (Input[0] == Shader!Sym, Sym...))
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Cons!(Input[0].Symbols, ResolvedSymbols!());
								alias Args = Cons!(Input[0].Args, Map!(GPUType, Input[1..$]));
							}
						else {/*...}*/
							alias Symbols = Cons!(Input[0].Symbols); // https://issues.dlang.org/show_bug.cgi?id=13883
							alias Args = Cons!(Input[0].Args);
						}
					}
				else static if (is (Input[0] == Tuple!Data, Data...)) // XXX removal pending http://wiki.dlang.org/DIP32
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = ResolvedTypes!(); // BUG this will miss things in the tuple
								alias Args = Map!(GPUType, Cons!(Data, Input[1..$]));
							}
						else {/*...}*/
							alias Symbols = ResolvedSymbols!();
							alias Args = Map!(GPUType, Data);
						}

						static assert (stage != Stage.fragment, 
							`tuple arg not valid for fragment shader`
						);
					}
				else {/*...}*/
					alias Symbols = ResolvedSymbols!();
					alias Args = Map!(GPUType, Input);

					static assert (stage != Stage.fragment, 
						`fragment shader must be attached to vertex shader`
					);
				}

				/////////////////////////////////////////////////////////////////

				alias S = Shader!(
					Symbols,
					Function!(stage, code),
					Args
				);
				
				auto shader 	 ()() {return S (input[0].args);}
				auto shader_etc  ()() {return S (input[0].args, input[1..$]);}
				auto tuple 		 ()() {return S (input[0].expand);}
				auto tuple_etc 	 ()() {return S (input[0].expand, input[1..$]);}
				auto forward_all ()() {return S (input);}

				return Match!(shader_etc, shader, tuple_etc, tuple, forward_all);
			}
	}

alias vertex_shader (Decl...) = generic_shader!(Stage.vertex, Decl);
alias fragment_shader (Decl...) = generic_shader!(Stage.fragment, Decl);

//////////////////////////////////////////
// PARTIAL SHADERS ///////////////////////
//////////////////////////////////////////
alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
	gl_Position.xy *= aspect_ratio;
});

//////////////////////////////////////////
// PROTO RENDERERS ///////////////////////
//////////////////////////////////////////
struct ProtoRenderer (S)
	{/*...}*/
		RenderMode mode;
		S shader;

		alias shader this; // TEMP
	}
auto triangle_fan (S)(ref S shader)
	{/*...}*/
		auto renderer = ProtoRenderer!S (RenderMode.t_fan);

		swap (renderer.shader, shader);

		return renderer;
	}
auto triangle_fan (S)(S shader)
	{/*...}*/
		S next;

		swap (shader, next);

		return next.triangle_fan;
	}

// OPERATORS
template CanvasOps (alias preprocess, alias setup, alias managed_id = identity)
	{/*...}*/
		static assert (is (typeof(preprocess(Shader!().init)) == Shader!Sym, Sym...),
			`preprocess: Shader → Shader`
		);
		// TODO really the bufferops belong over here, renderops opindex is just for convenience

		GLuint framebuffer_id ()
			{/*...}*/
				auto managed ()()
					{/*...}*/
						return managed_id;
					}
				auto unmanaged ()()
					{/*...}*/
						if (fbo_id == 0)
							gl.GenFramebuffers (1, &fbo_id);

						return fbo_id;
					}

				auto ret = Match!(managed, unmanaged); // TEMP return this


				glBindFramebuffer (GL_FRAMEBUFFER, ret);//TEMP

				setup; // TEMP when to do this?

				return ret;
			}

		static if (is (typeof(managed_id.identity)))
			alias fbo_id = managed_id;
		else GLuint fbo_id;

		auto attach (S)(S shader)
			if (is (S == Shader!Sym, Sym...))
			{/*...}*/
				preprocess (shader).activate;
			}
	}

template RenderOps (alias draw, shaders...)
	{/*...}*/
		static {/*analysis}*/
			enum is_shader (alias s) = is (typeof(s) == Shader!Sym, Sym...);
			enum rendering_stage_exists (uint i) = is (typeof(draw!i ()) == void);

			static assert (All!(is_shader, shaders),
				`shader symbols must resolve to Shaders`
			);
			static assert (All!(rendering_stage_exists, Count!shaders),
				`each given shader symbol must be accompanied by a function `
				`draw: (uint n)() → void, where n is the index of the associated rendering stage`
			);
		}
		public {/*rendering}*/
			auto ref render_to (T)(auto ref T canvas)
				{/*...}*/
					void render (uint i = 0)()
						{/*...}*/
							canvas.attach (shaders[i]);
							draw!i;

							static if (i+1 < shaders.length)
								render!(i+1);
						}

					gl.framebuffer = canvas;

					render;

					return canvas;
				}
		}
		public {/*convenience}*/
			Texture default_canvas;

			alias default_canvas this;

			auto opIndex (Args...)(Args args)
				{/*...}*/
					if (default_canvas.volume == 0)
						{/*...}*/
							default_canvas.allocate (256, 256); // REVIEW where to get default resolution?
							render_to (default_canvas);
						}

					return default_canvas.opIndex (args);
				}
		}
	}

// TO DEPRECATE, GOING INTO RENDEROPS
auto ref output_to (S,R,T...)(auto ref S shader, auto ref R target, T args)
	{/*...}*/
		//GLuint framebuffer_id = 0; // TODO create framebuffer
		//gl.GenFramebuffers (1, &framebuffer_id); TODO to create a framebuffer
		//gl.BindFramebuffer (GL_FRAMEBUFFER, framebuffer_id); // TODO to create a framebuffer
		// gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderedTexture, 0); TODO to set texture output
		// gl.DrawBuffers TODO set frag outputs to draw to these buffers, if you use this then you'll need to modify the shader program, to add some fragment_output variables
			GLuint fboid;
				static if (is (R == Texture))
					{/*...}*/
				//target.framebuffer_id;
				glGenFramebuffers (1, &fboid);

			//	target.allocate (256,256);
				target = ℕ[0..100].by (ℕ[0..100]).map!(x => yellow).Texture;
				glBindFramebuffer (GL_FRAMEBUFFER, fboid);//TEMP
				glFramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, target.texture_id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
				//glFramebufferTexture2D (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target.texture_id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
					}



			auto check () // TODO REFACTOR this goes somewhere... TODO make specific error messages for all the openGL calls
				{/*...}*/
					switch (glCheckFramebufferStatus (GL_FRAMEBUFFER)) 
						{/*...}*/
							case GL_FRAMEBUFFER_COMPLETE:
								return;

							case GL_FRAMEBUFFER_UNDEFINED:
								assert(0, `target is the default framebuffer, but the default framebuffer does not exist.`);

							case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
								assert(0, `some of the framebuffer attachment points are framebuffer incomplete.`);

							case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
								assert(0, `framebuffer does not have at least one image attached to it.`);

							case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
								assert(0, `value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for some color attachment point(s) named by GL_DRAW_BUFFERi.`);

							case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
								assert(0, `GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for the color attachment point named by GL_READ_BUFFER.`);

							case GL_FRAMEBUFFER_UNSUPPORTED:
								assert(0, `combination of internal formats of the attached images violates an implementation-dependent set of restrictions.`);

							case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
								assert(0, `value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers; or the value of GL_TEXTURE_SAMPLES is the not same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_RENDERBUFFER_SAMPLES does not match the value of GL_TEXTURE_SAMPLES.`
									"\n"`or the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not the same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not GL_TRUE for all attached textures.`
								);

							case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS:
								assert(0, `some framebuffer attachment is layered, and some populated attachment is not layered, or all populated color attachments are not from textures of the same target.`);

							default:
								assert (0, `framebuffer error`);
						}
				}

		shader.activate;
		gl.framebuffer = fboid;
		//gl.framebuffer = target.framebuffer_id;

		if (gl.framebuffer == 0)
			glDrawBuffer (GL_BACK);
		else glDrawBuffer (GL_COLOR_ATTACHMENT0);

		check;

		if (gl.framebuffer != 0)
			gl.ClearColor (1,0,0,1);
		else gl.ClearColor (0.1,0.1,0.1,1);

		gl.Clear (GL_COLOR_BUFFER_BIT);

		template length (uint i)
			{/*...}*/
				auto length ()() if (not (is (typeof(shader.args[i]) == Vector!U, U...)))
					{return shader.args[i].length.to!int;}
			}

		gl.DrawArrays (shader.mode, 0, Match!(Map!(length, Count!(S.Args))));

		// render_target.bind; REVIEW how does this interact with texture.bind, or any other bindable I/O type
		// render_target.draw (shader.args, args); REVIEW do this, or get length of shader array args? in latter case, how do we pick the draw mode?
				//glViewport (0,0,1000,1000);
				glBindFramebuffer (GL_FRAMEBUFFER, 0);//TEMP

		/*
			init FBO
			attach tex to FBO
			bind FBO
			draw
			unbind FBO
			use tex wherever
		*/

		return target;
	}

void main () // TODO GOAL
	{/*...}*/
		import evx.graphics.display;
		auto display = new Display;

		auto vertices = circle.map!(to!fvec)
			.enumerate.map!((i,v) => i%2? v : v/4);

		auto weights = ℕ[0..circle.length].map!(to!float);
		Color color = red;

		auto weight_map = τ(vertices, weights, color)
			.vertex_shader!(`position`, `weight`, `base_color`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_color = vec4 (base_color.rgb, weight);
				frag_alpha = weight;
			}).fragment_shader!(
				Color, `frag_color`,
				float, `frag_alpha`, q{
				gl_FragColor = vec4 (frag_color.rgb, frag_alpha);
			}).triangle_fan;

		//);//.array; TODO
		//static assert (is (typeof(weight_map) == Array!(Color, 2))); TODO

		auto tex_coords = circle.map!(to!fvec)
			.flip!`vertical`;

		auto texture = ℝ[0..1].by (ℝ[0..1])
			.map!((x,y) => Color (0, x^^4, x^^2) * 1)
			.grid (256, 256)
			.Texture;

		// TEXTURED SHAPE SHADER
		τ(vertices, tex_coords).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = (tex_coords + vec2 (1,1))/2;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture)
		.aspect_correction (display.aspect_ratio)
		.triangle_fan.output_to (display);

		display.render;

		import core.thread;
		Thread.sleep (2.seconds);

		Texture target;
		target.allocate (256,256);

		vertices.vertex_shader!(
			`pos`, q{
				gl_Position = vec4 (pos, 0, 1);
			}
		).fragment_shader!(
			Color, `col`, q{
				gl_FragColor = col;
			}
		)(blue)
		.triangle_fan
		.output_to (target);

		τ(square!float, square!float.scale (2.0f).translate (fvec(0.5))).vertex_shader!(
			`pos`, `texc_in`, q{
				gl_Position = vec4 (pos, 0, 1);
				texc = texc_in;
			}
		).fragment_shader!(
			fvec, `texc`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, texc);
			}
		)(target).triangle_fan.output_to (display);

		display.render;

		Thread.sleep (2.seconds);
	}

auto textured_shape_shader (R)(R shape, auto ref Texture texture)
	{/*...}*/
		return τ(shape, shape.scale (2).flip!`vertical`).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = (tex_coords + vec2 (1,1))/2;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture);
	}

unittest {/*texture transfer}*/
	import evx.graphics.display;
	auto display = new Display;

	auto vertices = square!float;

	auto tex1 = ℕ[0..100].by (ℕ[0..100]).map!((i,j) => (i+j)%2? red: yellow).Texture;
	auto tex2 = ℕ[0..50].by (ℕ[0..50]).map!((i,j) => (i+j)%2? blue: green).grid (100,100).Texture;

	assert (tex1[0,0] == yellow);

	tex1[50..75, 25..75] = tex2[0..25, 0..50];

	// TEXTURED SHAPE SHADER
	Cons!(vertices, tex1).textured_shape_shader // REVIEW Cons only works for symbols, rvalues need to be in tuples... with DIP32, this distinction will be removed (i think)
	.aspect_correction (display.aspect_ratio)
	.triangle_fan.output_to (display);

	display.render;

	assert (tex1[0,0] == yellow);

	import core.thread;
	Thread.sleep (1.seconds);
}

//////////////////////////////////////////
// RENDERING /////////////////////////////
//////////////////////////////////////////
// THIS BELONGS TO RENDERERS BUT MUST SOMEHOW BE USED UNDER UNIFORM RENDERING API ELSE RISK INCONSISTENCY DOWNSTREAM
enum RenderMode
	{/*...}*/
		point = GL_POINTS,
		l_strip = GL_LINE_STRIP,
		l_loop = GL_LINE_LOOP,
		line = GL_LINES,
		t_strip = GL_TRIANGLE_STRIP,
		t_fan = GL_TRIANGLE_FAN,
		tri = GL_TRIANGLES
	}
