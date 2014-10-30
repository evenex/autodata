module evx.graphics.color.sequences;

import evx.math.functional;
import evx.math.sequence;
import evx.graphics.color.core;

auto rainbow (size_t length)
	{/*...}*/
		return ℕ[0..length]
			.map!(i => i * 360.0/length)
			.map!(hue => Color.from_hsv (hue, 1.0, 1.0));
	}

auto shades_of (size_t n_shades, Color color)
	{/*...}*/
		auto base_color = Color.from_hsv (color.hue, color.saturation, 0);

		return ℕ[0..n_shades]
			.map!(i => Color.from_hsv (color.hue, color.saturation, (1.0*i)/n_shades).alpha (color.a));
	}
