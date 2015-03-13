module evx.graphics.operators;
version(none):

template CanvasOps (alias preprocess, alias framebuffer_id, alias attachment_id, alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import evx.operators;

			import evx.graphics.opengl;
			import evx.graphics.shader;
		}

		static assert (
			is (ExprType!preprocess == Shader!Sym, Sym...)
			|| is (ExprType!preprocess == typeof(null)),
			typeof(this).stringof ~ ` preprocess stage must be shader or null`
		);
		static assert (is (typeof(framebuffer_id.identity) == GLuint),
			`framebuffer_id must resolve to GLuint`
		);
		static assert (is (typeof(attachment_id.identity) == GLuint),
			`attachment_id must resolve to GLuint`
		);

		void setup ()
			out {/*...}*/
				auto status = gl.CheckFramebufferStatus (GL_DRAW_FRAMEBUFFER);

				if (status != GL_FRAMEBUFFER_COMPLETE)
					assert (0, gl.enum_string (status));
			}
			body {/*...}*/
				gl.framebuffer = framebuffer_id;

				if (gl.IsTexture (attachment_id)) // TODO blank the texture before rendering to it? somehow need to blank it or else prior contents of VRAM (including webpages and shit) will still be there in the background
					gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, attachment_id, 0);
				else if (gl.IsRenderbuffer (attachment_id))
					gl.FramebufferRenderbuffer (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, attachment_id);
				else assert (framebuffer_id == 0,
					`non-default framebuffer bound without attachment`
				);
			}
		void attach (S)(auto ref S shader)
			if (is (S == Shader!Sym, Sym...))
			{/*...}*/
				(shader ~ preprocess).activate; // REVIEW assume simple RAII? moves are cheap for these reference wrapper types
			}

		mixin BufferOps!(allocate, pull, access, LimitsAndExtensions);
	}

template RenderOps (alias draw, shaders...)
	{/*...}*/
		private {/*imports}*/
			import evx.operators;
			import evx.memory;

			import evx.graphics.opengl;
			import evx.graphics.shader;
		}

		static {/*analysis}*/
			enum is_shader (alias s) = is (ExprType!(s) == Shader!Sym, Sym...);
			enum rendering_stage_exists (uint i) = is (typeof(draw!i (0)) == void);

			static assert (All!(is_shader, shaders),
				`shader symbols must resolve to Shaders`
			);
			static assert (All!(rendering_stage_exists, Count!shaders),
				`each given shader symbol must be accompanied by a function `
				`draw: (uint i)(uint n) → void, `
				`where i is the index of the associated rendering stage `
				`and n is the length of the inputs` // REVIEW this will all go to shit when you introduct element index arrays or god forbid compute shaders
			);
		}
		public {/*rendering}*/
			auto ref render_to (Canvas)(auto ref Canvas canvas) // REVIEW DOC RENDER_TO SETS UP AND VERIFIES THE RENDER TARGETS AND CALLS RENDERER DRAW
				{/*...}*/
					canvas.setup;

					void render (uint i = 0)()
						{/*...}*/
							template length (uint j)
								{/*...}*/
									auto length ()() if (not (is (typeof(shaders[i].args[j]) == Vector!U, U...)))
										{return shaders[i].args[j].length.to!int;}
								}

							canvas.attach (shaders[i]);

							draw!i (Match!(Map!(length, Count!(ExprType!(shaders[i]).Args))));

							static if (i+1 < shaders.length)
								render!(i+1);
						}

					render;

					return forward!canvas; // REVIEW this bypasses the lack of a copy constructor, would wrapped types provide an alternative solution?
				}
		}
	}
