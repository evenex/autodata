module evx.graphics.display;

private {/*imports}*/
	import std.algorithm; // REVIEW probably i don't need half of this shit in here anymore
	import std.conv;
	import std.file;
	import std.range;
	import std.string;
	import std.array;
	import std.typetuple;
	import std.traits;
	import std.typecons;

	import opengl;

	import evx.math;

	import evx.misc.utils;
	import evx.traits.classification;
	import evx.codegen.declarations;
	import evx.type.extraction;
	import evx.patterns.builder;
	import evx.containers.set;

	mixin(MathToolkit!());
}

class Display
	{/*...}*/
		uvec display_size;
		GLFWwindow* window;

		this (uvec display_size = uvec(800, 600))
			{/*...}*/
				this.display_size = display_size;

				initialize_glfw;
				initialize_gl;
			}
		~this ()
			{/*...}*/
				terminate_glfw;
			}

		private {/*interface}*/
			void initialize_glfw ()
				{/*...}*/
					DerelictGLFW3.load ();

					glfwSetErrorCallback (&error_callback);

					auto initialized  = glfwInit ();

					if (not!initialized)
						assert (0, "glfwInit failed");


					auto dims = display_size;
					window = glfwCreateWindow (dims.x.to!uint, dims.y.to!uint, "evx.graphics.display", null, null);

					if (window is null)
						assert (0, `window creation failure`);

					glfwMakeContextCurrent (window);
					glfwSwapInterval (0);

					glfwSetWindowSizeCallback (window, &resize_window_callback);
					glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

					glfwSetWindowUserPointer (window, cast(void*)this);
				}
			void initialize_gl ()
				{/*...}*/
					DerelictGL3.load ();
					DerelictGL3.reload ();

					gl.ClearColor (0.1, 0.1, 0.1, 1.0);

					gl.Enable (GL_BLEND);
					gl.BlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				}

			void terminate_glfw ()
				{/*...}*/
					if (window !is null)
						glfwDestroyWindow (window);

					glfwTerminate ();
				}
		}

		auto pixel_dimensions ()
			{/*...}*/
				return display_size;
			}
		auto pixel_bounds ()
			{/*...}*/
				return [0.uvec, pixel_dimensions].bounding_box;
			}

		auto normalized_dimensions ()
			{/*...}*/
				auto min = pixel_dimensions[].reduce!min;

				return pixel_dimensions.to!vec / min;
			}
		auto normalized_bounds ()
			{/*...}*/
				auto Δ = normalized_dimensions;

				return [+Δ,-Δ].bounding_box;
			}

		void attach (S)(S shader)
			{/*...}*/
				shader.activate;

				evx.graphics.shader.parameters.set_uniform (gl.GetUniformLocation (shader.program, `aspect_ratio`), 1/normalized_dimensions);// REVIEW
			}

		void render ()
			{/*...}*/
				glfwPollEvents (); // TODO go to input
				glfwSwapBuffers (window);

				gl.Clear (GL_COLOR_BUFFER_BIT);
			}

		static:
		extern (C) nothrow {/*callbacks}*/
			void error_callback (int, const (char)* error)
				{/*...}*/
					import std.c.stdio;

					fprintf (stderr, "error glfw: %s\n", error);
				}
			void resize_window_callback (GLFWwindow* window, int width, int height)
				{/*...}*/
					(cast(Display) glfwGetWindowUserPointer (window))
						.display_size = uvec (width, height);
				}
			void resize_framebuffer_callback (GLFWwindow* window, int width, int height)
				{/*...}*/
					try gl.Viewport (0, 0, width, height);
					catch (Exception ex) assert (0, ex.msg);
				}
		}
	}

// TODO compile-time routing generic draw -> renderer through a router containing a list of renderers
// TODO VectorOps would unify colors, intervals, vectors, tuples, static arrays, and even simd vectors

auto to_pixel_space (R)(R range, Display display)// TODO
	{/*...}*/
	}
auto to_normalized_space (R)(R range, Display display)// TODO
	{/*...}*/
		
	}
