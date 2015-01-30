module evx.graphics.shader.experimental;

import evx.range;
import evx.math;
import evx.type;
import evx.containers;

import evx.misc.tuple;
import evx.misc.utils;
import evx.misc.memory;

import std.conv: to;

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

	//TEMP
	import evx.graphics.operators;

//////////////////////////////////////////
// MAIN //////////////////////////////////
//////////////////////////////////////////
void main () // TODO GOAL
	{/*...}*/
		import evx.graphics.display;

		auto display = Display (800, 600);

		display.background = grey;

		auto vertices = circle.map!(to!fvec)
			.enumerate.map!((i,v) => i%2? v : v/4);

		auto weights = ℕ[0..circle.length]
			.map!(i => float (i)/circle.length);

		Color color = red;

		auto weight_map = τ(vertices, weights, color)
			.vertex_shader!(`position`, `weight`, `base_color`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_color = base_color;
				frag_alpha = weight;
			}).fragment_shader!(
				Color, `frag_color`,
				float, `frag_alpha`, q{
				gl_FragColor = vec4 (frag_color.rgb, frag_alpha);
			})
			.triangle_fan
			.render_to (Texture (256, 256))
			[].array;

		static assert (is (typeof(weight_map) == Array!(Color, 2)));

		textured_shape_shader (square (1.1f), weight_map[].Texture) // BUG losing the texture by the time we try to render
			.triangle_fan
			.render_to (display); // BUG passing circle instead of vertices makes nonsensical error
		display.post;
		import core.thread;
		Thread.sleep (2.seconds);

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
		.triangle_fan.render_to (display); // TODO renderer.render_to (target) → target[] = renderer && target[] = source[] ↔ source.card_shader.render_to (target)

		display.post;

		Thread.sleep (2.seconds);
		display.background = white; // TEMP

		Texture target;
		target.allocate (256, 256);

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

		display.post;

		Thread.sleep (2.seconds);
	}
