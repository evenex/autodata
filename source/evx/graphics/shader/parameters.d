module evx.graphics.shader.parameters;

private {/*import}*/
	import std.typetuple;
	import std.typecons;
	import std.range;
	import std.conv;
	import std.traits;

	import evx.math.logic;
	import evx.math.geometry.traits;
	import evx.codegen.declarations;
	import evx.traits.classification;

	import evx.graphics.opengl;
}

public {/*shader params}*/
	struct Input (Args...)
		{/*...}*/
			enum is_input_params;

			alias List = Args;

			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Filter!(not!is_initializer, Args)
			);
		}
	struct Output (Args...)
		{/*...}*/
			enum is_output_params;

			alias List = Args;

			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Args
			);
		}

	struct Init (T...)
		{/*...}*/
			enum is_initializer;
			enum value = T;
		}

	enum Uniform;
}

package {/*traits}*/
	template is_initializer (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_initializer = allSatisfy!(has_trait!`is_initializer`, T);
		}

	template is_per_element_variable (T)
		{/*...}*/
			enum is_per_element_variable = is(T == U[], U);
		}
	alias is_uniform_variable = not!is_per_element_variable;

}
package {/*type processing}*/
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

			enum index = staticIndexOf!(T, ConversionTable) + 1;

			static if (index > 0)
				enum gl_type_enum = ConversionTable[index];
			else static assert (0, T.stringof~ ` has no opengl equivalent`);
		}
	template glsl_typename (T)
		{/*...}*/
			static if (is_vector!T)
				{/*...}*/
					enum stringof = ElementType!T.stringof[0].text ~`vec`~ T.length.text;

					static if (is(ElementType!T == float))
						enum glsl_typename = stringof[1..$];
					else enum glsl_typename = stringof;
				}
			else static if (isScalarType!T)
				enum glsl_typename = T.stringof;
			else static assert (0, `cannot pass ` ~T.stringof~ ` directly to shader`);
		}
	template glsl_declaration (T, Args...)
		{/*...}*/
			enum glsl_declaration = glsl_typename!T~ ` ` ~ct_values_as_parameter_string!Args;
		}
}
package {/*extraction}*/
	template get_initializer (string name, Args...)
		{/*...}*/
			enum init_index = staticIndexOf!(name, Args) + 1;

			static if (init_index < Args.length)
				{/*...}*/
					static if (is_initializer!(Args[init_index]))
						alias get_initializer = Args[init_index];
					else alias get_initializer = TypeTuple!();
				}
			else alias get_initializer = TypeTuple!();
		}

	template Uniforms (ShaderVariables)
		{/*...}*/
			alias Uniforms = Let!(ShaderVariables.Types, ShaderVariables.Names).OnlyWithTypes!is_uniform_variable.be_listed;
		}

	template Attributes (ShaderVariables)
		{/*...}*/
			alias Attributes = Let!(ShaderVariables.Types, ShaderVariables.Names).OnlyWithTypes!is_per_element_variable.be_listed;
		}
}
package {/*code generation}*/
	template declare_uniform_variables (ShaderVariables)
		{/*...}*/
			static code ()
				{/*...}*/
					string code;

					struct Split 
						{/*...}*/
							mixin ParameterSplitter!(
								`Types`, is_type,
								`Names`, is_string_param,
								Uniforms!ShaderVariables
							);
						}

					with (Split) foreach (i, T; Types)
						code ~= declare_uniform_variable!(T, Names[i], get_initializer!(Names[i], ShaderVariables.List));

					return code;
				}

			enum declare_uniform_variables = code;
		}
		template declare_uniform_variable (T, string name, Initial...)
			{/*...}*/
				static if (Initial.length == 0)
					enum declare_uniform_variable = q{
						uniform } ~glsl_typename!T~ q{ } ~name~ q{;
					};
				else enum declare_uniform_variable = q{
					uniform } ~glsl_typename!T~ q{ } ~name~ q{ = } ~glsl_declaration!(T, Initial[0].value)~ q{;
				};
			}

	template declare_attribute_variables (GLenum shader_type, ShaderVariables)
		{/*...}*/
			enum ParamType {input = true, output = false}
			enum parameter_type = ParamType (allSatisfy!(has_trait!`is_input_params`, ShaderVariables));

			static code ()
				{/*...}*/
					string code;

					struct Split 
						{/*...}*/
							mixin ParameterSplitter!(
								`Types`, is_type,
								`Names`, is_string_param,
								Attributes!ShaderVariables
							);
						}

					with (Split) foreach (i, T; Types)
						static if (shader_type is GL_VERTEX_SHADER)
							{/*...}*/
								static if (parameter_type is ParamType.input)
									code ~= declare_layout_variable!(T, Names[i], i);
								else static if (parameter_type is ParamType.output)
									code ~= declare_regular_variable!(q{smooth out}, T, Names[i]);
							}
						else static if (shader_type is GL_FRAGMENT_SHADER)
							{/*...}*/
								static if (parameter_type is ParamType.input)
									code ~= declare_regular_variable!(q{smooth in}, T, Names[i]);
								else static if (parameter_type is ParamType.output)
									code ~= declare_regular_variable!(q{out}, T, Names[i]);
							}
						else static assert (0);

					return code;
				}

			enum declare_attribute_variables = code;
		}
		template declare_layout_variable (T, string name, uint index)
			{/*...}*/
				enum declare_layout_variable = q{
					layout (location = } ~index.text~ q{) in } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
				};
			}
		template declare_regular_variable (string storage_class, T, string name)
			{/*...}*/
				enum declare_regular_variable = q{
					} ~storage_class~ q{ } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
				};
			}
}
package {/*linkers}*/
	struct AttributeLinker (ShaderVariables)
		{/*...}*/
			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Attributes!ShaderVariables
			);

			static code ()
				{/*...}*/
					string code;

					foreach (i, T; Types)
						code ~= q{
							auto } ~Names[i]~ q{ (R)(R buffer)
								}`{`q{
									buffer.link_attribute (} ~i.text~ q{);
									return this;
								}`}`q{
						};

					return code;
				}
		}

	auto link_attribute (R)(R buffer, uint index)
		if (is(R.gl_buffer) || is(R.Source.gl_buffer))
		{/*...}*/
			gl.EnableVertexAttribArray (index);

			buffer.bind; // BUG we can't do this with subbuffers... how to specify subbuffers of verts, elements and attributes for linkage? 

			static if (is_vector!(ElementType!R))
				{/*...}*/
					enum int n = ElementType!R.length;
					alias T = ElementType!(ElementType!R);
				}
			else {/*...}*/
				enum int n = 1;
				alias T = ElementType!R;
			}

			enum not_normalized = GL_FALSE;

			gl.VertexAttribPointer (index, n, gl_type_enum!T, not_normalized, 0, null);
		}

	struct UniformLinker (ShaderVariables...)
		{/*...}*/
			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Let!(staticMap!(Uniforms, ShaderVariables))
					.be_listed
			);

			static code ()
				{/*...}*/
					string code;

					foreach (i, T; Types)
						code ~= q{
							private GLint uniform_} ~Names[i]~ q{;

							public auto } ~Names[i]~ q{ (T)(T value) // TODO verify the value type
								}`{`q{
									set_uniform (uniform_} ~Names[i]~ q{, value);
									return this;
								}`}`q{
						};

					code ~= q{
						auto link_uniforms (GLuint program)
							}`{`;

						foreach (name; Names)
							code ~= q{
								uniform_} ~name~ q{ = gl.GetUniformLocation (program, }`"` ~name~ `"`q{);
							};

					code ~= `}`;

					return code;
				}
		}
}

void set_uniform (T)(GLuint handle, T value) // REFACTOR
	{/*...}*/
		static if (is_vector!T)
			{/*...}*/
				enum length = T.length.text;
				alias U = ElementType!T;
			}
		else {/*...}*/
			enum length = `1`;
			alias U = T;
		}

		enum type = glsl_typename!U[0].text;
		enum call = "gl.Uniform" ~length~type;

		mixin(q{
			} ~call~ q{ (handle, value.tuple.expand);
		});

	}
