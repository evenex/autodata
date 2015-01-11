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
		S base_shader; // REVIEW due to postproc, this won't wind up getting used!!

		void draw (uint i: 0)(uint n) // REVIEW DOC DRAW ISSUES THE DRAW COMMANDS
			in {/*...}*/
				assert (n != 0, `issued empty draw call`);
			}
			body {/*...}*/
				gl.DrawArrays (mode, 0, n);
			}

		mixin RenderOps!(draw, base_shader);
	}
auto triangle_fan (S)(ref S shader)
	{/*...}*/
		auto renderer = ArrayRenderer!S (RenderMode.t_fan);

		swap (renderer.base_shader, shader);

		return renderer;
	}
auto triangle_fan (S)(S shader)
	{/*...}*/
		S next;

		swap (shader, next);

		return next.triangle_fan;
	}

// TODO TODO TODO make CanvasOps a superset of BufferOps... probably do the same for RenderOps
// RENDERING OPERATORS
template CanvasOps (alias preprocess, alias framebuffer_id, alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		import evx.graphics.shader.core;/// TEMP 
		import evx.operators;/// TEMP 

		static assert (
			is (typeof((){auto s = Shader!().init; return typeof(preprocess (s)).init;}()) == Shader!R, R...)
			&& not (is (typeof(preprocess (Shader!().init)) == Shader!S, S...)),
			typeof(this).stringof ~ ` preprocess: ref Shader → Shader`
		);
		static assert (is (typeof(framebuffer_id.identity) == GLuint),
			`framebuffer_id must resolve to GLuint`
		);

		void attach (S)(ref S shader)
			if (is (S == Shader!Sym, Sym...))
			{/*...}*/
				//REVIEW if gl.framebuffer != framebuffer.id?
				gl.framebuffer = framebuffer.id;

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
		static {/*analysis}*/ // REVIEW
			enum is_shader (alias s) = is (typeof(s) == Shader!Sym, Sym...);
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
					gl.framebuffer = canvas;

					gl.clear;

					void render (uint i = 0)()
						{/*...}*/
							template length (uint j)
								{/*...}*/
									auto length ()() if (not (is (typeof(shaders[i].args[j]) == Vector!U, U...)))
										{return shaders[i].args[j].length.to!int;}
								}

							canvas.attach (shaders[i]);

							draw!i (Match!(Map!(length, Count!(typeof(shaders[i]).Args))));

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

					return default_canvas.opIndex (args); // REVIEW pull-to-ram will go per-element, unless push is detected via alias this` - might want to TransferOps this
				}
		}
	}

//////////////////////////////////////////
// MAIN //////////////////////////////////
//////////////////////////////////////////
void main () // TODO GOAL
	{/*...}*/
		import evx.graphics.display;
		Display display;

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
		.triangle_fan.render_to (display);

		display.show;

		import core.thread;
		Thread.sleep (2.seconds);

		Texture target;
		target.allocate (256,256);

		vertices.translate (-0.5.fvec).vertex_shader!(
			`pos`, q{
				gl_Position = vec4 (pos, 0, 1);
			}
		).fragment_shader!(
			Color, `col`, q{
				gl_FragColor = col;
			}
		)(blue)
		.triangle_fan.render_to (target);

		τ(square!float, square!float.translate (fvec(0.5))).vertex_shader!(
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

		display.show;

		Thread.sleep (2.seconds);
	}
