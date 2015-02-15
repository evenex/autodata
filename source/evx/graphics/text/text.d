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
	import evx.memory;
	import evx.misc.tuple;

	import evx.graphics.resource;
	import evx.graphics.color;
	import evx.graphics.display;
	import evx.graphics.opengl;
	import evx.graphics.operators;
	import evx.graphics.shader;

	import evx.misc.utils;
}
private {/*types}*/
	alias texture_font_t = void;
	alias texture_atlas_t = void;
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
			ColorBuffer.Sub!0 _color;
			VertexBuffer.Sub!0 _card;
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

				texture = MonoTexture.reconstruct (atlas.id);
			}
		~this ()
			{/*...}*/
				reset;
			}

		auto opDispatch (string data)()
			{/*...}*/
				return mixin(q{base.} ~ data);
			}

		MonoTexture texture;

		private:

		enum path = "./font/DejaVuSansMono.ttf";

		texture_font_t* base;
		texture_atlas_t* atlas;
		size_t size;

		alias base this;

		void reset ()
			{/*...}*/
				evx.memory.transfer.neutralize (texture);

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

				Stack!(Array!fvec) cards;
				Stack!(Array!fvec) tex_coords;
				Stack!(Array!size_t) newline_positions;

				auto wrap_width = (draw_box.width * î!vec.rotate (rotation)).to_pixel_space (display).norm;
				auto pen = fvec(0, -font.ascender);
				this.card_box = [0.fvec, pen].bounding_box; 

				{/*reserve memory}*/
					cards.capacity = 4 * text.length;
					tex_coords.capacity = 4 * text.length;
					{/*estimate line breaks}*/
						auto newlines = text[].count!(c => c == '\n');
						auto approx_glyphs_per_line = (wrap_width / Font.texture_font_get_glyph (font, ' ').width).floor;

						newline_positions.capacity = (newlines + text.length / approx_glyphs_per_line).ceil.to!size_t + 1;
					}
				}

				newline_positions ~= 0;

				{/*build buffers}*/
					foreach (i, symbol; enumerate (text[]))
						{/*...}*/
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
									size_t trim_length = text[0..i+1].retro.before!isWhite.length;

									if (trim_length < 0)
										trim_length = i + 1;

									auto cutoff = i + 1 - trim_length;
										
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

					card_box = card_box[].map!transform.to_normalized_space (display).bounding_box;

					cards[] = cards[].map!transform
						.map!(v => v.to_normalized_space (display) + translation)
						.map!(v => v + card_box.offset_to (alignment, draw_box))
						.map!(v => v.each!(to!float));
				}
				{/*flush buffers}*/
					this.cards[] = cards[];
					this.tex_coords[] = tex_coords[];
				}

				this.needs_refresh = false;
			}

		this ()(auto ref Font font, ref Display display, dstring text = ``)
			{/*...}*/
				import evx.memory.transfer;

				static if (__traits(isRef, font))
					this.font = borrow (font);
				else font.move (this.font);

				this.display = borrow (display);

				this.draw_box = display.normalized_bounds; 

				this = text;
			}

		public:
		public {/*alignment}*/
			ref align_to (Alignment alignment)
				{/*...}*/
					this._alignment = alignment;
					this.needs_refresh = true;

					return this;
				}
			auto alignment ()
				{/*...}*/
					return _alignment;
				}

			ref within (BoundingBox box)
				{/*...}*/
					this.draw_box = box;
					this.needs_refresh = true;

					return this;
				}
			auto bounding_box ()
				{/*...}*/
					return draw_box;
				}
		}
		public {/*affine transform}*/
			mixin AffineTransform!float affine;

			auto ref translate (fvec Δx)
				{/*...}*/
					this.needs_refresh = true;

					return affine.translate (Δx);
				}
			auto ref rotate (float θ)
				{/*...}*/
					this.needs_refresh = true;

					return affine.rotate (θ);
				}
			auto ref scale (float s)
				{/*...}*/
					this.needs_refresh = true;

					return affine.scale (s);
				}
			auto ref scale ()
				{/*...}*/
					return affine.scale;
				}
		}
		public {/*buffer ops}*/
			auto access (size_t i)
				{/*...}*/
					if (this.needs_refresh)
						refresh;

					return Glyph (data[i], colors[4*i..4*(i+1)], cards[4*i..4*(i+1)]);
				}
			auto pull (R)(R range, size_t i)
				{/*...}*/
					pull (range, i, i+1);
				}
			auto pull (R)(R range, size_t[2] interval)
				{/*...}*/
					auto i = interval.left, j = interval.right;

					static if (is (ElementType!R : dchar))
						{/*...}*/
							data[i..j] = range;

							this.needs_refresh = true;
						}
					else {/*...}*/
						foreach (k, glyph; enumerate (range))
							colors[4*k..4*(k+1)] = glyph.color;

						auto old_data = data;

						data[i..j] = range.map!(glyph => glyph.symbol).to!dstring;

						if (data != old_data)
							this.needs_refresh = true;
					}
				}
			auto allocate (size_t length)
				{/*...}*/
					data = Array!dchar (length);

					immutable n = 4 * length;

					cards = VertexBuffer (n);
					tex_coords = VertexBuffer (n);
					colors = black.repeat (n);
				}
			auto length () const
				{/*...}*/
					return data.length;
				}

			template TextOps ()
				{/*...}*/
					auto color (Color color)
						{/*...}*/
							this.colors (color.repeat (bounds[0].width));
						}
					auto colors (R)(R colors)
						in {/*...}*/
							static assert (is (ElementType!R == Color));

							assert (bounds[0].width == colors.length,
								`assignment length mismatch [` ~ bounds[0].width.text ~ `] = [` ~ colors.length.text ~ `]`
							);
						}
						body {/*...}*/
							source.colors[4*bounds[0].left..4*bounds[0].right] = colors.grid (colors.length * 4);
						}

					auto bounding_box ()
						{/*...}*/
							return this[].extract!`card`.join.bounding_box; // REVIEW optimization: source.cards[bounds[0].left..bounds[0].right].cached.bounding_box
						}

					auto toString ()
						{/*...}*/
							return this[].extract!`symbol`.cache.to!string;
						}
				}

			mixin BufferOps!(allocate, pull, access, length, RangeOps, TextOps);
		}
		public {/*render ops}*/
			auto shader ()
				{/*...}*/
					return τ(borrow (cards), borrow (tex_coords), borrow (colors))
						.vertex_shader!(
							`cards`, `tex_coords`, `colors`, q{
								gl_Position = vec4 (cards, 0, 1);
								color = colors;
								tex_uv = tex_coords;
							}
						).fragment_shader!(
							Color, `color`,
							fvec, `tex_uv`,
							Texture, `tex`, q{
								gl_FragColor = vec4 (color.rgb, color.a * texture (tex, tex_uv).r);
							}
						)(borrow (font.texture));
				}
			void draw (uint i : 0)(uint n)
				{/*...}*/
					foreach (j; 0..n/4)
						gl.DrawArrays (GL_TRIANGLE_FAN, 4*j, 4);
				}

			mixin RenderOps!(draw, shader) renderer;

			auto ref render_to (T)(auto ref T target)
				{/*...}*/
					if (data.length == 0)
						return target;

					if (this.needs_refresh)
						refresh;

					return renderer.render_to (target);
				}
		}
		private:
		private {/*buffers}*/
			VertexBuffer cards;
			VertexBuffer tex_coords;
			ColorBuffer colors;
		}
		private {/*data}*/
			bool needs_refresh;

			MaybeBorrowed!Font font;
			Borrowed!Display display;

			Array!dchar data;

			Alignment _alignment;
			Box!float card_box; // REVIEW out here why?
			BoundingBox draw_box;
		}
	}
	unittest {/*...}*/
		auto display = Display (512, 512);

		auto text = Text (Font (12), display, `hay sup`);

		assert (text[] == `hay sup`);
		text[0..3] = `oi,`;
		assert (text[] == `oi, sup`);

		text[].up_from (`s`).color = red;
		assert (text.colors[].stride (4).array[] == [black, black, black, black, red, red, red]);
	}
	unittest {/*...}*/
		import evx.graphics.display;

		auto display = Display (512, 512);

		auto t = Text (Font (20), display, 
			`Lorem ipsum dolor sit amet, `
			`consectetur adipiscing elit, `
			`sed do eiusmod tempor incididunt `
			`ut labore et dolore magna aliqua. `
			`Ut enim ad minim veniam, quis `
			`nostrud exercitation ullamco laboris `
			`nisi ut aliquip ex ea commodo consequat. `
			`Duis aute irure dolor in reprehenderit `
			`in voluptate velit esse cillum dolore `
			`eu fugiat nulla pariatur. Excepteur `
			`sint occaecat cupidatat non proident, `
			`sunt in culpa qui officia deserunt `
			`mollit anim id est laborum.`
		);

		t.align_to (Alignment.center)
			.within ([-1.vec, 1.vec].bounding_box)
			.rotate (π/4);

		t[].colors = rainbow (t.length*3)[$/3..2*$/3];

		t.render_to (display);

		display.post;

		import core.thread;
		Thread.sleep (7.seconds);
	}
