// TODO nice textboxes
// TODO nice consoles
// TODO picking
import std.range;
import std.conv;

import evx.spatial;
import evx.display;
import evx.camera;
import evx.scribe;
import evx.math;
import evx.meta;
import evx.range;
import evx.arrays;
import evx.colors;
import evx.input;
import evx.utils;

alias zip = evx.functional.zip;
alias map = evx.functional.map;
alias filter = evx.functional.filter;
alias reduce = evx.functional.reduce;

struct Entity
	{/*...}*/
		mixin TypeUniqueId;

		string name;
	}

alias Id = Entity.Id;
alias Physics = SpatialDynamics;


struct TextBox
	{/*...}*/
		Text text;

		auto draw (BoundingBox box, Display gfx)
			{/*...}*/
				gfx.draw (black (0.5), box[], GeometryMode.t_fan);
				gfx.draw (text.color.alpha (0.3), box[], GeometryMode.l_loop);

				box.width = box.width - 0.02;

				return text.inside (box)();
			}
	}
struct CommandLine
	{/*...}*/
		string text;

		Color color = green;

		enum pulse_ticks = 20;
		static uint tick = 0;

		void draw (BoundingBox box, Display gfx, Scribe txt, Input usr)
			{/*...}*/
				box = box.align_to (Alignment.top_left, box.bottom_left);
				with (box) bottom = top - 1.2 * txt.font_height (txt.available_sizes[0])/0.9;

				gfx.draw (black (0.5), box[], GeometryMode.t_fan);
				gfx.draw (color.alpha (0.3), box[], GeometryMode.l_loop);

				with (box) width = width - 0.02;

				txt.write (usr.get_text_input)
					.color (color)
					.inside (box)
					.align_to (Alignment.center_left)
				();
				if (++tick % pulse_ticks * 2 < pulse_ticks)
					txt.write (' '.repeat (usr.get_text_input.length).text~ `_`)
						.color (color)
						.inside (box)
						.align_to (Alignment.center_left)
					();
			}
	}

struct Console
	{/*...}*/
		Color color = green;

		TextBox display;
		CommandLine input;

		string history;
		size_t recall_index;

		void draw (BoundingBox box, Display gfx, Scribe txt, Input usr)
			{/*...}*/
				display = TextBox (txt.write (history).color (color).align_to (Alignment.bottom_left));
				input = CommandLine (usr.get_text_input);

				display.draw (box, gfx);
				input.draw (box, gfx, txt, usr);
			}
		void print (string text)
			{/*...}*/
				history ~= text~ "\n";
			}
		auto update (Input usr)
			{/*...}*/
				history ~= usr.get_text_input~ "\n";

				usr.clear_text_input;

				recall_index = 0;
			}

		void recall (Input usr)
			{/*...}*/
				auto split = history.splitter ("\n").retro.drop (2*recall_index++);

				if (split.empty)
					return;
				else usr.set_text_input = split.front;
			}
	}

struct Physical
	{/*...}*/
		Id id;
		Physics physics;

		Body* cached;
		size_t n_bodies;

		this (Id id, Physics physics)
			{/*...}*/
				this.id = id;
				this.physics = physics;

				update_cache;
			}

		@property opDispatch (string op, Args...)(Args args)
			{/*...}*/
				update_cache;

				mixin(q{
					return cached.} ~op~ q{ (args);
				});
			}

		void update_cache ()
			{/*...}*/
				if (n_bodies != physics.n_bodies)
					{/*...}*/
						n_bodies = physics.n_bodies;
						cached = physics.get_body (id.voidptr);
					}
			}
	}
struct Human
	{/*...}*/
		Id id;
		Color color;

		Entity* entity;
		Physical* physical;
		Appendable!(Item*[]) inventory;

		auto health = 100;
		bool is_dead ()
			{/*...}*/
				return health == 0;
			}
	}
struct Item
	{/*...}*/
		Id id;
		Color color;
		Displacement dimensions;

		enum Location {inventory, outside}
		Location location;

		Entity* entity;
		Physical* physical;
	}

static if (0)
void main ()
	{/*...}*/
		bool game_terminated;

		auto phy = new Physics;
		auto gfx = new Display (1000,1000);
		auto cam = new Camera (phy, gfx);

		gfx.start; scope (exit) gfx.stop;

		auto usr = new Input (gfx, (bool pressed){if (pressed) game_terminated = true;});
		auto txt = new Scribe (gfx, [12, 18, 32, 128]);

		enum origin = 0.meters.Position;

		Entity[Id] entities;
		Physical[Id] physical;
		Human[Id] humans;
		Item[Id] items;

		auto new_human (string name, Position position, Color color)
			{/*...}*/
				auto eid = Id.create;

				phy.new_body (eid, 70.kilograms, circle (1.meter))
					.position (position)
					.damping (0.05);

				entities[eid] = Entity (name);
				physical[eid] = Physical (eid, phy);

				humans[eid] = Human (eid, color, &entities[eid], &physical[eid]);

				return &humans[eid];
			}
		auto new_item (string name, Position position, Displacement dimensions, Color color)
			{/*...}*/
				auto eid = Id.create;

				phy.new_body (eid, 1.kilogram, bounding_box ([zero!Position + dimensions/2, zero!Position - dimensions/2])[])
					.position (position)
					.damping (0.1);

				entities[eid] = Entity (name);
				physical[eid] = Physical (eid, phy);
				items[eid] = Item (eid, color, dimensions, Item.Location.outside, &entities[eid], &physical[eid]);

				return &items[eid];
			}

		auto fred = new_human (`fred`, origin, red);
		auto bob = new_human (`bob`, origin + 2.meters.Position, blue);

		auto gun = new_item (`M1911A1`, origin - Position (2.meters, 0.meters), vector (500.millimeters, 300.millimeters), green);

		cam.set_program = (SpatialId spatial_id)
			{/*draw}*/
				auto id = spatial_id.as!Id;

				void draw_human (ref Human human)
					{/*...}*/
						auto position = human.physical.position;
				
						gfx.draw (human.color*black*grey, circle (1.meter, position).map!(v => v.to_view_space (cam)), GeometryMode.t_fan);

						txt.write (human.entity.name)
							.translate (position.to_view_space (cam))
							.color (human.color*white)
							.size (32)
							.scale (cam.zoom_factor / 100)
							.align_to (Alignment.center)
						();
					}
				void draw_item (ref Item item)
					{/*...}*/
						auto position = item.physical.position;
				
						gfx.draw (item.color*black*grey, 
							(vector (origin - item.dimensions, origin + item.dimensions)/2)
							[].bounding_box[]
							.translate (position)
							.map!(v => v.to_view_space (cam)),
						GeometryMode.t_fan);

						txt.write (item.entity.name)
							.translate (position.to_view_space (cam))
							.color (item.color*white)
							.size (32)
							.scale (cam.zoom_factor * item.dimensions.x.dimensionless / 200)
							.align_to (Alignment.center)
						();
					}

				if (auto aspect = id in humans)
					draw_human (*aspect);
				if (auto aspect = id in items)
					draw_item (*aspect);
			};

		phy.on_collision = (SpatialId id_a, SpatialId id_b)
			{/*...}*/
				Id object;
				auto a = id_a.as!Id;
				auto b = id_b.as!Id;

				if (a == fred.id)
					object = b;
				else if (b == fred.id)
					object = a;
				else return;

				if (auto item = object in items)
					{/*...}*/
						if (item.location is Item.Location.inventory)
							return;

						fred.inventory ~= item;
						item.location = Item.Location.inventory;
						item.physical.layer = 0x0;
					}
			};

		auto cmd = Console (green);
		void delegate()[string] commands = [
			`look`: {cmd.print = `you are inside an endless grey hell. everything is generic vector art, and you look down in horror to discover that you yourself are a nondescript red circle`;},
			`bob`: {cmd.print = bob.is_dead? `bob is dead! fuck bob!`: `bob is an ugly twat. you hate him so much`;},
			`gun`: {cmd.print = gun.location == Item.Location.inventory? `you have the gun in your hands`:`its a gun! quick, use it to shoot bob!`;},
			`shoot bob`: {cmd.print = gun.location == Item.Location.inventory? (bob.health = 0, `FUCK YES BOB IS FUCKING DEAD`):`alas you cannot for YOU HAVE NO GUN!!!!! ARGH!!!!!`;},
			`exit`: {game_terminated = true;},
			`quit`: {game_terminated = true;},
			`warp`: {fred.physical.position = zero!Position;},
		];
		void parse (string input)
			{/*...}*/
				cmd.update (usr);

				if (auto command = input in commands)
					(*command)();
				else cmd.print = `cannot ` ~input;
			}
		bool parser_up; 
		{/*set key bindings}*/
			usr.push_context (`parser`);
			usr.bind (Input.Key.enter, (bool pressed) {/*}*/
				if (pressed) parse (usr.get_text_input);
			});
			usr.bind (Input.Key.tilde, (bool pressed) {/*}*/
				if (pressed) usr.pop_context;
			});
			usr.bind (Input.Key.up, (bool pressed) {/*}*/
				if (pressed)
					cmd.recall (usr);
			});
			usr.pop_context;

			usr.bind (Input.Key.tilde, (bool pressed) {/*...}*/
				if (pressed)
					{/*...}*/
						usr.push_context (`parser`);
						usr.enter_text_mode;

						parser_up = true;

						usr.on_pop = {/*...}*/
							usr.clear_text_input;
							usr.enter_action_mode;

							parser_up = false;
						};
					}
			});
		}

		while (not (game_terminated))
			{/*...}*/
				import core.thread;
				import std.datetime;
				import evx.utils;
				alias seconds = evx.math.seconds;

				enum frametime_target = (1/60.).seconds;
				auto clock = Clock.currTime;

				///////
				phy.update;
				cam.capture;
				usr.process;
				///////
				{/*display hud}*/
					foreach (i, item; enumerate (fred.inventory[]))
						txt.write (item.entity.name)
							.color (red)
							.translate (-i * ĵ.vec / 10)
							.align_to (Alignment.top_right)
						();
				}
				{/*center camera}*/
					cam.center_at (phy.get_body (fred.id).position);
				}

				auto pointer_box = square (0.2, usr.pointer).bounding_box;
				if (parser_up)
					{/*...}*/
						cmd.draw (gfx.extended_bounds[].scale (vec(1,1/4.)).bounding_box.align_to (Alignment.top_left, gfx.extended_bounds.top_left), gfx, txt, usr);
					}
				else {/*handle action input}*/
					with (Input) fred.physical.velocity = usr.keys_pressed ([
						Key.w, Key.a, Key.s, Key.d
					]).zip ([
						vector ( 0.meters/second,	 1.meter/second), 
						vector (-1.meters/second,	 0.meter/second), 
						vector ( 0.meters/second,	-1.meter/second), 
						vector ( 1.meter/second,	 0.meters/second), 
					]).map!((pressed, velocity) => pressed? velocity: zero!Velocity)
						.vector!4[].sum.unit * (usr.keys_pressed ([Key.left_shift])[0]? 
							9.0.meters/second: 1.5.meter/second);

					txt.write (Unicode.symbol[`crosshair`])
						.color (red.alpha (0.8))
						.size (32)
						.inside (pointer_box)
						.align_to (Alignment.center)
						.rotate (π/4)
					();
					txt.write (distance (usr.pointer.to_world_space (cam), fred.physical.position))
						.color (red.alpha (0.5))
						.inside (pointer_box)
						.align_to (Alignment.bottom_left)
						.wrap_width (999)
					();
					gfx.draw (red.alpha (0.2), circle (cam.zoom_factor/1000, usr.pointer));

					if (fred.physical.position.distance_to (usr.pointer.to_world_space (cam)) > 10.millimeters * cam.zoom_factor)
						txt.write (Unicode.arrow[`right`])
							.color (red.alpha (0.3))
							.size (32)
							.inside (pointer_box[].translate ((usr.pointer - fred.physical.position.to_view_space (cam)).unit * cam.zoom_factor / 1000))
							.rotate (î.vec.bearing_to ((usr.pointer - fred.physical.position.to_view_space (cam)).unit))
							.align_to (Alignment.center)
							.wrap_width (999)
						();

					enum zoom_factor = 1.05;
					with (Input) cam.zoom (
						usr.keys_pressed ([Key.n_minus, Key.n_plus]).zip (
							[1/zoom_factor, zoom_factor]
						).map!((pressed, zoom) => pressed? zoom: 1.0)
							.vector!2[].product
					);
				}
				///////
				gfx.render;
				///////

				if (Clock.currTime > clock + frametime_target.to_duration)
					pwriteln (`missed frametime target`);
				while (Clock.currTime < clock + frametime_target.to_duration)
					{Thread.sleep (100.nsecs);}
			}
	}

static if (0)
void main ()
	{/*...}*/
		import evx.utils;

		auto gfx = new Display;

		gfx.start; scope (exit) gfx.stop;
		auto txt = new Scribe (gfx, [14]);

		bool quitting;
		auto usr = new Input (gfx, (bool){quitting = true;});

		import std.variant;
		struct Tag
			{/*...}*/
				ulong code;

				__gshared string[ulong] translate;

				this (string tag)
					{/*...}*/
						this.code = typeid(string).getHash (&tag);
						
						if (code !in translate)
							translate[code] = tag;
					}
			}
		struct Info
			{/*...}*/
				mixin TypeUniqueId;

				struct Link
					{/*...}*/
						string label;
						Info.Id target;
						BoundingBox box;
					}
				struct Text
					{/*...}*/
						string text;
					}

				__gshared Id[string] dictionary;
				__gshared Info*[Id] database;

				Id id;
				string title;
				Tag domain;
				Dynamic!(Algebraic!(Link, Text)[]) details;
				Color link_color = red;

				this (string title, Tag domain, string details)
					{/*...}*/
						this.id = Id.create;
						this.title = title;
						this.domain = domain;
						foreach (detail; details.splitter)
							{/*...}*/
								this.details.grow (1);
								if (auto id = detail in dictionary)
									this.details[$-1] = Link (detail, *id);
								else this.details[$-1] = Text (detail);
							}

						dictionary[title] = this.id;
					}

				auto display (Display gfx, Scribe txt, BoundingBox box)
					{/*...}*/
						auto typeset = txt.Typeset (txt.write (``).color (white).inside (box));// HACK

						foreach (word; details[])
							{/*...}*/
								auto glyphs = typeset.append (word.visit!(
										(Text text) => text.text,
										(Link link) => link.label,
								));

								word.visit!(
										(Text text) {},
										(Link link) {foreach (ref glyph; glyphs) glyph.color = link_color;},
								);

								typeset.append (` `);
							}

						typeset.finalize;
						gfx.draw (white, box[]);
						txt.draw (typeset); // REFACTOR
					}
			}

		scope world = new SpatialDynamics;
		scope scene = new SpatialDynamics;
		scope hud = new SpatialDynamics;

		auto s = Info (`sky`, Tag (`general`), `the sky is up`);
		Info.database[s.id] = &s;
		auto q = Info (`grass`, Tag (`specific`), `something you smoke`);
		Info.database[q.id] = &q;
		auto a = Info (``, Tag (`general`), `the sky is blue the grass is green`);
		Info.database[a.id] = &a;

		auto infobox = [-1.vec, 1.vec].scale (0.2).bounding_box;
		usr.bind (Input.Mouse.left, (bool clicked) {
			if (clicked) 
				{/*...}*/
					auto pos = usr.pointer * meters;

					Appendable!(Info.Id[]) result;
					hud.box_query ([pos + 0.1.meters, pos - 0.1.meters], result);

					auto pick = result[].filter!(id => id in Info.database);

					if (pick.empty) return;
					else {/*...}*/
						with (Info.database[pick.front])
							if (link_color == green)
								link_color = red;
							else if (link_color == red)
								link_color = green;
					}
				}
		});

		hud.new_body (a.id, 1.kilogram, infobox[].map!(v => v*meters))
			.position (zero!Position);
		hud.new_body (q.id, 1.kilogram, infobox[].map!(v => v*meters))
			.position (unity!Position/2);
		hud.new_body (s.id, 1.kilogram, infobox[].map!(v => v*meters))
			.position (-unity!Position/2);

		{/*loop}*/
			import core.thread;
			import std.datetime;

			void loop ()
				{/*...}*/
					a.display (gfx, txt, infobox[].translate (hud.get_body (a.id).position[].map!dimensionless.vec).bounding_box);
					q.display (gfx, txt, infobox[].translate (hud.get_body (q.id).position[].map!dimensionless.vec).bounding_box);
					s.display (gfx, txt, infobox[].translate (hud.get_body (s.id).position[].map!dimensionless.vec).bounding_box);

					gfx.render;
					usr.process;
					txt.write (Unicode.symbol[`crosshair`])
						.color (blue*white)
						.align_to (Alignment.center)
						.translate (usr.pointer)
					();
				}

			while (not(quitting))
				{/*...}*/
					loop;
					Thread.sleep (20.msecs);
				}
		}

		// TODO with phy, txt, generate wordboxes => (strings) → [spatial_ids of wordboxes]
		// REVIEW SpatialId instead of voidcasting?

		// TODO look tool - high-order spatial location info, then cast a view and report individual objects. clicking on object names will yield further info.
		void look ()
			{/*...}*/
				// lookup player location
				// get info tree for location
				// traverse info tree
				// cast view, report items and their relative locations
				// someday - also report situational awareness stuff, like current mission, or i just saw a guy over there, etc

					// more info on item - lookup info tree for item and traverse
			}
	}
