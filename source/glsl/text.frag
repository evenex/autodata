#version 420 compatibility

in vec2 texture_coordinates;

uniform sampler2D texture;

uniform vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);

void main (void) {
	float lum = texture2D (texture, texture_coordinates).a;
	gl_FragColor = vec4 (color) * vec4 (1.0, 1.0, 1.0, color.a);
}
