module evx.plot;

private {/*imports}*/
	private {/*std}*/
		import std.traits;
		import std.typecons;
		import std.algorithm;
		import std.range;
		import std.string;
		import std.conv;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.colors;
		import evx.math;
		import evx.display;
		import evx.scribe;
	}

	mixin(FunctionalToolkit!());
}

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
		@property {/*}*/
			auto draw_box ()
				{/*...}*/
					
				}
		}
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

			alias x_units = unit_options!`x`;
			alias y_units = unit_options!`y`;
		}
		public {/*drawing}*/
			void draw ()
				in {/*...}*/
					assert (display !is null);
					assert (scribe !is null);
					assert (display.is_running);
				}
				body {/*...}*/
					if (data.empty) return;

					auto y_data = data.map!((y,x) => y);
					auto x_data = data.map!((y,x) => x);

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

					{/*set unit string}*/
						if (_x_units.empty)
							{/*...}*/
								_x_units = x_max.text.find (` `);

								if (not (_x_units.empty))
									_x_units = `(` ~_x_units[1..$]~ `)`;
							}
						else _x_units = `(` ~_x_units~ `)`;

						if (_y_units.empty)
							{/*...}*/
								_y_units = y_max.text.find (` `);

								if (not (_y_units.empty))
									_y_units = `(` ~_y_units[1..$]~ `)`;
							}
						else _y_units = `(` ~_y_units~ `)`;
					}

					void draw_data ()
						{/*...}*/
							void draw_zero_line ()
								{/*...}*/
									auto zero_y = (1 - y_max/(y_max-y_min)) * plot_field.height + plot_field.bottom;

									display.draw (_color (0.2), [vec(plot_field.left, zero_y), vec(plot_field.right, zero_y)]);
								}
							void draw_border ()
								{/*...}*/
									display.draw (_color.alpha (0.25), plot_field[]);
								}
							void draw_signal ()
								{/*...}*/
									display.draw (_color, 
										data.map!((y,x) => vec(x.to!double, y.to!double))
											.map!(v => v - vec(x_min.to!double, y_min.to!double))
											.map!(v => v / vec((x_max-x_min).to!double, (y_max-y_min).to!double))
											.map!(v => v * vec(plot_field.width, plot_field.height))
											.map!(v => v + plot_field.low_left),
										GeometryMode.l_strip
									);
								}

							draw_zero_line;
							draw_border;
							draw_signal;
						}

					static if (style is Style.standard)
						{/*...}*/
							auto x_ticks = x_field[].translate (vec(0, h_0)).bounding_box;
							auto y_ticks = y_field[].translate (vec(h_0, 0)).bounding_box;

							scribe.write (_title)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_center)
								.inside (title_field)
							();
							scribe.write (x_label~ ` ` ~_x_units)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_center)
								.inside (x_field)
							();
							scribe.write (x_min.to!double)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_left)
								.inside (x_ticks)
							();
							scribe.write (x_max.to!double)
								.size (_text_size)
								.color (_color)
								.align_to (Alignment.top_right)
								.inside (x_ticks)
							();
							scribe.write (y_label~ ` ` ~_y_units)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.center_right)
								.wrap_width (y_field.height)
								.inside (y_field)
							();
							scribe.write (y_min.to!double)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.bottom_right)
								.wrap_width (y_field.height)
								.inside (y_ticks)
							();
							scribe.write (y_max.to!double)
								.size (_text_size)
								.color (_color)
								.rotate (π/2)
								.align_to (Alignment.top_right)
								.wrap_width (y_field.height)
								.inside (y_ticks)
							();

							draw_data;
						}
					else static if (style is Style.minimal)
						{/*...}*/
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

							draw_data;
						}
				}
			
			alias opCall = draw;
		}
		public {/*fields}*/
			auto title_field ()
				{/*...}*/
					auto field = bounds;
					
					with (field) {/*...}*/
						static if (style is Style.standard)
							{/*...}*/
								left = left + 2*h_0;
								bottom = bottom + h_1 + ε;
							}
						else static if (style is Style.minimal)
							{/*...}*/
								bottom = bottom + h_1 + ε;
							}
					}

					return field;
				}

			auto y_field ()
				{/*...}*/
					auto field = bounds;

					with (field) {/*...}*/
						static if (style is Style.standard)
							{/*...}*/
								top 	= top 	 - h_0;
								bottom 	= bottom + 2*h_0;
								right 	= right	 - w_1 - ε;
								left 	= left	 + ε;
							}
						else static if (style is Style.minimal)
							{/*...}*/
								top 	= top 	 - h_0;
								bottom 	= bottom + h_0;
								right 	= right	 - w_1 - ε;
							}
					}

					return field;
				}

			auto x_field ()
				{/*...}*/
					auto field = bounds;

					with (field) {/*...}*/
						static if (style is Style.standard)
							{/*...}*/
								left	= left	 + 2*h_0;
								top		= top 	 - h_1 - ε;
								right	= right	 - 2*ε;
							}
						else static if (style is Style.minimal)
							{/*...}*/
								left	= left	+ h_0;
								top		= top 	- h_1;
								right	= right	- 2*ε;
							}
					}

					return field;
				}

			auto plot_field ()
				{/*...}*/
					auto field = bounds;

					with (field) {/*...}*/
						static if (style is Style.standard)
							{/*...}*/
								left   = left   + 2*h_0;
								right  = right  - 2*ε;
								top	   = top	- h_0;
								bottom = bottom + 2*h_0;
							}
						else static if (style is Style.minimal)
							{/*...}*/
								left   = left   + h_0;
								right  = right  - 2*ε;
								top    = top 	- h_0;
								bottom = bottom + h_0;
							}
					}

					return field;
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
			string _x_units;
			XRange x_range = interval (-infinite!XType, infinite!XType);

			string y_label;
			string _y_units;
			YRange y_range = interval (-infinite!YType, infinite!YType);

			Color _color = black;
			size_t _text_size;

			auto bounds = bounding_box ([-1.vec, 1.vec]);
		}
		private {/*measurements}*/
			auto h_0 ()
				in {/*...}*/
					assert (scribe !is null,
						`operation requires valid ` ~typeof(scribe).stringof
					);
				}
				body {/*...}*/
					return 2.5 * scribe.font_height (_text_size);
				}
			auto h_1 ()
				{/*...}*/
					return bounds.height - h_0;
				}
			auto w_1 ()
				{/*...}*/
					return bounds.width - h_0;
				}
			auto ε ()
				{/*...}*/
					return 0.1*h_0;
				}
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

			template unit_options (string axis)
				{/*...}*/
					static code ()
						{/*...}*/
							return q{
								auto unit_options (String)(String label)
									}`{`q{
										this._} ~axis~ q{_units = label.text;

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

		scope gfx = new Display (600,400);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [20]);

		plot (
			ℕ[1..100].map!(x => exp (0.1 * x))
			.versus (
				ℕ[1..100].map!(x => 0.1 * x)
			)
		)	.y_axis (`exp (x)`)
			.x_axis (`x`)
			.color (red).text_size (20).using (gfx, txt)
		();

		gfx.render;

		import std.datetime: msecs;
		core.thread.Thread.sleep (10000.msecs);
	}
	unittest {/*units}*/
		import std.math;
		import evx.units;

		scope gfx = new Display (400,400);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [14]);

		plot (
			ℕ[1..100].map!(x => (x^^2).joules - 10.joules)
			.versus (
				ℕ[1..100].map!(x => x.meters/second)
			)
		)	.title (`energy vs speed`)
			.x_axis (`speed`)
			.y_axis (`energy`).y_units (`J`)
			.inside ([vec(-1,-1), vec(1,1)].scale (0.5).bounding_box)
			.color (white).text_size (14).using (gfx, txt)
		();

		gfx.render;

		import std.datetime: msecs;
		core.thread.Thread.sleep (1000.msecs);
	}
