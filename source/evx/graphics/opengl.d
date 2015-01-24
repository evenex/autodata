module evx.graphics.opengl;

private {/*imports}*/
	import std.conv;
	import std.typecons;
	import std.string;

	import evx.misc.utils;
	import evx.type;
	import evx.math;
	import evx.range;

	import derelict.glfw3.glfw3;
}
public import derelict.opengl3.gl3;

void main ()
	{/*...}*/
		import std.stdio;

		scope (exit) std.stdio.stdout.flush;
	}

struct gl
	{/*...}*/
		template type_enum (T)
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

				static if (0 < index && index < ConversionTable.length - 1)
					enum type_enum = ConversionTable[index];
				else static assert (0, T.stringof ~ ` has no opengl equivalent`);
			}

		static:

		shared static {/*ctor/dtor}*/
			shared static this ()
				{/*...}*/
					void initialize_glfw ()
						{/*...}*/
							glfwSetErrorCallback (&error_callback);

							if (not (glfwInit ()))
								assert (0, "glfwInit failed");
						}
					void initialize_glfw_window ()
						{/*...}*/
							window = glfwCreateWindow (1, 1, ``, null, null);
		
							if (window is null)
								assert (0, `window creation failure`);

							glfwHideWindow (window);

							glfwMakeContextCurrent (window);
							glfwSwapInterval (0);

							glfwSetWindowSizeCallback (window, &resize_window_callback);
							glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

							glfwSetWindowTitle (window, text (
								`evx.graphics.display `,
								`(openGL `,
									glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MAJOR),
									`.`,
									glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MINOR),
								`)`
							).to_c.expand);
						}

					DerelictGL3.load ();
					DerelictGLFW3.load ();
					initialize_glfw;
					initialize_glfw_window;
					DerelictGL3.reload ();
				}
			shared static ~this ()
				{/*...}*/
					void terminate_glfw ()
						{/*...}*/
							if (window !is null)
								glfwDestroyWindow (window);

							glfwTerminate ();
						}

					terminate_glfw;
				}
		}

		public:
		public {/*callbacks}*/
			void delegate (size_t width, size_t height) nothrow on_resize;
		}
		public {/*state}*/
			void clear (GLbitfield mask = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
				{/*...}*/
					gl.Clear (mask);
				}
		}
		public {/*general}*/
			public {/*introspection}*/
				auto get (T)(GLenum param)
					{/*...}*/
						T value;

						static if (is (T == Vector!(n,U), uint n, U))
							{}
						else alias U = T;

						static if (is (U == bool))
							enum t_str = `Boolean`;
						else static if (is (U == int))
							enum t_str = `Integer`;
						else static if (is (U == float))
							enum t_str = `Float`;
						else static if (is (U == double))
							enum t_str = `Double`;
						else static assert (0, `glGet ` ~ T.stringof ~ ` not implemented`);

						mixin(q{gl.Get} ~ t_str ~ q{v (param, cast(U*)&value);});

						return value;
					}
			}
			public {/*dispatch}*/
				auto opDispatch (string op, Args...)(Args args)
					if (is (typeof (call!op (args))))
					{/*...}*/
						return call!op (args);
					}
			}
		}
		public {/*buffer}*/
			auto get_buffer_parameter (GLenum target, GLenum parameter)
				{/*...}*/
					int value;

					glGetBufferParameteriv (target, parameter, &value);
					
					return value;
				}

			auto opDispatch (string target, Buffer...)(Buffer buffer)
				if (target.contains (`_buffer`))
				{/*...}*/
					enum set_target = q{GL_} ~ target.toUpper;
					enum get_target = q{GL_} ~ target.toUpper ~ q{_BINDING};

					static if (is (Buffer[0]))
						gl.BindBuffer (mixin(set_target), buffer);
					else return get!int (mixin(get_target));
				}
		}
		public {/*texture}*/
			auto opDispatch (string target, Texture...)(Texture texture)
				if (target.contains (`texture`))
				{/*...}*/
					enum set_target = q{GL_} ~ target.toUpper;
					enum get_target = q{GL_TEXTURE_BINDING} ~ target.find (`_`).toUpper;

					static if (is (Texture[0]))
						gl.BindTexture (mixin(set_target), texture);
					else return get!int (mixin(get_target));
				}
		}
		public {/*framebuffer}*/
			auto opDispatch (string target, Buffer...)(Buffer framebuffer)
				if (target.contains (`framebuffer`))
				{/*...}*/
					enum set_target = q{GL_} ~ target.toUpper;
					enum get_target = q{GL_} ~ target.toUpper ~ q{_BINDING};

					static if (is (Buffer[0]))
						gl.BindFramebuffer (mixin(set_target), framebuffer);
					else return get!int (mixin(get_target));
				}
		}

		private:
		private {/*context}*/
			GLFWwindow* window;
		}
		private {/*callbacks}*/
			extern (C) nothrow:

			void error_callback (int, const (char)* error)
				{/*...}*/
					import std.c.stdio;

					fprintf (stderr, "error glfw: %s\n", error);
				}
			void resize_framebuffer_callback (GLFWwindow* window, int width, int height)
				{/*...}*/
					glViewport (0, 0, width, height);
					//try gl.Viewport (0, 0, width, height);
					//catch (Exception ex) assert (0, ex.msg);
				}
			void resize_window_callback (GLFWwindow*, int width, int height)
				{/*...}*/
					if (gl.on_resize !is null)
						gl.on_resize (width, height);
				}
		}
		private {/*direct call}*/
			template call (string name)
				{/*...}*/
					auto call (Args...)(Args args)
						out {/*...}*/
							error_check!name (args);
						}
						body {/*...}*/
							mixin (q{
								return gl} ~ name ~ q{ (args.to_c.expand);
							});
						}
				}

			void error_check (string name, Args...) (Args args)
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
		}
	}
