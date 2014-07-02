module gui.infobox;

import std.algorithm;
import std.range;
import std.variant;

import resource.view;

import tools.scribe;
import tools.plot;

import utils;
import math;

struct InfoBox
	{/*...}*/
		BoundingBox bounds;
		struct Element 
			{/*...}*/
				public:
				BoundingBox bounds;
				public {/*...}*/
					ref auto align_to (Alignment alignment)
						{/*...}*/
							this.alignment = alignment;
							return this;
						}
					ref auto decorate (void delegate(BoundingBox) decoration)
						{/*...}*/
							this.decoration = decoration;
							return this;
						}
				}
				private:
				private {/*data}*/
					Algebraic!(Text, Plot, Table) payload;
					void delegate(BoundingBox) decoration;
					Alignment alignment;
				}
				private {/*☀}*/
					this (T1, T2)(T1 element, T2 bounds)
						if (is_geometric!T2)
						{/*...}*/
							this.payload = element;
							this.bounds = bounds.bounding_box;
						}
				}
				mixin Database;
			}
		public:
		public {/*interface}*/
			InfoBox decorate (void delegate(BoundingBox) decoration)
				{/*...}*/
					this.decoration = decoration;
					return this;
				}
			auto add (T1, T2)(T1 element, T2 bounds)
				if (is_geometric!T2)
				{/*...}*/
					auto id = Element.Id.create;
					Element[id] = Element (element, bounds);
					elements ~= Element.Proxy (id);
					return elements.back;
				}
			void remove (Element.Proxy element)
				{/*...}*/
					Element.remove (element);
					elements.remove (elements.countUntil (element));
				}
			void reset ()
				{/*...}*/
					foreach (element; elements)
						Element.remove (element);
					elements.clear;
				}
			void draw ()
				{/*...}*/
					if (this.decoration !is null)
						this.decoration (bounds);

					foreach (element; elements)
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

							element.payload.visit!(
								(ref Text text) {text.inside (draw_box)();},
								(ref Plot plot) {plot.inside (draw_box)();},
								(ref Table table) {/*TODO*/}
							);
						}
				}
		}
		public {/*☀}*/
			this (T)(T bounds)
				if (is_geometric!T)
				{/*...}*/
					this.bounds = bounds.bounding_box;
				}
		}
		private:
		private {/*data}*/
			Element.Proxy[] elements;
			void delegate(BoundingBox) decoration;
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

		auto info = InfoBox (square (0.5))
			.decorate ((BoundingBox bounds){gfx.draw (white.alpha (0.5), bounds.scale (1.05));});

		info.add (
			txt.write (`time is like a bullet from behind`)
				.color ((yellow * white).alpha (0.8))
				.align_to (Alignment.top_left), 
			square (0.5).map!(v => v*vec(0.8,1))
		)	.align_to (Alignment.top_left)
			.decorate ((BoundingBox bounds){gfx.draw (yellow.alpha (0.5), bounds);});
		
		static auto X (ulong i) {return 1.0*i;}
		static auto Y (ulong i) {return cast(double)sin ((i*0.8)^^2);} // BUG do some kind of auto type conversion in IdentityView
		info.add (
			Plot ((&X).view (0,24), (&Y).view (0,24))
				.title (`testing`)
				.y_axis (`output`, Plot.Range (-1, 1))
				.x_axis (`input`)
				.text_size (8)
				.color (blue * white)
				.using (gfx, txt),
			square (0.5).map!(v => v*vec(1.2,1))
		)	.align_to (Alignment.top_right) // BUG don't think this is aligning right either
			.decorate ((BoundingBox bounds){gfx.draw (blue.alpha (0.5), bounds);});

		info.add (
			txt.write (`as the water grinds the stone,`
				` we rise and fall. as our ashes turn to dust,`
				` we shine like stars.`
			) 	.color (purple * white)
				.size (10)
				.align_to (Alignment.center), // BUG totally not aligning correctly
			square (0.5).map!(v => v * vec(2,1))
		)	.align_to (Alignment.bottom_center)
			.decorate ((BoundingBox bounds){gfx.draw (purple.alpha (0.5), bounds);});

		info.draw;
		gfx.render;

		import std.datetime: seconds;
		core.thread.Thread.sleep (1.seconds);
	}
