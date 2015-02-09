module evx.graphics.shader.experimental;

private {/*import}*/
	import evx.range;
	import evx.math;
	import evx.type;
	import evx.containers;
	import evx.memory;

	import evx.misc.tuple;
	import evx.misc.utils;

	import std.conv: to;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.texture;
	import evx.graphics.color;

	import evx.graphics.shader.core;
	import evx.graphics.shader.repo;
}
public {/*PROTO RENDERERS}*/
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
	auto triangle_fan (S)(S shader)
		{/*...}*/
			return ArrayRenderer!S (RenderMode.t_fan, shader);
		}
}

	//TEMP
	import evx.graphics.operators;

//////////////////////////////////////////
// DEMO //////////////////////////////////
//////////////////////////////////////////
void demo () // TODO various texture sizes
	{/*...}*/
		import evx.graphics.display;

		auto display = Display (800, 600);

		void preview ()
			{/*...}*/
				import core.thread;

				display.post;

				Thread.sleep (2.seconds);
			}

		display.background = grey;

		auto vertices = circle (1.0f)
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
			.triangle_fan.render_to (Texture (256, 256))
			[].array;

		static assert (is (typeof(weight_map) == Array!(Color, 2)));

		textured_shape_shader (circle, weight_map[].Texture)
			.triangle_fan
			.render_to (display);

		preview;

		auto tex_coords = circle.map!(to!fvec)
			.flip!`vertical`;

		auto texture = ℝ[0..1].by (ℝ[0..1])
			.map!((x,y) => Color (0, x^^4, x^^2) * 1)
			.grid (256, 256)
			.Texture;

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

		preview;

		display.background = white;

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
		)(target)
		.triangle_fan.render_to (display);

		preview;
	}

auto card (T)(auto ref T texture, vec position = 0.vec, vec dimensions = 2.vec)
	{/*...}*/
		return textured_shape_shader (
			square!float.scale (dimensions).translate (position),
			(){/*...}*/
				static if (__traits(isRef, texture) && is (InitialType!T == T))
					return borrow (texture);
				else return texture;
			}()
		).triangle_fan;
	}

auto extrude (S,T)(S space, T length) // TODO T is integral for now, later i need a general way to change coordinate types
	{/*...}*/
		return space.by (ℕ[0..length])
			.map!((e,_) => e);
	}

void main ()
	{/*...}*/
		import evx.graphics.display;
		import core.thread;

		auto hsv_map = rainbow (256).by (ℝ[0..1].grid (256))
			.map!((color, x) => color.value (1-x))
			.Texture;

		auto display = Display (512, 512);

		void preview ()
			{/*...}*/
				display.post;
				Thread.sleep (50.msecs);
			}

		foreach_reverse (x; ℝ[0..2].grid (100)[])
			{/*...}*/
				hsv_map.card (0.vec, x.vec).render_to (display);
				preview;
			}
	}
