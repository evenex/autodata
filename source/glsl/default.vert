#version 420 compatibility

varying vec2 local_coords;
uniform vec4 screen_aabb = vec4 (0.0, 0.0, 0.0, 0.0);
uniform float rotation = 0.0;

void main (void) {
	local_coords = gl_Vertex - screen_aabb;
	gl_Position = gl_Vertex;
}
