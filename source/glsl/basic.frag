#version 420

#define NONE	0
#define COLOR	1
#define TEXT	2
#define SPRITE 	3

uniform int mode;
uniform vec4 color;
uniform sampler2D tex;
smooth in vec2 tex_coords;

out vec4 frag_color;

void main (void) {
	switch (mode)
	{/*...}*/
		case NONE:
			frag_color = vec4 (1.0, 0.0, 1.0, 1.0);
			break;
		case COLOR:
			frag_color = color;
			break;
		case TEXT:
			frag_color = vec4 (color.rgb, color.a * texture (tex, tex_coords).a);
			break;
		case SPRITE:
			frag_color = texture (tex, tex_coords);
			break;
	}
}
