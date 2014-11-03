module evx.graphics.renderer;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.shader;

	import evx.patterns;
	import evx.math;
}

struct Geometry
	{/*...}*/
		VertexBuffer vertices;
		IndexBuffer indices;

		void bind ()
			{/*...}*/
				vertices.buffer.bind;
				indices.buffer.bind;
			}
	}

class MeshRenderer
	{/*...}*/
		enum Mode {solid, wireframe, overlay}

		struct Order
			{/*...}*/
				mixin Builder!(
					Color,   `color`,
					vec,     `translate`, // REFACTOR
					double,  `rotate`, // REFACTOR
					double,  `scale`, // REFACTOR
					Mode,    `mode`,
				);

				public:
				public {/*fulfillment}*/
					void enqueued () // REFACTOR
						{/*...}*/
							renderer.enqueue (this);
						}
					void immediately () // REFACTOR
						{/*...}*/
							renderer.process (this);
						}
				}
				public {/*ctor}*/
					this (MeshRenderer renderer, Geometry mesh)
						{/*...}*/
							this.renderer = renderer;
							this.mesh = mesh;

							color = magenta (0.5);
							translate = 0.vec;
							rotate = 0;
							scale = 1;
						}
				}
				private:
				private {/*data}*/
					Geometry mesh;
					MeshRenderer renderer;
				}

			}

		public:
		public {/*rendering}*/
			auto draw (Geometry mesh)
				{/*...}*/
					return Order (this, mesh);
				}

			void process ()
				{/*...}*/
					shader.activate;

					foreach (order; orders[])
						process (order);

					orders = null;
				}

			void process (Order order)
				{/*...}*/
					order.mesh.bind;

					with (order)
					shader.position (mesh.vertices)
						.color (color.vector.each!(to!float))
						.translation (translate)
						.rotation (rotate)
						.scale (scale);

					void draw_solid ()
						{/*...}*/
							with (order)
							gl.DrawElements (GL_TRIANGLES, mesh.indices.length.to!int, GL_UNSIGNED_SHORT, null);
						}
					void draw_wireframe ()
						{/*...}*/
							with (order)
							foreach (i; 0..mesh.indices.length/3)
								gl.DrawElements (GL_LINE_LOOP, 3, GL_UNSIGNED_SHORT, cast(void*)(3*i*ushort.sizeof));
						}

					with (Mode) final switch (order.mode)
						{/*...}*/
							case solid:
								draw_solid;
								break;
							case wireframe:
								draw_wireframe;
								break;
							case overlay:
								draw_solid;
								draw_wireframe;
								break;
						}
				}
		}

		private:
		private {/*data}*/
			BasicShader shader;
			Order[] orders;
		}
		package {/*ops}*/
			void enqueue (Order order)
				{/*...}*/
					orders ~= order;
				}

			void attach (BasicShader shader)
				{/*...}*/
					this.shader = shader;
				}
		}
	}

class GraphRenderer
	{/*...}*/
		struct Order
			{/*...}*/
				mixin Builder!(
					Color,  `node_color`,
					Color,  `edge_color`,
					Color,  `color`,
					vec,    `translate`,
					double, `rotate`,
					double, `scale`,
					double, `node_radius`,
				);

				public:
				public {/*fulfillment}*/
					void enqueued ()
						{/*...}*/
							renderer.enqueue (this);
						}

					void immediately ()
						{/*...}*/
							renderer.process (this);
						}
				}
				public {/*ctor}*/
					this (GraphRenderer renderer, Geometry graph)
						{/*...}*/
							this.renderer = renderer;
							this.graph = graph;

							node_color = yellow;
							edge_color = blue;
							node_radius = 0.02;
							rotate = 0;
							scale = 1;
							translate = 0.vec;
						}
				}
				private:
				private {/*data}*/
					GraphRenderer renderer;
					Geometry graph;
				}
			}

		public:
		public {/*rendering}*/
			auto draw (Geometry graph)
				{/*...}*/
					return Order (this, graph);
				}

			void process ()
				{/*...}*/
					shader.activate;

					foreach (order; orders[])
						process (order);

					orders = null;
				}

			void process (Order order)
				{/*...}*/
					void draw_nodes ()
						{/*...}*/
							node.bind;
							shader.position (node)
								.color (order.node_color.vector.to!Cvec)
								.scale (order.scale * order.node_radius.to!float);

							foreach (v; order.graph.vertices[])
								{/*...}*/
									shader.translation (order.translate + v);

									gl.DrawArrays (GL_TRIANGLE_FAN, 0, node.length.to!int); // BUG what to do about setting slices as draw arguments??? what happens when i want set slices of gl arrays as shader parameters?
								}
						}
					void draw_edges ()
						{/*...}*/
							order.graph.bind;

							with (order)
							shader.position (graph.vertices)
								.color (order.edge_color.vector.to!Cvec)
								.translation (translate)
								.rotation (rotate)
								.scale (scale);

							with (order)
							gl.DrawElements (GL_LINES, graph.indices.length.to!int, GL_UNSIGNED_SHORT, null);
						}

					draw_edges;
					draw_nodes;
				}
		}
		public {/*ctor}*/
			this ()
				{/*...}*/
					this.node = node_geometry;
				}
		}
		private:
		private {/*data}*/
			BasicShader shader;
			Order[] orders;
			VertexBuffer node;

			auto node_geometry ()
				{/*...}*/
					return circle!36;
				}
		}
		protected {/*ops}*/
			void enqueue (Order order)
				{/*...}*/
					orders ~= order;
				}

			void attach (BasicShader shader)
				{/*...}*/
					this.shader = shader;
				}
		}
	}

class TextRenderer
	{/*...}*/
		struct Order
			{/*...}*/
				public:
				@property {/*font settings}*/
					mixin Builder!(
						Color, `color`,
						size_t, `size`
					);
				}
				@property {/*alignment}*/
					auto inside (T)(T bounds)
						if (is_geometric!T)
						{/*...}*/
							this.bounds[] = [
								bounds[].reduce!((u,v) => vec(min(u.x,v.x), min(u.y,v.y))), 
								bounds[].reduce!((u,v) => vec(max(u.x,v.x), max(u.y,v.y)))
							];
							return this;
						}
					auto align_to (Alignment alignment)
						{/*...}*/
							this.alignment = alignment;
							return this;
						}
					mixin Builder!(
						double, `wrap_width`,
					);
				}
				@property {/*transformation}*/
					mixin Builder!(
						double, `rotate`,
						vec, 	`translate`,
						double, `scale`,
					);
				}
				@property {/*fulfillment}*/
					auto opCall ()
						{/*...}*/
							assert (0);
						}
				}
				private:
				private {/*data}*/
					Font font;
					dstring text;
					vec[2] bounds;
					Alignment alignment;
				}
				private {/*ctor}*/
					this (dstring text)
						{/*...}*/
							this.text = text;
						}
				}
			}
	}

version (all) {/*...}*/
	import evx.patterns;
	import std.range;
	import evx.misc.utils;

	alias map = evx.math.functional.map;
	void main (){}

	alias texture_font_t = void;
	alias texture_atlas_t = void;

	struct Font
		{/*...}*/
			enum path = "./font/DejaVuSansMono.ttf";

			private:
				texture_font_t* base;
				texture_atlas_t* atlas; // TODO resource mgmt
				size_t size;

				alias base this;

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
				private {/*services}*/
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
				private {/*definitions}*/
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
		unittest {/*...}*/
			import evx.graphics;

			scope gfx = new Display;
			auto f = Font (12);
		}

	alias TextureId = GLint;

	struct Glyph
		{/*...}*/
			dchar symbol;
			TextureId texture;
			vec[2] roi;
			Color color = black;

			@("pixel") ivec offset;
			@("pixel") ivec dims;
			@("pixel") float advance;
		}

	auto glyph (Font font, dchar code)
		in {/*...}*/
			assert (font.is_loaded);
		}
		body {/*...}*/
			auto glyph = Font.texture_font_get_glyph (font, code);

			float s0 = glyph.s0;
			float t0 = glyph.t0;
			float s1 = glyph.s1;
			float t1 = glyph.t1;

			int width  = glyph.width.to!int;
			int height = glyph.height.to!int;

			int offset_x = glyph.offset_x;
			int offset_y = glyph.offset_y;

			Glyph g;
			with (g) {/*...}*/
				symbol = code;
				texture = font.atlas.id;
				roi = [vec(s0, t0), vec(s1, t1)];
				offset = ivec(offset_x, offset_y);
				dims = ivec(width, height);
				advance = glyph.advance_x;
				color = black;
			}

			return g;
		}

	import evx.containers; // REFACTOR

	struct Typeset
		{/*...}*/
	import evx.graphics.display; // REFACTOR
			Display display;
			BoundingBox card_box;

			vec[] cards; // TODO appendable wrapper over stuff
			size_t[] newline_positions;
			Glyph[] glyphs;

			size_t size;
			Color color;
			vec pen;
			Font font;
			double wrap_width;
			double rotation;
			BoundingBox draw_box;
			Alignment alignment;
			double scale;
			vec translation;

			this (TextRenderer.Order order)
				{/*...}*/
					this.cards.length = 4 * order.text.length;

					this.font = order.font;
					this.size = order.size;
					this.color = order.color;

					this.pen = vec(0, -font.ascender);

					auto bounds = order.bounds;
					this.draw_box = bounds[].to_pixel_space (display).bounding_box;

					this.rotation = order.rotate;
					this.wrap_width = order.wrap_width;
					this.alignment = order.alignment;
					this.scale = order.scale;
					this.translation = order.translate;

					if (wrap_width < 0) 
						wrap_width = draw_box.width;
					else wrap_width = (wrap_width * î!vec.rotate (rotation)).to_pixel_space (display).norm;

					newline_positions ~= 0;
					this.card_box = [0.vec, pen].bounding_box; 
				}

			auto append (String)(String input_text)
				if (isSomeString!String)
				{/*...}*/
					//HACK
					auto text = input_text.to!dstring;

					if (text.length == 0)
						return glyphs[0..0];

					auto font = scribe.font[size];
					auto start = glyphs.length;

					glyphs ~= text.map!(c => scribe.glyph (c, size, color));

					foreach (i, glyph; glyphs[].enumerate[start..$])
						{/*set card coordinates in pixel-space}*/
							auto offset = glyph.offset;
							auto dims   = glyph.dims;

							cards ~= [
								pen,
								pen + vec(dims.x, 0),
								pen + dims,
								pen + vec(0, dims.y)
							];

							if (pen.x + dims.x > wrap_width)
								{/*word wrap}*/
									auto length = glyphs[0..i+1].retro.countUntil!(g => g.symbol.isWhite);
									if (length < 0)
										length = i+1;
									auto cutoff = i+1 - length;
										
									auto word = ℕ[0..length]
										.map!(j => j + cutoff)
										.map!(j => cards[4*j..4*(j+1)]);

									auto Δx = (word.empty? 
										pen.x + glyph.advance : word[0][0].x
									) - glyph.offset.x;
									auto carriage_return = (vec v) => v - vec(Δx, font.height);

									foreach (ref letter; word)
										letter.map!carriage_return.copy (letter);

									pen = carriage_return (pen);

									newline_positions ~= i - word.length + 1;
								}
							else if (glyph.symbol == '\n')
								{/*line break}*/
									newline_positions ~= i;
									pen = vec(0, pen.y - font.height);
								}

							cards[$-4..$] = cards[$-4..$].map!(v => v - vec(-offset.x, dims.y - offset.y));

							pen.x += glyph.advance;

							with (card_box) width = max (width, pen.x);
						}

					card_box.height = max (pen.y.abs, font.height);
					card_box = card_box.align_to (Alignment.top_left, 0.vec);

					return glyphs[start..$];
				}

			auto finalize ()
				{/*...}*/
					newline_positions ~= glyphs.length;
					foreach (i, line_start; newline_positions[0..$-1])
						{/*justify lines}*/
							auto line_stop = newline_positions[i+1];

							if (line_stop == line_start)
								continue;

							auto line_box = cards[4*line_start..4*line_stop].bounding_box;

							auto justification = line_box.offset_to (alignment, card_box).x;

							cards[4*line_start..4*line_stop] += vec(justification, 0);
						}

					auto p = pen;
					auto transform (vec v) { return scale*((v-p/2).rotate (rotation) + p/2);}

					card_box = card_box[].map!transform.bounding_box;

					cards[] = cards[].map!transform
						.map!(v => v + card_box.offset_to (alignment, draw_box))
						.map!(v => v.to_normalized_space (display) + translation);

					return cards;
				}
		}
}

unittest {/*...}*/
	import evx.graphics;//	import evx.graphics.display;
	import evx.math;//	import evx.math.overloads;
	import core.thread;

	alias map = evx.math.functional.map;

	scope display = new Display;
	scope shader = new BasicShader;
	scope mesh = new MeshRenderer;
	scope graph = new GraphRenderer;

	display.attach (shader);
	mesh.attach (shader);
	graph.attach (shader);

	auto geometry = Geometry (
		VertexBuffer (circle),
		IndexBuffer ([0,1,2, 2,1,4, 6,7,5, 9,5,3, 2,9,12])
	);

	foreach (i; 0..80)
		{/*...}*/
			mesh.draw (geometry)
				.color (grey (0.1))
				.rotate (i*π/24)
				.enqueued;

			mesh.draw (geometry)
				.color (white (0.1))
				.rotate (-i*π/24)
				.enqueued;

			mesh.process;

			mesh.draw (geometry)
				.color (blue (0.1))
				.rotate ((12+i)*π/24)
				.immediately;

			graph.draw (geometry)
				.node_color (white (gaussian) * cyan (gaussian))
				.immediately;

			geometry.indices[] = ℕ[0..geometry.indices.length].map!(i => (24 * gaussian).abs.round.clamp (interval (0, 23)));

			// STICKING POINT: getting all the order variables loaded into the shader... sometimes they get missed, and the shader doesn't draw
			// STICKING POINT: remembering to bind buffers
			// STICKING POINT: attaching shit to other shit
			// other than that, pretty confortable...

			display.render;

			Thread.sleep (20.msecs);
		}
}
