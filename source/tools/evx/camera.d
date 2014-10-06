module evx.camera;

import std.traits;
import std.algorithm;

import evx.spatial;
import evx.display;
import evx.display: GLenum;

import evx.utils;
import evx.math;
import evx.meta;
import evx.future;
import evx.arrays;

private import evx.service;

mixin(FunctionalToolkit!());

public {/*mappings}*/
	Display.Coords to_view_space (Position from_world_space, Camera camera) // BUG the problem is that vec can't interop with display coords right now
		{/*...}*/
			auto v = from_world_space.dimensionless;
			auto c = camera.world_center.dimensionless;
			auto s = camera.world_scale;

			return Display.Coords ((v-c)/s, Display.Space.draw);
		}
	auto to_view_space (R)(R from_world_space, Camera camera)
		if (is_geometric!R)
		{/*...}*/
			return from_world_space.map!(v => v.to_view_space (camera));
		}

	Position to_world_space (V)(V from_view_space, Camera camera)
		{/*...}*/
			auto v = from_view_space;
			auto c = camera.world_center;
			auto s = camera.world_scale[].map!meters.Position;

			return v*s+c;
		}
	auto to_world_space (R)(R from_view_space, Camera camera)
		if (is_geometric!R)
		{/*...}*/
			return from_view_space.map!(v => v.to_world_space (camera));
		}
}

final class Camera
	{/*...}*/
		alias Capture = SpatialId;

		alias World = SpatialDynamics;

		public {/*controls}*/
			void set_program (void delegate(Capture) program)
				{/*...}*/
					this.program = program;
				}
			void center_at (Position pos)
				{/*...}*/
					world_center = pos;
				}
			void pan (Displacement δ)
				{/*...}*/
					world_center += δ;
				}
			void zoom (float z)
				in {/*...}*/
					assert (z >= 0, `attempted negative zoom`);
				}
				body {/*...}*/
					_zoom_factor *= z;
				}
			auto capture ()
				in {/*...}*/
					assert (world !is null, `world has not been instantiated`);
				}
				body {/*...}*/
					auto capture = Appendable!(Capture[])(256);

					world.box_query (view_bounds, capture);

					if (program) foreach (x; capture)
						program (x);
					return capture;
				}
		}
		@property {/*}*/
			auto zoom_factor ()
				{/*...}*/
					return _zoom_factor;
				}
		}
		public {/*ctor}*/
			this (World world, Display display)
				{/*...}*/
					this.world = world;
					this.display = display;
					this.program = program;
				}
			this () {assert (0, `must initialize camera with spatial and display`);} // OUTSIDE BUG @disable this() => linker error
		}
		private:
		private {/*program}*/
			void delegate(Capture) program;
		}
		private {/*properties}*/
			double _zoom_factor = 1.0;
			Position world_center = zero!Position;
			vec world_scale ()
				{/*...}*/
					return display.dimensions / _zoom_factor;
				}
			vec _world_scale = unity!vec;

			Position[2] view_bounds ()
				{/*...}*/
					alias c = world_center;
					immutable s = world_scale[].map!meters.Position;

					return [c+s, c-s];
				}
		}
		private {/*services}*/
			World world;
			Display display;
		}
	}

static if (0) // TODO broken unittest
unittest
	{/*...}*/
		alias Id = SpatialDynamics!().Id;
		auto world = new SpatialDynamics!();
		auto display = new Display;

		world.start; scope (exit) world.stop;
		display.start; scope (exit) display.stop;

		auto cam = new Camera (world, display);

		auto frame = cam.capture;
		assert (frame.length == 0);

		auto triangle = [vec(0), vec(1), vec(1,0)]
			.map!(v => Position (v.x.meters, v.y.meters));

		auto handle = Id (0);

		with (world) add (new_body (handle)
			.position (100.meters.vector!2)
			.mass (1.kilogram)
			.shape (triangle.map!(v => v - triangle.mean))
		);
		world.expedite_uploads;

		auto x = world.get_body (handle);

		frame = cam.capture;
		assert (frame.length == 1);
		assert (frame[0] == handle);

		cam.zoom (1000);
		frame = cam.capture;
		assert (frame.length == 0);
	}
