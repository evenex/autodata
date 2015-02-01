module evx.graphics.texture;

private {/*imports}*/
	import std.conv: to, text;

	import evx.operators;
	import evx.containers;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.operators;

	import evx.math;
}

ubyte[4] texel (Color color)
	{/*...}*/
		return color.vector.texel;
	}
ubyte[4] texel (float[4] color)
	{/*...}*/
		return color.vector.texel;
	}
ubyte[4] texel (Vector!(4, float) color)
	{/*...}*/
		return (color * 255).each!(to!ubyte);
	}

debug enum out_of_bounds_color = magenta;
else enum out_of_bounds_color = Color ().alpha(0);

struct Texture
	{/*...}*/
		enum base_mip_level = 0;
		enum format = GL_RGBA;

		GLuint texture_id;
		GLuint framebuffer_id;

		size_t width, height;

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsTexture (texture_id), `cannot bind uninitialized texture ` ~ texture_id.text);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.texture_2D = this.texture_id;
			}

		template TextureId ()
			{/*...}*/
				GLuint texture_id ()
					{/*...}*/
						return source.texture_id;
					}

				auto offset ()
					{/*...}*/
						return vector (bounds[0].left, bounds[1].left);
					}
			}

		mixin CanvasOps!(
			preprocess, framebuffer_id, texture_id,
			allocate, pull, access, 
			width, height,
			RangeOps, TextureId
		);

		ref preprocess (S)(ref S shader)
			{/*...}*/
				return shader;
			}

		Color access (size_t x, size_t y)
			 {/*...}*/
			 	Color value;
				auto view = array_view (&value, 1, 1);

				push (view[], x, y);

				return value;
			 }

		void allocate (size_t width, size_t height)
			in {/*...}*/
				assert ((width == 0) == (height == 0), 
					`cannot make 1D assignment to 2D Texture`
				);
			}
			body {/*...}*/
				free;

				if (width * height == 0)
					return;

				if (texture_id == 0)
					{/*...}*/
						gl.GenTextures (1, &texture_id);

						gl.texture_2D = texture_id;

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

						gl.TexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, out_of_bounds_color[].ptr);

						assert (gl.IsTexture (texture_id),
							`failed to create texture ` ~ texture_id.text
						);

						assert (framebuffer_id == 0);

						gl.GenFramebuffers (1, &framebuffer_id);
					}

				auto previous_texture = gl.texture_2D;

				gl.texture_2D = texture_id;

				gl.TexImage2D (GL_TEXTURE_2D, 
					base_mip_level,
					format,
					width.to!int, height.to!int, 0,
					format, gl.type_enum!ubyte, null
				);

				gl.texture_2D = previous_texture;

				this.width = width;
				this.height = height;
			}
		void free ()
			{/*...}*/
				gl.DeleteTextures (1, &texture_id);
				gl.DeleteFramebuffers (1, &framebuffer_id);

				texture_id = 0;
				framebuffer_id = 0;
				width = 0;
				height = 0;
			}

		void pull (R)(R range, size_t[2] xs, size_t[2] ys)
			{/*...}*/
				bind;

				static if (is (typeof(*R.source) == Texture))
					{/*...}*/
						gl.CopyImageSubData (
							range.source.texture_id, GL_TEXTURE_2D, base_mip_level,
							range.offset.x.to!int, range.offset.y.to!int, 0,

							this.texture_id, GL_TEXTURE_2D, base_mip_level,
							xs.left.to!int, ys.left.to!int, 0,

							xs.width.to!int, ys.width.to!int, 1
						);
					}
				else {/*...}*/
					static if (is (typeof(vector (*range.ptr)) == Vector!(4, ubyte)))
						auto ptr = range.ptr;
					else {/*...}*/
						auto temp = range.map!texel.array;
						auto ptr = temp.ptr;
					}

					gl.TexSubImage2D (GL_TEXTURE_2D,
						base_mip_level,
						xs.left.to!int, ys.left.to!int,
						xs.width.to!int, ys.width.to!int,
						format, gl.type_enum!ubyte, ptr
					);
				}
			}
		void pull (R)(R range, size_t x, size_t[2] ys)
			{/*...}*/
				pull (range, [x, x+1], ys);
			}
		void pull (R)(R range, size_t[2] xs, size_t y)
			{/*...}*/
				pull (range, xs, [y, y+1]);
			}
		void pull (R)(R range, size_t x, size_t y)
			{/*...}*/
				pull (range, [x, x+1], [y, y+1]);
			}

		void push (R)(R range, size_t[2] xs, size_t[2] ys)
			{/*...}*/
				static assert (not (is (typeof(*R.source) == Texture)),
					`texture-texture transfers are handled by pull`
				);

				void write_data (Vector!(4, ubyte)* ptr)
					{/*...}*/
						auto temp = Texture (this[xs.left..xs.right, ys.left..ys.right]);

						temp.bind;

						gl.GetTexImage (GL_TEXTURE_2D,
							base_mip_level,
							format, gl.type_enum!ubyte,
							ptr
						);
					}

				static if (is (typeof(vector (*range.ptr)) == Vector!(4, ubyte)))
					write_data (range.ptr);
				else {/*convert}*/
					Array!(Vector!(4, ubyte), 2) temp;

					temp.allocate (xs.width, ys.width);

					write_data (temp.ptr);

					range[] = temp[].map!(to!(Element!R));
				}
			}
		void push (R)(R range, size_t x, size_t[2] ys)
			{/*...}*/
				push (range, [x, x+1], ys);
			}
		void push (R)(R range, size_t[2] xs, size_t y)
			{/*...}*/
				push (range, xs, [y, y+1]);
			}
		void push (R)(R range, size_t x, size_t y)
			{/*...}*/
				push (range, [x, x+1], [y, y+1]);
			}
	}

unittest {/*texture transfer}*/
	import evx.graphics.display;
	import evx.graphics.shader;
	import evx.graphics.shader.experimental; // TEMP pending renderer module
	import evx.type;

	auto display = Display (800, 600);

	auto vertices = square!float;

	auto tex1 = ℕ[0..100].by (ℕ[0..100])
		.map!((i,j) => (i+j)%2? red: yellow)
		.Texture;

	assert (tex1[0,0] == yellow);

	auto tex2 = ℕ[0..50].by (ℕ[0..50])
		.map!((i,j) => (i+j)%2? blue: green)
		.grid (100,100)
		.Texture;

	tex1[50..75, 25..75] = tex2[0..25, 0..50];

	Cons!(vertices, tex1).textured_shape_shader // REVIEW Cons only works for symbols, rvalues need to be in tuples... with DIP32, this distinction will be removed (i think)
	.triangle_fan.render_to (display);

	display.post;

	assert (tex1[0,0] == yellow);

	import core.thread;
	Thread.sleep (1.seconds);
}
