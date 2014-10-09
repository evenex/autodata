module evx.ai;

private {/*import}*/
	private {/*std}*/
		import std.algorithm;
		import std.typecons;
		import std.range;
	}
	private {/*evx}*/
		import evx.meta;
		import evx.arrays;
		import evx.range;
		import evx.spatial;
		import evx.math;
		import evx.utils;
		import evx.display;
		import evx.colors;
		import evx.grid;
		import evx.camera;
		import evx.input;
		import evx.scribe;
	}

	mixin(FunctionalToolkit!());
	alias m = meters;
	alias sum = evx.arithmetic.sum;
}
import rubble_generator;
import std.random;

static if (0)
void main ()
	{/*...}*/
		auto view_cone = [vector (0.m, 0.m), vector (1.m, 0.5.m), vector (1.m, -0.5.m)];

		struct Physics {mixin TypeUniqueId;}
		scope phy = new SpatialDynamics;

		struct Human
			{/*...}*/
				mixin TypeUniqueId;
				Body physical;

				static geometry ()
					{/*...}*/
						return circle!10 (0.5.meter);
					}
			}
		Human[Physics.Id] humans;
		auto new_human (Kilograms mass)
			{/*...}*/
				auto id = Physics.Id.create;

				humans[id] = Human (phy.new_body (id, mass, Human.geometry).damping (0.2));

				return humans[id];
			}

		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;

		auto fred = new_human (70.kilograms);
		auto bob = new_human (70.kilograms);
		auto george = new_human (70.kilograms);
		bob.physical.position (10.meters.Position);
		george.physical.position (-10.meters.Position);

		Tuple!(Box!Meters, Color)[Physics.Id] debris;
		foreach (i; 0..100)
			{/*generate debris}*/
				auto Δx = vec (uniform (-500, 500), uniform (-500, 500)) * meters;

				foreach (box; rubble (20))
					{/*...}*/
						if (box[].area.approx (0))
							continue;

						auto chunk = box[].map!(v => v*meters).translate (Δx);

						auto id = Physics.Id.create;

						debris[id] = τ(chunk.bounding_box, grey * black (uniform (0.0, 1.0)));

						phy.new_body (id, infinity.kilograms, debris[id][0][]);
					}
			}
		
		enum DrawLayer: uint {floor, object, hud, ui}
		auto camera = new Camera (phy, gfx);
		camera.set_program = (SpatialId id)
			{/*...}*/
				auto entity = phy.get_body (id);

				auto pos = entity.position;
				auto dir = entity.orientation;

				if (auto human = id.as!(Physics.Id) in humans)
					{/*...}*/
						auto entity_view_cone = view_cone.map!(v => 50*v).rotate (dir, zero!Position).translate (pos);
						auto view_cone_visual = entity_view_cone.to_view_space (camera);

						gfx.draw (blue, human.geometry.rotate (dir, zero!Position).translate (pos).to_view_space (camera), GeometryMode.t_fan, DrawLayer.object);

						auto view_cone_color = blue;

						Appendable!(SpatialId[16], Overflow.blocked) bodies_in_view;
						phy.polygon_query (entity_view_cone, bodies_in_view);

						foreach (visible; bodies_in_view[].filter!(seen => seen.as!(Physics.Id) in humans && seen != id))
							view_cone_color = red;

						gfx.draw (view_cone_color (0.1), view_cone_visual, GeometryMode.t_fan, DrawLayer.hud);
						gfx.draw (view_cone_color, view_cone_visual, GeometryMode.l_loop, DrawLayer.hud);
					}

				if (auto chunk = id.as!(Physics.Id) in debris)
					gfx.draw ((*chunk)[1], (*chunk)[0][].to_view_space (camera), GeometryMode.t_fan, DrawLayer.object);
			};

		bool terminated;
		scope usr = new Input (gfx, (bool){terminated = true;});

		scope txt = new Scribe (gfx, [32, 128]);

		while (not!terminated)
			{/*...}*/
				import core.thread;

				{/*camera}*/
					camera.center_at (fred.physical.position);
					camera.capture;
				}
				{/*user input}*/
					with (Input.Key) fred.physical.applied_force = 
						usr.keys_pressed ([w,      a,     s,      d    ])
						.zip             ([ĵ!vec, -î!vec, -ĵ!vec, î!vec])
						.filter!((key_pressed,_) => key_pressed)
						.map!((_,force) => force)
						.sum.unit * 6000.newtons
						* (usr.keys_pressed ([left_shift])
							.filter!(x => x)
							.empty? 1.0: 2.0);

					usr.on_scroll ((double Δy) {camera.zoom = Δy > 0? 1.1:1/1.1;});

					auto ptr_pos = usr.pointer.from_extended_space.to_draw_space (gfx).to_world_space (camera);
					Appendable!(Physics.Id[8], Overflow.blocked) nearest_things;
					phy.circle_query (ptr_pos, 1.meter, nearest_things); // REVIEW from_ext.to_view is too verbose

					auto nearest_thing = nearest_things[]
						.map!(id => τ(id, phy.get_body (id).position.distance_to (ptr_pos)))
						.reduce!((a,b) => a[1] < b[1]? a: b)
						[0];

					if (auto human = nearest_thing in humans)
						gfx.draw (red, human.geometry.rotate (human.physical.orientation).translate (human.physical.position).to_view_space (camera), GeometryMode.l_loop, DrawLayer.hud);

					gfx.draw (red, circle (0.05, usr.pointer), GeometryMode.l_loop, DrawLayer.ui);
					txt.write (ptr_pos.distance_to (fred.physical.position))
						.color (red)
						.inside (square (1.0, usr.pointer + vec(0.6, 0)))
						.align_to (Alignment.center_left)
						.scale (0.35)
					();

					fred.physical.orientation = î!vec.bearing_to (usr.pointer);
				}
				{/*main processing}*/
					gfx.render;
					phy.update;
					usr.process;
				}

				Thread.sleep (10.msecs);
			}

		auto generate_floor ()
			{/*...}*/
				Appendable!(Array!Position) nav_mesh;

				auto noisy (R)(R range)
					{/*...}*/
						return range.map!(v => v + 0.1 * vec(gaussian.clamp (-1,1), gaussian.clamp (-1,1))*meters);
					}
				void draw ()
					{/*draw}*/
						camera.capture;

						gfx.draw (green, nav_mesh[].to_view_space (camera), GeometryMode.points, DrawLayer.ui);

						gfx.render;
						usr.process;
						import core.thread;
						Thread.sleep (10.msecs);
					}

				void sense_grid (Position center, Meters width)
					{/*...}*/
						auto grid = Grid!Meters ().resolution (20,20).measure (width, width);
						auto intersections = Array!Position (ℕ[0..grid[].length].map!(i => vec.init * meters));

						immutable radius = grid.Δx/2;

						auto intersected (size_t i)
							{/*...}*/
								return not!any (intersections[i].isNaN[]);
							}

						foreach (i, point; enumerate (noisy (grid[]).translate (center)))
							if (i.not!intersected)
								{/*...}*/
									Appendable!(Tuple!(Physics.Id, Position)[8], Overflow.blocked) result;

									phy.circle_query (point + grid.Δx/10 * vec(gaussian, gaussian), radius, result);

									auto intersect = result[].filter!((id, pos) => phy.get_body (id).mass.is_infinite);

									if (intersect.empty)
										continue;
									else intersections[i] = intersect.map!((id, pos) => pos).closest_to (point);
								}

						draw;

						if (grid.Δx < 2.meters)
							nav_mesh ~= enumerate (grid[].translate (center))
								.filter!((i, point) => i.not!intersected && any (grid.neighborhood (i)[].filter!intersected))
								.map!((i, point) => point);
						else foreach (point; enumerate (grid[].translate (center))
							.filter!((i, point) => intersected (i) && any (grid.neighborhood (i)[].filter!(j => j.not!intersected)))
							.map!((i, point) => point)
						)	{/*...}*/
								sense_grid (point, grid.Δx);
							}
					}

				sense_grid (fred.physical.position, 250.m);

				terminated = false;
				while (not!terminated)
					draw;
			}

		generate_floor;
	}
