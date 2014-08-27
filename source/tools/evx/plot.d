module evx.plot;// TODO refactor everything

import std.traits;
import std.typecons;
import std.algorithm;
import std.range;
import std.string;

import evx.allocators;

import evx.utils;
import evx.colors;
import evx.math;

import evx.display;

import evx.scribe;

alias zip = evx.functional.zip;
alias map = evx.functional.map;
alias reduce = evx.functional.reduce;

alias versus = zip;

enum Style {standard, minimal}

struct Plot (Data, Style style)
	if (is(ElementType!Data == Tuple!(T,U), T, U))
	{/*...}*/
		alias Point = ElementType!Data;

		alias YType = Point.Types[0];
		alias XType = Point.Types[1];

		alias XRange = Interval!XType;
		alias YRange = Interval!YType;
		enum {automatic}

		public:
		@property {/*options}*/
			auto using (Display display, Scribe scribe)
				{/*...}*/
					this.display = display;
					this.scribe = scribe;
					if (_text_size == 0)
						this.text_size (scribe.available_sizes.front);

					return this;
				}

			auto title (String)(String title)
				if (isSomeString!String)
				{/*...}*/
					_title = title.text;
					return this;
				}

			auto text_size (size_t size)
				in {/*...}*/
					if (scribe !is null)
						assert (scribe.available_sizes.canFind (size));
				}
				body {/*...}*/
					_text_size = size;
					return this;
				}

			auto color (Color color)
				{/*...}*/
					_color = color;
					return this;
				}

			auto inside (T)(T bounds)
				if (is_geometric!T)
				{/*...}*/
					this.bounds = bounds.bounding_box;

					return this;
				}

			alias x_axis = axis_options!`x`;
			alias y_axis = axis_options!`y`;
		}
		public {/*drawing}*/
			void draw ()
				{/*...}*/
					if (data.empty) return;

					enum x1 = unity!XType;
					enum y1 = unity!YType;
					
					auto y_data = data.map!(τ => τ[0]);
					auto x_data = data.map!(τ => τ[1]);

					auto get_limit (string axis, string side)()
						{/*...}*/
							static if (side == `min`)
								const size_t i = 0;
							else static if (side == `max`)
								const size_t i = 1;
							else static assert (0);

							mixin(q{
								alias _data = } ~axis~ q{_data;
								alias _range = } ~axis~ q{_range;
								alias _side = } ~side~ q{;
							});

							mixin(q{
								return _range.} ~side~ q{.is_infinite?
									_data.reduce!_side : _range.} ~side~ q{;
							});
						}

					auto x_min = get_limit!(`x`,`min`);
					auto x_max = get_limit!(`x`,`max`);
					auto y_min = get_limit!(`y`,`min`);
					auto y_max = get_limit!(`y`,`max`);

					auto h_0 = 2.5 * scribe.font_height (_text_size);
					auto h_1 = bounds.height - h_0;
					auto w_1 = bounds.width - h_0;
					auto ε = 0.1*h_0;

					void draw_data_in (Box!double plot_field)
						{/*...}*/
							display.draw (_color.alpha (0.25), plot_field[].from_extended_space.to_draw_space (display));
							display.draw (_color, 
								data.map!(τ => vec(τ[1]/x1, τ[0]/y1))
									.map!(v => v - vec(x_min/x1, y_min/y1))
									.map!(v => v / vec((x_max-x_min)/x1, (y_max-y_min)/y1))
									.map!(v => v * vec(plot_field.width, plot_field.height))
									.map!(v => v + plot_field.low_left)
									.from_extended_space.to_draw_space (display),
								GeometryMode.l_strip
							);
						}

					static if (style is Style.standard)
						{/*...}*/
							auto title_field = bounds;
								with (title_field) {/*...}*/
									left = left + 2*h_0;
									bottom = bottom + h_1 + ε;
								}

							auto y_field = bounds;
								with (y_field) {/*...}*/
									top 	= top 	 - h_0;
									bottom 	= bottom + 2*h_0;
									right 	= right	 - w_1 - ε;
									left 	= left	 + ε;
								}

							auto x_field = bounds;
								with (x_field) {/*...}*/
									left	= left	 + 2*h_0;
									top		= top 	 - h_1 - ε;
									right	= right	 - 2*ε;
								}

							auto x_ticks = x_field[].translate (vec(0, h_0)).bounding_box;
							auto y_ticks = y_field[].translate (vec(h_0, 0)).bounding_box;

							auto plot_field = bounds;
								with (plot_field) {/*...}*/
									left   = left   + 2*h_0;
									right  = right  - 2*ε;
									top 	  = top 	  - h_0;
									bottom = bottom + 2*h_0;
								}

							scribe.write (_title)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_center)
								.inside (title_field)
							();
							scribe.write (x_label~ ` (` ~x_max.text.find (` `)[1..$]~ `)`)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_center)
								.inside (x_field)
							();
							scribe.write (x_min/x1)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_left)
								.inside (x_ticks)
							();
							scribe.write (x_max/x1)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_right)
								.inside (x_ticks)
							();
							scribe.write (y_label~ ` (` ~y_max.text.find (` `)[1..$]~ `)`)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.center_right)
								.wrap_width (y_field.height)
								.inside (y_field)
							();
							scribe.write (y_min/y1)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.bottom_right)
								.wrap_width (y_field.height)
								.inside (y_ticks)
							();
							scribe.write (y_max/y1)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.top_right)
								.wrap_width (y_field.height)
								.inside (y_ticks)
							();

							draw_data_in (plot_field);
						}
					else static if (style is Style.minimal)
						{/*...}*/
							auto title_field = bounds;
								title_field.bottom = title_field.bottom + h_1 + ε;

							auto y_field = bounds;
								with (y_field) {/*...}*/
									top 	= top 	 - h_0;
									bottom 	= bottom + h_0;
									right 	= right	 - w_1 - ε;
								}

							auto x_field = bounds;
								with (x_field) {/*...}*/
									left	= left	+ h_0;
									top		= top 	- h_1;
									right	= right	- 2*ε;
								}

							auto plot_field = bounds;
								with (plot_field) {/*...}*/
									left   = left   + h_0;
									right  = right  - 2*ε;
									top    = top 	- h_0;
									bottom = bottom + h_0;
								}

							scribe.write (_title)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.center)
								.inside (title_field)
							();
							scribe.write (x_label)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_left)
								.inside (x_field)
							();
							scribe.write (x_max)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_right)
								.inside (x_field)
							();
							scribe.write (y_label)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.bottom_right)
								.wrap_width (y_field.height)
								.inside (y_field)
							();
							scribe.write (y_max)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.top_right)
								.wrap_width (y_field.height)
								.inside (y_field)
							();

							draw_data_in (plot_field);
						}
				}
		}
		public {/*ctor}*/
			this (Data data)
				{/*...}*/
					this.data = data;
				}
		}
		private:
		private {/*services}*/
			Display display;
			Scribe scribe;
		}
		private {/*data}*/
			Data data;

			string _title;
			string x_label;
			string y_label;
			XRange x_range = interval (-infinite!XType, infinite!XType);
			YRange y_range = interval (-infinite!YType, infinite!YType);
			Color _color = black;
			size_t _text_size;
			Box!double bounds = bounding_box ([-1.vec, 1.vec]);
		}
		private {/*code generation}*/
			template axis_options (string axis)
				{/*...}*/
					static code ()
						{/*...}*/
							enum Range = axis.capitalize ~ q{Range};
							enum Type = axis.capitalize ~ q{Type};

							return q{
								auto axis_options (String)(String label, } ~Range~ q{ range = interval (-infinite!} ~Type~ q{, infinite!} ~Type~ q{))
									}`{`q{
										this.} ~axis~ q{_label = label.text;
										this.} ~axis~ q{_range = range;

										return this;
									}`}`q{
							};
						}

					mixin(code);
				}
		}
	}

auto plot (Style style = Style.standard, Data)(Data data)
	{/*...}*/
		static assert (is(ElementType!Data == Tuple!(T,U), T, U));

		return Plot!(Data, style) (data);
	}
	unittest {/*...}*/
		import std.math;

		scope gfx = new Display (400,400);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [20]);

		writeln (ℕ[1..100].map!(x => exp (1. * x)).reduce!max);
		plot (ℕ[1..100].map!(x => exp (0.1 * x)).versus (ℕ[1..100].map!(x => 0.1 * x)))
			.color (red)
			.text_size (20)
			.using (gfx, txt)
			.x_axis (`x`)
			.y_axis (`exp (x)`)
		.draw;

		gfx.render;

		import std.datetime: msecs;
		core.thread.Thread.sleep (2000.msecs);
	}
	unittest {/*units}*/
		import std.math;
		import evx.units;

		scope gfx = new Display (400,400);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [14]);

		plot (ℕ[1..100].map!(x => (x^^2).joules).versus (ℕ[1..100].map!(x => x.meters/second)))
			.color (white)
			.title (`energy vs speed`)
			.text_size (14)
			.using (gfx, txt)
			.x_axis (`speed`)
			.y_axis (`energy`)
			.inside ([vec(-1,-1), vec(1,1)].scale (0.5).bounding_box)
		.draw;

		gfx.render;

		import std.datetime: msecs;
		core.thread.Thread.sleep (3000.msecs);
	}
