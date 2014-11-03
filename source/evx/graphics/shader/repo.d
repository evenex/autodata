module evx.graphics.shader.repo;

private {/*imports}*/
	import evx.graphics.shader.program;
	import evx.graphics.color;

	import evx.math;
}

public {/*basic shader}*/
	alias BasicShader = ShaderProgram!(
		VertexShader!(
			Input!(
				fvec[], `position`,		Init!(0,0),
				Color,  `color`,		Init!(1,0,1,1),
				fvec,   `translation`,	Init!(0,0),
				float,  `rotation`,		Init!(0),
				float,  `scale`,		Init!(1),
			), q{
				float c = cos(rotation);
				float s = sin(rotation);

				vec2 rotated = vec2 (c*position.x - s*position.y, s*position.x + c*position.y);

				gl_Position = vec4 (scale*rotated + translation, 0, 1);
			}
		),
		FragmentShader!(
			Input!(
				Color,	`color`,
			),
			Output!(
				Color[], `frag_color`,
			), q{
				frag_color = color;
			}
		),
	);
}
