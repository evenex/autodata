module color;

import std.math;

import utils;
import math;

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
	gray	= black*white,
	orange 	= red*yellow,
	purple 	= blue*magenta,
	brown	= orange*black,
}
struct Color
	{/*...}*/
		public:
		@Normalized {/*components}*/
			float 	r = 1.0, 
					g = 0.0,
					b = 1.0, 
					a = 1.0;
		}
		public {/*ops}*/
			Color alpha (float A)
				{/*...}*/
					Color ret = this;
					ret.a = A;
					return ret;
				}
			Color clamp ()
				{/*...}*/
					import math;
					foreach (c; Aⁿ!(`r`,`g`,`b`,`a`))
						mixin (q{
							} ~c~ q{ = math.clamp (} ~c~ q{, 0.0, 1.0);
						});
					return this;
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
		public {/*☀}*/
			this (float brightness, float A = 1.0)
				{/*...}*/
					auto L = brightness;
					r = (g = (b = L));
					a = A;
					this.clamp;
				}
			this (float R, float G, float B, float A = 1.0)
				{/*...}*/
					r = R;
					g = G;
					b = B;
					a = A;
					this.clamp;
				}
			this (Color color)
				{/*...}*/
					this.r = color.r;
					this.g = color.g;
					this.b = color.b;
					this.a = color.a;
				}
			static auto from_hsv (float H, float S = 1.0, float V = 1.0)
				{/*...}*/
					import math;

					H = H.clamp (0, 360);
					S = S.clamp (0, 1);
					V = V.clamp (0, 1);

					auto M = 255*V;
					auto m = M*(1.0-S);
					
					auto z = (M-m)*(1.0 - abs((H/60.0)%2.0-1.0));

					float R, G, B;
					if (H.between (-float.infinity, 60))
						R = M, G = z+m, B = m;
					else if (H.between (60, 120))
						R = z+m, G = M, B = m;
					else if (H.between (120, 180))
						R = m, G = M, B = z+m;
					else if (H.between (180, 240))
						R = m, G = z+m, B = M;
					else if (H.between (240, 300))
						R = z+m, G = m, B = M;
					else R = M, G = m, B = z+m;

					R /= 255.0;
					G /= 255.0;
					B /= 255.0;

					return Color (R,G,B);
				}
		}
		mixin NormalizedInvariance!(Normalized.positive);
		unittest
			{/*...}*/
				mixin (report_test!"Color ops");

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
	};
