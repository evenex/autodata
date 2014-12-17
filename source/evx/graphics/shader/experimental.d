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

template vertex_shader (Code...)
	{/*...}*/
		auto vertex_shader (T...)(T args)
			{/*...}*/
				static if (is (T[0] == Tuple!U, U...))
					{}
				else alias U = T;

				auto v = VertexShader!(Code[$-1], Code[0..$-1], U)();
				return 1;
			}
	}
template fragment_shader (Code...)
	{/*...}*/
		auto fragment_shader (T...)(T args)
			{/*...}*/
				return Array!(Color, 2)();
			}
	}

template gl_type_enum (T)
	{/*...}*/
		alias ConversionTable = TypeTuple!(
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

		else static assert (0, `cannot pass ` ~ T.stringof ~ ` directly to shader`);
	}
template glsl_declaration (T, Args...)
	{/*...}*/
		enum glsl_declaration = glsl_typename!T ~ ` ` ~ ct_values_as_parameter_string!Args;
	}

struct VertexShader (string main, Vars...)
	{/*...}*/
		template GetVars (alias pair)
			{/*...}*/
				static if (is (pair.first == VertexShader!T, T...))
					alias GetVars = pair.first.Variables;
				else alias GetVars = pair;
			}

		template code ()
			{/*...}*/
				template get_code (T...)
					{/*...}*/
						static if (is (T[0] == VertexShader!U, U...))
							enum this_code = T[0].code!();
						else enum this_code = ``;

						static if (T.length == 1)
							enum get_code = this_code;
						else enum get_code = this_code ~ get_code!(T[1..$]);
					}

				enum code = main ~ get_code!(Filter!(is_type, Vars));
			}

		alias Variables = Map!(GetVars,
			Zip!(
				Filter!(is_type, Vars),
				Filter!(is_string_param, Vars),
			)
		);

		static generate ()
			{/*...}*/
				string[] code;

				uint location;

				foreach (Var; Variables)
					static if (is (typeof(glsl_typename!(Var.first))))
						code ~= `uniform ` ~ glsl_typename!(Var.first) ~ ` ` ~ Var.second ~ `;`"\n";
					else code ~= `layout (location = ` ~ (location++).text ~ `) in ` ~ glsl_typename!(Element!(Var.first)) ~ ` ` ~ Var.second ~ `;`"\n";

				return code.join.to!string;
			}

		pragma(msg, code!());
	}

struct FragmentShader (string code, Vars...)
	{/*...}*/
		
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

		static if (0)
		{/*...}*/
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
		)(texture)
		.aspect_correction (aspect_ratio)
		.output_to (display);
		}
	}
