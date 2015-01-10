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

class Display // REVIEW mayb with bufferops we can declass this
	{/*...}*/
		uvec display_size;
		GLFWwindow* window;

		void allocate (size_t width, size_t height)
			{/*...}*/
				display_size = uvec (width, height);
			}

		this (size_t width = 800, size_t height = 600)
			{/*...}*/
				allocate (width, height);

				initialize_glfw;
				initialize_gl;
			}
		~this ()
			{/*...}*/
				terminate_glfw;

				gl.reset;
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
