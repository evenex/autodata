module evx.graphics.text.font;

private {/*import}*/
	import evx.patterns;
	import evx.math;
	import evx.range;

	import evx.misc.utils;
	import evx.graphics.opengl; // texture
}

public:

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

		mixin Original!reset;

		package:

		enum path = "./font/DejaVuSansMono.ttf";

		texture_font_t* base;
		texture_atlas_t* atlas;
		size_t size;

		alias base this;

		auto texture ()
			{/*...}*/
				return Texture (atlas.id);
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

			static mixin DynamicLibrary;
			shared static this (){load_library;}
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
					dchar[] all;
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
						all = chain (ascii, arrow.byValue, symbol.byValue).array;
					}
				@disable this();
			}
	}

package:

alias texture_font_t = void;
alias texture_atlas_t = void;
