#version 420 compatibility

uniform vec4 color = vec4 (0.0, 0.0, 0.0, 1.0);

void main (void) {
	gl_FragColor = color;
}
