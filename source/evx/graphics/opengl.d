module evx.graphics.opengl;

private {/*imports}*/
	import std.conv;
	import std.typecons;

	import evx.misc.utils;
	import evx.type;
	import evx.math;
}
public:
	import derelict.glfw3.glfw3;
	import derelict.opengl3.gl3;

struct gl
	{/*...}*/
		static:

		template type (T)
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
					enum type = ConversionTable[index];
				else static assert (0, T.stringof ~ ` has no opengl equivalent`);
			}

		auto ref opDispatch (string name, Args...) (Args args)
			{/*...}*/
				debug scope (exit) check_GL_error!name (args);

				mixin (q{
					return gl} ~ name ~ q{ (args);
				});
			}

		void check_GL_error (string name, Args...) (Args args)
			{/*...}*/
				GLenum error;

				while ((error = glGetError ()) != GL_NO_ERROR)
					{/*...}*/
						string error_msg;

						final switch (error)
							{/*...}*/
								case GL_INVALID_ENUM:
									error_msg = "GL_INVALID_ENUM";
									break;
								case GL_INVALID_VALUE:
									error_msg = "GL_INVALID_VALUE";
									break;
								case GL_INVALID_OPERATION:
									error_msg = "GL_INVALID_OPERATION";
									break;
								case GL_INVALID_FRAMEBUFFER_OPERATION:
									error_msg = "GL_INVALID_FRAMEBUFFER_OPERATION";
									break;
								case GL_OUT_OF_MEMORY:
									error_msg = "GL_OUT_OF_MEMORY";
									break;
							}

						assert (0, `OpenGL error ` ~error.text~ `: ` ~error_msg~ "\n"
							`    calling gl` ~function_call_to_string!name (args)
						);
					}
			}

		auto verify (string object_type)(GLuint gl_object)
			{/*...}*/
				GLint status;

				const string glGet_iv = q{glGet} ~object_type~ q{iv};
				const string glGet_InfoLog = q{glGet} ~object_type~ q{InfoLog};
				const string glStatus = object_type == `Shader`? `COMPILE`:`LINK`;

				mixin(q{
					} ~glGet_iv~ q{ (gl_object, GL_} ~glStatus~ q{_STATUS, &status);
				});

				if (status == GL_FALSE) 
					{/*error}*/
						GLchar[] error_log; 
						GLsizei log_length;

						mixin(q{
							} ~glGet_iv~ q{(gl_object, GL_INFO_LOG_LENGTH, &log_length);
						});

						error_log.length = log_length;

						mixin (q{
							} ~glGet_InfoLog~ q{(gl_object, log_length, null, error_log.ptr);
						});

						return error_log.to!string;
					}
				else return null;
			}

		void uniform (T)(T value, GLuint index = 0)
			in {/*...}*/
				GLint program, n_uniforms;

				gl.GetIntegerv (GL_CURRENT_PROGRAM, &program);
				gl.GetProgramiv (program, GL_ACTIVE_UNIFORMS, &n_uniforms);

				assert (index < n_uniforms,
					`uniform location invalid`
				);

				char[256] name;
				GLint sizeof;
				GLenum type;

				gl.GetActiveUniform (program, index, name.length.to!int, null, &sizeof, &type, name.ptr);

				auto uniform_type (T)()
					{/*...}*/
						import evx.graphics.texture;//TEMP circular dep

						alias ConversionTable = Cons!(
							float, `FLOAT`,
							double, `DOUBLE`,
							int, `INT`,
							uint, `UNSIGNED_INT`,
							bool, `BOOL`,
							Texture, `SAMPLER_2D`,
						);

						enum n = `_VEC` ~ T.length.text;
							
						static if (Contains!(T, ConversionTable))
							mixin(q{
								return ConversionTable[IndexOf!(T, ConversionTable) + 1];
							});
						else return -1;
					}

				auto uniform_call (GLenum type)
					{/*...}*/
						return [
							-1: `unknown type`,

							GL_FLOAT: `float`,
							GL_FLOAT_VEC2: `vec2`,
							GL_FLOAT_VEC3: `vec3`,
							GL_FLOAT_VEC4: `vec4`,
							GL_DOUBLE: `double`,
							GL_DOUBLE_VEC2: `dvec2`,
							GL_DOUBLE_VEC3: `dvec3`,
							GL_DOUBLE_VEC4: `dvec4`,
							GL_INT: `int`,
							GL_INT_VEC2: `ivec2`,
							GL_INT_VEC3: `ivec3`,
							GL_INT_VEC4: `ivec4`,
							GL_UNSIGNED_INT: `uint`,
							GL_UNSIGNED_INT_VEC2: `uvec2`,
							GL_UNSIGNED_INT_VEC3: `uvec3`,
							GL_UNSIGNED_INT_VEC4: `uvec4`,
							GL_BOOL: `bool`,
							GL_BOOL_VEC2: `bvec2`,
							GL_BOOL_VEC3: `bvec3`,
							GL_BOOL_VEC4: `bvec4`,
							GL_FLOAT_MAT2: `mat2`,
							GL_FLOAT_MAT3: `mat3`,
							GL_FLOAT_MAT4: `mat4`,
							GL_FLOAT_MAT2x3: `mat2x3`,
							GL_FLOAT_MAT2x4: `mat2x4`,
							GL_FLOAT_MAT3x2: `mat3x2`,
							GL_FLOAT_MAT3x4: `mat3x4`,
							GL_FLOAT_MAT4x2: `mat4x2`,
							GL_FLOAT_MAT4x3: `mat4x3`,
							GL_DOUBLE_MAT2: `dmat2`,
							GL_DOUBLE_MAT3: `dmat3`,
							GL_DOUBLE_MAT4: `dmat4`,
							GL_DOUBLE_MAT2x3: `dmat2x3`,
							GL_DOUBLE_MAT2x4: `dmat2x4`,
							GL_DOUBLE_MAT3x2: `dmat3x2`,
							GL_DOUBLE_MAT3x4: `dmat3x4`,
							GL_DOUBLE_MAT4x2: `dmat4x2`,
							GL_DOUBLE_MAT4x3: `dmat4x3`,
							GL_SAMPLER_1D: `sampler1D`,
							GL_SAMPLER_2D: `sampler2D`,
							GL_SAMPLER_3D: `sampler3D`,
							GL_SAMPLER_CUBE: `samplerCube`,
							GL_SAMPLER_1D_SHADOW: `sampler1DShadow`,
							GL_SAMPLER_2D_SHADOW: `sampler2DShadow`,
							GL_SAMPLER_1D_ARRAY: `sampler1DArray`,
							GL_SAMPLER_2D_ARRAY: `sampler2DArray`,
							GL_SAMPLER_1D_ARRAY_SHADOW: `sampler1DArrayShadow`,
							GL_SAMPLER_2D_ARRAY_SHADOW: `sampler2DArrayShadow`,
							GL_SAMPLER_2D_MULTISAMPLE: `sampler2DMS`,
							GL_SAMPLER_2D_MULTISAMPLE_ARRAY: `sampler2DMSArray`,
							GL_SAMPLER_CUBE_SHADOW: `samplerCubeShadow`,
							GL_SAMPLER_BUFFER: `samplerBuffer`,
							GL_SAMPLER_2D_RECT: `sampler2DRect`,
							GL_SAMPLER_2D_RECT_SHADOW: `sampler2DRectShadow`,
							GL_INT_SAMPLER_1D: `isampler1D`,
							GL_INT_SAMPLER_2D: `isampler2D`,
							GL_INT_SAMPLER_3D: `isampler3D`,
							GL_INT_SAMPLER_CUBE: `isamplerCube`,
							GL_INT_SAMPLER_1D_ARRAY: `isampler1DArray`,
							GL_INT_SAMPLER_2D_ARRAY: `isampler2DArray`,
							GL_INT_SAMPLER_2D_MULTISAMPLE: `isampler2DMS`,
							GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: `isampler2DMSArray`,
							GL_INT_SAMPLER_BUFFER: `isamplerBuffer`,
							GL_INT_SAMPLER_2D_RECT: `isampler2DRect`,
							GL_UNSIGNED_INT_SAMPLER_1D: `usampler1D`,
							GL_UNSIGNED_INT_SAMPLER_2D: `usampler2D`,
							GL_UNSIGNED_INT_SAMPLER_3D: `usampler3D`,
							GL_UNSIGNED_INT_SAMPLER_CUBE: `usamplerCube`,
							GL_UNSIGNED_INT_SAMPLER_1D_ARRAY: `usampler2DArray`,
							GL_UNSIGNED_INT_SAMPLER_2D_ARRAY: `usampler2DArray`,
							GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE: `usampler2DMS`,
							GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: `usampler2DMSArray`,
							GL_UNSIGNED_INT_SAMPLER_BUFFER: `usamplerBuffer`,
							GL_UNSIGNED_INT_SAMPLER_2D_RECT: `usampler2DRect`,
							GL_IMAGE_1D: `image1D`,
							GL_IMAGE_2D: `image2D`,
							GL_IMAGE_3D: `image3D`,
							GL_IMAGE_2D_RECT: `image2DRect`,
							GL_IMAGE_CUBE: `imageCube`,
							GL_IMAGE_BUFFER: `imageBuffer`,
							GL_IMAGE_1D_ARRAY: `image1DArray`,
							GL_IMAGE_2D_ARRAY: `image2DArray`,
							GL_IMAGE_2D_MULTISAMPLE: `image2DMS`,
							GL_IMAGE_2D_MULTISAMPLE_ARRAY: `image2DMSArray`,
							GL_INT_IMAGE_1D: `iimage1D`,
							GL_INT_IMAGE_2D: `iimage2D`,
							GL_INT_IMAGE_3D: `iimage3D`,
							GL_INT_IMAGE_2D_RECT: `iimage2DRect`,
							GL_INT_IMAGE_CUBE: `iimageCube`,
							GL_INT_IMAGE_BUFFER: `iimageBuffer`,
							GL_INT_IMAGE_1D_ARRAY: `iimage1DArray`,
							GL_INT_IMAGE_2D_ARRAY: `iimage2DArray`,
							GL_INT_IMAGE_2D_MULTISAMPLE: `iimage2DMS`,
							GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY: `iimage2DMSArray`,
							GL_UNSIGNED_INT_IMAGE_1D: `uimage1D`,
							GL_UNSIGNED_INT_IMAGE_2D: `uimage2D`,
							GL_UNSIGNED_INT_IMAGE_3D: `uimage3D`,
							GL_UNSIGNED_INT_IMAGE_2D_RECT: `uimage2DRect`,
							GL_UNSIGNED_INT_IMAGE_CUBE: `uimageCube`,
							GL_UNSIGNED_INT_IMAGE_BUFFER: `uimageBuffer`,
							GL_UNSIGNED_INT_IMAGE_1D_ARRAY: `uimage1DArray`,
							GL_UNSIGNED_INT_IMAGE_2D_ARRAY: `uimage2DArray`,
							GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE: `uimage2DMS`,
							GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY: `uimage2DMSArray`,
							GL_UNSIGNED_INT_ATOMIC_COUNTER: `atomic_uint`,
						][type];
					}

				assert (type == uniform_type!T,
					`attempted to upload ` ~ T.stringof ~ ` to uniform ` ~ uniform_call (type) ~ ` ` ~ name
				);
			}
			body {/*...}*/
				static if (is (T == Vector!(n,U), uint n, U))
					{}
				else {/*...}*/
					enum n = 1;
					alias U = T;
				}

				mixin(q{
					gl.Uniform} ~ n.text ~ U.stringof[0] ~ q{ (index, value.tuple.expand);
				});
			}
	}


