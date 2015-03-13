module evx.graphics.resource.texture;
version(none):

private {/*imports}*/
	import std.conv: to, text;

	import evx.operators;
	import evx.containers;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.operators;

	import evx.type;
	import evx.math;
	import evx.range; // all
}

// BUG blank-allocated texture contains whatever the hell happened to be in VRAM prior... need a SELECTIVE zero-fill

alias RGBATexture = GLTexture!(float, GL_RGBA);
alias RGBTexture = GLTexture!(float, GL_RGB);
alias MonoTexture = GLTexture!(float, GL_RED);

/* base texture type 
*/
struct GLTexture (Component, GLuint format)
	{/*...}*/
	// TODO static assert format is valid, ReadFormat component has gl_type_enum, ReadFmt and store_fmt are compatible
		public {/*aliases}*/
			enum base_mip_level = 0;

			enum n_components = IndexOf!(format, 0, GL_RED, GL_RG, GL_RGB, GL_RGBA);

			static if (n_components == 1)
				alias Texel = Component;
			else alias Texel = Vector!(n_components, Component);
		}
		public {/*handles}*/
			GLuint texture_id;
			GLuint framebuffer_id;
		}
		public {/*canvas ops}*/
			size_t width, height;

			mixin CanvasOps!(
				null, framebuffer_id, texture_id,
				allocate, pull, access, 
				width, height,
				RangeOps, TextureId
			);

			public {/*buffer}*/
				Texel access (size_t x, size_t y)
					 {/*...}*/
						Texel value;
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

								static if (is (ReadFormat == Color))
									debug gl.TexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, magenta[].ptr);

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
							format, gl.type_enum!Component, null
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
			}
			public {/*transfer}*/
				void pull (R)(R range, size_t[2] xs, size_t[2] ys)
					{/*...}*/
						static if (is (typeof(*R.source) : GLTexture))
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
							static if (is (typeof(vector (*range.ptr)) == Texel))
								auto ptr = range.ptr;
							else {/*...}*/
								auto converted ()() {return range.map!(to!Texel);}
								auto expanded ()() {return range.map!(v => Texel (v.tuple.expand));}

								auto temp = Match!(converted, expanded).array;
								auto ptr = temp.ptr;
							}

							this.bind;

							gl.TexSubImage2D (GL_TEXTURE_2D,
								base_mip_level,
								xs.left.to!int, ys.left.to!int,
								xs.width.to!int, ys.width.to!int,
								format, gl.type_enum!Component, ptr
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
						static assert (not (is (typeof(*R.source) : GLTexture!T, T...)),
							`texture-texture transfers are handled by pull`
						);

						void write_data (Texel* ptr)
							{/*...}*/
								auto temp = GLTexture (this[xs.left..xs.right, ys.left..ys.right]);

								temp.bind;

								gl.GetTexImage (GL_TEXTURE_2D,
									base_mip_level,
									format, gl.type_enum!Component,
									ptr
								);
							}

						static if (is (typeof(*range.ptr) == Texel))
							{/*direct write}*/
								write_data (range.ptr);
							}
						else {/*convert}*/
							Array!(Texel, 2) temp;

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
			public {/*extension}*/
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
			}
		}

		void bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsTexture (texture_id), `cannot bind uninitialized texture ` ~ texture_id.text);
			}
			body {/*...}*/
				auto target = GL_TEXTURE0 + index;

				gl.ActiveTexture (target);

				gl.texture_2D = this.texture_id;
			}

		static reconstruct (GLuint id)
			{/*...}*/
				GLTexture texture;

				auto measure (GLenum param)
					{/*...}*/
						GLint value;

						gl.GetTexLevelParameteriv (GL_TEXTURE_2D, 0, param, &value);

						return value;
					}

				with (texture) {/*...}*/
					texture_id = id;

					bind;

					width = measure (GL_TEXTURE_WIDTH);
					height = measure (GL_TEXTURE_HEIGHT);
				}
				
				return texture;
			}
	}

/* Color texture 
*/
struct ImageTexture
	{/*...}*/
		RGBATexture base;
		alias base this;

		Color access (size_t x, size_t y)
			{/*...}*/
				return Color (base[x,y]);
			}
		auto width () const
			{/*...}*/
				return base.width;
			}
		auto height () const
			{/*...}*/
				return base.height;
			}
		void pull (Args...)(Args args)
			{/*...}*/
				base.pull (args);
			}
		void push (Args...)(Args args)
			{/*...}*/
				base.push (args);
			}
		void allocate (size_t width, size_t height)
			{/*...}*/
				base.allocate (width, height);
			}
		auto framebuffer_id ()
			{/*...}*/
				return base.framebuffer_id;
			}
		auto texture_id ()
			{/*...}*/
				return base.texture_id;
			}
		alias TextureId = RGBATexture.TextureId;

		mixin CanvasOps!(
			null, framebuffer_id, texture_id,
			allocate, pull, access, 
			width, height,
			RangeOps, TextureId
		);
	}

alias Texture = ImageTexture;

debug void render_to_console (MonoTexture texture)
	{/*...}*/
		import std.stdio;

		auto arr = texture[].array;

		foreach (row; arr[].limit!1.left..arr[].limit!1.right)
			std.stdio.stderr.writeln (arr[~$..$, row].map!((float x)
				{/*...}*/
					if (x < 0.2)
						return ` `;
					else if (x < 0.4)
						return `░`;
					else if (x < 0.6)
						return `▒`;
					else if (x < 0.8)
						return `▓`;
					else return `█`;
				}
			).join.text);
	}

unittest {/*texture transfer}*/
	import evx.graphics.display;
	import evx.graphics.shader;
	import evx.graphics.renderer;
	import evx.memory;
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

	textured_shape_shader (vertices, tex1)
	.triangle_fan.render_to (display);

	display.post;

	assert (tex1[0,0] == yellow);

	import core.thread;
	Thread.sleep (1.seconds);
}
