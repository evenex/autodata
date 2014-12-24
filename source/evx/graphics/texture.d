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

ubyte[4] texel (Vector!(4, float) color)
	{/*...}*/
		return (color.each!clamp (interval (0,1)).vector * 255).each!(to!ubyte);
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

				gl.texture_2D = id; // TODO autodiscover
			}

		mixin BufferOps!(allocate, pull, access, width, height, RangeOps);
		mixin CanvasOps!(preprocess, bind_output);

		void bind_output ()
			{/*...}*/
				gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
			}
		auto ref preprocess (S)(auto ref S shader)
			{/*...}*/
				return shader;
			}

		Color access (size_t x, size_t y)
			 {/*...}*/
			 	Color value;

			//	push (&value, x, y); TODO

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

						gl.texture_2D = id;

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
						gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

						gl.TexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, magenta[].ptr);

						assert (gl.IsTexture (id));
					}

				gl.texture_2D = id;

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

		void pull (R)(R range, size_t[2] xs, size_t[2] ys)
			{/*...}*/
				bind;

				static if (is (typeof(R.source) == Texture))
					{/*...}*/
						gl.BindBuffer (range.id);
					}

				static if (is (typeof(vector (*range.ptr)) == Vector!(4, ubyte)))
					auto ptr = range.ptr;
				else {/*...}*/
					auto temp = evx.containers.array.array (range.map!texel); // REVIEW control overloads so UFCS possible, too many clash w/ std.array
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
		void pull (R)(R range, size_t x, size_t[2] ys)
			{/*...}*/
			}
		void pull (R)(R range, size_t[2] xs, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}
		void pull (R)(R range, size_t x, size_t y) // TODO glsubtexture transfer?
			{/*...}*/
				
			}

		enum base_mip_level = 0;
		enum format = GL_RGBA;

	}
