import std.stdio;
import std.range;
import std.conv;

import math;
import utils;
import color;
import meta;

import resource.view;
import resource.allocator;
import resource.directory;

import services.display;
import services.collision;

import tools.image;

/*
 As a matter of policy, all public methods at this level should deal exclusively in Views, not hard data. Either Fields or Looks are ok.
 In general it seems like it would be better to take Looks to Views instead of raw Views, because that way every fetch can yield an up-to-date view
 even if the data has been moved.
 so what about this supposed advantage of taking a view and having it be always up to date with the backing data?
 	this is only true if the data doesn't MOVE
	if it changes in-place then it will stay up to date
so Looks to Views keep the data up-to-date even if it moves
while having the View stay up-to-date even as its being changed, without paying the cost of a Look observation
so basically we pay the cost of the Look once per traversal, and pay the cost of the View for each element.
*/

public {/*entity}*/
	struct Entity 
		{/*...}*/
			public:
			public @property {/*}*/
				auto id ()
					{/*...}*/
						return _id;
					}
				auto name ()
					{/*...}*/
						return metadata[id].name;
					}
				mixin(is_member_become_member);
			}
			private:
			private {/*data}*/
				mixin TypeUniqueId; 
				Id _id;
			}
			private __gshared {/*metadata}*/
				struct Metadata
					{/*...}*/
						string name;
						Representation representation;
					}
				Metadata[Id] metadata;
			}
			private static {/*code generation}*/
				string is_member_become_member ()
					{/*...}*/
						import std.traits;
						string code;

						foreach (T; EnumMembers!Representation)
							static if (T.text != `none`)
								code ~= q{
									bool is_} ~T.text~ q{ () }`{`q{
										return metadata[id].representation & Representation.} ~T.text~ q{? true: false;
									}`}`q{
									void become_} ~T.text~ q{ () }`{`q{
										metadata[id].representation |= Representation.} ~T.text~ q{;
									}`}`q{
								};

						return code;
					}
			}
		}
	enum Representation
		{/*...}*/
			none		= 2^^0,
			visual 		= 2^^1,
			physical 	= 2^^2,
			material 	= 2^^3,
			floor	 	= 2^^4,
		}
}
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
public {/*services}*/
	Display display;
	CollisionDynamics!(Entity.Id) collision;
	shared static this ()
		{/*...}*/
			display = new typeof(display);
			collision = new typeof(collision);
		}
}
public {/*models/aspects}*/
	struct Visual
		{/*...}*/
			public {/*aspects}*/
				struct Object
					{/*...}*/
						public:
						public {/*ctor}*/
							this (T)(T entity)
								{/*...}*/
								}
						}
						public {/*command}*/
							auto geometry (View!vec verts)
								{/*...}*/
									_geometry = verts;
									return this;
								}
							auto texture (TextureId id, View!vec coords) // XXX instead manage zips and maps internally, because (0,4) will crash you with anything but quads
								in  {/*...}*/
									assert (_type & (Type.none | Type.texture));
								}
								body {/*...}*/
									_texture = Texture (id, coords);
									_type = Type.texture;
									return this;
								}
							auto color (Color color)
								in {/*...}*/
									assert (_type & (Type.none | Type.drawing));
								}
								body {/*...}*/
									_drawing.color = color;
									_type = Type.drawing;
									return this;
								}
							auto mode (GeometryMode mode)
								in  {/*...}*/
									assert (_type & (Type.none | Type.drawing));
								}
								body {/*...}*/
									_drawing.mode = mode;
									_type = Type.drawing;
									return this;
								}
						}
						public {/*properties}*/
							auto texture ()
								in {/*...}*/
									assert (_type & (Type.none | Type.texture));
								}
								body {/*...}*/
									return _texture;
								}
							auto drawing ()
								in {/*...}*/
									assert (_type & (Type.none | Type.drawing));
								}
								body {/*...}*/
									return _drawing;
								}
						}
						private:
						private {/*data}*/
							View!vec _geometry;
							union {/*...}*/
								Texture _texture;
								Drawing _drawing;
							}
							Type _type; enum Type {none = 0x1, drawing = 0x2, texture = 0x4}
						}
					}
			}
			public {/*substruct}*/
				struct Texture
					{/*...}*/
						TextureId id;
						View!vec coords;
					}
				struct Drawing
					{/*...}*/
						Color color;
						GeometryMode mode;
					}
			}
		__gshared:
			private {/*resources}*/
				Directory!(Object, Entity.Id) objects;
			}
			static {/*interface}*/
				auto update ()
					{/*...}*/
						foreach (ref object; objects)
							with (Object.Type) 
							final switch (object._type)
								{/*...}*/
									case drawing:
										display.draw (object._drawing.color, object._geometry, object._drawing.mode);
										break;
									case texture:
										display.draw (object._texture.id, object._geometry, object._texture.coords);
										break;
									case none:
										assert (0);
								}
					}
			}
			static {/*toolkit}*/
				auto full_texture (Index i)
					{/*...}*/
						return square.translate (0.5.vec)[i];
					}
			}
			shared static this ()
				{/*...}*/
					objects = Directory!(Object, Entity.Id)(66);
				}
		}
	auto visual (T)(T entity)
		if (__traits(compiles, entity.id == Entity.Id.init))
		{/*...}*/
			if (entity.id in Visual.objects)
				return Visual.objects.get (entity.id);
			else return Visual.objects.add (entity.id);
		}
	struct Physical
		{/*...}*/
			public {/*}*/ // @Aspect 
				struct Body
					{/*...}*/
						vec[] geometry;
						vec position;
						vec velocity;
						vec heading;
						double mass;
						double damping;
						double elevation;
						double height;
					}
			}
		__gshared:
			private {/*services}*/
				CollisionDynamics!(Entity.Id) collision;
			}
			private {/*resources}*/
				Directory!(Body, Entity.Id) bodies;
				Allocator!vec geometry;
			}
			static {/*toolkit}*/
			}
			shared static this ()
				{/*...}*/
					geometry = Allocator!vec ();
				}
		}
	auto physical (T)(T entity)
		if (__traits(compiles, entity.id == Entity.Id.init))
		{/*...}*/
			if (entity.id in Physical.bodies)
				return Physical.bodies.get (entity.id);
			else return Physical.bodies.add (entity.id);
		}
	class Material
		{/*...}*/
			struct Substance 
				{/*...}*/
					public {/*ctor}*/
						this (double a)
							{/*...}*/
								
							}
						this (T)(T entity, Material material)
							{/*...}*/
							}
					}
					float density;
					float strength;
				}
			static {/*toolkit}*/
			}
		}
	class Floor
		{/*...}*/
			struct Surface
				{/*...}*/
					View!vec _area = vec[].init;
					Material.Substance _material;

					/*
						physical aspect - 0 elevation, 0 height,
						collides for the sake of the camera capture
						and for footsteps and friction
						so to find the effect on your traction you would say
						"hey what floor am i standing on?"
						and then get the material properties from that floor
						to determine traction effects
					*/

					public {/*command}*/
						auto material (Material.Substance m)
							{/*...}*/
								_material = m;

								return this;
							}
					}
				}
			static {/*toolkit}*/
			}
		}
}
public {/*catalogs}*/
	enum materials
		{/*...}*/
			 concrete = Material.Substance (0),
			 pavement = Material.Substance (1)
		}
}
public {/*entity ctors}*/
	public {/*floor}*/
		auto floor (R)(R geometry)
			if (is_geometric!R)
			{/*...}*/
				auto TEMP = geometry.array;
				Floor.Surface f;
				f._area = TEMP.view;

				return f;
			}
		auto floor_strip (R)(R geometry)
			if (is_geometric!R)
			{/*...}*/
				auto TEMP = geometry.array;
				Floor.Surface f;
				f._area = TEMP.view;

				return f;
			}
	}
}
public {/*overloads for performing a strip-tidle uv-wrapping over a quad-strip}*/
	auto uv_strip_tile (R)(R geometry)
		if (is_geometric!R)
		in {/*...}*/
			assert (geometry.length % 2 == 0);
		}
		body {/*...}*/
			ℕ (geometry.length)
				.map!(uv_strip_tile!Index);
		}
	auto uv_strip_tile (View!vec geometry)
		{/*...}*/
			return (&identity).view (0, geometry.length).map_view (&uv_strip_tile!Index);
		}
	auto uv_strip_tile (T)(T i)
		if (is (T == Index))
		{/*...}*/
			return vec(i/2, i%2);
		}
}

unittest
	{/*...}*/
		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;
		///////////////////////////////////////
		auto concrete_texture = Image (`/home/vlad/tcr/art/concrete.tga`).upload_to (gfx);
		auto sidewalk_texture = Image (`/home/vlad/tcr/art/sidewalk.tga`).upload_to (gfx);
		auto asphalt_texture = Image (`/home/vlad/tcr/art/asphalt.tga`).upload_to (gfx);
		///////////////////////////////////////
		time_is (23,59);
		// STATIC ENVIRONMENT
		auto yard = floor (only (0.vec, vec(-100, 0), vec(-100, 500), vec(0, 500)))
			.material (materials.concrete);
		auto driveway = floor (only (vec(20, 0), vec(-100, 0), vec(-100, -10), vec(20, -10)))
			.material (materials.pavement);
		auto parking_lot = floor (only (vec (-100, -10), vec(-100, -60), vec(10, -60), vec(10, -10)))
			.material (materials.pavement);
		auto sidewalk = floor_strip (only (vec(0,0)))
			.material (materials.concrete);
			//sidewalk.visual.texture (sidewalk_texture, uv_strip_tile (sidewalk.physical.geometry)); 
			// TODO .visual converts the sidewalk from Material to Visual via Id, if its constructed
			// if not, i dunno, we construct one i guess
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
