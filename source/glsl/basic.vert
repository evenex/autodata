#version 420

layout (location = 0) in vec2 position;
layout (location = 1) in vec2 texture_coords;

smooth out vec2 tex_coords;

void main (void) {
	gl_Position = vec4 (position, 0, 1);
	tex_coords = texture_coords;
}
