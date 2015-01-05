module evx.graphics.shader.experimental;

import evx.range;
import evx.math;
import evx.type;
import evx.containers;

import evx.misc.tuple;
import evx.misc.utils;
import evx.misc.memory;

import std.typecons;
import std.conv;
import std.string;
import std.ascii;

import evx.graphics.opengl;
import evx.graphics.buffer;
import evx.graphics.texture;
import evx.graphics.color;

import evx.graphics.shader.core;
import evx.graphics.shader.repo;

//////////////////////////////////////////
// PROTO RENDERERS ///////////////////////
//////////////////////////////////////////
struct ProtoRenderer (S)
	{/*...}*/
		RenderMode mode;
		S shader;

		alias shader this; // TEMP
	}
auto triangle_fan (S)(ref S shader)
	{/*...}*/
		auto renderer = ProtoRenderer!S (RenderMode.t_fan);

		swap (renderer.shader, shader);

		return renderer;
	}
auto triangle_fan (S)(S shader)
	{/*...}*/
		S next;

		swap (shader, next);

		return next.triangle_fan;
	}

// RENDERING OPERATORS
template CanvasOps (alias preprocess, alias setup, alias managed_id = identity)
	{/*...}*/
		static assert (is (typeof(preprocess(Shader!().init)) == Shader!Sym, Sym...),
			`preprocess: Shader → Shader`
		);
		// TODO really the bufferops belong over here, renderops opindex is just for convenience

		GLuint framebuffer_id ()
			{/*...}*/
				auto managed ()()
					{/*...}*/
						return managed_id;
					}
				auto unmanaged ()()
					{/*...}*/
						if (fbo_id == 0)
							gl.GenFramebuffers (1, &fbo_id);

						return fbo_id;
					}

				auto ret = Match!(managed, unmanaged); // TEMP return this


				glBindFramebuffer (GL_FRAMEBUFFER, ret);//TEMP

				setup; // TEMP when to do this?

				return ret;
			}

		static if (is (typeof(managed_id.identity)))
			alias fbo_id = managed_id;
		else GLuint fbo_id;

		auto attach (S)(S shader)
			if (is (S == Shader!Sym, Sym...))
			{/*...}*/
				preprocess (shader).activate;
			}
	}

template RenderOps (alias draw, shaders...)
	{/*...}*/
		static {/*analysis}*/
			enum is_shader (alias s) = is (typeof(s) == Shader!Sym, Sym...);
			enum rendering_stage_exists (uint i) = is (typeof(draw!i ()) == void);

			static assert (All!(is_shader, shaders),
				`shader symbols must resolve to Shaders`
			);
			static assert (All!(rendering_stage_exists, Count!shaders),
				`each given shader symbol must be accompanied by a function `
				`draw: (uint n)() → void, where n is the index of the associated rendering stage`
			);
		}
		public {/*rendering}*/
			auto ref render_to (T)(auto ref T canvas)
				{/*...}*/
					void render (uint i = 0)()
						{/*...}*/
							canvas.attach (shaders[i]);
							draw!i;

							static if (i+1 < shaders.length)
								render!(i+1);
						}

					gl.framebuffer = canvas;

					render;

					return canvas;
				}
		}
		public {/*convenience}*/
			Texture default_canvas;

			alias default_canvas this;

			auto opIndex (Args...)(Args args)
				{/*...}*/
					if (default_canvas.volume == 0)
						{/*...}*/
							default_canvas.allocate (256, 256); // REVIEW where to get default resolution?
							render_to (default_canvas);
						}

					return default_canvas.opIndex (args);
				}
		}
	}

// TO DEPRECATE, GOING INTO RENDEROPS
auto ref output_to (S,R,T...)(auto ref S shader, auto ref R target, T args)
	{/*...}*/
		//GLuint framebuffer_id = 0; // TODO create framebuffer
		//gl.GenFramebuffers (1, &framebuffer_id); TODO to create a framebuffer
		//gl.BindFramebuffer (GL_FRAMEBUFFER, framebuffer_id); // TODO to create a framebuffer
		// gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, renderedTexture, 0); TODO to set texture output
		// gl.DrawBuffers TODO set frag outputs to draw to these buffers, if you use this then you'll need to modify the shader program, to add some fragment_output variables
			GLuint fboid;
				static if (is (R == Texture))
					{/*...}*/
				//target.framebuffer_id;
				glGenFramebuffers (1, &fboid);

			//	target.allocate (256,256);
				target = ℕ[0..100].by (ℕ[0..100]).map!(x => yellow).Texture;
				glBindFramebuffer (GL_FRAMEBUFFER, fboid);//TEMP
				glFramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, target.texture_id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
				//glFramebufferTexture2D (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target.texture_id, 0); // REVIEW if any of these redundant calls starts impacting performance, there is generally some piece of state that can inform the decision to elide. this state can be maintained in the global gl structure.
					}



			auto check () // TODO REFACTOR this goes somewhere... TODO make specific error messages for all the openGL calls
				{/*...}*/
					switch (glCheckFramebufferStatus (GL_FRAMEBUFFER)) 
						{/*...}*/
							case GL_FRAMEBUFFER_COMPLETE:
								return;

							case GL_FRAMEBUFFER_UNDEFINED:
								assert(0, `target is the default framebuffer, but the default framebuffer does not exist.`);

							case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
								assert(0, `some of the framebuffer attachment points are framebuffer incomplete.`);

							case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
								assert(0, `framebuffer does not have at least one image attached to it.`);

							case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
								assert(0, `value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for some color attachment point(s) named by GL_DRAW_BUFFERi.`);

							case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
								assert(0, `GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for the color attachment point named by GL_READ_BUFFER.`);

							case GL_FRAMEBUFFER_UNSUPPORTED:
								assert(0, `combination of internal formats of the attached images violates an implementation-dependent set of restrictions.`);

							case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
								assert(0, `value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers; or the value of GL_TEXTURE_SAMPLES is the not same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_RENDERBUFFER_SAMPLES does not match the value of GL_TEXTURE_SAMPLES.`
									"\n"`or the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not the same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not GL_TRUE for all attached textures.`
								);

							case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS:
								assert(0, `some framebuffer attachment is layered, and some populated attachment is not layered, or all populated color attachments are not from textures of the same target.`);

							default:
								assert (0, `framebuffer error`);
						}
				}

		shader.activate;
		gl.framebuffer = fboid;
		//gl.framebuffer = target.framebuffer_id;

		if (gl.framebuffer == 0)
			glDrawBuffer (GL_BACK);
		else glDrawBuffer (GL_COLOR_ATTACHMENT0);

		check;

		if (gl.framebuffer != 0)
			gl.ClearColor (1,0,0,1);
		else gl.ClearColor (0.1,0.1,0.1,1);

		gl.Clear (GL_COLOR_BUFFER_BIT);

		template length (uint i)
			{/*...}*/
				auto length ()() if (not (is (typeof(shader.args[i]) == Vector!U, U...)))
					{return shader.args[i].length.to!int;}
			}

		gl.DrawArrays (shader.mode, 0, Match!(Map!(length, Count!(S.Args))));

		// render_target.bind; REVIEW how does this interact with texture.bind, or any other bindable I/O type
		// render_target.draw (shader.args, args); REVIEW do this, or get length of shader array args? in latter case, how do we pick the draw mode?
				//glViewport (0,0,1000,1000);
				glBindFramebuffer (GL_FRAMEBUFFER, 0);//TEMP

		/*
			init FBO
			attach tex to FBO
			bind FBO
			draw
			unbind FBO
			use tex wherever
		*/

		return target;
	}

//////////////////////////////////////////
// RENDERING /////////////////////////////
//////////////////////////////////////////
// THIS BELONGS TO RENDERERS BUT MUST SOMEHOW BE USED UNDER UNIFORM RENDERING API ELSE RISK INCONSISTENCY DOWNSTREAM
enum RenderMode
	{/*...}*/
		point = GL_POINTS,
		l_strip = GL_LINE_STRIP,
		l_loop = GL_LINE_LOOP,
		line = GL_LINES,
		t_strip = GL_TRIANGLE_STRIP,
		t_fan = GL_TRIANGLE_FAN,
		tri = GL_TRIANGLES
	}

//////////////////////////////////////////
// MAIN //////////////////////////////////
//////////////////////////////////////////
void main () // TODO GOAL
	{/*...}*/
		import evx.graphics.display;
		scope display = new Display;

		auto vertices = circle.map!(to!fvec)
			.enumerate.map!((i,v) => i%2? v : v/4);

		auto weights = ℕ[0..circle.length].map!(to!float);
		Color color = red;

		auto weight_map = τ(vertices, weights, color)
			.vertex_shader!(`position`, `weight`, `base_color`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_color = vec4 (base_color.rgb, weight);
				frag_alpha = weight;
			}).fragment_shader!(
				Color, `frag_color`,
				float, `frag_alpha`, q{
				gl_FragColor = vec4 (frag_color.rgb, frag_alpha);
			}).triangle_fan;

		//);//.array; TODO
		//static assert (is (typeof(weight_map) == Array!(Color, 2))); TODO

		auto tex_coords = circle.map!(to!fvec)
			.flip!`vertical`;

		auto texture = ℝ[0..1].by (ℝ[0..1])
			.map!((x,y) => Color (0, x^^4, x^^2) * 1)
			.grid (256, 256)
			.Texture;

		// TEXTURED SHAPE SHADER
		τ(vertices, tex_coords).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = (tex_coords + vec2 (1,1))/2;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture)
		.aspect_correction (display.aspect_ratio)
		.triangle_fan.output_to (display);

		display.render;

		import core.thread;
		Thread.sleep (2.seconds);

		Texture target;
		target.allocate (256,256);

		vertices.vertex_shader!(
			`pos`, q{
				gl_Position = vec4 (pos, 0, 1);
			}
		).fragment_shader!(
			Color, `col`, q{
				gl_FragColor = col;
			}
		)(blue)
		.triangle_fan
		.output_to (target);

		τ(square!float, square!float.scale (2.0f).translate (fvec(0.5))).vertex_shader!(
			`pos`, `texc_in`, q{
				gl_Position = vec4 (pos, 0, 1);
				texc = texc_in;
			}
		).fragment_shader!(
			fvec, `texc`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, texc);
			}
		)(target).triangle_fan.output_to (display);

		display.render;

		Thread.sleep (2.seconds);
	}

