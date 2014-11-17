module evx.graphics.renderer.simple;

private {/*imports}*/
	import std.conv;

	import evx.graphics.renderer.core;
	import evx.graphics.renderer.mesh;
	import evx.graphics.renderer.text;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.text;
	import evx.graphics.shader;
	import evx.graphics.buffer;

	import evx.patterns;
	import evx.math;
}

	// TODO: 2) make immediate renderer, 3) fix text alignment using immediate renderer 
class SimpleRenderer
	{/*...}*/
		mixin Wrapped!Implementation;
		mixin RenderOps!wrapped;

		struct Implementation
			{/*...}*/
				struct Order
					{/*...}*/
						mixin Builder!(
							Text, `text`,
							VertexBuffer, `vertices`,
							Color, `color`,
						);

						mixin RenderOrder!SimpleRenderer;
					}
				
				void render (Order order)
					{/*...}*/
						with (order) {/*...}*/
							if (text)
								{/*...}*/
									text_renderer.shader.activate; // BUG BUG BUG
									text_renderer.draw.text (text) // TODO need better control over processing stages from within Renderers
										.rotate (rotation)
										.translate (translation)
										.scale (order.scale) // BUG scale again
										.immediately;
								}

							shader.activate; // BUG BUG BUG uniforms are not linked before this step, i don't want to have to remember it
							shader.position (vertices)
								.color (color)
								.translation (translation)
								.rotation (rotation)
								.scale (order.scale);
						}

						gl.DrawArrays (GL_LINE_LOOP, 0, order.vertices.length.to!int);
					}

				BasicShader shader;
				TextRenderer text_renderer;
			}
	}

import evx.misc.services;
void main ()
	{/*...}*/
		static if (1)
			{/*...}*/
				import evx.graphics.display;
				scope gfx = new Display;

				scope f = new Font (200);
				scope t = new Text (f, gfx, `Lorem`);// ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`);

				t.align_to (Alignment.top_right)
					.within ([-1.vec, 1.vec].bounding_box);

				scope sh1 = new TextShader;
				scope txt = new TextRenderer;

				scope sh0 = new BasicShader;
				scope dbg = new SimpleRenderer;

				connect_services (sh0, sh1, txt).to_clients (txt, dbg);

				auto triangle = [fvec (1), fvec(0), fvec(1,0)];

				gfx.attach (sh1);

				t[].color = red;

				txt.draw.text (t)
					.rotate (π/4)
					.translate (vec(0,1))
					.scale (0.2)
					.immediately;

				auto verts = VertexBuffer (gfx.normalized_bounds[].map!(v => v / 2));
				gfx.attach (sh0); // BUG i don't want to have to manually attach
				dbg.draw
			//		.text (t)
					.vertices (verts)
					.color (blue)
					.immediately;
				
				gfx.render;

				import core.thread;
				Thread.sleep (1000.msecs);

			}
		else {/*...}*/
			import evx.graphics;

			scope gfx = new Display;

			scope sh0 = new BasicShader;
			scope sh1 = new TextShader;
			scope txt = new TextRenderer;
			scope dbg = new SimpleRenderer;

			connect_services (sh0, sh1, txt).to_clients (gfx, txt, dbg);

			auto verts = VertexBuffer (gfx.normalized_bounds[].map!(v => v / 2));

			auto f = new Font (36);
			auto t = new Text (f, gfx, `fuck`);
			t.align_to (Alignment.top_right)
				.within ([-1.vec, 1.vec].bounding_box); // TODO forward builders in ops -> if it returns ref wrapped, wrap it in ref this

			sh1.activate; // BUG BUG BUG uniform not linked if not activated
			t[].color = red;

			txt.draw.text (t).immediately;
			
			dbg.draw
		//		.text (t)
				.vertices (verts)
				.color (blue)
				.immediately;

			gfx.render;

			import core.thread;

			Thread.sleep (1000.msecs);
		}
	}
