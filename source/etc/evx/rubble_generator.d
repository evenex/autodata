module rubble_generator;

private {/*import}*/
	private {/*std}*/
		import std.range;
		import std.random;
		import std.typecons;
	}
	private {/*evx}*/
		import evx.meta;
		import evx.move;
		import evx.arrays;
		import evx.spatial;
		import evx.math;
		import evx.utils;
		import evx.display;
		import evx.colors;
		import evx.camera;
		import evx.input;
		import evx.lsystem;
	}
	import libtriangle;

	mixin(MathToolkit!());
	alias m = meters;
}

auto rubble (double size)
	{/*...}*/
		enum Dir {horizontal, vertical}
		align (1)
		struct Room
			{/*...}*/
				BoundingBox walls;

				this (Args...)(Args args)
					{/*...}*/
						walls = args.bounding_box;
					}

				auto divide (Dir dir)
					{/*...}*/
						double dice;

						with (Dir) final switch (dir)
							{/*...}*/
								case horizontal:
									dice = walls.width/2;

									auto left = walls;
									auto right = walls;

									left.right = left.right - dice;
									right.left = right.left + dice;

									return τ(Room (left), Room (right));
								case vertical:
									dice = walls.height/2;
									auto upper = walls;
									auto lower = walls;

									lower.top = lower.top - dice;
									upper.bottom = upper.bottom + dice;

									return τ(Room (lower), Room (upper));
							}
					}
			}

		auto building = Appendable!(Array!Room, Overflow.blocked)(100);
		building ~= Room ([vec(-size,-size),vec(size,size)]);

		Dir direction;
		int room_target = 100;
		int max_iterations = 1000;
		while (building.length < room_target && max_iterations--)
			{/*...}*/
				enum min = 0.1;
				enum div_probability = 0.5;

				foreach (ref room; building[])
					if (room.walls.dimensions[].zip (min.vec[]).filter!((a,b) => a < b).empty && uniform (0.0, 1.0) < div_probability)
						{/*...}*/
							auto divided = room.divide (direction);

							room = divided[0];
							building ~= divided[1];
						}

				with (Dir) direction = direction == horizontal? vertical: horizontal;
			}

		enum remove_chance = 0.95;
		Appendable!(size_t[100]) to_remove;
		foreach (i, room; building)
			if (uniform (0.0, 1.0) < remove_chance)
				to_remove ~= i;

		foreach (i, j; to_remove)
			building.shift_down_on (j - i);

		return *(cast(Appendable!(Array!BoundingBox, Overflow.blocked)*)&building);
	}

void main ()
	{/*...}*/
		display_loop!((Display gfx, Input usr, Scribe txt)
			{/*...}*/
				
			}
		);
	}
