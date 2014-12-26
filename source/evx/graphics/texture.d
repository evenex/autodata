module evx.graphics.texture;

import evx.graphics.shader;// TEMP
private {/*imports}*/
	import std.conv;

	import evx.operators;
	import evx.containers;

	import evx.graphics.opengl;
	import evx.graphics.color;

	import evx.math;

	alias array = evx.containers.array.array; // REVIEW namespace clash
}

ubyte[4] texel (Color color)
	{/*...}*/
		return cast(Vector!(4, ubyte))(color);
	}

debug enum out_of_bounds_color = magenta;
else enum out_of_bounds_color = Color ().alpha(0);

struct Texture
	{/*...}*/
		GLuint texture_id;
		alias texture_id this;

		size_t width, height;

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsTexture (texture_id), `cannot bind uninitialized texture`);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.texture_2D = this;
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

		mixin BufferOps!(allocate, pull, access, width, height, RangeOps, TextureId);
		mixin CanvasOps!(preprocess, setup);

		void setup ()
			{/*...}*/
				gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, texture_id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
			}
		auto ref preprocess (S)(auto ref S shader)
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

						gl.texture_2D = this;

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

						gl.TexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, out_of_bounds_color[].ptr);

						assert (gl.IsTexture (texture_id),
							`failed to create texture ` ~ texture_id.text
						);
					}

				gl.texture_2D = this;

				gl.TexImage2D (GL_TEXTURE_2D, 
					base_mip_level,
					format,
					width.to!int, height.to!int, 0,
					format, gl.type!ubyte, null
				);

				this.width = width;
				this.height = height;

				gl.texture_2D = 0;
			}
		void free ()
			{/*...}*/
				gl.DeleteTextures (1, &texture_id);

				texture_id = 0;
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
						auto temp = evx.containers.array.array (range.map!texel); // REVIEW control overloads so UFCS possible, too many clash w/ std.array.. probably local import in upstream mixin
						auto ptr = temp.ptr;
					}

					gl.TexSubImage2D (GL_TEXTURE_2D,
						base_mip_level,
						xs.left.to!int, ys.left.to!int,
						xs.width.to!int, ys.width.to!int,
						format, gl.type!ubyte,
						ptr
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

				void write_data (T)(T ptr)
					{/*...}*/
						auto temp = this[xs.left..xs.right, ys.left..ys.right].Texture;

						temp.bind;

						gl.GetTexImage (GL_TEXTURE_2D,
							base_mip_level,
							format, gl.type!ubyte,
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

		enum base_mip_level = 0;
		enum format = GL_RGBA;

	}
