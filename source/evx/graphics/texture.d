module evx.graphics.texture;

private {/*imports}*/
	import evx.operators;

	import evx.graphics.opengl;
	import evx.graphics.color;
}

struct Texture
	{/*...}*/
		GLuint id;
		alias id this;

		size_t width, height;

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (id != 0, `cannot bind uninitialized texture`);
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
			{/*...}*/
				
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
