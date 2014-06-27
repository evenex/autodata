#version 420 compatibility

layout (location = 0) in vec2 position; // XXX
layout (location = 1) in vec2 texture_coords; // XXX

smooth out vec2 tex_coords; // XXX

void main (void) {
	gl_Position = vec4 (position, 0, 1);
	tex_coords = texture_coords;
}
