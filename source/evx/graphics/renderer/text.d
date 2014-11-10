module evx.graphics.renderer.text;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.text;
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
						Text text;

						mixin RenderOrder!TextRenderer;

						this (TextRenderer renderer, Text text)
							{/*...}*/
								this.renderer = renderer;
								this.text = text;
							}
					}

				void process (Order order)
					{/*...}*/
						
					}

				TextShader shader;
			}
	}

void main ()
	{/*...}*/
		import evx.graphics.display;
		scope gfx = new Display;

		auto f = Font (200);
		scope t = new Text (f, gfx, `hello`);
		t.align_to (Alignment.top_right)
			.within ([-1.vec, 1.vec].bounding_box);

		scope s = new TextShader;

		auto triangle = [fvec (1), fvec(0), fvec(1,0)];

		gfx.attach (s);

		t[0..$/3].color = red;
		t[$/3..2*$/3].color = white;
		t[2*$/3..$].color = blue;

		s.cards (t.cards)
			.colors (t.colors)
			.tex_coords (t.tex_coords)
			.rotation (float(π/4))
			.translation (vec(0,1))
			.scale (float (0.5))
			;

		foreach (i; 0..t.length.to!int)
			gl.DrawArrays (GL_TRIANGLE_FAN, 4*i, 4);
		
		gfx.render;

		import core.thread;
		Thread.sleep (3000.msecs);
	}
	// TODO: 2) make immediate renderer, 3) fix text alignment using immediate renderer 
