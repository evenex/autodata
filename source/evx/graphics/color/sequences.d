module evx.graphics.color.sequences;

private {/*imports}*/
	import evx.math;//	import evx.math.functional;
	import evx.math;//	import evx.math.sequence;
	import evx.graphics.color.core;
}

auto rainbow (size_t length = 7)
	{/*...}*/
		return ℕ[0..length]
			.map!(i => i * 360.0/length)
			.map!(hue => Color ().hsv (hue, 1.0, 1.0));
	}

auto shades_of (size_t n_shades, Color color)
	{/*...}*/
		return ℕ[0..n_shades]
			.map!(i => Color ().hsl (color.h, color.s, (1.0 + i)/n_shades).alpha (color.a));
	}
