module evx.loops;

public {/*imports}*/
	import evx.display;
	import evx.scribe;
	import evx.input;
	import evx.math;
}

void display_loop (alias loop)(Hertz framerate = 30.hertz)
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

				loop (gfx, usr, txt);

				gfx.render;
				usr.process;

				auto remaining = (1/framerate).to_duration - (Clock.currTime - time);
				Thread.sleep (remaining);
			}
	}
