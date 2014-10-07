import std.conv;
import std.algorithm;
import std.typecons;
import std.range;
import evx.range;
import evx.meta;
import evx.arrays;
import evx.math;
import evx.display;
import evx.scribe;
import evx.colors;
import evx.input;
import evx.utils;
import evx.spatial;
import evx.camera;

// TODO if the normal of the surface hit is close enough to π/2.... do an exclusive raycast without that shape, cause its probably a grazing hit?!?!

//vertices[].enumerate.rotate_elements[0..$].map!((i,v) => i).pl; // this preserves the original range
//vertices[].enumerate.rotate_elements[1..$].map!((i,v) => i).pl; // BUG This winds up kicking out the first AND last element... must be a bug in Cycle? dropOne works, but drop (1) doesn't...

mixin(FunctionalToolkit!());
mixin(ArithmeticToolkit!());

struct Triangle (T)
	{/*...}*/
		alias Vertex = Vector!(2,T);

		union {Vertex[3] vertices; struct {Vertex a,b,c;}}

		this (Vertex a, Vertex b, Vertex c)
			{/*...}*/
				this.a = a;
				this.b = b;
				this.c = c;
			}

		bool has_clockwise_winding ()
			{/*...}*/
				return (b-a).det (c-b) < 0;
			}
	}

void game_loop (alias loop)()
	{/*...}*/
		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;

		bool terminated;
		scope usr = new Input (gfx, (bool){terminated = true;});

		scope txt = new Scribe (gfx, [18, 36, 144]);

		while (not!terminated)
			{/*...}*/
				loop (gfx, usr, txt);

				gfx.render;
				usr.process;

				import core.thread;
				Thread.sleep (20.msecs);
			}
	}

struct Edge (T)
	{/*...}*/
		alias Vertex = Vector!(2,T);

		Vertex[2] endpoints;
		alias endpoints this;

		this (Vertex u, Vertex v)
			{/*...}*/
				endpoints[] = [u,v];
			}
	}
auto edge (V)(V u, V v)
	{/*...}*/
		return Edge!(ElementType!V)(u,v);
	}

auto edges (R)(R range)
	{/*...}*/
		return range.adjacent_pairs.map!edge;
	}

auto is_left_turn (V)(V a, V b, V c)
	{/*...}*/
		return (b-a).det (c-b) > 0;
	}
	unittest {/*...}*/
		assert (is_left_turn (0.vec, î!vec, 1.vec));
	}

auto is_left_of (V, T = ElementType!V)(V v, Edge!T e)
	{/*...}*/
		return is_left_turn (e[0], e[1], v);
	}

auto sort_by_polar_angle_about (R, V = ElementType!R)(auto ref R vertices, V center)
	{/*...}*/
		enum x_axis = î!V;
		auto p = center;

		vertices[].sort!((u,v) => (u-p).bearing_to (x_axis) < (v-p).bearing_to (x_axis));
	}

SpatialDynamics space;

alias filled = GeometryMode.t_fan; // TEMP

bool is_degenerate (R)(R polygon)
	{/*...}*/
		return polygon[].area == 0.squared!meters;
	}

auto is_visible_from (Position b, Position a)
	{/*...}*/
		auto ab = b-a;

		auto Δ = ab.unit;
		auto ε = 0.01;
		auto δ = Δ * ε * ab.norm;
		auto ρ = δ.rotate (π/2);

		auto incidences = [
			space.ray_cast ([a+δ-ρ, b-δ-ρ]),
			space.ray_cast ([a+δ, b-δ]),
			space.ray_cast ([a+δ+ρ, b-δ+ρ]),
		];

		return not!all (incidences.map!(inc => inc.occurred));
	}

auto overlap (R)(R range, size_t overlap = 1)
	{/*...}*/
		return chain (range[], range[0..overlap]);
	}

static if (0)
void main ()
	{/*...}*/
		static if (1)
		Appendable!(vec[]) vertices;
		else
		auto vertices = square.scale (2);

		vertices ~= square.scale (2);

		enum nn = 4;
		static if (0)
		foreach (i; 0..nn^^2)
			vertices ~= vec(i/nn, i%nn) / (nn/2.0) - 1.vec;
			//vertices ~= vec(2*gaussian % 1, 2*gaussian % 1) * 0.5;

		space = new SpatialDynamics; // REVIEW global
		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;
		bool step;
		bool finished;
		import core.thread: Thread, msecs;
		scope usr = new Input (gfx, (bool yes){if (yes) finished = true;});
		scope cam = new Camera (space, gfx);
		cam.zoom (500);
		usr.bind (Input.Key.s, (bool yes){if (yes) step = true;});
		scope txt = new Scribe (gfx);

		struct Temp {mixin TypeUniqueId;}

		alias StaticBody = Dynamic!(Position[]);
		StaticBody[Temp.Id] static_bodies;
		foreach (_; 0..4)
			{/*...}*/
				auto id = Temp.Id.create;
				static_bodies[id] = StaticBody (square (0.1.meters, vec(2*gaussian % 2, 2*gaussian % 2) * 0.25.meters));
				space.new_body (id, infinity.kilograms, static_bodies[id][]);
			}

		auto convex_hull (R)(auto ref R points)
			if (is_geometric!R)
			{/*...}*/
				/* Graham's Scan */
				alias Vertex = ElementType!R;

				static if (__traits(isRef, points))
					alias vertices = points;
				else auto vertices = Array!Vertex (points);

				vertices[].multiSort!((u,v) => u.y < v.y, (u,v) => u.x < v.x);

				vertices[1..$].sort_by_polar_angle_about (vertices[0]);

				auto hull = Appendable!(Array!Vertex)(vertices.length);
				hull ~= vertices[0..2];

				foreach (v; vertices[].rotate_elements.dropOne)
					{/*...}*/
						while (not!step)
							{/*...}*/
								gfx.draw (green, circle (0.02, vertices[0]), filled);
								gfx.draw (green (0.2), hull[], filled);
								gfx.draw (green, hull[]);
								gfx.draw (red, circle (0.02, v), filled);
								gfx.draw (yellow, circle (0.02, hull[$-1]), filled);

								gfx.render;
								usr.process;
								Thread.sleep (50.msecs);
							}
						step = false;

						while (v.is_left_of (edge (hull[$-2], hull[$-1])) && hull.length >= 2)
							hull.shrink (1);

						hull ~= v;
					}

				return hull;
			}

		auto sweep_triangulation (R)(auto ref R geometry)
			if (is (ElementType!R == Position))
			{/*...}*/
				alias Triangle = Dynamic!(Position[3]);
				alias TriangleFan = Appendable!(Position[]);
				alias Triangulation = Appendable!(TriangleFan[]);

				Triangle[Temp.Id] temp_bodies;

				cam.set_program = (SpatialId id)
					{/*...}*/
						if (auto temp = id.as!(Temp.Id) in temp_bodies)
							{/*...}*/
								gfx.draw (blue, (*temp)[].to_view_space (cam));
								gfx.draw (blue (0.2), (*temp)[].to_view_space (cam), filled);
							}
						else if (auto stat = id.as!(Temp.Id) in static_bodies)
							gfx.draw (red (0.2), (*stat)[].to_view_space (cam), filled);
					};

				auto add_triangle (Position a, Position b, Position c)
					{/*...}*/
						auto id = Temp.Id.create;
						auto tri = Triangle ([a,b,c]);

						if (tri[].is_degenerate)
							return;

						temp_bodies[id] = tri;
						space.new_body (id, infinity.kilograms, tri[]);
					}

				auto triangulations = Triangulation ();

				auto triangle_is_clear (Position u, Position v, Position w)
					{/*...}*/
						Appendable!(SpatialId[1], Overflow.blocked) result;

						space.polygon_query ([u,v,w].scale (0.95), result); // EPSILON

						return result.empty;
					}

				foreach (v; geometry[])
					{/*...}*/
						auto ref t_fan (){return triangulations.back;}

						triangulations ~= TriangleFan ();

						t_fan ~= v;

				auto vertices = Array!Position (geometry[].filter!(u => u != v));
				vertices[].sort_by_polar_angle_about (v);


				Triangle[] bad_triangles;
						foreach (u; vertices[].overlap (3).filter!(u => u.is_visible_from (v)))
							{/*...}*/
								if (t_fan.length >= 3)
									{/*consider new triangle}*/
										auto w = t_fan.back;

										if (triangle_is_clear (u,v,w)) // TODO empty -> free function, TODO queries without output array -> construct an output array inside the f'n, TODO return to original syntax (polygon_query).empty | not!empty
											add_triangle (u,v,w);
										else {/*}*/
											t_fan.shrink (1);
											bad_triangles ~= Triangle([u,v,w]);
										}
									}

								t_fan ~= u;
							}

						if (t_fan.length < 3)
							triangulations.shrink (1);

						{/*...}*/
							while (not (step || finished))
								{/*...}*/
									txt.write (triangulations.length, ` fans, `, triangulations[].map!(fan => fan.length - 2).sum, ` triangles`)
										.color (white)										
									();

									foreach (tr; bad_triangles)
										gfx.draw (yellow (0.15), tr[].to_view_space (cam), filled);


									cam.capture;

									gfx.draw ((black*grey)(0.5), [vertices[0],v].to_view_space (cam), GeometryMode.l_strip);

									foreach (u; vertices[].filter!(u => u != v))
										gfx.draw ((black*red)(0.5), circle (0.01.meters, u).to_view_space (cam), filled);

									static bool flip;
									gfx.draw (flip? yellow:black, circle (0.01.meters, v).to_view_space (cam), filled);
									flip ^= 0x1;

									foreach (u; vertices[].filter!(u => u != v && u.is_visible_from (v)))
										gfx.draw (green*black, circle (0.01.meters, u).to_view_space (cam), filled);

									if (0)
									foreach (i, u; enumerate (vertices[]))
										txt.write (i)
											.inside (square (1.meter, u).to_view_space (cam).to_extended_space (gfx).bounding_box)
											.color (u == v && not!flip? black:white)
											.align_to (Alignment.center)
										();

									gfx.render;
									usr.process;
									Thread.sleep (250.msecs);
								}
							step = false;
						}
					}

				foreach (temp; temp_bodies.byKey)
					space.delete_body (temp);
			}

		//convex_hull (vertices[]);
		foreach (bod; static_bodies.byValue)
			vertices ~= bod[].map!dimensionless;

		sweep_triangulation (vertices[].map!(v => v * meters));

		static if (0)
		{/*...}*/
			game_loop!((Display gfx, Input usr, Scribe txt)
				{/*...}*/
					foreach (i, vertex; vertices)
						gfx.draw (purple, circle (0.02, vertex), GeometryMode.t_fan);

					static bool draw_result;
					static bool started;
					if (not!started)
						{/*...}*/
							usr.bind (Input.Key.tilde, (bool on)
								{if (on) draw_result = not!draw_result;}
							);
							started = true;
						}

					if (not!draw_result)
						gfx.draw (purple (0.2), vertices[], GeometryMode.t_fan);
					else
						gfx.draw (red (1.0), convex_hull_graham (vertices[])[], GeometryMode.t_fan);

					foreach (i, vertex; vertices)
						txt.write (i)
							.inside (circle (1, vertex).bounding_box)
							.color (purple*white*white)
							.align_to (Alignment.center)
							.scale (0.75)
						();
				}
			);
		}
	}
