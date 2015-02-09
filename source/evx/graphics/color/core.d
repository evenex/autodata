module evx.graphics.color.core;

private {/*imports}*/
	import core.stdc.stdio;

	import std.conv; 

	import evx.math;
	import evx.range;
	import evx.type;
}

struct Color
	{/*...}*/
		Vector!(4, float) base = vector (0.0f, 0.0f, 0.0f, 1.0f);
		alias base this;

		public:
		public {/*rgb}*/
			auto red ()
				{/*...}*/
					return this.r;
				}
			auto green ()
				{/*...}*/
					return this.g;
				}
			auto blue ()
				{/*...}*/
					return this.b;
				}

			auto ref red (float r)
				{/*...}*/
					this.r = r;
					this.normalize;
					return this;
				}
			auto ref green (float g)
				{/*...}*/
					this.g = g;
					this.normalize;
					return this;
				}
			auto ref blue (float b)
				{/*...}*/
					this.b = b;
					this.normalize;
					return this;
				}
		}
		public {/*hsv}*/
			auto hue ()
				out (h) {/*...}*/
					assert (h.between (0, 360), `hue for ` ~base.to!string~ ` is ` ~h.to!string);
				}
				body {/*...}*/
					auto m = max (r,g,b);
					auto μ = min (r,g,b);
					auto c = m - μ;

					if (c == 0)
						return 0.0;
					else if (m == r)
						return 60.0 * (((g-b)/c + 6) % 6);
					else if (m == g)
						return 60.0 * ((b-r)/c + 2);
					else if (m == b)
						return 60.0 * ((r-g)/c + 4);

					assert (0, `couldn't compute hue`);
				}
			auto saturation ()
				out (s) {/*...}*/
					assert (s.between (0, 1));
				}
				body {/*...}*/
					if (value == 0)
						return 0;

					else return (max (r,g,b) - min (r,g,b))/v;
				}
			auto value ()
				out (v) {/*...}*/
					assert (v.between (0, 1));
				}
				body {/*...}*/
					return max (r, g, b);
				}

			auto ref hue (float h)
				{/*...}*/
					return hsv (h,s,v);
				}
			auto ref saturation (float s)
				{/*...}*/
					return hsv (h,s,v);
				}
			auto ref value (float v)
				{/*...}*/
					return hsv (h,s,v);
				}

			auto hsv ()
				{/*...}*/
					return vector (h,s,v);
				}
			auto ref hsv (float h, float s, float v)
				in {/*...}*/
					assert (s.between (0, 1), `sat was ` ~s.text);
					assert (v.between (0, 1), `val was ` ~v.text);
				}
				body {/*...}*/
					auto c = v * s;
					auto x = c * (1 - abs ((h/60.0) % 2.0 - 1));
					auto m = v - c;

					convert_from_cylindrical (h, c, x, m);

					return this;
				}

			alias h = hue;
			alias s = saturation;
			alias v = value;
		}
		public {/*hsl}*/
			auto lightness ()
				{/*...}*/
					return (max (r,g,b) + min (r,g,b)) / 2;
				}
			auto ref lightness (float l)
				{/*...}*/
					return hsl (h,s,l);
				}

			auto hsl ()
				{/*...}*/
					return vector (h,s,l);
				}
			auto ref hsl (float h, float s, float l)
				{/*...}*/
					auto c = (1 - (2*l - 1).abs) * s;
					auto x = c * (1 - abs ((h/60.0) % 2.0 - 1));
					auto m = l - c/2;

					convert_from_cylindrical (h, c, x, m);

					return this;
				}

			alias l = lightness;
		}
		public {/*alpha}*/
			auto alpha ()
				{/*...}*/
					return this.a;
				}
			auto ref alpha (float a)
				{/*...}*/
					this.a = a;
					this.normalize;
					return this;
				}

			auto opCall (float alpha)
				{/*...}*/
					return this.alpha (alpha);
				}
		}
		public {/*ctor}*/
			this (float r, float g, float b, float a = 1.0)
				{/*...}*/
					this.base = typeof(base)(r,g,b,a);

					normalize;
				}
			this (float l)
				{/*...}*/
					this.base = typeof(base)(l,l,l, 1.0);

					normalize;
				}
			this (Vector!(4, ubyte) pixel)
				{/*...}*/
					base = pixel.each!(to!float);

					base /= 255;

					normalize;
				}
			this (Vector!(4, float) color)
				{/*...}*/
					base = color;

					normalize;
				}
		}
		public {/*cast}*/
			V opCast (V)()
				{/*...}*/
					static if (is (V == Vector!(4,T), T : long))
						{}
					else static assert (0);

					return (base * T.max).each!(to!T);
				}
		}
		public {/*ops}*/
			Color opBinaryRight (string op)(Color color)
				{/*...}*/
					auto alpha = color.alpha;

					static if (op == `+`)
						color.base += this.a * this.base;
					static if (op == `-`)
						color.base[0..3] -= this.a * this.base[0..3];
					else static if (op == `*`)
						{/*...}*/
							color.base += this.a * this.base;
							color.base /= this.a + 1;
							color.alpha = alpha;
						}

					color.normalize;

					return color;
				}
			auto ref opOpAssign (string op)(Color color)
				{/*...}*/
					mixin (q{
						this = this } ~op~ q{ color;
					});
					
					normalize;

					return this;
				}
		}
		public {/*text}*/
			auto toString ()
				{/*...}*/
					static get_hex (uint x)
						{/*...}*/
							char[16] hex;

							sprintf (hex.ptr, "%.2X", x);

							return hex[].before ("\0").to!string;
						}

					string ret = `#`;

					try foreach (h; (this * 255).each!(to!uint).each!get_hex[])
						ret ~= h;
					catch (ConvOverflowException) ret ~= `--------`;

					return ret;
				}
		}
		private:
		private {/*ops}*/
			void normalize ()
				{/*...}*/
					base = base.each!clamp (interval (0, 1));
				}

			void convert_from_cylindrical (float h, float c, float x, float m)
				in {/*...}*/
					assert (h.between (0, 360), `hue was ` ~h.text);
				}
				body {/*...}*/
					if (h.between (0, 60))
						r = c, g = x, b = 0;
					else if (h.between (60, 120))
						r = x, g = c, b = 0;
					else if (h.between (120, 180))
						r = 0, g = c, b = x;
					else if (h.between (180, 240))
						r = 0, g = x, b = c;
					else if (h.between (240, 300))
						r = x, g = 0, b = c;
					else if (h.between (300, 360))
						r = c, g = 0, b = x;

					this[0..3] += m;

					normalize;
				}
		}
		invariant () {/*...}*/
			assert (this[].all!(c => c.between (0.0, 1.0)),
				`color is not normalized! ` ~ this.text
			);
		}
	}
