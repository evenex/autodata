module evx.graphics.text.core;

private {/*import}*/
	import std.ascii;
	import std.conv;
	import std.typetuple;

	import evx.math;
	import evx.range;
	import evx.operators;
	import evx.adaptors;
	import evx.containers;
	import evx.patterns;
	import evx.codegen;

	import evx.graphics.text.font;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.display;
}

struct Glyph
	{/*...}*/
		immutable(dchar) symbol;

		auto color ()
			{/*...}*/
				return _color[0];
			}
		void color (Color color)
			{/*...}*/
				_color[0..4] = color;
			}

		auto card ()
			{/*...}*/
				return _card[];
			}

		alias symbol this;

		auto toString ()
			{/*...}*/
				return symbol.to!string;
			}

		this (typeof(symbol) symbol, typeof(_color) color, typeof(_card) card)
			in {/*...}*/
				assert (color.length == 4);
				assert (card.length == 4);
			}
			body {/*...}*/
				this.symbol = symbol;
				this._color = color;
				this._card = card;
			}

		private:
		private {/*...}*/
			Sub!(Appendable!(LocalView!ColorBuffer)) _color;
			Sub!(Appendable!(LocalView!VertexBuffer)) _card;
		}
	}

class Text
	{/*...}*/
		this (Font font, Display display, string text)
			{/*...}*/
				wrapped = Implementation (font, display, text.to!dstring);
			}

		mixin Wrapped!Implementation;

		mixin View!(wrapped,
			InvalidateOn!(`within`, `align_to`, `translate`, `rotate`, `scale`),
			RefreshOn!(`bind`)
		);

		mixin TransferOps!(wrapped,
			ExtendSlice!q{
				auto color (Color color)
					}`{`q{
						auto me = this;

						foreach (glyph; me)
							glyph.color = color;
					}`}`q{

				auto bounding_box ()
					}`{`q{
						return this.get!`card`.join.bounding_box;
					}`}`q{

				auto toString ()
					}`{`q{
						return this.get!`symbol`.array.to!string;
					}`}`q{
			}
		);

		struct Implementation
			{/*...}*/
				void refresh ()
					in {/*...}*/
						assert (font.is_loaded);
					}
					body {/*...}*/
						alias text = data;

						if (text.length == 0)
							return;

						auto wrap_width = (draw_box.width * î!vec.rotate (rotation)).to_pixel_space (display).norm;
						auto pen = fvec(0, -font.ascender);
						this.card_box = [0.fvec, pen].bounding_box; 

						{/*reserve memory}*/
							cards.clear;
							tex_coords.clear;
							newline_positions.clear;

							cards.capacity = 4 * text.length;
							tex_coords.capacity = 4 * text.length;
							{/*estimate line breaks}*/
								auto newlines = text.count!(c => c == '\n');
								auto approx_glyphs_per_line = (wrap_width / Font.texture_font_get_glyph (font, ' ').width).floor;

								newline_positions.capacity = (newlines + text.length / approx_glyphs_per_line).ceil.to!size_t;
							}
						}

						newline_positions ~= 0;

						foreach (i, symbol; text[])
							{/*build buffers}*/
								auto glyph = Font.texture_font_get_glyph (font, symbol);

								auto offset = ivec(glyph.offset_x, glyph.offset_y);
								auto dims = uvec(glyph.width, glyph.height);
								auto advance = glyph.advance_x;

								std.stdio.writeln (`app`);
								with (glyph) 
								tex_coords ~= [
									fvec(s0, t0), 
									fvec(s1, t1)
								].bounding_box[].flip!`vertical`;
								std.stdio.writeln (`/app`);

								cards ~= [
									pen,
									pen + fvec(dims.x, 0),
									pen + dims,
									pen + fvec(0, dims.y)
								];

								if (pen.x + dims.x > wrap_width)
									{/*word wrap}*/
										auto trim_length = text[0..i+1].retro.up_to!isWhite.length;

										if (trim_length < 0)
											trim_length = i + 1;

										auto cutoff = i + 1 - length;
											
										auto word = ℕ[0..trim_length]
											.map!(j => j + cutoff)
											.map!(j => cards[4*j..4*(j+1)]);

										auto Δx = (word.empty? 
											pen.x + advance : word[0][0].x
										) - offset.x;

										auto carriage_return (fvec v) {return v - fvec(Δx, font.height);} 

										foreach (ref letter; word)
											letter.transform!(map!carriage_return);

										pen = carriage_return (pen);

										newline_positions ~= i - word.length + 1;
									}
								else if (symbol == '\n')
									{/*line break}*/
										newline_positions ~= i;

										pen = fvec(0, pen.y - font.height);
									}

								cards[$-4..$] = cards[$-4..$].map!(v => v - fvec(-offset.x, dims.y - offset.y));

								pen.x += advance;

								card_box.width = max (card_box.width, pen.x);
							}

						{/*align text}*/
							card_box.height = max (pen.y.abs, font.height);
							card_box = card_box.align_to (Alignment.top_left, 0.fvec);

							newline_positions ~= data.length;

							foreach (i, line_start; enumerate (newline_positions[0..$-1]))
								{/*justify lines}*/
									auto line_stop = newline_positions[i+1];

									if (line_stop == line_start)
										continue;

									auto line_box = cards[4*line_start..4*line_stop].bounding_box;

									auto justification = line_box.offset_to (alignment, card_box).x;

									auto line = cards[4*line_start..4*line_stop];

									line[] = line.map!(v => v + fvec(justification, 0));
								}

							auto transform (fvec v) {return scale * (v-pen/2).rotate (rotation) + pen/2;}

							card_box = card_box[].map!transform.bounding_box;

							cards[] = cards[].map!transform
								.map!(v => v + card_box.offset_to (alignment, draw_box))
								.map!(v => v.to_normalized_space (display) + translation)
								.map!(v => v.each!(to!float));
						}
					}

				void bind ()
					{/*...}*/
						alias Buffers = TypeTuple!(q{cards}, q{tex_coords}, q{colors});

						mixin(apply_to_each!(`.post`, Buffers));
						mixin(apply_to_each!(`.bind`, Buffers, q{font.texture}));
					}

				this (ref Font font, Display display, dstring text)
					{/*...}*/
						this.font = font;
						this.display = display;
						this.draw_box = display.normalized_bounds; 
						this.data = text;

						{/*reserve memory}*/
							colors.clear;
							colors.capacity = 4*text.length;
						}

						colors ~= black.repeat (4*text.length);

						refresh;
					}

				mixin AffineTransform!float;

				public:
				public {/*alignment}*/
					ref align_to (Alignment alignment)
						{/*...}*/
							this._alignment = alignment;

							return this;
						}
					auto alignment ()
						{/*...}*/
							return _alignment;
						}

					ref within (BoundingBox box)
						{/*...}*/
							this.draw_box = box;

							return this;
						}
					auto bounding_box ()
						{/*...}*/
							return draw_box;
						}
				}
				public {/*transfer}*/
					auto access (size_t i)
						{/*...}*/
							return Glyph (data[i], colors[4*i..4*(i+1)], cards[4*i..4*(i+1)]);
						}
					auto pull (R)(R range, size_t i, size_t j)
						{/*...}*/
							static if (is_string!R)
								{/*...}*/
									data = data[0..i] ~ range.to!dstring ~ data[j..$];

									refresh;
								}
							else {/*...}*/
								foreach (k, glyph; enumerate (range))
									colors[4*k..4*(k+1)] = glyph.color;

								auto old_data = data;

								data = data[0..i] ~ range.map!(glyph => glyph.symbol).to!dstring ~ data[j..$];

								if (data != old_data)
									refresh;
							}
						}
					auto length () const
						{/*...}*/
							return data.length;
						}
				}
				public {/*data}*/
					Appendable!(LocalView!VertexBuffer) cards;
					Appendable!(LocalView!VertexBuffer) tex_coords;
					Appendable!(LocalView!ColorBuffer) colors;
				}
				private:
				private {/*data}*/
					Font font;

					dstring data;
					Appendable!(MArray!size_t) newline_positions;

					Display display; // REVIEW need this
					Alignment _alignment;
					Box!float card_box; // REVIEW out here why?
					BoundingBox draw_box;
				}
			}
	}
	unittest {/*...}*/
		scope gfx = new Display; // BUG need this before using gpu stuff at all... how to enforce?

		scope f = Font (12); // class
		scope x = new Text (f, gfx, `hay sup`);

		assert (x[][1] == x[1]);

		x[].up_from (`s`).color = red;

		assert (x[1] == 'a');
		x[0..3] = `oi,`;
		assert (x[1] == 'i');

		assert (x.colors[].stride (4).m_array[] == [black, black, black, black, red, red, red]);

		assert (x[] == `oi, sup`);
	}
