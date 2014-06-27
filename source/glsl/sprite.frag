#version 420 compatibility

smooth in vec2 tex_coords; // XXX

uniform sampler2D texture; // XXX

uniform bool text = false; // REVIEW
uniform vec4 color = vec4 (0.0, 0.0, 0.0, 1.0); // XXX

void main (void) {
gl_FragColor = vec4(0,0,1,1);
	if (text)
		gl_FragColor = vec4 (color.rgb, color.a * texture2D (texture, tex_coords).a);
	else
		gl_FragColor = texture2D (texture, tex_coords);
}
