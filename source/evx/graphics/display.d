module evx.graphics.display;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.operators;
	import evx.graphics.shader;
	import evx.graphics.texture;

	import evx.type;
	import evx.math;
	import evx.range;
	import evx.containers;

	import evx.misc.utils;
}

struct Display
	{/*...}*/
		size_t width, height;

		auto access (size_t x, size_t y)
			{/*...}*/
				Color color;

				push ((&color).array_view (1, 1), x, y);

				return color;
			}
		void pull (S, Selected...)(S space, Selected selected)
			{/*...}*/
				gl.framebuffer = 0;
				
				static if (is (S == Texture))
					alias texture = space;
				else auto texture = space.Texture;
				
				square!float.scale (1.0f).translate (zero!fvec) // TODO scale is tricky... its relative to the display size
					.textured_shape_shader (texture).render_to (this); // TODO card should have scalable geometry
			}
		void push (S, Selected...)(S space, Selected selected)
			in {/*...}*/
				alias AcceptedTargets = Cons!(Color, Vector!(4, float), float[4]);

				static assert (IndexOf!(Element!S, AcceptedTargets) >= 0);
			}
			body {/*...}*/
				alias AcceptedTargets = Cons!(Color, Vector!(4, float), float[4]);

				gl.framebuffer = 0;
				
				GLint origin (uint dim)()
					{/*...}*/
						static if (is (Selected[dim] == size_t[2]))
							return selected[dim].left.to!int;

						else static if (is (Selected[dim] == size_t))
							return selected[dim].to!int;

						else static assert (0);
					}
				GLsizei span (uint dim)()
					{/*...}*/
						static if (is (Selected[dim] == size_t[2]))
							return selected[dim].width;

						else static if (is (Selected[dim] == size_t))
							return 1;

						else static assert (0);
					}

				static if (IndexOf!(typeof(*space.ptr), AcceptedTargets) >= 0)
					{/*...}*/
						auto ptr = space.ptr;
					}
				else {/*...}*/
					auto array = space.array;
					auto ptr = array.ptr;
				}

				gl.ReadPixels (Map!(origin, Iota!2), Map!(span, Iota!2), GL_RGBA, GL_FLOAT, ptr);

				static if (is (typeof(array.ptr)))
					space[] = array[];
			}
		void allocate (size_t width, size_t height)
			{/*...}*/
				this.width = width;
				this.height = height;

				gl.window_size (width, height);

				if (width * height == 0)
					gl.on_resize = null;
				else gl.on_resize = (size_t w, size_t h)
					{this.width = w; this.height = h;};

				background = black;
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

		auto preprocess ()
			{/*...}*/
				return aspect_correction (aspect_ratio);
			}

		void post ()
			{/*...}*/
				gl.swap_buffers;
			}

		void background (Color color)
			{/*...}*/
				gl.clear_color = color;
			}
		auto background ()
			{/*...}*/
				return gl.clear_color;
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
