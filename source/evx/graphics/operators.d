module evx.graphics.operators;


template CanvasOps (alias preprocess, alias framebuffer_id, alias attachment_id, alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import evx.operators;

			import evx.graphics.opengl;
			import evx.graphics.error;
			import evx.graphics.shader;
		}

		static assert (
			is (typeof((){auto s = Shader!().init; return typeof(preprocess (s)).init;}()) == Shader!R, R...)
			&& not (is (typeof(preprocess (Shader!().init)) == Shader!S, S...)),
			typeof(this).stringof ~ ` preprocess: ref Shader → Shader`
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
					assert (0, status.constant_string);
			}
			body {/*...}*/
				gl.framebuffer = framebuffer_id;

				if (gl.IsTexture (attachment_id))
					gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, attachment_id, 0);
				else if (gl.IsRenderbuffer (attachment_id))
					gl.FramebufferRenderbuffer (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, attachment_id);
				else assert (framebuffer_id == 0,
					`non-default framebuffer bound without attachment`
				);

				gl.clear;
			}
		void attach (S)(auto ref S shader)
			if (is (S == Shader!Sym, Sym...))
			{/*...}*/
				import evx.misc.memory : move; // TEMP

				typeof(preprocess(shader)) prepared;
				
				move (preprocess (shader), prepared);
				
				prepared.activate;

				shader = S (prepared.args); // REVIEW all these moves are inefficient, need a system for referencing lvalue resources and passing back rvalue resources... put resource placement control in the hands of the top-level caller
			}

		mixin BufferOps!(allocate, pull, access, LimitsAndExtensions);
	}

template RenderOps (alias draw, shaders...)
	{/*...}*/
		private {/*imports}*/
			import evx.operators;
			import evx.misc.memory;

			import evx.graphics.opengl;
			import evx.graphics.shader;
		}

		static {/*analysis}*/ // REVIEW
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
			auto ref render_to (T)(auto ref T canvas) // REVIEW DOC RENDER_TO SETS UP AND VERIFIES THE RENDER TARGETS AND CALLS RENDERER DRAW
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

					return forward!canvas;
				}
		}
	}
