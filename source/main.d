import std.stdio;
import std.range;

import math;
import utils;
import memory.view;

public {/*world}*/
	struct World
		{/*...}*/
			import std.datetime;
			struct Clock
				{/*...}*/
					union {
						struct {
							uint hour, minute, second;
						}
						uint[3] indexed;
					}
					alias indexed this;
				}
			Clock clock;
		}
	static World world;
	void time_is (uint hour, uint minute, uint second = 0)
		in {/*...}*/
			assert (hour == hour % 24);
			assert (minute == minute % 60);
			assert (second == second % 60);
		}
		body {/*...}*/
			world.clock.hour = hour;
			world.clock.minute = minute;
			world.clock.second = second;
		}
	auto current_time ()
		{/*...}*/
			return world.clock;
		}
}
public {/*floor}*/
	struct Floor
		{/*...}*/
			View!vec _area = [];
			Material _material;

			/*
				physical aspect - 0 elevation, 0 height,
				collides for the sake of the camera capture
				and for footsteps and friction
				so to find the effect on your traction you would say
				"hey what floor am i standing on?"
				and then get the material properties from that floor
				to determine traction effects

				visual aspect - tile its texture over its area
					so set tex coords scaling with the actual area
					instead of with the texture
				unless we want to tile
					one unit for each tile in the strip
					like for a sidewalk
			*/

			auto material (Material m)
				{/*...}*/
					_material = m;

					return this;
				}
		}
	auto floor (R)(R geometry)
		if (is_geometric!R)
		{/*...}*/
			auto TEMP = geometry.array;
			Floor f;
			f._area = TEMP.view;

			return f;
		}
	auto floor_strip (R)(R geometry)
		if (is_geometric!R)
		{/*...}*/
			auto TEMP = geometry.array;
			Floor f;
			f._area = TEMP.view;

			return f;
		}
}

struct Entity 
	{/*...}*/
		mixin TypeUniqueId; 
		Id id;
	}

struct Material
	{/*...}*/
		enum {/*...}*/
			 concrete = Material (0),
			 pavement = Material (1)
		}
		uint data;
	}

struct Visual
	{/*...}*/
		int tex_id = 0;
		@property texture (string texstr)
			{/*...}*/
				return this;
			}
	}
auto visual (T)(T entity)
	{/*...}*/
		return Visual ();
	}

void umain ()
	{/*...}*/
		time_is (23,59);
		// STATIC ENVIRONMENT
		auto yard = floor (only (0.vec, vec(-100, 0), vec(-100, 500), vec(0, 500)))
			.material (Material.concrete);
		auto driveway = floor (only (vec(20, 0), vec(-100, 0), vec(-100, -10), vec(20, -10)))
			.material (Material.pavement);
		auto parking_lot = floor (only (vec (-100, -10), vec(-100, -60), vec(10, -60), vec(10, -10)))
			.material (Material.pavement);
		auto sidewalk = floor_strip (only (vec(0,0)))
			.material (Material.concrete) // material should be static global returning Material??
			.visual.texture (`sidewalk.tga`); // .visual converts the sidewalk from Material to Visual via Id
	/*
		auto bay = water ([XXX])
			.depth (20.meters)
			.elevation (-2.meters)
			.state (choppy)
			.type (salt);
		auto railing = wall ([XXX])
			.type (steel_railing); // steel railing implies height (0.5)
		auto lamps = group (ℕ(8).map!(i => sodium_lamp.position (i)));
			lamps.on;
		auto containers = group (ℕ(4).map (i => cargo_container.position (i))); // automatically gives me some drab random cargo container color unless i ask for something specific
		// GATE
		auto fence = wall ([XXX])
			.type (fence)
			.height (3.meters);
		auto gate = wall ([XXX])
			.type (fence)
			.height (3.meters);
		auto gate_motor = linear_motor
			.range (x0, x1)
			.drive (electric, chain)
			.speed (XXX)
			.position (XXX)
			.rotation (XXX); // some keywords could just be preset packagesXXX. like .preset (crappy_electric_motor) loads speed and such
		auto gate_assembly = group (fence, gate, gate_motor);
		// CAR
		auto car = car
			.type (sedan)
			.position (XXX);
			car.engine.on;
			car.lights.on;
		// WAREHOUSE
		auto warehouse = building
			.dimensions ([XXX])
			.walls (aluminum_siding)
			.roof (roof.sloped.material (tin));
		auto warehouse_door = door
			.material (composite)
			.handle (lever)
			.opens (outward)
			.through (warehouse.south_wall)
			.relative_position (-0.8)
			.locked (lock.type (mechanical).quality (low));
		warehouse.interior
			.floor (concrete)
			.lighting (overhead_lights (flourescent)) // assumes walls of exterior since unspecified
			.contains (
				ℕ!20.map!(i => vec(i/something,i%other))
					.map!(v => pallete.position (v).containing (
						generate (cardboard_box).sizes (XXX).rotations (XXX).density (XXX)
					)),
				forklift.position (XXX),
				ℕ!3.map!(i => vec(XXX)).map (v => fuel_barrel.position (v))
			)
			.room (
				room.walls (composite)
					.dimensions (XXX)
					.door (west_wall (XXX), 
						door.opens (inward)
						.material (composite)
						.lock (lock.type (keypad).quality (medium))
					)
					.contains (
						desk.position (XXX)
							.contains (
								computer.model (XXX)
							)
					)
					.window (window
						.position (south_wall (XXX))
						.type (vertical_slide)
					)
			);
		warehouse.interior.room[1].get!`desk`.get!`computer`.on;
		// DUDES
		auto goons = group (
			person.gender (male).height (τ(1.5*meters, 1.8*meters)) // probabilistically selects from the range
				.clothing (generate!clothing (c => c.style == generic && c.color.brightness < x))
		);
			foreach (ref goon; goons[0..2])
				goon.inventory = group (
					pistol_10mm,
					generate (5, 20).usd
				);
			goons[2].inventory.set (
				smg_10mm,
				key (warehouse_door),
				kevlar_armor, // the agent should automatically choose to equip this because it expects danger (alert_level == ready)
				generate (50, 400).usd
			);
			foreach (i, ref goon; goons)
				{
					goon.add_goal (patrol ([XXX]), prority (1));
					goon.add_goal (guard (warehouse_door), prority (2));
					goon.add_goal (maintain (
						only(0..3).filter!(j => j != i)
							.map!(j => distance_to (goons[j]))
							.mean < minimal_distance
					), priority (3));
					goon.alert_level (ready);
				}
		*/
	}	
