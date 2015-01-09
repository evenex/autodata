module evx.graphics.display;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;

	import evx.math;
	import evx.range;

	import evx.misc.utils;
}

import evx.graphics.shader.repo;// TEMP
import evx.graphics.shader.experimental;// TEMP

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

				gl.reset;
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
					window = glfwCreateWindow (dims.x.to!uint, dims.y.to!uint, ``, null, null);

					if (window is null)
						assert (0, `window creation failure`);

					glfwMakeContextCurrent (window);
					glfwSwapInterval (0);

					glfwSetWindowSizeCallback (window, &resize_window_callback);
					glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

					glfwSetWindowUserPointer (window, cast(void*)this);

					glfwSetWindowTitle (window, text (
						"evx.graphics.display openGL ",
						glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MAJOR), '.',
						glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MINOR)
					).to_c.expand);
				}
			void initialize_gl ()
				{/*...}*/
					DerelictGL3.load ();
					DerelictGL3.reload ();

					debug gl.context_initialized = true; // TODO eventually just open a hidden context if the context doesn't already exist, then let the display pick it up if one ever gets initted

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

		auto aspect_ratio ()
			{/*...}*/
				return (1/normalized_dimensions).to!fvec;
			}

		auto preprocess (S)(ref S shader) // TODO enforce refness
			{/*...}*/
				return shader.aspect_correction (aspect_ratio);
			}

		void show ()
			{/*...}*/
				glfwPollEvents (); // TODO go to input
				glfwSwapBuffers (window);

				gl.Clear (GL_COLOR_BUFFER_BIT); // REVIEW redundant
			}

		mixin CanvasOps!(preprocess, zero!GLuint);

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

auto to_pixel_space (vec v, Display display)
	{/*...}*/
		v /= display.normalized_dimensions;
		v += unity!vec;
		v /= 2;
		v *= display.pixel_dimensions / 2;

		return v;
	}
auto to_normalized_space (vec v, Display display)
	{/*...}*/
		v /= display.pixel_dimensions;
		v *= 2;
		v -= unity!vec;
		v *= display.normalized_dimensions;

		return v;
	}

@(`from pixel space`) 
auto to_normalized_space (R)(R range, Display display)
	{/*...}*/
		return range.map!(v => v.to_normalized_space (display));
	}

@(`from normalized space`) 
auto to_pixel_space (R)(R range, Display display)
	{/*...}*/
		return range.map!(v => v.to_pixel_space (display));
	}
