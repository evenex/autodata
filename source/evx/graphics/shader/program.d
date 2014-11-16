module evx.graphics.shader.program;
public import evx.graphics.shader.parameters;

/* shader programs 
	consist of 2 shaders: vertex and fragment 

	shaders consist of 3 parts: the input, output and the body.
		the body is a string containing the shader's main function code, in GLSL
		the input and output are Input and Output templates, respectively.
			the templates contain declaration lists 
				(i.e. interleaved types and identifier strings)
			in these declaration lists, 
				non-array types denote uniform variables,
				while array types denote per-work-item data
					(i.e:
						for vertex input, this is per-vertex data in an attribute buffer
						for vertex output, this writes interpolated data
						for fragment input, this reads interpolated data
						for fragment output, this is per-fragment data in a render target
					)
			in addition, default initializers may be specified in the declaration lists,
				using the Init!(...) template,
					where the ... parameters are numeric constructor components

	shader programs must be activated before use
		after activating a shader, all subsequent glDraw* calls will use that shader

	parameters can be set using a builder pattern
		it is an error to set parameters before activating the shader

	all shader programs use the following set of common parameters:
		translation
		rotation
		scale
		aspect_ratio
*/

private {/*imports}*/
	import std.conv;
	import std.string;
	import std.typetuple;

	import evx.graphics.opengl;

	import evx.math;
	import evx.range;
	import evx.traits;
	import evx.codegen;
}

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

		void activate ()
			{/*...}*/
				gl.UseProgram (program);

				link_uniforms (program);
			}

		public:
		public {/*parameters}*/
			auto ref aspect_ratio (vec ratio)
				{/*...}*/
					set_uniform (gl.GetUniformLocation (program, `aspect_ratio`), ratio);

					return this;
				}

			auto ref transform (T)(T affine)
				{/*...}*/
					return this.translation (affine.translation)
						.rotation (affine.rotation)
						.scale (affine.scale);
				}

			static if (Vert.Inputs.length > 0)
				mixin(AttributeLinker!(Vert.Inputs).code);

			mixin(
				UniformLinker!(
					Vert.Inputs, Frag.Inputs,
					Perspective, AspectRatio,
				).code
			);
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
		package:
		package {/*data}*/
			GLuint program;
		}
		private:
		private {/*codegen}*/
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
	}
	unittest {/*...}*/
		import evx.graphics;

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
			GLuint shader_object;
			alias shader_object this;

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
			private {/*code gen}*/
				static shader_code ()
					{/*...}*/
						string shader_code = q{
							#version } ~glsl_version.text~ q{
						};

						static if (Inputs.length)
							{/*declare input variables}*/
								shader_code ~= declare_uniform_variables!Input;
								shader_code ~= declare_attribute_variables!(shader_type, Input);

								static if (shader_type is GL_VERTEX_SHADER)
									{/*declare common inputs}*/
										shader_code ~= declare_uniform_variables!Perspective;
										shader_code ~= declare_uniform_variables!AspectRatio;
									}
							}

						static if (Outputs.length)
							{/*declare output variables}*/
								shader_code ~= declare_uniform_variables!Output;
								shader_code ~= declare_attribute_variables!(shader_type, Output);
							}

						static if (shader_type is GL_VERTEX_SHADER)
							{/*apply common transform}*/
								enum transform = perspective ~ aspect_ratio;
							}
						else enum transform = ``;

						shader_code ~= q{
							void main (void) 
							}`{`q{
								} ~code~ q{
								} ~transform~ q{
							}`}`q{
						};

						return shader_code;
					}
			}
		}
}
private {/*common shader code}*/
	alias Perspective = Input!(
		fvec,   `translation`,	Init!(0,0),
		float,  `rotation`,		Init!(0),
		float,  `scale`,		Init!(1),
	);
	enum perspective = q{
		float cos_rotation = cos (rotation);
		float sin_rotation = sin (rotation);

		gl_Position.xy = scale * vec2 (
			cos_rotation * gl_Position.x - sin_rotation * gl_Position.y, 
			sin_rotation * gl_Position.x + cos_rotation * gl_Position.y
		) + translation;
	};

	alias AspectRatio = Input!(
		fvec, `aspect_ratio`, Init!(1,1),
	);
	enum aspect_ratio = q{
		gl_Position.xy *= aspect_ratio;
	};
}
