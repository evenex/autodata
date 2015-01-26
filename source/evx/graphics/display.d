module evx.graphics.display;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;
	import evx.graphics.operators;

	import evx.math;
	import evx.range;

	import evx.misc.utils;
}

struct Display
	{/*...}*/
		size_t width, height;

		auto access (size_t x, size_t y)
			{/*...}*/
				// TODO gl.ReadPixels or something
			}
		void pull (Args...)(Args)
			{/*...}*/
				// TODO use fullscreen card renderer
			}
		void allocate (size_t width, size_t height)
			{/*...}*/
				this.width = width;
				this.height = height;

				gl.window_size (width, height);

				std.stdio.stderr.writeln (width, ` × `, height);

				if (width * height == 0)
					gl.on_resize = null;
				else gl.on_resize = (size_t w, size_t h)
					{this.width = w; this.height = h;};
			}

		this (size_t width = 800, size_t height = 600)
			in {/*...}*/
				assert (gl.on_resize == null,
					`only one display supported`
				);
			}
			body {/*...}*/
				allocate (width, height);
			}

		auto pixel_dimensions ()
			{/*...}*/
				return uvec (width, height);
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

		void post ()
			{/*...}*/
				gl.clear;
				gl.swap_buffers;
			}

		mixin CanvasOps!(
			preprocess, zero!GLuint, zero!GLuint,
			allocate, pull,
			access, width, height
		);
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
