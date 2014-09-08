module evx.camera;

import std.traits;
import std.algorithm;

import evx.collision;
import evx.display;
import evx.display: GLenum;

import evx.utils;
import evx.math;
import evx.meta;
import evx.future;
import evx.arrays;

private import evx.service;

alias map = evx.functional.map;

public {/*mappings}*/
	vec to_view_space (Cam)(Position from_world_space, Cam camera)
		{/*...}*/
			auto v = from_world_space.dimensionless;
			auto c = camera.world_center.dimensionless;
			auto s = camera.world_scale;

			return (v-c)/s;
		}
	auto to_view_space (R, Cam)(R from_world_space, Cam camera)
		if (is_geometric!R)
		{/*...}*/
			return from_world_space.map!(v => v.to_view_space (camera));
		}

	Position to_world_space (Cam)(vec from_view_space, Cam camera)
		{/*...}*/
			auto v = from_view_space;
			auto c = camera.world_center;
			auto s = camera.world_scale[].map!meters.Position;

			return v*s+c;
		}
	auto to_world_space (R, Cam)(R from_view_space, Cam camera)
		if (is_geometric!R)
		{/*...}*/
			return from_view_space.map!(v => v.to_world_space (camera));
		}
}

class Camera (Capture)
	{/*...}*/
		alias World = CollisionDynamics!Capture;

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
					world_scale /= z;
				}
			auto capture ()
				in {/*...}*/
					assert (world !is null);
				}
				body {/*...}*/
					Future!(Appendable!(Capture[2^^10])) capture;

					world.box_query (view_bounds, capture);
					
					world.expedite_queries; // TEMP
					capture.await; // TEMP

					if (program) foreach (x; capture)
						program (x);
					return capture.stream;
				}
		}
		public {/*ctor}*/
			this (World world, Display display)
				{/*...}*/
					this.world = world;
					this.display = display;
					this.program = program;

					this.world_scale = display.dimensions;
				}
			this () {assert (0, `must initialize camera with collision and display`);} // OUTSIDE BUG @disable this() => linker error
		}
		private:
		private {/*program}*/
			void delegate(Capture) program;
		}
		private {/*properties}*/
			Position world_center = 0.meter.Position;
			vec world_scale = 1.vec;

			Position[2] view_bounds ()
				{/*...}*/
					alias c = world_center;
					immutable s = world_scale[].map!(α => α.meters).Position;

					return [c+s, c-s];
				}
		}
		private {/*services}*/
			World world;
			Display display;
		}
	}

unittest
	{/*...}*/
		alias Id = CollisionDynamics!().Id;
		auto world = new CollisionDynamics!();
		auto display = new Display;

		world.start; scope (exit) world.stop;
		display.start; scope (exit) display.stop;

		auto cam = new Camera!Id (world, display);

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
		world.update;

		auto x = world.get_body (handle);

		frame = cam.capture;
		assert (frame.length == 1);
		assert (frame[0] == handle);

		cam.zoom (1000);
		frame = cam.capture;
		assert (frame.length == 0);
	}
