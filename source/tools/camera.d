module tools.camera;

import std.traits;
import std.algorithm;

import services.collision;
import services.display;
import services.display: GLenum;

import utils;
import math;
import meta;
import future;

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

class Camera (Capture)
	{/*...}*/
		alias World = CollisionDynamics!Capture;
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
					Future!(Dynamic!(Capture[2^^10])) capture;
					world.box_query (view_bounds, capture);
					capture.await;

					if (program) foreach (x; capture)
						program (x);
					return capture;
				}
		}
		public {/*☀}*/
			this (World world, Display display)
				{/*...}*/
					this.world = world;
					this.display = display;
					this.program = program;
					this.world_scale = cast(vec)(display.dimensions);
				}
			this () {assert (0, `must initialize camera with collision and display`);} // OUTSIDE BUG @disable this() => linker error
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
			World world;
			Display display;
		}
	}

unittest
	{/*...}*/
		mixin(report_test!"camera");

		auto world = new CollisionDynamics;
		auto display = new Display;
		alias Body = CollisionDynamics.Body;
		world.start; scope (exit) world.stop;
		display.start; scope (exit) display.stop;
		auto cam = new Camera (world, display);

		auto frame = cam.capture;
		assert (frame.length == 0);

		auto triangle = [vec(0), vec(1), vec(1,0)];

		auto x = world.add (CollisionDynamics.Body (vec(0)), triangle.map!(v => v - triangle.mean));
		world.update;

		frame = cam.capture;
		assert (frame.length == 1);
		assert (frame[0] == x.id);

		x.position = vec(100,100);
		cam.zoom (1000);
		frame = cam.capture;
		assert (frame.length == 0);
	}
