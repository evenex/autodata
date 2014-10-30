module evx.graphics.opengl;

private {/*imports}*/
	import std.conv;

	import evx.misc.utils;
}
public:
	import derelict.glfw3.glfw3;
	import derelict.opengl3.gl3;

struct gl
	{/*...}*/
		static auto ref opDispatch (string name, Args...) (Args args)
			{/*...}*/
				debug scope (exit) check_GL_error!name (args);

				static if (name == "GetUniformLocation")
					mixin (q{
						return gl} ~name~ q{ (to_c (args).expand); }
					);
				else mixin ("return gl"~name~" (args);");
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

						assert (null, `GL error: ` ~error_log);
					}
			}
	}
