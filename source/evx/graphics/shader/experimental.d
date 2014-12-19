module evx.graphics.shader;

__gshared struct GraphicsContext
	{/*...}*/
		static:


	}

import evx.range;

import evx.math;
import evx.type;
import evx.graphics.color;
import evx.misc.tuple;
import evx.containers;

import std.typecons;
import std.conv;

import evx.graphics.opengl;

alias array = evx.containers.array.array; // REVIEW how to exclude std.array.array

template gl_type_enum (T)
	{/*...}*/
		alias ConversionTable = Cons!(
			byte,   GL_BYTE,
			ubyte,  GL_UNSIGNED_BYTE,
			short,  GL_SHORT,
			ushort, GL_UNSIGNED_SHORT,
			int,    GL_INT,
			uint,   GL_UNSIGNED_INT,
			float,  GL_FLOAT,
			double, GL_DOUBLE,
		);

		enum index = IndexOf!(T, ConversionTable) + 1;

		static if (index > 0)
			enum gl_type_enum = ConversionTable[index];
		else static assert (0, T.stringof ~ ` has no opengl equivalent`);
	}
template glsl_typename (T)
	{/*...}*/
		static if (is_vector_array!T)
			{/*...}*/
				enum stringof = ElementType!T.stringof[0].text ~`vec`~ T.length.text;

				static if (is (ElementType!T == float))
					enum glsl_typename = stringof[1..$];

				else enum glsl_typename = stringof;
			}

		else static if (is_scalar_type!T)
			enum glsl_typename = T.stringof;

		else static if (is (T == Texture)) // TODO 2D/3D
			enum glsl_typename = `sampler2D`;

		else static assert (0, `no glsl equivalent for ` ~ T.stringof);
	}
template glsl_declaration (T, Args...)
	{/*...}*/
		enum glsl_declaration = glsl_typename!T ~ ` ` ~ ct_values_as_parameter_string!Args;
	}

private enum Stage {vertex = GL_VERTEX_SHADER, fragment = GL_FRAGMENT_SHADER}

struct Uniform (Decl...) {alias Vars = Zip!Decl; enum uniform;}
struct Attribute (Decl...) {alias Vars = Zip!Decl; enum attribute;}
struct Smooth (Decl...) {alias Vars = Zip!Decl; enum smooth;}

struct ShaderProgram (Variables...)
	{/*...}*/
		alias Uniform (Decl...)   = ShaderProgram!(Variables, .Uniform!Decl);
		alias Attribute (Decl...) = ShaderProgram!(Variables, .Attribute!Decl);
		alias Smooth (Decl...)    = ShaderProgram!(Variables, .Smooth!Decl);

		alias Uniforms = Filter!(λ!q{(S) = is (S.uniform)}, Variables);
		alias Attributes = Filter!(λ!q{(S) = is (S.attribute)}, Variables);
		alias Smooths = Filter!(λ!q{(S) = is (S.smooth)}, Variables);

		static assert (Uniforms.length < 2);
		static assert (Attributes.length < 2);
		static assert (Smooths.length < 2);

		static string uniforms ()
			{/*...}*/
				static if (is (Uniforms[0]))
					{/*...}*/
						string[] code;

						foreach (pair; Uniforms[0].Vars)
							code ~= glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

						return code.join ("\n").to!string;
					}
				else return ``;
			}
		static string attributes ()
			{/*...}*/
				static if (is (Attributes[0]))
					{/*...}*/
						string[] code;

						foreach (pair; Attributes[0].Vars)
							code ~= glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

						return code.join ("\n").to!string;
					}
				else return ``;
			}
		static string smooths ()
			{/*...}*/
				static if (is (Smooths[0]))
					{/*...}*/
						string[] code;

						foreach (pair; Smooths[0].Vars)
							code ~= glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

						return code.join ("\n").to!string;
					}
				else return ``;
			}

		static string vertex_stage ()
			{/*...}*/
				return [uniforms, attributes, smooths].join ("\n").to!string;
			}
	}

pragma(msg, ShaderProgram!().Uniform!(int, `poot`).vertex_stage);


template Shader (Stage shader_stage, string main, Parameters...)
	{/*...}*/
		enum shader;
		enum is_shader (T) = is (T.shader);
		enum stage = shader_stage;

		alias Shaders = Filter!(is_shader, Filter!(is_type, Parameters));
		alias Arguments = Filter!(not!is_shader, Filter!(is_type, Parameters));
		alias Identifiers = Filter!(not!is_type, Parameters);

		alias Signature = Cons!(
			Zip!(Arguments, Identifiers),
			Map!(Λ!q{(S) = S.Signature}, Shaders)
		);

		template code ()
			{/*...}*/
				enum same_stage (S) = S.stage == shader_stage;

				enum code = Map!(λ!q{(T) = T.code!()}, Filter!(same_stage, Shaders)).stringof[1..$] ~ main;
			}

		Shaders shaders;
		Arguments args;

		static generate ()
			{/*...}*/
				string[] code;

				uint location;

				const glsl_qualifier = stage is Stage.vertex? // BUG this is not how you tell a uniform from a smooth
					`uniform ` : `smooth in `;

				foreach (Var; Zip!(Arguments, Identifiers))
					static if (is (typeof(glsl_typename!(Var.first))))
						code ~= glsl_qualifier ~ glsl_typename!(Var.first) ~ ` ` ~ Var.second ~ `;`"\n";
					else code ~= `layout (location = ` ~ (location++).text ~ `) in ` ~ glsl_typename!(Element!(Var.first)) ~ ` ` ~ Var.second ~ `;`"\n";

				return code.join.to!string ~ 
					q{void main () }`{`
						~ typeof(this).code!() ~
					`}`;
			}
	}
struct VertexShader (string main, Parameters...)
	{/*...}*/
		mixin Shader!(Stage.vertex, main, Parameters);
		//pragma(msg, generate);
	}
struct FragmentShader (string main, Parameters...)
	{/*...}*/
		mixin Shader!(Stage.fragment, main, Parameters);
		//pragma(msg, generate);
	}

template vertex_shader (Defs...)
	{/*...}*/
		auto vertex_shader (T...)(T data)
			{/*...}*/
				static if (is (T[0] == Tuple!Args, Args...))
					auto args = data[0].expand;
				else {/*...}*/
					alias Args = T;
					alias args = data;
				}

				alias signature = Defs[0..$-1];
				enum code = Defs[$-1];

				return VertexShader!(code, signature, Args)(args);
			}
	}
template fragment_shader (Defs...)
	{/*...}*/
		auto fragment_shader (T...)(T data)
			{/*...}*/
				static if (is (T[0] == Tuple!Args, Args...))
					auto args = data[0].expand;
				else {/*...}*/
					alias Args = T;
					alias args = data;
				}

				alias signature = Defs[0..$-1];
				enum code = Defs[$-1];

			//	auto f = FragmentShader!(code, signature, Args)(args);

				return Array!(Color, 2)();
			}
	}

void main () // TODO the goal
	{/*...}*/
		vec[] positions;
		double[] weights;
		Color color;

		auto weight_map = τ(positions, weights, color)
			.vertex_shader!(`position`, `weight`, `color`, q{
				glPosition = position;
				frag_color = color;
				frag_alpha = weight;
			},
		).fragment_shader!(
			Color, `frag_color`, q{
				glFragColor = vec4 (frag_color.rgb, frag_alpha);
			}
		).array;

		static assert (is (typeof(weight_map) == Array!(Color, 2)));

		alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
			gl_Position *= aspect_ratio;
		});
		auto aspect_ratio = vec(1.0, 2.0);

		vec[] tex_coords;
		Texture texture;

		τ(positions, tex_coords).vertex_shader!(
			`position`, `tex_coords`, q{
				glPosition = position;
				frag_tex_coords = tex_coords;
			}
		).fragment_shader!(
			vec, `frag_tex_coords`,
			Texture, `tex`, q{
				glFragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture);
//		.aspect_correction (aspect_ratio)
//		;
		//.output_to (display);
	}
