module evx.graphics.color.palette;

import evx.graphics.color.core;

public enum {/*Color palette}*/
	/* mono */
	black 	= Color (0.0),
	white 	= Color (1.0),
	/* primary */
	red 	= Color (1.0, 0.0, 0.0),
	green 	= Color (0.0, 1.0, 0.0),
	blue 	= Color (0.0, 0.0, 1.0),
	/* secondary */
	yellow 	= red + green,
	cyan 	= green + blue,
	magenta = blue + red,
	/* others */
	grey	= black*white,
	orange 	= red*yellow,
	purple 	= blue*magenta,
	brown	= orange*black,
}
unittest {/*...}*/
	assert (red + blue == magenta);
	assert (red + green == yellow);
	
	assert (cyan - blue == green);
	assert (cyan - blue - green == black);
	assert (red + yellow + blue == white);
	assert (white - (red + blue) == green);

	auto orange = Color (1.0, 0.5, 0.0);
	assert (red + yellow == yellow);
	assert (red * yellow == orange);
}
