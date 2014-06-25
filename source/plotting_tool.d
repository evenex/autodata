import std.traits;
import std.typecons;
import std.algorithm;
import std.range;
import utils;
import views;
import memory;
import math;
import display_service;
import scribe_tool;

struct Plot
	{/*...}*/
		public:
		@property {/*options}*/ // TODO annotate
			auto using (Display display, Scribe scribe)
				{/*...}*/
					this.display = display;
					this.scribe = scribe;
					_text_size = scribe.available_sizes.front;

					return this;
				}
			auto title (String)(String title)
				if (isSomeString!String)
				{/*...}*/
					_title = title.to!dstring;
					return this;
				}
			auto x_axis (String)(String x_label, Range x_range = Range (automatic, automatic))
				if (isSomeString!String)
				{/*...}*/
					this.x_label = x_label.to!dstring;
					this.x_range = x_range;
					return this;
				}
			auto y_axis (String)(String y_label, Range y_range = Range (automatic, automatic))
				if (isSomeString!String)
				{/*...}*/
					this.y_label = y_label.to!dstring;
					this.y_range = y_range;
					return this;
				}
			auto text_size (uint size)
				in {/*...}*/
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
		}
		public {/*draw}*/
			void opCall ()
				{/*...}*/
					if (data.empty) return;
					
					auto x_data = data.map!(τ => τ[0]);
					auto y_data = data.map!(τ => τ[1]);

					auto get_limit (string axis, string side)()
						{/*...}*/
							static if (side == `min`)
								const uint i = 0;
							else static if (side == `max`)
								const uint i = 1;
							else static assert (0);

							mixin(q{alias _data = }~axis~q{_data;});
							mixin(q{alias _range = }~axis~q{_range;});
							mixin(q{alias _side = }~side~q{;});

							return _range[i] == automatic?
								_data.reduce!_side : _range[i];
						}
					auto x_min = get_limit!(`x`,`min`);
					auto x_max = get_limit!(`x`,`max`);
					auto y_min = get_limit!(`y`,`min`);
					auto y_max = get_limit!(`y`,`max`);

					auto h_0 = 2.5*scribe.font_height (_text_size);
					auto h_1 = bounds.height - h_0;
					auto w_1 = bounds.width - h_0;
					auto ε = 0.1*h_0;

					auto title_field = bounds;
						title_field.bottom = title_field.bottom + h_1 + ε;
					auto y_field = bounds;
						y_field.top 	= y_field.top 	 - h_0;
						y_field.bottom 	= y_field.bottom + h_0;
						y_field.right 	= y_field.right	 - w_1 - ε;
					auto x_field = bounds;
						x_field.left	= x_field.left	+ h_0;
						x_field.top		= x_field.top 	- h_1;
						x_field.right	= x_field.right	- 2*ε;
					auto plot_field = bounds;
						plot_field.left   = plot_field.left   + h_0;
						plot_field.right  = plot_field.right  - 2*ε;
						plot_field.top 	  = plot_field.top 	  - h_0;
						plot_field.bottom = plot_field.bottom + h_0;

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
					scribe.write (x_max.to!string.length < 5? x_max.to!string : x_max.to!string[0..5]~`…`)
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
					scribe.write (y_max.to!string.length < 5? y_max.to!string : y_max.to!string[0..5]~`…`)
						.size (_text_size)
						.color (_color)
						.rotate (π/2)
						.align_to (Alignment.top_right)
						.inside (y_field)
					();

					display.draw (_color.alpha (0.25), plot_field.from_extended_space.to_draw_space (display));
					display.draw (_color, 
						data.map!(τ => vec(τ[0],τ[1]))
							.map!(v => v - vec(x_min, y_min))
							.map!(v => v / vec(x_max-x_min, y_max-y_min))
							.map!(v => v * vec(plot_field.width, plot_field.height))
							.map!(v => v + plot_field.low_left)
							.from_extended_space.to_draw_space (display),
						Geometry_Mode.l_strip
					);
				}
		}
		public {/*types}*/
			alias Point = Tuple!(double, double);
			alias Range = Tuple!(double, double);
			static immutable automatic = double.infinity;
		}
		public {/*☀}*/
			this (R1,R2)(ref R1 x, ref R2 y)
				if (not (allSatisfy!(is_IdentityView, TypeTuple!(R1,R2))))
				{/*...}*/
					this.data = zip_view (x,y);
				}
			this (R1,R2)(R1 x, R2 y)
				if (allSatisfy!(is_IdentityView, TypeTuple!(R1,R2)))
				{/*...}*/
					this.data = zip_view (x,y);
				}
		}
		private:
		private {/*services}*/
			Display display;
			Scribe scribe;
		}
		private {/*data}*/
			dstring _title;
			dstring x_label;
			dstring y_label;
			Range x_range = Range (automatic, automatic);
			Range y_range = Range (automatic, automatic);
			Color _color = black;
			uint _text_size;
			Bounding_Box bounds;
			ZipView!(double, double) data;
		}
	}
unittest
	{/*...}*/
		import std.array;
		import std.math;
		import display_service;
		import scribe_tool;
		scope gfx = new Display (400,400);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [20]);

		auto x = ℕ!100.map!(i => 1.0*i).array;
		auto y = ℕ!100.map!(i => 1.0*i).array;

		x.map!(i => 0.04*i).copy (x);
		x.map!(x => exp(x)).copy (y);
	
		Plot (x, y)
			.title (`test`)
			.color (red)
			.x_axis (`x`, Plot.Range (0, 4))
			.y_axis (`exp (x)`)
			.text_size (20)
			.using (gfx, txt);
		//(); XXX plot (data) should go ahead and plot
		// TODO need a different method for constructing placeholders
		// TODO probably a general struct (!(alias action)?) that combines a "struct Options" and a "T[] function() stream" so we can "action (stream()).using (options);"

		gfx.render;

		import std.datetime: seconds;
		core.thread.Thread.sleep (1.seconds);
	}
