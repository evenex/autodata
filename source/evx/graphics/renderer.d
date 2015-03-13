module evx.graphics.renderer;
version(none):

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
	import evx.graphics.operators;
	import evx.graphics.resource;
	import evx.graphics.color;

	import evx.graphics.shader.core;
	import evx.graphics.shader.repo;
}

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
auto triangle_strip (S)(S shader)
	{/*...}*/
		return ArrayRenderer!S (RenderMode.t_strip, shader);
	}
auto line_loop (S)(S shader)
	{/*...}*/
		return ArrayRenderer!S (RenderMode.l_loop, shader);
	}

auto card (T)(auto ref T texture, vec position = 0.vec, vec dimensions = 2.vec) // TODO builder struct
	{/*...}*/
		static if (__traits(isRef, texture) && is (InitialType!T == T))
			auto card_texture = borrow (texture);
		else alias card_texture = texture;

		return textured_shape_shader (
			square!float.scale (dimensions).translate (position),
			card_texture 
		).triangle_fan;
	}
