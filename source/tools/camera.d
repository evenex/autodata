module tools.camera;

import std.traits;
import std.algorithm;
import services.physics;
import services.display;
import services.display: GLenum;
import utils;
import math;

private import services.service;

public {/*mappings}*/
	vec to_view_space (Cam)(vec from_world_space, Cam camera) pure
		{/*...}*/
			auto v = from_world_space;
			auto c = camera.world_center; 
			auto s = camera.world_scale;
			return (v-c)/s;
		}
	auto to_view_space (T, Cam)(T from_world_space, Cam camera)
		if (is_geometric!T)
		{/*...}*/
			return from_world_space.map!(v => v.to_view_space (camera));
		}
	vec to_world_space (Cam)(vec from_view_space, Cam camera) pure
		{/*...}*/
			auto v = from_view_space;
			auto c = camera.world_center;
			auto s = camera.world_scale;
			return v*s+c;
		}
	auto to_world_space (T, Cam)(T from_view_space, Cam camera)
		if (is_geometric!T)
		{/*...}*/
			return from_view_space.map!(v => v.to_world_space (camera));
		}
}

class Camera
	{/*...}*/
		alias Capture = Physics.UserId;
		public {/*controls}*/
			void set_program (void delegate(Capture) program)
				{/*...}*/
					this.program = program;
				}
			void center_at (vec pos)
				{/*...}*/
					world_center = pos;
				}
			void pan (vec δ)
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
					auto captured = world.box_query (view_bounds);
					if (program) foreach (x; captured)
						program (x);
					return captured;
				}
		}
		public {/*☀}*/
			this (Physics world, Display display)
				{/*...}*/
					this.world = world;
					this.display = display;
					this.program = program;
					this.world_scale = cast(vec)(display.dimensions);
				}
			this () {assert (0, `must initialize camera with physics and display`);} // OUTSIDE BUG @disable this() => linker error
		}
		private:
		private {/*program}*/
			void delegate(Capture) program;
		}
		private {/*properties}*/
			vec world_center = 0.vec;
			vec world_scale = 1.vec;
			vec[2] view_bounds ()
				{/*...}*/
					alias C = world_center;
					alias S = world_scale;
					return [C+S, C-S];
				}
		}
		private {/*services}*/
			Physics world;
			Display display;
		}
	}

unittest
	{/*...}*/
		mixin(report_test!"camera");

		auto world = new Physics;
		auto display = new Display;
		alias Body = Physics.Body;
		world.start; scope (exit) world.stop;
		display.start; scope (exit) display.stop;
		auto cam = new Camera (world, display);

		auto frame = cam.capture;
		assert (frame.length == 0);

		auto triangle = [vec(0), vec(1), vec(1,0)];

		auto x = world.add (Physics.Body (vec(0)), triangle.map!(v => v - triangle.mean));
		world.update;

		frame = cam.capture;
		assert (frame.length == 1);
		assert (frame[0] == x.id);

		x.position = vec(100,100);
		cam.zoom (1000);
		frame = cam.capture;
		assert (frame.length == 0);
	}
