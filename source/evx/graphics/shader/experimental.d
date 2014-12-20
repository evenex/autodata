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
import std.string;

import evx.graphics.opengl;

alias array = evx.containers.array.array; // REVIEW how to exclude std.array.array
alias join = evx.range.join;

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

struct Uniform   (Decl...) {alias Vars = Zip!(Deinterleave!Decl); enum uniform;}
struct Attribute (Decl...) {alias Vars = Zip!(Deinterleave!Decl); enum attribute;}
struct Smooth    (Decl...) {alias Vars = Zip!(Deinterleave!Decl); enum smooth;}
struct Vertex   (string code) {enum main = code; enum vertex;}
struct Fragment (string code) {enum main = code; enum fragment;}

/* notes
	Vert
		.in = x[]
		.out = frag.in
		.uniform = x

	Frag
		.in = x ¬ϵ RTArgs 
		.uniform = x ϵ RTArgs

	on any concat:
		union all.uniform
	on vert concat:
		concat vert.code
		union vert.in
	on frag concat:
		concat frag.code
		union frag.in
		union vert.out
*/

alias TestShader = Shader!(
	).Uniform!(
		int, `a`,
		fvec, `b`,
	).Attribute!(
		fvec, `c`,
		double, `d`,
	).Smooth!(
		Color, `e`,
		uint, `f`,
	).Vertex!q{
		glPosition = b;
	}.Fragment!q{
		glFragColor = vec4 (0,0,1,1);
	};

pragma(msg, TestShader.vertex_stage);

private enum Stage {vertex = GL_VERTEX_SHADER, fragment = GL_FRAGMENT_SHADER}
template SSShader (Stage shader_stage, string main, Parameters...)
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
		mixin SSShader!(Stage.vertex, main, Parameters);
		//pragma(msg, generate);
	}
struct FragmentShader (string main, Parameters...)
	{/*...}*/
		mixin SSShader!(Stage.fragment, main, Parameters);
		//pragma(msg, generate);
	}

struct Shader (Program...)
	{/*...}*/
		template Variables (string storage_class)
			{/*...}*/
				enum StorageClass = storage_class.capitalize;
				enum Decls = StorageClass ~ `s`;

				mixin(q{
					alias } ~ StorageClass ~ q{ (Decl...) = Shader!(Program, .} ~ StorageClass ~ q{!Decl);

					enum is_storage_class (S) = is (S.} ~ storage_class ~ q{);

					alias } ~ Decls ~ q{ = Filter!(is_storage_class, Program);

					static assert (} ~ Decls ~ q{.length < 2);
				});
			}
		template Code (string stage)
			{/*...}*/
				enum Stage = stage.capitalize;

				mixin(q{
					alias } ~ Stage ~ q{ (string code) = Shader!(Program, .} ~ Stage ~ q{!code);

					enum is_shader_stage (S) = is (S.} ~ stage ~ q{);

					enum } ~ stage ~ q{_code () = [Map!(λ!q{(T) = T.main}, Filter!(is_shader_stage, Program))].join.to!string;
				});
			}

		mixin Variables!`uniform`;
		mixin Variables!`attribute`;
		mixin Variables!`smooth`;
		mixin Code!`vertex`;
		mixin Code!`fragment`;

		static string uniforms ()
			{/*...}*/
				static if (is (Uniforms[0]))
					{/*...}*/
						string[] code;

						foreach (pair; Uniforms[0].Vars)
							code ~= `uniform ` ~ glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

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
							code ~= `in ` ~ glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

						return code.join ("\n").to!string;
					}
				else return ``;
			}
		static string smooths (string in_out)()
			{/*...}*/
				static if (is (Smooths[0]))
					{/*...}*/
						string[] code;

						foreach (pair; Smooths[0].Vars)
							code ~= `smooth ` ~ in_out ~ ` ` ~ glsl_typename!(pair.first) ~ ` ` ~ pair.second ~ `;`;

						return code.join ("\n").to!string;
					}
				else return ``;
			}

		static string vertex_stage ()()
			{/*...}*/
				return [
					uniforms,
					attributes,
					smooths!`out`,

					q{void main ()},
					`{`, vertex_code!(), `}`

				].join ("\n").to!string;
			}
		static string fragment_stage ()()
			{/*...}*/
				return [
					uniforms,
					smooths!`in`, 

					q{void main ()}, 
					`{`, fragment_code!(), `}`

				].join ("\n").to!string;
			}
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
