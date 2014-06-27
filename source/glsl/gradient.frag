#version 420 compatibility

varying vec2 local_coords;

uniform vec4 start_color = vec4 (1.0, 0.0, 1.0, 1.0);
uniform vec4 final_color = vec4 (1.0, 1.0, 0.0, 1.0);

uniform vec2 center_pos = vec2 (0.0, 0.0);
uniform vec2 lerp_vec = vec2 (1.0, 0.0);
uniform float lerp_range = 1.0;

void main (void)
	{/*...}*/
		vec2 displacement_vec = local_coords - center_pos;
		float projection_length = dot (displacement_vec, lerp_vec);
		float gradient_pos = 0.5 + 2*projection_length / lerp_range;
		gl_FragColor = (1.0 - gradient_pos) * start_color + (gradient_pos) * final_color;
	}
