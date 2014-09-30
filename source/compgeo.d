import std.conv;
import std.algorithm;
import std.typecons;
import std.range;
import evx.range;
import evx.arrays;
import evx.math;
import evx.display;
import evx.scribe;
import evx.colors;
import evx.input;
import evx.utils;

//vertices[].enumerate.rotate_elements[0..$].map!((i,v) => i).pl; // this preserves the original range
//vertices[].enumerate.rotate_elements[1..$].map!((i,v) => i).pl; // BUG This winds up kicking out the first AND last element... must be a bug in Cycle? dropOne works, but drop (1) doesn't...

mixin(FunctionalToolkit!());

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


void main ()
	{/*...}*/
		vec[] vertices;

		foreach (i; 0..10)
			vertices ~= vec(gaussian, gaussian) * 0.25;

		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;
		bool step;
		scope usr = new Input (gfx, (bool yes){if (yes) step = true;});

		auto convex_hull_graham (R)(R points) // TODO auto ref => ref? in_place: internal_alloc
			if (is_geometric!R)
			{/*...}*/
				alias Vertex = ElementType!R;

				auto vertices = Array!Vertex (points);
				vertices[].multiSort!((u,v) => u.y < v.y, (u,v) => u.x < v.x);
				auto p = vertices[0];

				enum x_axis = î!Vertex;
				vertices[1..$].sort!((u,v) => (u-p).bearing_to (x_axis) < (v-p).bearing_to (x_axis));

				auto hull = Appendable!(Array!Vertex)(vertices.length);
				hull ~= vertices[0..2];

				foreach (v; vertices[].rotate_elements.dropOne)
					{/*...}*/
						while (not!step)
							{/*...}*/
								import core.thread;
								alias filled = GeometryMode.t_fan;

								foreach (i, vertex; vertices)
									gfx.draw (grey, circle (0.02, vertex), filled);

								gfx.draw (green, circle (0.02, vertices[0]), filled);
								gfx.draw (green (0.2), hull[], filled);
								gfx.draw (green, hull[]);
								gfx.draw (red, circle (0.02, v), filled);
								gfx.draw (yellow, circle (0.02, hull[$-1]), filled);

								gfx.draw (red, [hull[$-2], hull[$-1], v], GeometryMode.l_strip);

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

		convex_hull_graham (vertices[]);

		{/*...}*/
			static if (0)
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
