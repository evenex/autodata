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
struct ArrayRenderer (S)
	{/*...}*/
		RenderMode mode;
		S shader;

		void draw (uint i: 0)() // REVIEW DOC DRAW ISSUES THE DRAW COMMANDS
			{/*...}*/
				template length (uint i)
					{/*...}*/
						auto length ()() if (not (is (typeof(shader.args[i]) == Vector!U, U...)))
							{return shader.args[i].length.to!int;}
					}

				gl.DrawArrays (mode, 0, Match!(Map!(length, Count!(S.Args))));
			}

		mixin RenderOps!(draw, shader);
	}
auto triangle_fan (S)(ref S shader)
	{/*...}*/
		auto renderer = ArrayRenderer!S (RenderMode.t_fan);

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
template CanvasOps (alias preprocess, alias managed_id = identity)
	{/*...}*/
		import evx.graphics.shader.core;/// TEMP 
		static assert (is (typeof(preprocess(Shader!().init)) == Shader!Sym, Sym...),
			`preprocess: Shader → Shader`
			~ typeof(preprocess(Shader!().init)).stringof
		);
		// TODO make sure this is indexable? like an image or something

		static if (is (typeof(managed_id.identity)))
			alias framebuffer_id = managed_id;
		else GLuint framebuffer_id;

		auto attach (S)(auto ref S shader)
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
			auto ref render_to (T)(auto ref T canvas) // REVIEW DOC RENDER_TO SETS UP AND VERIFIES THE RENDER TARGETS AND CALLS RENDERER DRAW
				{/*...}*/
					gl.framebuffer = canvas;

					if (gl.framebuffer == 0)
						gl.DrawBuffer (GL_BACK);
					else gl.DrawBuffer (GL_COLOR_ATTACHMENT0);

					{/*TEMP VISUALLY TESTING THE FRAMBUFFER}*/
						if (gl.framebuffer != 0)
							gl.ClearColor (1,0,0,1);
						else gl.ClearColor (0.1,0.1,0.1,1);
					}

					gl.Clear (GL_COLOR_BUFFER_BIT);

					void render (uint i = 0)()
						{/*...}*/
							canvas.attach (shaders[i]);
							draw!i;

							static if (i+1 < shaders.length)
								render!(i+1);
						}

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
		.triangle_fan.render_to (display);

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
		.render_to (target);

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
		)(target).triangle_fan.render_to (display);

		display.render;

		Thread.sleep (2.seconds);
	}
