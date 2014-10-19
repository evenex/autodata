module evx.graphics.shader.repo;

private {/*imports}*/
	import evx.graphics.shader.codegen;

	import evx.math.geometry.vectors;
}

public {/*basic shader}*/
	alias BasicShader = ShaderProgram!(
		VertexShader!(
			Input!(
				fvec[], `position`,		Init!(0,0),
				Cvec,   `color`,		Init!(1,0,1,1),
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
				Cvec,	`color`,
			),
			Output!(
				Cvec[], `frag_color`,
			), q{
				frag_color = color;
			}
		),
	);
}
