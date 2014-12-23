module evx.graphics.texture;

private {/*imports}*/
	import std.conv;

	import evx.operators;

	import evx.graphics.opengl;
	import evx.graphics.color;

	import evx.math;
}

ubyte[4] texel (Color color)
	{/*...}*/
		return (color.vector * 255).each!(to!ubyte);
	}

struct Texture
	{/*...}*/
		GLuint id;
		alias id this;

		size_t width, height;

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsTexture (id), `cannot bind uninitialized texture`);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.BindTexture (GL_TEXTURE_2D, id);
			}

		mixin BufferOps!(allocate, pull, access, width, height, RangeOps);

		Color access (size_t x, size_t y)
			 {/*...}*/
			 	Color value;

				push (&value, x, y);

				return value;
			 }
		void allocate (size_t width, size_t height)
			in {/*...}*/
				assert ((width == 0) == (height == 0), 
					`cannot make 1D assignment to 2D Texture`
				);
			}
			body {/*...}*/
				if (width * height == 0)
					{/*...}*/
						free;

						return;
					}

				if (id == 0)
					{/*...}*/
						gl.GenTextures (1, &id);

						gl.BindTexture (GL_TEXTURE_2D, id);

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

						gl.TexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, Color (0,0,0,0)[].ptr);

						assert (gl.IsTexture (id));
					}

				gl.BindTexture (GL_TEXTURE_2D, id);

				enum base_mip_level = 0;
				enum format = GL_RGBA;

				gl.TexImage2D (GL_TEXTURE_2D, 
					base_mip_level,
					format,
					width.to!int, height.to!int, 0,
					format, gl.type!ubyte, null
				);

				this.width = width;
				this.height = height;
			}
		void free ()
			{/*...}*/
				gl.DeleteTextures (1, &id);

				id = 0;
				width = 0;
				height = 0;
			}

		void push (R)(R range, size_t[2] xs, size_t[2] ys) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void push (R)(R range, size_t x, size_t[2] ys) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void push (R)(R range, size_t[2] xs, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void push (R)(R range, size_t x, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}

		void pull (R)(R range, size_t[2] xs, size_t[2] ys) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void pull (R)(R range, size_t x, size_t[2] ys) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void pull (R)(R range, size_t[2] xs, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void pull (R)(R range, size_t x, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
	}
