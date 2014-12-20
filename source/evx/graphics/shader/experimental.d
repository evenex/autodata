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
template glsl_declaration (T, Args...)
	{/*...}*/
		enum glsl_declaration = glsl_typename!T ~ ` ` ~ ct_values_as_parameter_string!Args;
	}

private {/*glsl variables}*/
	enum StorageClass {vertex_input, vertex_fragment, uniform}

	struct Type (uint n, Base)
		if (Contains!(Base, bool, int, uint, float, double))
		{/*...}*/
			enum decl =	n > 1? (
				is (Base == float)?
				`` : Base.stringof[0].to!string
			) ~ q{vec} ~ n.text
			: (
				Base.stringof
			);
		}

	struct Variable (StorageClass storage_class, Type, string identifier){}
}
private {/*glsl functions}*/
	enum Stage {vertex = GL_VERTEX_SHADER, fragment = GL_FRAGMENT_SHADER}

	struct Function (Stage stage, string code){}
}

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

alias ShaderProgramId = GLuint;
__gshared ShaderProgramId[string] shader_ids;

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
					string[] code;

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
		public {/*runtime}*/
			Args args;
		}
	}

pragma(msg, 
	Shader!(
		Variable!(StorageClass.vertex_input, Type!(1, bool), `foo`),
		Variable!(StorageClass.vertex_fragment, Type!(2, double), `bar`),
		Variable!(StorageClass.uniform, Type!(4, float), `baz`),

		Function!(Stage.vertex, q{glPosition = foo;}),
		Function!(Stage.fragment, q{glFragColor = baz * vec2 (bar, 0, 1);}),

		Variable!(StorageClass.uniform, Type!(2, float), `ar`),
		Function!(Stage.vertex, q{glPosition *= ar;}),
	).fragment_code
);

template vertex_shader (Decl...)
	{/*...}*/
		auto vertex_shader (Input...)(Input input)
			{/*...}*/
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
									alias MakeVar = Variable!(StorageClass.uniform, GetType!Var, Decl[i]);

								else static if (is (Element!Var == T, T))
									alias MakeVar = Variable!(StorageClass.vertex_input, GetType!T, Decl[i]);

								else static assert (0);
							}

						alias Parse = Map!(Pair!().Both!MakeVar, Indexed!Vars);
					}

				static if (is (Input[0] == Shader!Sym, Sym...))
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Cons!(Sym, Parse!(Input[1..$]));
								auto args = tuple (input[0].args, input[1..$]).expand;
							}
						else {/*...}*/
							alias Symbols = Sym;
							auto args = input[0].args;
						}
					}
				else static if (is (Input[0] == Tuple!Data, Data...))
					{/*...}*/
						static if (is (Input[1]))
							{/*...}*/
								alias Symbols = Parse!(Data, Input[1..$]);
								auto args = tuple (input[0].expand, input[1..$]).expand;
							}
						else {/*...}*/
							alias Symbols = Parse!Data;
							auto args = input[0].expand;
						}
					}
				else {/*...}*/
					 alias Symbols = Parse!Input;
					 auto args = input;
				}

				return Shader!(Symbols, typeof(args))(args);
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

				return FragmentShader!(code, signature, Args)(args);
			}
	}

alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
	gl_Position *= aspect_ratio;
});

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
);
std.stdio.writeln (weight_map);
static if (0){
		fragment_shader!(
			Color, `frag_color`, q{
				glFragColor = vec4 (frag_color.rgb, frag_alpha);
			}
		);//.array;

		//static assert (is (typeof(weight_map) == Array!(Color, 2)));

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
		.aspect_correction (aspect_ratio);
		//.output_to (display);
		}
	}
