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
			`in dvec2 bar;`,
			`uniform vec4 baz;`,
			`uniform vec2 ar;`,
			`void main ()`,
			`{`,
			`	glFragColor = baz * vec2 (bar, 0, 1);`,
			`}`
		].join ("\n").text
	);

	static assert (
		TestShader.vertex_code == [
			`in bool foo;`,
			`out dvec2 bar;`,
			`uniform vec4 baz;`,
			`uniform vec2 ar;`,
			`void main ()`,
			`{`,
			`	glPosition = foo;`,
			`	glPosition *= ar;`,
			`}`,
		].join ("\n").text
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

template vertex_shader (Decl...)
	{/*...}*/
		mixin decl_syntax_check!(Decl[0..$-1]);

		auto vertex_shader (Input...)(Input input)
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
								auto args = tuple (input[0].args, input[1..$]).expand;
							}
						else {/*...}*/
							alias Symbols = Front!Input.Symbols; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
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

				return Shader!(Symbols, Function!(Stage.vertex, code), typeof(args))(args);
			}
	}
template fragment_shader (Decl...)
	{/*...}*/
		mixin decl_syntax_check!(Decl[0..$-1]);

		static assert (is (Decl[0]), 
			`fragment shader auto type deduction not implemented`
		);

		auto fragment_shader (Input...)(Input input)
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
								auto args = tuple (input[0].args, input[1..$]).expand;
							}
						else {/*...}*/
							alias Symbols = Front!Input.Symbols; // HACK https://issues.dlang.org/show_bug.cgi?id=13883
							auto args = input[0].args;
						}
					}
				else static if (is (Input[0] == Tuple!Data, Data...))
					{/*...}*/
						static assert (0, `tuple arg not valid for fragment shader`);
					}
				else {/*...}*/
					static assert (0, `fragment shader must be attached to vertex shader`);
				}

				return Shader!(Symbols, 
					Map!(Uniform, Filter!(is_uniform, Count!DeclTypes)),
					Map!(Smooth, Filter!(not!is_uniform, Count!DeclTypes)),
					Function!(Stage.fragment, code),
					typeof(args)
				)(args);
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
			.vertex_shader!(`position`, `weight`, `base_color`, q{
				glPosition = position;
				frag_color = vec4 (base_color.rgb, weight);
				frag_alpha = weight;
			}).fragment_shader!(Color, `frag_color`, q{
				glFragColor = vec4 (frag_color.rgb, frag_alpha);
			});

		//);//.array;
		//static assert (is (typeof(weight_map) == Array!(Color, 2)));

		auto aspect_ratio = vec(1.0, 2.0);

		vec[] tex_coords;
		Texture texture;

		import std.stdio;
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
