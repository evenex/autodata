module evx.graphics.color.core;// REFACTOR

private {/*imports}*/
	import evx.misc.tuple;
	import evx.math;

	alias map = evx.math.functional.map; // REVIEW why does this not already happen (colors complains calculus.map is private)
}


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

public {/*hex}*/ // REVIEW
	auto to_hex (Color color) // REVIEW
		{/*...}*/
			import std.conv; 

			static get_hex (uint x)
				{/*...}*/
					char[16] me;

					import core.stdc.stdio;

					sprintf (me.ptr, "%.2x", x);

					import std.algorithm;
					return me[].findSplitBefore ("\0")[0].to!string;
				}

			string ret;

			foreach (h; (color.vector * 255).each!(to!uint)[].map!get_hex)
				ret ~= h;

			return ret;
		}
}

struct Color
	{/*...}*/
		mixin NormalizedInvariance;

		auto opIndex (size_t i)
			{/*...}*/
				return (cast(double*)&this)[i];
			}

		enum length = 4;

		pure nothrow:
		auto hue ()
			{/*...}*/
				auto m = max (r,g,b);
				auto μ = min (r,g,b);
				auto c = m - μ;

				if (c == 0)
					return double.init;
				else if (m == r)
					return 60.0 * ((g-b)/c % 6);
				else if (m == g)
					return 60.0 * ((b-r)/c + 2);
				else if (m == b)
					return 60.0 * ((r-g)/c + 4);

				assert (0, `couldn't compute hue`);
			}

		auto value ()
			{/*...}*/
				return max (r, g, b);
			}

		alias v = value;

		auto saturation ()
			{/*...}*/
				if (value == 0)
					return 0;

				else return (max (r,g,b) - min (r,g,b))/v;
			}

		@(Normalized.positive) {/*components}*/
			double 	r = 1.0, 
					g = 0.0,
					b = 1.0, 
					a = 1.0;
		}
		@property {/*channels}*/
			Color red (double r)
				{/*...}*/
					return Color (r,g,b,a);
				}
			Color green (double g)
				{/*...}*/
					return Color (r,g,b,a);
				}
			Color blue (double b)
				{/*...}*/
					return Color (r,g,b,a);
				}
			Color alpha (double a)
				{/*...}*/
					return Color (r,g,b,a);
				}

			double red ()
				{/*...}*/
					return r;
				}
			double green ()
				{/*...}*/
					return g;
				}
			double blue ()
				{/*...}*/
					return b;
				}
			double alpha ()
				{/*...}*/
					return a;
				}
		}
		public {/*ops}*/
			Color opCall (double alpha)
				{/*...}*/
					return this.alpha (alpha);
				}
			Color opBinary (string op) (Color color)
				{/*...}*/
					Color ret = this;
					static if (op == `+` || op == `-`) with (color)
						foreach (c; Aⁿ!(`r`,`g`,`b`))
							mixin (q{
								ret.} ~c~ q{} ~op~q{= a * } ~c~ q{;
							});
					else static if (op == `*`)
						foreach (c; Aⁿ!(`r`,`g`,`b`)) with (color)
							mixin (q{
								ret.} ~c~ q{ += a* } ~c~ q{; 
								ret.} ~c~ q{ /= a + 1;
							});
					return ret.clamp;
				}
			Color opOpAssign (string op) (Color color)
				{/*...}*/
					mixin (q{
						this = this } ~op~ q{ color;
					});
					clamp ();
					return this;
				}
		}
		public {/*ctors}*/
			this (double brightness, double a = 1.0)
				{/*...}*/
					auto L = brightness;

					r = (g = (b = L));

					this.a = a;
					this.clamp;
				}
			this (double r, double g, double b, double a = 1.0)
				{/*...}*/
					this.r = r;
					this.g = g;
					this.b = b;
					this.a = a;
					this.clamp;
				}
			this (Color color)
				{/*...}*/
					this.r = color.r;
					this.g = color.g;
					this.b = color.b;
					this.a = color.a;
				}
			static auto from_hsv (double h, double s = 1.0, double v = 1.0)
				{/*...}*/
					h = h.clamp (0, 360);
					s = s.clamp (0, 1);
					v = v.clamp (0, 1);

					auto M = 255*v;
					auto m = M*(1.0-s);
					
					auto z = (M-m)*(1.0 - abs((h/60.0)%2.0-1.0));

					double r, g, b;
					if (h.between (-infinity, 60))
						r = M, g = z+m, b = m;
					else if (h.between (60, 120))
						r = z+m, g = M, b = m;
					else if (h.between (120, 180))
						r = m, g = M, b = z+m;
					else if (h.between (180, 240))
						r = m, g = z+m, b = M;
					else if (h.between (240, 300))
						r = z+m, g = m, b = M;
					else r = M, g = m, b = z+m;

					r /= 255.0;
					g /= 255.0;
					b /= 255.0;

					return Color (r,g,b);
				}
		}
		private:
		private {/*ops}*/
			Color clamp ()
				{/*...}*/
					foreach (c; Aⁿ!(`r`,`g`,`b`,`a`))
						mixin (q{
							} ~c~ q{ = .clamp (} ~c~ q{, 0.0, 1.0);
						});

					return this;
				}
		}
	};
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