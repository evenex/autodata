module evx.graphics.text;

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

	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.display;
	import evx.graphics.opengl;
	
	import evx.misc.utils;
}
private {/*types}*/
	alias texture_font_t = void;
	alias texture_atlas_t = void;
}

void main (){}
struct Glyph
	{/*...}*/
		immutable(dchar) symbol;

		auto color ()
			{/*...}*/
				return _color[0];
			}
		void color (Color color)
			{/*...}*/
				_color[0..4] = color.repeat (4);
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
			Stack!ColorBuffer.Sub!0 _color;
			Stack!VertexBuffer.Sub!0 _card;
		}
	}

struct Font
	{/*...}*/
		this (size_t size)
			out {/*...}*/
				assert (this.is_loaded);
			}
			body {/*...}*/
				auto atlas_size = uvec(64, 64);

				void load_texture_atlas ()
					{/*...}*/
						atlas = texture_atlas_new (atlas_size.x, atlas_size.y, 1);

						this.base = texture_font_new_from_file (atlas, size, path); 

						assert (base !is null, `couldn't load font from ` ~path);

						auto missed_glyphs = texture_font_load_glyphs (base, Unicode.ptr);

						if (missed_glyphs > 0)
							{/*...}*/
								reset;

								if (atlas_size.y == 2*atlas_size.x)
									atlas_size.x *= 2;
								else atlas_size.y *= 2;

								load_texture_atlas;
							}
					}
				
				mixin(error_suppression);

				load_texture_atlas ();
			}
		~this ()
			{/*...}*/
				reset;
			}

		package:

		enum path = "./font/DejaVuSansMono.ttf";

		texture_font_t* base;
		texture_atlas_t* atlas;
		size_t size;

		alias base this;

		auto texture_id ()
			{/*...}*/
				return atlas.id;
			}

		void reset ()
			{/*...}*/
				if (atlas !is null)
					texture_atlas_delete (atlas);

				if (base !is null)
					texture_font_delete (base);

				atlas = null;
				base = null;
			}

		bool is_loaded ()
			{/*...}*/
				return base !is null && atlas !is null;
			}

		__gshared extern (C) {/*library}*/
			package {/*services}*/
				texture_atlas_t* function (const size_t width, const size_t height, const size_t depth)
					texture_atlas_new;
				void function (texture_atlas_t* self)
					texture_atlas_delete;

				texture_font_t* function (texture_atlas_t* atlas, const float size, const char* filename)
					texture_font_new_from_file;

				size_t function (texture_font_t* self, const dchar* charcodes) 
					texture_font_load_glyphs;
				void function (texture_font_t* self)
					texture_font_delete;
				void function (texture_atlas_t* self)
					texture_atlas_upload;
				texture_glyph_t* function (texture_font_t* self, dchar charcode)
					texture_font_get_glyph;
			}
			package {/*definitions}*/
				struct texture_atlas_t
					{/*...}*/
						void* nodes; // Allocated nodes 
						size_t width; //  Width (in pixels) of the underlying texture 
						size_t height; // Height (in pixels) of the underlying texture 
						size_t depth; // Depth (in bytes) of the underlying texture 
						size_t used; // Allocated surface size 
						uint id; // Texture identity (OpenGL) 
						ubyte* data; // Atlas data 
					}
				struct texture_font_t
					{/*...}*/
						/**
						 * Vector of glyphs contained in this font.
						 */
						void* glyphs;

						/**
						 * Atlas structure to store glyphs data.
						 */
						texture_atlas_t* atlas;
						
						/**
						 * font location
						 */
						enum Location {
							TEXTURE_FONT_FILE = 0,
							TEXTURE_FONT_MEMORY,
						};
						Location location;

						union {
							/**
							 * Font filename, for when location == TEXTURE_FONT_FILE
							 */
							char* filename;

							/**
							 * Font memory address, for when location == TEXTURE_FONT_MEMORY
							 */
							struct Memory {
								const void* base;
								size_t size;
							};
							Memory memory;
						};

						/**
						 * Font size
						 */
						float size;
						
						/**
						 * Whether to use autohint when rendering font
						 */
						int hinting;

						/**
						 * Outline type (0 = None, 1 = line, 2 = inner, 3 = outer)
						 */
						int outline_type;

						/**
						 * Outline thickness
						 */
						float outline_thickness;

						/** 
						 * Whether to use our own lcd filter.
						 */
						int filtering;

						/**
						 * Whether to use kerning if available
						 */
						int kerning;

						/**
						 * LCD filter weights
						 */
						ubyte[5] lcd_weights;

						/**
						 * This field is simply used to compute a default line spacing (i.e., the
						 * baseline-to-baseline distance) when writing text with this font. Note
						 * that it usually is larger than the sum of the ascender and descender
						 * taken as absolute values. There is also no guarantee that no glyphs
						 * extend above or below subsequent baselines when using this distance.
						 */
						float height;

						/**
						 * This field is the distance that must be placed between two lines of
						 * text. The baseline-to-baseline distance should be computed as:
						 * ascender - descender + linegap
						 */
						float linegap;

						/**
						 * The ascender is the vertical distance from the horizontal baseline to
						 * the highest 'character' coordinate in a font face. Unfortunately, font
						 * formats define the ascender differently. For some, it represents the
						 * ascent of all capital latin characters (without accents), for others it
						 * is the ascent of the highest accented character, and finally, other
						 * formats define it as being equal to bbox.yMax.
						 */
						float ascender;

						/**
						 * The descender is the vertical distance from the horizontal baseline to
						 * the lowest 'character' coordinate in a font face. Unfortunately, font
						 * formats define the descender differently. For some, it represents the
						 * descent of all capital latin characters (without accents), for others it
						 * is the ascent of the lowest accented character, and finally, other
						 * formats define it as being equal to bbox.yMin. This field is negative
						 * for values below the baseline.
						 */
						float descender;

						/**
						 * The position of the underline line for this face. It is the center of
						 * the underlining stem. Only relevant for scalable formats.
						 */
						float underline_position;

						/**
						 * The thickness of the underline for this face. Only relevant for scalable
						 * formats.
						 */
						float underline_thickness;

					}
				struct texture_glyph_t
					{/*...}*/
						dchar charcode; // Wide character this glyph represents
						uint id; // Glyph id (used for display lists) 
						size_t width; // Glyph's width in pixels. 
						size_t height; // Glyph's height in pixels. 
						int offset_x; // Glyph's left bearing expressed in integer pixels. 
						int offset_y; // Glyphs's top bearing expressed in integer pixels. Remember that this is the distance from the baseline to the top-most glyph scanline, upwards y coordinates being positive.
						float advance_x; // For horizontal text layouts, this is the horizontal distance (in fractional pixels) used to increment the pen position when the glyph is drawn as part of a string of text.
						float advance_y; // For vertical text layouts, this is the vertical distance (in fractional pixels) used to increment the pen position when the glyph is drawn as part of a string of text.
						float s0; // First draw texture coordinate (x) of top-left corner 
						float t0; // Second draw texture coordinate (y) of top-left corner 
						float s1; // First draw texture coordinate (x) of bottom-right corner 
						float t1; // Second draw texture coordinate (y) of bottom-right corner 
						void* kerning; // A vector of kerning pairs relative to this glyph. 
						int outline_type; // Glyph outline type (0 = None, 1 = line, 2 = inner, 3 = outer) 
						float outline_thickness; // Glyph outline thickness 
					}
			}

			static mixin DynamicLibrary; // REVIEW coalesce?
			shared static this (){load_library;} // REVIEW coalesce?
		}

		struct Unicode
			{/*...}*/
				__gshared: 

				const {/*character maps}*/
					dchar[] ascii;
					dchar[string] arrow;
					dchar[string] symbol;
				}
				const {/*aliasing}*/
					Array!(dchar, 1) all;
					alias all this;
				}

				shared static this ()
					{/*...}*/
						{/*initialize character maps}*/
							{/*ascii}*/
								ascii =
									` !"#$%&'()*+,-./0123456789:;<=>?`
									`@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`
									"`abcdefghijklmnopqrstuvwxyz{|}~"
									;
							}
							{/*arrow}*/
								arrow = [
									`left`		:'←',
									`up`		:'↑',
									`right`		:'→',
									`down`		:'↓',
									`left_right`:'↔',
									`up_down`	:'↕',
									`left_2`	:'↞',
									`up_2`		:'↟',
									`right_2`	:'↠',
									`down_2`	:'↡',
									`back_left`	:'↩',
									`back_right`:'↪',
									`loop_left`	:'↫',
									`loop_right`:'↬',
									`over_left`	:'↶',
									`over_right`:'↷',
									`ccw`		:'↺',
									`cw`		:'↻',
									`bi_horiz`	:'⇄',
									`bi_vert`	:'⇅',
									`2_left`	:'⇇',
									`2_up`		:'⇈',
									`2_right`	:'⇉',
									`2_down`	:'⇊',
									`bi_harpoon`:'⇋',
									`dash_left`	:'⇠',
									`dash_up`	:'⇡',
									`dash_right`:'⇢',
									`dash_down`	:'⇣',
									`compass`	:'➢',
									`head`		:'➤',
									`halo`		:'➲',
								];
							}
							{/*symbol}*/
								symbol = [
									`lightning`	:'⚡',
									`warning`	:'⚠',
									`white_flag`:'⚐',
									`black_flag`:'⚑',
									`hammers`	:'⚒',
									`anchor`	:'⚓',
									`swords`	:'⚔',
									`medicine`	:'⚕',
									`scales`	:'⚖',
									`alembic`	:'⚗',
									`flower`	:'⚘',
									`gear`		:'⚙',
									`commerce`	:'⚚',
									`atom`		:'⚛',
									`fleur`		:'⚜',
									`skull`		:'☠',
									`caution`	:'☡',
									`nuke`		:'☢',
									`biohazard`	:'☣',
									`hermes`	:'☤',
									`communism`	:'☭',
									`peace`		:'☮',
									`yinyang`	:'☯',
									`x` 		:'✕',
									`(+)`		:'⊕',
									`(-)`		:'⊖',
									`(x)`		:'⊗',
									`(/)`		:'⊘',
									`(.)`		:'⊙',
									`(o)`		:'⊚',
									`(*)`		:'⊛',
									`(=)`		:'⊜',
									`[+]`		:'⊞',
									`[-]`		:'⊟',
									`[x]`		:'⊠',
									`[.]`		:'⊡',
									`box_empty`	:'☐',
									`box_check`	:'☑',
									`box_cross`	:'☒',
									`flash_on`	:'☀',
									`flash_off`	:'☼',
									`crosshair`	:'✛',
								];
							}
						}
						all = chain (ascii, arrow.byValue, symbol.byValue).cache;
					}
				@disable this();
			}
	}

struct Text
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

						with (glyph) 
						tex_coords ~= [
							fvec(s0, t0), 
							fvec(s1, t1)
						].bounding_box[].flip!`vertical`;

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
		public {/*transfer ops}*/
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

			template TextOps ()
				{/*...}*/
					auto color (Color color)
						{/*...}*/
							foreach (glyph; this[])
								glyph.color = color;
						}

					auto bounding_box ()
						{/*...}*/
							return this[].extract!`card`.join.bounding_box;
						}

					auto toString ()
						{/*...}*/
							return this[].extract!`symbol`.cache.to!string;
						}
				}

			mixin TransferOps!(pull, access, length, RangeOps, TextOps);
		}
		public {/*data}*/
			Stack!VertexBuffer cards;
			Stack!VertexBuffer tex_coords;
			Stack!ColorBuffer colors;
		}
		private:
		private {/*data}*/
			Font font;

			dstring data;
			Stack!(Array!(size_t, 1)) newline_positions;

			Display display; // REVIEW need this
			Alignment _alignment;
			Box!float card_box; // REVIEW out here why?
			BoundingBox draw_box;
		}
	}
version (none):

void main () {/*...}*/
	scope gfx = new Display; // BUG need this before using gpu stuff at all... how to enforce?

	scope f = new Font (12); // class
	scope x = new Text (f, gfx, `hay sup`);

	assert (x[][1] == x[1]);

	x[].up_from (`s`).color = red;

	assert (x[1] == 'a');
	x[0..3] = `oi,`;
	assert (x[1] == 'i');

	assert (x.colors[].stride (4).m_array[] == [black, black, black, black, red, red, red]);

	assert (x[] == `oi, sup`);
}
