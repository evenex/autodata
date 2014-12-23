module evx.graphics.shader;

__gshared struct GraphicsContext
	{/*...}*/
		static:


	}

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

template glsl_declaration (T, Args...)
	{/*...}*/
		enum glsl_declaration = glsl_typename!T ~ ` ` ~ ct_values_as_parameter_string!Args;
	}

private {/*glsl variables}*/
	enum StorageClass {vertex_input, vertex_fragment, uniform}

	struct Type (uint n, Base)
		if (Contains!(Base, bool, int, uint, float, double, Texture))
		{/*...}*/
			enum decl =	n > 1? (
				is (Base == float)?
				`` : Base.stringof[0].to!string
			) ~ q{vec} ~ n.text
			: (
				is (Base == Texture)?
				q{sampler2D} : Base.stringof
			);
		}

	struct Variable (StorageClass storage_class, Type, string identifier){}
}
private {/*glsl functions}*/
	enum Stage {vertex = GL_VERTEX_SHADER, fragment = GL_FRAGMENT_SHADER}

	struct Function (Stage stage, string code){}
}

alias ShaderProgramId = GLuint;
__gshared ShaderProgramId[string] shader_ids;

template GPUType (T)
	{/*...}*/
		static if (is (T == GLBuffer!U, U...))
			alias GPUType = T;
		else static if (is (typeof(T.init[].source) == GLBuffer!U, U...))
			alias GPUType = T;
		else static if (is (typeof(T.init.gpu_array) == U, U))
			alias GPUType = U;

		else alias GPUType = T;
	}

struct Shader (Parameters...)
	{/*...}*/
		enum Mode
			{/*...}*/
				points = GL_POINTS,
				l_strip = GL_LINE_STRIP,
				l_loop = GL_LINE_LOOP,
				lines = GL_LINES,
				t_strip = GL_TRIANGLE_STRIP,
				t_fan = GL_TRIANGLE_FAN,
				tris = GL_TRIANGLES
			}

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
					string[] code = [q{#version 420}];

					{/*variables}*/
						foreach (V; Variables)
							{/*...}*/
								static if (is (V == Variable!(storage_class, Type, identifier), 
									StorageClass storage_class, Type, string identifier
								)) 
									{/*...}*/
										static if (storage_class is StorageClass.vertex_input)
											{/*...}*/
												static if (stage is Stage.vertex)
													enum qual = q{in};
											}

										else static if (storage_class is StorageClass.vertex_fragment)
											{/*...}*/
												static if (stage is Stage.vertex)
													enum qual = q{out};

												else static if (stage is Stage.fragment)
													enum qual = q{in};
											}

										else static if (storage_class is StorageClass.uniform)
											{/*...}*/
												enum qual = q{uniform};
											}

										static if (is (typeof(qual)))
											code ~= qual ~ ` ` ~ Type.decl ~ ` ` ~ identifier ~ `;`;
									}
							}
					}
					{/*functions}*/
						code ~= [q{void main ()}, `{`];

						foreach (F; Functions)
							static if (is (F == Function!(stage, main), string main))
								code ~= "\t" ~ main;

						code ~= `}`;
					}

					return code.join ("\n").to!string;
				}
		}
		static {/*runtime}*/
			__gshared:
			ShaderProgramId program_id = 0;
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
						static if (is (Var == Variable!(storage_class, T, name),
							StorageClass storage_class, T, string name
						))
							{/*...}*/
								static if (storage_class is StorageClass.uniform)
									variable_locations[i] = gl.GetUniformLocation (program_id, name.to_c.expand);

								else static if (storage_class is StorageClass.vertex_input)
									variable_locations[i] = gl.GetAttribLocation (program_id, name.to_c.expand);

								else static if (storage_class is StorageClass.vertex_fragment)
									variable_locations[i] = -1;

								else static assert (0);
							}
						else static assert (0);
				}
		}
		public {/*runtime}*/
			Args args;
			Mode mode;

			this (T...)(auto ref T input)
				{/*...}*/
					foreach (i,_; Args)
						static if (is (Args[i] == T[i]))
							input[i].move (args[i]);
						else args[i] = input[i].gpu_array;
				}

			enum is_uniform (T) = is (T == Variable!(StorageClass.uniform, U), U...);
			enum is_vertex_input (T) = is (T == Variable!(StorageClass.vertex_input, U), U...);
			enum is_texture (T) = is (T == Variable!(StorageClass.uniform, Type!(1, Texture), U), U...);

			void activate ()()
				in {/*...}*/
					static assert (Args.length == Filter!(or!(is_uniform, is_vertex_input), Variables).length);
				}
				body {/*...}*/
					if (program_id == 0)
						initialize;

					gl.UseProgram (program_id);

					foreach (i, ref arg; args)
						{/*...}*/
							alias T = Filter!(or!(is_uniform, is_vertex_input), Variables)[i];

							static if (is_texture!T || is_vertex_input!T)
								arg.bind (variable_locations[IndexOf!(T, Variables)]); // TODO ensure that what you're binding to has compatible properties

							else static if (is_uniform!T)
								gl.uniform (arg, variable_locations[IndexOf!(T, Variables)]);

							else static assert (0);
						}
				}
		}
	}


unittest {/*codegen}*/
	alias TestShader = Shader!(
		Variable!(StorageClass.vertex_input, Type!(1, bool), `foo`),
		Variable!(StorageClass.vertex_fragment, Type!(2, double), `bar`),
		Variable!(StorageClass.uniform, Type!(4, float), `baz`),

		Function!(Stage.vertex, q{glPosition = foo;}),
		Function!(Stage.fragment, q{glFragColor = baz * vec2 (bar, 0, 1);}),

		Variable!(StorageClass.uniform, Type!(2, float), `ar`),
		Function!(Stage.vertex, q{glPosition *= ar;}),
	);

	static assert (
		TestShader.fragment_code == [
			`#version 420`,
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
			`#version 420`,
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

template decl_syntax_check (Decl...)
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

private alias Front (T...) = T[0]; // HACK https://issues.dlang.org/show_bug.cgi?id=13883

template vertex_shader (Decl...) // TODO enforce that data containers don't belong as args... only shit thats copy constructible... slices and PODs
	{/*...}*/
		mixin decl_syntax_check!(Decl[0..$-1]);

		auto vertex_shader (Input...)(auto ref Input input)
			{/*...}*/
				alias DeclTypes = Filter!(is_type, Decl[0..$-1]);
				alias Identifiers = Filter!(is_string_param, Decl[0..$-1]);
				enum code = Decl[$-1];

				template Parse (Vars...)
					{/*...}*/
						template GetType (Var)
							{/*...}*/
								static if (is (Var == Vector!(n,T), size_t n, T))
									alias GetType = Type!(n, T);

								else static if (is (Type!(1, Var)))
									alias GetType = Type!(1, Var);

								else static assert (0);
							}

						template MakeVar (uint i, Var)
							{/*...}*/
								static if (is (GetType!Var))
									alias MakeVar = Variable!(StorageClass.uniform, GetType!Var, Identifiers[i]);

								else static if (is (Element!Var == T, T))
									alias MakeVar = Variable!(StorageClass.vertex_input, GetType!T, Identifiers[i]);

								else static assert (0);

								static if (is (DeclTypes[i] == U, U))
									static assert (is (MakeVar == MakeVar!(i, U)), 
										`argument type does not match declared type`
									);
							}

						alias Parse = Map!(Pair!().Both!MakeVar, Indexed!Vars);
					}

				static if (is (Input[0] == Shader!Sym, Sym...))
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Cons!(Input[0].Symbols, Parse!(Input[1..$]));
								alias Args = Cons!(Input[0].Args, Input[1..$]);
							}
						else {/*...}*/
							alias Symbols = Front!Input.Symbols; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
							alias Args = Front!Input.Args;
						}
					}
				else static if (is (Input[0] == Tuple!Data, Data...))
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Parse!(Data, Input[1..$]);
								alias Args = Cons!(Input[0].Types, Input[1..$]);
							}
						else {/*...}*/
							alias Symbols = Parse!Data;
							alias Args = Front!Input.Types; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
						}
					}
				else {/*...}*/
					 alias Symbols = Parse!Input;
					 alias Args = Input;
				}

				alias S = Shader!(Symbols, 
					Function!(Stage.vertex, code),
					Map!(GPUType, Args),
				);
				
				auto shader 	()() {return S (input[0].args);}
				auto shader_etc ()() {return S (input[0].args, input[1..$]);}
				auto tuple 		()() {return S (input[0].expand);}
				auto tuple_etc 	()() {return S (input[0].expand, input[1..$]);}
				auto forward_all ()() {return S (input);}

				return Match!(shader_etc, shader, tuple_etc, tuple, forward_all);
			}
	}
template fragment_shader (Decl...)
	{/*...}*/
		mixin decl_syntax_check!(Decl[0..$-1]);

		static assert (is (Decl[0]), 
			`fragment shader auto type deduction not implemented`
		);

		auto fragment_shader (Input...)(auto ref Input input)
			{/*...}*/
				alias DeclTypes = Filter!(is_type, Decl[0..$-1]);
				alias Identifiers = Filter!(is_string_param, Decl[0..$-1]);
				enum code = Decl[$-1];

				template GetType (uint i)
					{/*...}*/
						alias T = DeclTypes[i];

						static if (is (T == Vector!(n,U), size_t n, U))
							alias GetType = Type!(n,U);

						else alias GetType = Type!(1,T);
					}

				alias Uniform (uint i) = Variable!(StorageClass.uniform, GetType!i, Identifiers[i]);
				alias Smooth (uint i) = Variable!(StorageClass.vertex_fragment, GetType!i, Identifiers[i]);

				static if (is (Input[1]))
					static assert (
						All!(Pair!().Both!(λ!q{(T, U) = is (T == U)}),
							Zip!(Input[1..$], DeclTypes[$-(Input.length - 1)..$])
						)
					);

				static if (is (Input[0] == Shader!Sym, Sym...))
					{/*...}*/
						enum is_uniform (uint i) =
							i > DeclTypes.length - Input.length // tail Decltypes correspond with Inputs, and all Inputs are Uniforms, therefore tail Decltypes are Uniforms
							|| Contains!(Uniform!i, Input[0].Symbols);

						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Front!Input.Symbols; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
								alias Args = Cons!(Front!Input.Args, Input[1..$]);
							}
						else {/*...}*/
							alias Symbols = Front!Input.Symbols; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
							alias Args = Front!Input.Args;
						}
					}
				else static if (is (Input[0] == Tuple!Data, Data...))
					{/*...}*/
						static assert (0, `tuple arg not valid for fragment shader`);
					}
				else {/*...}*/
					static assert (0, `fragment shader must be attached to vertex shader`);
				}

				alias S = Shader!(Symbols, 
					Map!(Uniform, Filter!(is_uniform, Count!DeclTypes)),
					Map!(Smooth, Filter!(not!is_uniform, Count!DeclTypes)),
					Function!(Stage.fragment, code),
					Map!(GPUType, Args)
				);
				
				auto forward_all_args 	 ()() {return S (input[0].args, input[1..$]);}
				auto forward_shader_args ()() {return S (input[0].args);}
				auto forward_input_args  ()() {return S (input);}

				return Match!(forward_all_args, forward_shader_args, forward_input_args);
			}
	}

alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
	gl_Position.xy *= aspect_ratio;
});

// DRAW MODES
ref triangle_fan (S)(ref S shader)
	{/*...}*/
		shader.mode = S.Mode.t_fan;

		return shader;
	}
auto triangle_fan (S)(S shader)
	{/*...}*/
		S next;

		swap (shader, next);

		next.triangle_fan;

		return next;
	}

template RenderTarget (int permanent_id = -1)
	{/*...}*/
		static if (permanent_id < 0)
			GLuint renderbuffer_id;
		else enum GLuint renderbuffer_id = permanent_id.to!GLuint;

		void draw (T)(T order)
			if (is(T.render_order))
			{/*...}*/
				order.renderer.process (order);
			}
		void draw (R...)(R orders)
			if (All!(has_trait!`render_order`, staticMap!(ElementType, R)))
			{/*...}*/
				foreach (queue; orders)
					foreach (subqueue; queue.group!((a,b) => a.renderer == b.renderer))
						queue.front.renderer.process (queue);
			}
	}

auto output_to (S,R,T...)(S shader, R render_target, T args)
	{/*...}*/
		//GLuint framebuffer_id = 0; // TODO create framebuffer
		//gl.GenFramebuffers (1, &framebuffer_id); TODO to create a framebuffer
		//gl.BindFramebuffer (GL_FRAMEBUFFER, framebuffer_id); // TODO to create a framebuffer
		// gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderedTexture, 0); TODO to set texture output
		// gl.DrawBuffers TODO set frag outputs to draw to these buffers, if you use this then you'll need to modify the shader program, to add some fragment_output variables

		shader.activate;
		gl.BindFramebuffer (GL_FRAMEBUFFER, render_target.framebuffer_id);
		// render_target.bind; REVIEW how does this interact with texture.bind, or any other bindable I/O type
		// render_target.draw (shader.args, args); REVIEW do this, or get length of shader array args? in latter case, how do we pick the draw mode?
	}

void main () // TODO the goal
	{/*...}*/
	import evx.graphics.display;
	auto display = new Display; // BUG display launches gfx context which is required for shader stuff, but fialure to do so segs. need sensible errmsg:

		auto positions = circle.map!(to!fvec);
		auto weights = ℕ[0..circle.length].map!(to!float);
		Color color = red;

		auto weight_map = τ(positions, weights, color)
			.vertex_shader!(`position`, `weight`, `base_color`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_color = vec4 (base_color.rgb, weight);
				frag_alpha = weight;
			}).fragment_shader!(
				Color, `frag_color`,
				float, `frag_alpha`, q{
				gl_FragColor = vec4 (frag_color.rgb, frag_alpha);
			});

		//);//.array; TODO
		//static assert (is (typeof(weight_map) == Array!(Color, 2))); TODO

		auto aspect_ratio = fvec(1.0, 2.0);

		auto tex_coords = circle.scale (0.5).map!(to!fvec);
		auto texture = Texture (ℕ[0..256].by (ℕ[0..256]).map!((i,j) => red));

		import std.stdio;
		τ(positions, tex_coords).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = tex_coords;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture)
		.aspect_correction (aspect_ratio)
		.triangle_fan.output_to (display);
	}
