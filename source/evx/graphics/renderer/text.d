module evx.graphics.renderer.text;

private {/*imports}*/
	import std.conv;

	import evx.graphics.text;
	import evx.graphics.shader.text;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.renderer.core;

	import evx.patterns;
	import evx.math;
}

class TextRenderer
	{/*...}*/
		mixin Wrapped!Implementation;
		mixin RenderOps!wrapped;

		struct Implementation
			{/*...}*/
				struct Order
					{/*...}*/
						mixin Builder!(
							Text, `text`,
						);

						mixin RenderOrder!TextRenderer;
					}

				void render (Order order)
					{/*...}*/
						with (order)
						shader.cards (text.cards)
							.colors (text.colors)
							.tex_coords (text.tex_coords);

						foreach (i; 0..order.text.length.to!int)
							gl.DrawArrays (GL_TRIANGLE_FAN, 4*i, 4);
					}

				TextShader shader;
			}
	}

unittest // TEMP
	{/*...}*/
		import evx.graphics.display;
		scope gfx = new Display;

		auto f = new Font (200);
		scope t = new Text (f, gfx, `Lorem`);// ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`);

		t.align_to (Alignment.top_right)
			.within ([-1.vec, 1.vec].bounding_box);

		scope s = new TextShader;
		scope r = new TextRenderer;

		auto triangle = [fvec (1), fvec(0), fvec(1,0)];

		gfx.attach (s);
		r.attach (s);

		t[0..$/3].color = red;
		t[$/3..2*$/3].color = white;
		t[2*$/3..$].color = blue;

		r.draw.text (t)
			.rotate (π/4)
			.translate (vec(0,1))
			.scale (0.2)
			.immediately;
		
		gfx.render;

		import core.thread;
		Thread.sleep (1000.msecs);
	}
