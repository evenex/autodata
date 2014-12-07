module evx.graphics.shader.text;

private {/*import}*/
	import evx.graphics.shader;
	import evx.graphics.color;
	import evx.graphics.opengl;

	import evx.math;
}

alias TextShader = ShaderProgram!(
	VertexShader!(
		Input!(
			fvec[], `cards`,		Init!(0,0),
			fvec[], `tex_coords`,
			Color[], `colors`, Init!(1,1,0,1),
		), 
		Output!(
			Color[], `color`,
			fvec[], `tex_uv`,
		), q{
			gl_Position.xy = cards;
			color = colors;
			tex_uv = tex_coords;
		}
	),
	FragmentShader!(
		Input!(
			Color[], `color`,
			fvec[], `tex_uv`,
			Texture, `tex`,
		), 
		Output!(
			Color[], `frag_color`,
		), q{
			frag_color = vec4 (color.rgb, color.a * texture (tex, tex_uv).r);
		}
	)
);
