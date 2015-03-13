module evx.graphics.shader.repo;
version(none):

private {/*imports}*/
	import evx.math;
	import evx.type;
	import evx.range;
	import evx.memory;
	import evx.misc.tuple;

	import evx.graphics.shader;
	import evx.graphics.resource;
	import evx.graphics.color;
}

alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
	gl_Position.xy *= aspect_ratio;
});

auto textured_shape_shader (R, T)(R shape, auto ref T texture)
	{/*...}*/
		static if (is (Element!R == Vector!(2,float)))
			alias draw_shape = shape;
		else auto draw_shape = shape.map!(to!(Vector!(2,float)));

		static if (__traits(isRef, texture) && is (InitialType!T == T))
			auto draw_texture = borrow (texture);
		else alias draw_texture = texture;

		return τ(
			draw_shape,
			draw_shape.flip!`vertical`.into_bounding_box_of (square (2.0f))
		).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = (tex_coords + vec2 (1,1))/2;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(draw_texture);
	}

auto basic_shader (R)(R shape, Color color = red)
	{/*...}*/
		return shape.vertex_shader!(
			`vert`, 
			q{gl_Position = vec4(vert,0,1);}
		).fragment_shader!(
			Color, `color`,
			q{gl_FragColor = color;}
		)(color);
	}
