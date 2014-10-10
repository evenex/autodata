module evx.loops;

public {/*imports}*/
	import evx.display;
	import evx.scribe;
	import evx.input;
	import evx.camera;
	import evx.spatial;
	import evx.math;
	import evx.utils;
}

enum Instrumentation {enabled, disabled}
void display_loop (alias loop, Instrumentation instrument = Instrumentation.disabled)(Hertz framerate = 30.hertz)
	{/*...}*/
		bool terminated;

		scope gfx = new Display;
		scope usr = new Input (gfx, (bool){terminated = true;});
		scope txt = new Scribe (gfx, [18, 36, 144]);

		static assert (__traits(compiles, loop (gfx, usr, txt)),
			`loop function must take arguments: (Display, Input, Scribe)`
		);

		while (not!terminated)
			{/*...}*/
				import std.datetime;
				import core.thread;

				auto time = Clock.currTime;

				// TODO instrumentation
				loop (gfx, usr, txt);

				gfx.render;
				usr.process;

				auto remaining = (1/framerate).to_duration - (Clock.currTime - time);
				if (remaining > 100.nsecs)
					Thread.sleep (remaining);
			}
	}

void physics_loop (alias loop, Instrumentation instrument = Instrumentation.disabled)(Hertz physics_framerate = 120.hertz)
	{/*...}*/
		auto render_framerate = physics_framerate/2;

		bool terminated;

		scope gfx = new Display;
		scope phy = new SpatialDynamics;
		scope usr = new Input (gfx, (bool){terminated = true;});
		scope txt = new Scribe (gfx, [18, 36, 144]);
		scope cam = new Camera (phy, gfx);

		cam.zoom (gfx.dimensions[].mean);

		static assert (__traits(compiles, loop (phy, cam, gfx, usr, txt)),
			`loop function must take arguments: (SpatialDynamics, Camera, Display, Input, Scribe)`
		);

		while (not!terminated)
			{/*...}*/
				import std.datetime;
				import core.thread;

				auto time = Clock.currTime;

				static if (instrument == Instrumentation.enabled)
					{/*...}*/
						auto timer = Clock.currTime;

						auto perf (string stage)
							{/*...}*/
								auto elapsed = Clock.currTime - timer;
								pl (stage, elapsed);

								timer = Clock.currTime;
							}
					}
				else auto perf (lazy string){}

				loop (phy, cam, gfx, usr, txt);
				perf (`loop`);

				usr.process;
				perf (`usr`);
				cam.capture;
				perf (`cam`);
				gfx.render;
				perf (`gfx`);
				phy.update;
				phy.update;
				perf (`phy`);

				auto remaining = (1/render_framerate).to_duration - (Clock.currTime - time);
				if (remaining > 100.nsecs)
					Thread.sleep (remaining);
			}
	}
