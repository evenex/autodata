module evx.graphics.texture;

private {/*imports}*/
	import evx.operators;

	import evx.graphics.opengl;
	import evx.graphics.color;
}

struct Texture
	{/*...}*/
		GLuint id;
		size_t width, height;

		alias id this;

		Color access (size_t x, size_t y)
			 {/*...}*/
			 	
			 }
		void allocate (size_t width, size_t height)
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

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (id != 0, `cannot bind uninitialized texture`);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.BindTexture (GL_TEXTURE_2D, id);
			}
	}
