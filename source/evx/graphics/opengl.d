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
		static auto ref opDispatch (string name, Args...) (Args args)
			{/*...}*/
				debug scope (exit) check_GL_error!name (args);

				mixin (q{
					return gl} ~ name ~ q{ (args);
				});
			}
		static check_GL_error (string name, Args...) (Args args)
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

		static verify (string object_type)(GLuint gl_object)
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

		static uniform (T)(T value, GLuint index = 0)
			{/*...}*/
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

struct Texture
	{/*...}*/
		 GLuint id;
		 alias id this;

		 void bind (GLuint index = 0)
			in {/*...}*/
				assert (id != 0);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.BindTexture (GL_TEXTURE_2D, id);
			}
	}
