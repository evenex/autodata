module gui.infobox;

import std.algorithm;
import std.range;
import std.variant;

import resource.view;
import resource.allocator;
import resource.directory;

import tools.scribe;
import tools.plot;

import utils;
import color;
import math;
import meta;

struct InfoBox
	{/*...}*/
		Box bounds;
		struct Element 
			{/*...}*/
				public:
				Box bounds;
				public {/*...}*/
					ref auto align_to (Alignment alignment)
						{/*...}*/
							this.alignment = alignment;
							return this;
						}
					ref auto decorate (void delegate(Box) decoration)
						{/*...}*/
							this.decoration = decoration;
							return this;
						}
				}
				private:
				mixin TypeUniqueId;
				private {/*data}*/
					union {/*...}*/
						Text text; 
						Plot plot; 
						Table table;
					}
					auto type = Type.none;
					enum Type {none, text, plot, table}

					void delegate(Box) decoration;
					Alignment alignment;
				}
				private {/*☀}*/
					this (T1, T2)(lazy T1 element, lazy T2 bounds)
						if (is_geometric!T2)
						{/*...}*/
							static if (is (T1 == Text))
								{/*...}*/
									this.text = element;
									type = Type.text;
								}
							else static if (is (T1 == Plot))
								{/*...}*/
									this.plot = element;
									type = Type.plot;
								}
							else static if (is (T1 == Table))
								{/*...}*/
									this.table = element;
									type = Type.table;
								}
							else static assert (0);

							this.bounds = bounds.bounding_box;
						}
				}
			}
		public:
		public {/*interface}*/
			ref auto decorate (void delegate(Box) decoration)
				{/*...}*/
					this.decoration = decoration;
					return this;
				}
			ref auto add (T1, T2)(T1 element, T2 bounds)
				if (is_geometric!T2)
				{/*...}*/
					auto id = Element.Id.create;

					elements.append (id, Element (element, bounds));

					return elements.back[1];
				}
			void remove (Element.Id id)
				{/*...}*/
					elements.remove (id);
				}
			void reset ()
				{/*...}*/
					elements.clear;
				}
			void draw ()
				{/*...}*/
					if (this.decoration !is null)
						this.decoration (bounds);

					foreach (ref element; elements)
						{/*...}*/
							const auto aligned ()
								{/*...}*/
									auto normalized = element.bounds
										.map!(v => v * bounds.dimensions);

									auto δ = normalized.bounding_box.offset_to (element.alignment, bounds);

									return normalized.map!(v => v + δ);
								}

							if (element.decoration !is null)
								element.decoration (aligned.bounding_box);

							auto draw_box = aligned.bounding_box;
							
							with (Element.Type) final switch (element.type)
								{/*...}*/
									case text:
										 element.text.inside (draw_box)();
										 break;
									case plot: 
										 element.plot.inside (draw_box)();
										 break;
									case table: 
										break; // TODO
									case none:
								}
						}
				}
		}
		public {/*☀}*/
			this (T)(T bounds)
				if (is_geometric!T)
				{/*...}*/
					this.bounds = bounds.bounding_box;
					this.elements = Directory!(Element, Element.Id)(8);
				}
		}
		private:
		private {/*data}*/
			Directory!(Element, Element.Id) elements;
			void delegate(Box) decoration;

			static immutable margin = 0.01;
		}
	}

unittest
	{/*...}*/
		import std.math;
		import services.display;

		mixin(report_test!`infobox`);

		scope gfx = new Display (600, 600);
		gfx.start; scope (exit) gfx.stop;
		scope txt = new Scribe (gfx, [12, 10, 8]);

		auto info = InfoBox (square (0.5));
		info.decorate ((Box bounds){gfx.draw (white.alpha (0.5), bounds.scale (1.05));});

		info.add (
			txt.write (`time is like a bullet from behind`)
				.color ((yellow * white).alpha (0.8))
				.align_to (Alignment.top_left), 
			square (0.5).map!(v => v*vec(0.8,1))
		)	.align_to (Alignment.top_left)
			.decorate ((Box bounds){gfx.draw (yellow.alpha (0.5), bounds);});
		
		static double X (ulong i) {return 1.0*i;}
		static double Y (ulong i) {return sin ((i*0.8)^^2);}
		info.add (
			Plot ((&X).view (0,24), (&Y).view (0,24))
				.title (`testing`)
				.y_axis (`output`, Plot.Range (-1, 1))
				.x_axis (`input`)
				.text_size (8)
				.color (blue * white)
				.using (gfx, txt),
			square (0.5).map!(v => v*vec(1.2,1))
		)	.align_to (Alignment.top_right)
			.decorate ((Box bounds){gfx.draw (blue.alpha (0.5), bounds);});

		info.add (
			txt.write (`as the water grinds the stone,`
				` we rise and fall. as our ashes turn to dust,`
				` we shine like stars.`
			) 	.color (purple * white)
				.size (10)
				.align_to (Alignment.center),
			square (0.5).map!(v => v * vec(2,1))
		)	.align_to (Alignment.bottom_center)
			.decorate ((Box bounds){gfx.draw (purple.alpha (0.5), bounds);});

		info.draw;
		gfx.render;

		import std.datetime: seconds;
		core.thread.Thread.sleep (1.seconds);
	}
