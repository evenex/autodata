module evx.graphics.shader.program;

private {/*imports}*/
	import std.conv;
	import std.string;
	import std.typetuple;

	import evx.graphics.opengl;

	import evx.math;

	import evx.traits;//	import evx;//	import evx.traits;//	import evx.traits.classification;
	import evx.codegen;//	import evx;//	import evx.codegen;//	import evx.codegen.declarations;
}

public import evx.graphics.shader.parameters;

enum glsl_version = 420;

class ShaderProgram (Vert, Frag)
	{/*...}*/
		static {/*verification}*/
			static if (Vert.Outputs.length == 1 && Frag.Inputs.length == 1)
				{/*...}*/
					alias InterpolateOut = Let!(Vert.Output.Types, Vert.Output.Names).OnlyWithTypes!is_per_element_variable;
					alias InterpolateIn = Let!(Frag.Input.Types, Frag.Input.Names).OnlyWithTypes!is_per_element_variable;

					static assert (is(InterpolateOut == InterpolateIn),
						`per-vertex vertex shader outputs do not match interpolated fragment shader inputs`"\n"
						~InterpolateOut.be_declared~ ` != ` ~InterpolateIn.be_declared
					);
				}
		}

		static if (Vert.Inputs.length > 0)
			mixin(AttributeLinker!(Vert.Inputs).code);

		mixin(UniformLinker!(Vert.Inputs, Frag.Inputs).code);

		public {/*codegen}*/
			static code ()
				{/*...}*/
					return Vert.shader_code ~ Frag.shader_code;
				}

			static uniform_variables ()
				{/*...}*/
					return declare!(Uniforms!(Vert.Input), Uniforms!(Frag.Input));
				}
			static uniform_handles ()
				{/*...}*/
					alias Names = Filter!(is_string_param, Uniforms!(Vert.Input), Uniforms!(Frag.Input));

					template to_GLint (T...)
						{/*...}*/
							alias to_GLint = GLint;
						}

					return declare!(Names, staticMap!(to_GLint, Names));
				}
		}

		public {/*ctor}*/
			this ()
				{/*...}*/
					auto vert_shader = new Vert;
					auto frag_shader = new Frag;

					program = gl.CreateProgram ();

					gl.AttachShader (program, vert_shader);
					gl.AttachShader (program, frag_shader);

					gl.LinkProgram (program); 
					gl.verify!`Program` (program);

					gl.DeleteShader (vert_shader);
					gl.DeleteShader (frag_shader);
					gl.DetachShader (program, vert_shader);
					gl.DetachShader (program, frag_shader);
				}
		}
		public {/*program}*/ // TODO package
			GLuint program;

			void activate ()
				{/*...}*/
					gl.UseProgram (program);

					link_uniforms (program);
				}
		}
	}
	unittest {/*...}*/
		import evx.graphics;//		import evx.graphics.display;
		import evx.graphics;//		import evx.graphics.buffer;
		import evx.graphics;//		import evx.graphics.shader.repo;

		scope display = new Display;
		scope shader = new BasicShader;

		auto verts = circle.map!(to!fvec).gpu_array;

		display.attach (shader);

		shader.position (verts)
			.color (Color (1.0, 0.0, 0.0, 0.5));

		gl.DrawArrays (GL_TRIANGLE_FAN, 0, verts.length.to!int);

		display.render;

		import core.thread;
		Thread.sleep (500.msecs);
	}

template VertexShader (Parameters...)
	{/*...}*/
		alias VertexShader = Shader!(GL_VERTEX_SHADER, Parameters);
	}
template FragmentShader (Parameters...)
	{/*...}*/
		alias FragmentShader = Shader!(GL_FRAGMENT_SHADER, Parameters);
	}

private {/*implementation}*/
	class Shader (GLenum shader_type, Parameters...)
		{/*...}*/
			private {/*definitions}*/
				alias Inputs = Filter!(has_trait!`is_input_params`, Parameters);
				alias Outputs = Filter!(has_trait!`is_output_params`, Parameters);
				alias Code = Filter!(is_string_param, Parameters);
				static {/*assertions}*/
					static assert (Inputs.length <= 1);
					static assert (Outputs.length <= 1);
					static assert (Code.length == 1);
				}

				static if (Inputs.length)
					alias Input = Inputs[0];
				else alias Input = TypeTuple!();

				static if (Outputs.length)
					alias Output = Outputs[0];
				else alias Output = TypeTuple!();

				enum code = Code[0];
			}
			private {/*ctor}*/
				this ()
					{/*...}*/
						shader_object = gl.CreateShader (shader_type);

						auto source = shader_code.toStringz;

						gl.ShaderSource (shader_object, 1, &source, null);
						gl.CompileShader (shader_object);

						gl.verify!`Shader` (shader_object);
					}
			}
			public {/*data}*/ // TODO package
				GLuint shader_object;
				alias shader_object this;
			}
			static {/*code gen}*/
				string shader_code ()
					{/*...}*/
						string shader_code = q{
							#version } ~glsl_version.text~ q{

							uniform vec2 aspect_ratio = vec2 (1,1);
						};

						static if (Inputs.length)
							{/*...}*/
								shader_code ~= declare_uniform_variables!Input;
								shader_code ~= declare_attribute_variables!(shader_type, Input);
							}

						static if (Outputs.length)
							{/*...}*/
								shader_code ~= declare_uniform_variables!Output;
								shader_code ~= declare_attribute_variables!(shader_type, Output);
							}

						static if (shader_type is GL_VERTEX_SHADER)
							enum correction = q{gl_Position *= vec4 (aspect_ratio, 1, 1);};
						else enum correction = ``;

						shader_code ~= q{
							void main (void) 
							}`{`q{
								} ~code~ q{
								} ~correction~ q{
							}`}`q{
						};

						return shader_code;
					}
			}
		}
}
