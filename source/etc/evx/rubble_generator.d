module rubble_generator;

private {/*import}*/
	private {/*std}*/
		import std.range;
		import std.random;
		import std.typecons;
		import std.conv;
		import std.algorithm;
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
		import evx.loops;
		import evx.lsystem;
		import evx.range;
	}
	import libtriangle;

	mixin(MathToolkit!());
	// TODO mixin(MetricAbbreviations!());
	alias m = meters;
	alias kg = kilograms;
}

void main ()
	{/*...}*/
		version (LSYS)
			{/*...}*/
				enum Instruction
					{/*...}*/
						new_chunk, // value = (n_vertices, area)
						rotate, // value = (angle, null)
						translate, // value = (x,y)
						scale // value = (width, height)
					}
				alias Value = vec;
				alias Command = Tuple!(Instruction, Value);

				LSystem!Command rubble_generator;

				with (typeof(rubble_generator)) with (Instruction)
					{/*define rubble_generator}*/
						auto rules = Rules (
							Rule (),
						);

						Axiom initial = [τ(new_chunk, vec(4,1))];
					}
			}

		struct Mesh {mixin TypeUniqueId;}
		Position[][Mesh.Id] rubble;
		Position[3][Mesh.Id] nav_mesh;

		bool initialized;

		physics_loop!((SpatialDynamics phy, Camera cam, Display gfx, Input usr, Scribe txt)
			{/*...}*/
				if (not!initialized)
					{/*...}*/
						initialized = true;

						cam.set_program ((SpatialId id)
							{/*...}*/
								if (auto boulder = id.as!(Mesh.Id) in rubble)
									gfx.draw (red (0.2), (*boulder).to_view_space (cam), GeometryMode.t_fan);
								else if (auto triangle = id.as!(Mesh.Id) in nav_mesh)
									{/*...}*/
										gfx.draw (cyan (0.2), (*triangle)[].to_view_space (cam), GeometryMode.t_fan);
										gfx.draw (cyan (0.2), (*triangle)[].to_view_space (cam));
									}
							}
						);

						foreach (i; 0..20)
							{/*generate rubble}*/
								import std.array;

								auto id = Mesh.Id.create;

								auto geometry = circle (uniform (0.05, 0.1) * meters, vec (uniform (-1.0, 1), uniform (-1.0, 1)) * meters);

								rubble[id] = geometry.array;
							}

						foreach (triangle; rubble.values.contigious.array.triangulate)
							{/*generate nav_mesh}*/
								auto id = Mesh.Id.create;
								nav_mesh[id] = triangle;
							}

						foreach (id, geometry; rubble)
							phy.new_body (id, infinity.kg, geometry);

						Mesh.Id[] to_delete;
						foreach (id, triangle; nav_mesh)
							{/*...}*/
								enum ε = 0.001.m;

								if (all (phy.circle_query (triangle[].mean, ε)[].map!((id => id.as!(Mesh.Id) in nav_mesh))))
									phy.new_body (id, infinity.kg, triangle[]);
								else to_delete ~= id;
							}
						foreach (id; to_delete)
							nav_mesh.remove (id);
					}
					
				with (Input.Key)
					{/*...}*/
						cam.pan (
							usr.keys_pressed ([w,a,s,d]).map!(on => on? 1:0)
								.zip ([+ĵ!vec, -î!vec, -ĵ!vec, +î!vec])
								.map!multiply.sum.unit * meters / 50
						);

						cam.zoom (
							usr.keys_pressed ([n_plus, n_minus])
								.zip ([1.05, 0.95])
								.map!((on, zoom) => on? zoom: 1)
								.product
						);
					}
			},
		);
	}
