module tools.scribe;

import std.traits;
import std.datetime;
import std.concurrency;
import std.exception;
import std.stdio;
import std.ascii;
import std.algorithm;
import std.range;
import std.array;

import utils;
import math;

import resource.allocator;

import services.display;

struct Unicode
	{/*...}*/
		alias Char = dchar; // XXX on 64-bit systems
		private {/*imports}*/
			import std.range;
		}
		__gshared: 
		const {/*character maps}*/
			Char[] ascii;
			Char[string] arrow;
			Char[string] symbol;
		}
		const {/*aliasing}*/
			Char[] all;
			alias all this;
		}
		private {/*☀}*/
			shared static this ()
				{/*...}*/
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
					all = chain (ascii, arrow.byValue, symbol.byValue).array;
				}
			@disable this();
		}
	}

class Scribe
	{/*...}*/
		private {/*imports}*/
			mixin DynamicLibraryLoader;
		}
		public:
		public {/*interface}*/
			Text write (T)(T text)
				{/*...}*/
					return Text (this, text.to!dstring)
						.color (black)
						.size (font_sizes[0])
						.inside (only (-1.vec, 1.vec))
						.wrap_width (-1)
						.rotate (0.0)
						.translate (0.vec)
						.scale (1.0)
						.align_to (Alignment.top_left);
				}
			shared Glyph glyph (Args...) (Args args)
				{/*↓}*/
					return (cast(Scribe)this).glyph (args);
				}
			Glyph glyph (char_T) (char_T code, uint size = 0, Color glyph_color = black)
				in {/*...}*/
					import std.traits;
					assert (isSomeChar!char_T);
					assert (font !is null);
					assert (size == 0 || size in font);
				}
				body {/*...}*/
					if (size == 0)
						size = font_sizes[0];
					auto font = font[size];
					auto glyph = texture_font_get_glyph (font, code);
					float s0 = glyph.s0;
					float t0 = glyph.t0;
					float s1 = glyph.s1;
					float t1 = glyph.t1;
					uint width  = cast (uint) glyph.width;
					uint height = cast (uint) glyph.height;
					int offset_x = glyph.offset_x;
					int offset_y = glyph.offset_y;

					Glyph G;
					with (G)
						{/*...}*/
							symbol = code;
							texture = atlas.id;
							roi = [vec(s0, t0), vec(s1, t1)];
							offset = ivec(offset_x, offset_y);
							dims = uvec(width, height);
							advance = glyph.advance_x;
							color = glyph_color;
						}
					return G;
				}
					// TODO properties?? actions ^^^
			auto font_height (uint size)
				in {/*...}*/
					assert (size in font);
				}
				body {/*...}*/
					auto scale = font[size].height.vec / display.dimensions;
					return scale.max;
				}
			auto available_sizes ()
				{/*...}*/
					return font_sizes;
				}
			void connect_to (Display display)
				in {/*...}*/
					assert (display);
				}
				body {/*...}*/
					alias received_before = receiveTimeout;

					display.access_rendering_context 
						((){texture_atlas_upload (atlas);});

					this.display = display;
						display.on_stop (&reset);
				}
		}
		public {/*☀/~}*/
			this (uint[] sizes = [12])
				{/*...}*/
					import std.string;
					mixin (error_suppression);
					mixin (load_dynamic_library!"freetype_gl");

					auto atlas_size = uvec(64, 64);
					void load_texture_atlas ()
						{/*...}*/
							atlas = texture_atlas_new (atlas_size.x, atlas_size.y, 1);
							foreach (size; font_sizes)
								{/*...}*/
									font[size] = texture_font_new (atlas, font_path, size);
									auto missed_glyphs 	= texture_font_load_glyphs (font[size], Unicode.ptr);
									if (missed_glyphs > 0)
										{/*...}*/
											reset ();
											if (atlas_size.y == 2*atlas_size.x)
												atlas_size.x *= 2;
											else atlas_size.y *= 2;
											load_texture_atlas ();
											break;
										}
								}
						}
					
					font_sizes = sizes.idup;
					load_texture_atlas ();

					vertex_pool = Allocator!vec (2^^14);
					glyph_pool = Allocator!Glyph (2^^12);
				}
			this (Display display, uint[] sizes = [12])
				in {/*...}*/
					assert (display);
				}
				body {/*...}*/
					this (sizes);
					connect_to (display);
				}
		}
		private:
		private {/*ops}*/
			void output (Text order)
				in {/*...}*/
					assert (display, "tried to write but scribe has no display");
				}
				body {/*...}*/
					auto text = order.text;
					auto color = order.color;
					auto size = order.size;
					if (text.empty) return;
					
					auto glyphs = glyph_pool.save (text.map!(c => glyph (c, size, color)));
					auto cards = vertex_pool.allocate (4*text.length);

					typeset (glyphs, order, cards);

					foreach (i, glyph; glyphs[])
						{/*...}*/
							auto geometry = cards [4*i..4*i+4];
							auto tex_coords = glyph.roi.bounding_box.flip!`vertical`;

							display.draw (glyph.texture, geometry, tex_coords, color);
						}

					glyphs.free;
					cards.free;
				}
			auto typeset (T1, T2)(ref T1 glyphs, ref Text order, ref T2 cards)
				if (__traits(compiles, glyphs[0] == Glyph.init) && is_geometric!T2)
				in {/*...}*/
					assert (order.size in font);
				}
				body {/*...}*/
					auto size = order.size;
					auto font = this.font[size];
					auto card_box = Box ([0.vec, vec(0, -font.height)]);
					vec pen = vec(0, -font.ascender);

					auto bounds = order.bounds;
					auto rotation = order.rotate;
					auto wrap_width = order.wrap_width;
					auto draw_box = bounds[].from_extended_space.to_pixel_space (display).bounding_box;
					if (wrap_width < 0) 
						with (draw_box) wrap_width = right - left;
					else wrap_width = (wrap_width*î.vec.rotate (rotation)).from_extended_space.to_pixel_space (display).norm;

					foreach (i, glyph; glyphs[])
						{/*set card coordinates in pen-space}*/
							vec offset = glyph.offset;
							vec dims   = glyph.dims;

							cards ~= [
								pen,
								pen + vec(dims.x, 0),
								pen + dims,
								pen + vec(0, dims.y)
							];

							auto new_position = pen.x + dims.x;

							if (new_position > wrap_width)
								{/*word wrap}*/
									auto length = glyphs[0..i+1].retro.countUntil!(g => g.symbol.isWhite);
									if (length < 0)
										length = i+1;
									auto cutoff = i+1 - length;
										
									auto word = length.ℕ
										.map!(j => j + cutoff)
										.map!(j => cards[4*j..4*(j+1)]);

									auto Δx = word.empty? 
										pen.x + glyph.advance - glyph.offset.x
										: word[0][0].x - glyph.offset.x;
									auto carriage_return = (vec v) => v - vec(Δx, font.height);

									foreach (ref letter; word)
										letter.map!carriage_return.copy (letter);

									pen = carriage_return (pen);
									card_box.bottom = card_box.bottom - font.height;
								}
							if (new_position > card_box.right)
								card_box.right = new_position;

							cards[$-4..$] = cards[$-4..$].map!(v => v - vec(-offset.x, dims.y - offset.y));

							pen.x += glyph.advance;
						}

					auto scale = order.scale;
					auto transform = (vec v) => scale*((v-pen/2).rotate (rotation) + pen/2);
					card_box = card_box.map!transform.bounding_box;

					auto alignment = order.alignment;
					auto translation = order.translate;

					cards[] = cards[].map!transform
						.map!(v => v + card_box.offset_to (alignment, draw_box))
						.map!(v => v.from_pixel_space.to_draw_space (display) + translation);
				}
			void reset ()
				{/*...}*/
					if (atlas !is null)
						texture_atlas_delete (atlas);
					foreach (f; font)
						{texture_font_delete (f);}
					font = null;
				}
		}
		private {/*data}*/
			texture_atlas_t* atlas;
			texture_font_t*[uint] font;
		}
		private {/*settings}*/
			enum font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"; // TEMP
			immutable uint[] font_sizes;
		}
		private {/*services}*/
			Display display;
		}
		private {/*resources}*/
			Allocator!Glyph glyph_pool;
			Allocator!vec vertex_pool;
		}
		extern (C):
		extern (C) {/*services}*/
			texture_atlas_t* function (const size_t width, const size_t height, const size_t depth)
				texture_atlas_new;
			void function (texture_atlas_t* self)
				texture_atlas_delete;
			texture_font_t* function (texture_atlas_t* atlas, const char* filename, const float size) 
				texture_font_new;
			size_t function (texture_font_t* self, const dchar* charcodes) 
				texture_font_load_glyphs;
			void function (texture_font_t* self)
				texture_font_delete;
 			void function (texture_atlas_t* self)
				texture_atlas_upload;
			texture_glyph_t* function (texture_font_t* self, dchar charcode) // XXX 32-64-bit
				texture_font_get_glyph;
		}
		extern (C) {/*definitions}*/
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
					void* glyphs; // Vector of glyphs contained in this font. 
					texture_atlas_t* atlas; // Atlas structure to store glyphs data. 
					char* filename; // Font filename 
					float size; // Font size 
					int hinting; // Whether to use autohint when rendering font 
					int outline_type; // Outline type (0 = None, 1 = line, 2 = inner, 3 = outer) 
					float outline_thickness; // Outline thickness 
					int filtering; //  Whether to use our own lcd filter.
					int kerning; // Whether to use kerning if available 
					ubyte lcd_weights[5]; // LCD filter weights 
					float height; // This field is simply used to compute a default line spacing (i.e., the baseline-to-baseline distance) when writing text with this font. Note that it usually is larger than the sum of the ascender and descender taken as absolute values. There is also no guarantee that no glyphs extend above or below subsequent baselines when using this distance.
					float linegap; // This field is the distance that must be placed between two lines of text. The baseline-to-baseline distance should be computed as: ascender - descender + linegap 
					float ascender; // The ascender is the vertical distance from the horizontal baseline to the highest 'character' coordinate in a font face. Unfortunately, font formats define the ascender differently. For some, it represents the ascent of all capital latin characters (without accents), for others it is the ascent of the highest accented character, and finally, other formats define it as being equal to bbox.yMax. 
					float descender; // The descender is the vertical distance from the horizontal baseline to the lowest 'character' coordinate in a font face. Unfortunately, font formats define the descender differently. For some, it represents the descent of all capital latin characters (without accents), for others it is the ascent of the lowest accented character, and finally, other formats define it as being equal to bbox.yMin. This field is negative for values below the baseline. 
					float underline_position; // The position of the underline line for this face. It is the center of the underlining stem. Only relevant for scalable formats. 
					float underline_thickness; // The thickness of the underline for this face. Only relevant for scalable formats. 
				}
			struct texture_glyph_t
				{/*...}*/
					dchar charcode; // Wide character this glyph represents  // XXX 32/64 bit
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
	}
struct Text
	{/*...}*/
		public:
		@property {/*font settings}*/
			mixin Command!(
				Color, `color`,
				uint, `size`
			);
		}
		@property {/*alignment}*/
			auto inside (T)(T bounds)
				if (is_geometric!T)
				{/*...}*/
					this.bounds[] = [
						bounds.reduce!((u,v) => vec(min(u.x,v.x), min(u.y,v.y))), 
						bounds.reduce!((u,v) => vec(max(u.x,v.x), max(u.y,v.y)))
					];
					return this;
				}
			auto align_to (Alignment alignment)
				{/*...}*/
					this.alignment = alignment;
					return this;
				}
			mixin Command!(
				double, `wrap_width`,
			);
		}
		@property {/*transformation}*/
			mixin Command!(
				double, `rotate`,
				vec, 	`translate`,
				double, `scale`,
			);
		}
		@property {/*fulfillment}*/
			void opCall ()
				{/*...}*/
					scribe.output (this);
				}
		}
		private:
		private {/*data}*/
			Scribe scribe;
			dstring text;
			vec[2] bounds;
			Alignment alignment;
		}
		private {/*☀}*/
			this (Scribe scribe, dstring text)
				{/*...}*/
					this.scribe = scribe;
					this.text = text;
				}
		}
	}
struct Table
	{/*...}*/
		struct Entry
			{/*...}*/
				string label;
				string value;
			}
		Entry[] entries;
		Color borders;
	}

unittest
	{/*...}*/
		mixin (report_test!"scribe");
		import core.thread;
		import std.datetime;

		static immutable hold_time = 1.seconds;

		static void test ()
			{/*...}*/
				try	{/*...}*/
					scope (success) ownerTid.send (true);

					scope display = new Display (800, 600);
					display.start; scope (exit) display.stop;

					auto scribe = new Scribe (display, [14, 18]);
					auto stuff (float x) 
						{/*...}*/
							auto upper = [vec(-1.5*x+0.2, -x), vec(2*x+0.2, x)];
							auto lower = [vec(x, -x - 0.1), vec(-x, x - 0.1)];
							scribe.write ("The sky above the port was the color of television,")
								.size (18)
								.color (white)
								.inside (upper)
							();
							scribe.write ("tuned to a dead channel.")
								.size (14)
								.color (white)
								.rotate (π/4)
								.align_to (Alignment.top_right)
								.inside (lower)
							();
							display.draw ((blue*white).alpha (0.2), upper.bounding_box.from_extended_space.to_draw_space (display));
							display.draw ((blue*white).alpha (0.2), lower.bounding_box.from_extended_space.to_draw_space (display));
						}
					stuff (0.7);

					{/*alignment test}*/
						auto bb = [vec(0.6,-0.6), 0.vec];
						scribe.write ("top_left")
							.scale (0.75)
							.color (white)
							.align_to (Alignment.top_left)
							.inside (bb)
						();
						scribe.write ("center_left")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.center_left)
							.inside (bb)
						();
						scribe.write ("bottom left")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.bottom_left)
							.inside (bb)
						();
						scribe.write ("top_center")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.top_center)
							.inside (bb)
						();
						scribe.write ("center")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.center)
							.inside (bb)
						();
						scribe.write ("bottom_center")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.bottom_center)
							.inside (bb)
						();
						scribe.write ("top_right")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.top_right)
							.inside (bb)
						();
						scribe.write ("center_right")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.center_right)
							.inside (bb)
						();
						scribe.write ("bottom_right")
							.color (white)
							.scale (0.75)
							.align_to (Alignment.bottom_right)
							.inside (bb)
						();

						display.draw (red.alpha (0.3), bb.bounding_box.from_extended_space.to_draw_space (display));
					}
					{/*word wrap test}*/
						auto bounds = [-0.8.vec, vec(-0.2,0)];
						scribe.write (`stop hustling and you sank without a trace,`
							` but move a little too swiftly and you break the fragile`
							` surface tension of the black market. either way, you were gone,`
							` with nothing left of you but some vague memory in the mind`
							` of a fixture, like ratz. though your heart, or lungs, or kidneys`
							` might survive in the service of some stranger with new yen`
							` for the clinic tanks.`)
							.inside (bounds)
							.color (yellow.alpha (0.2)*green.alpha(0.5))
						();
						display.draw (orange.alpha (0.2), bounds.bounding_box.from_extended_space.to_draw_space (display));
					}

					display.render;
					Thread.sleep (hold_time);
					display.stop;
				}
				catch (Throwable ex) {elaborate_exception (ex);}
			}

		spawn (&test);
		assert (receiveTimeout (hold_time + 1.seconds, (bool _){}));
	}
