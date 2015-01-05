module evx.graphics.shader.repo;

private {/*imports}*/
	import evx.math;
	import evx.misc.tuple;

	import evx.graphics.shader;
	import evx.graphics.texture;
}

alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
	gl_Position.xy *= aspect_ratio;
});

auto textured_shape_shader (R)(R shape, auto ref Texture texture)
	{/*...}*/
		return τ(shape, shape.scale (2).flip!`vertical`).vertex_shader!(
			`position`, `tex_coords`, q{
				gl_Position = vec4 (position, 0, 1);
				frag_tex_coords = (tex_coords + vec2 (1,1))/2;
			}
		).fragment_shader!(
			fvec, `frag_tex_coords`,
			Texture, `tex`, q{
				gl_FragColor = texture2D (tex, frag_tex_coords);
			}
		)(texture);
	}
