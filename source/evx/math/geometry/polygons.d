module evx.math.geometry.polygons;

private {/*imports}*/
	import std.conv;
	import std.math;
	
	import evx.range;
	import evx.misc.memory;

	import evx.math.geometry.vectors;
	import evx.math.geometry.traits;

	import evx.math.logic;
	import evx.math.ordinal;
	import evx.math.floatingpoint;
	import evx.math.algebra;
	import evx.math.sequence;
	import evx.math.fields;
	import evx.math.arithmetic;
	import evx.math.functional;
	import evx.math.constants;
	import evx.math.vectors;
	import evx.math.statistics;
}

/* shape generators 
*/
auto square (T = double)(T side = unity!T, Vector!(2,T) center = zero!(Vector!(2,T)))
	in {/*...}*/
		assert (side > zero!T);
	}
	body {/*...}*/
		alias V = Vector!(2,T);

		return [V(1,1), V(-1,1), V(-1,-1), V(1,-1)]
			.map!(v => v*side/2 + center);
	}
template circle (uint samples = 24)
	{/*...}*/
		auto circle (T = double)(T radius = unity!T, Vector!(2,T) center = zero!(Vector!(2,T)))
			in {/*...}*/
				assert (radius > zero!T, "circle radius (" ~radius.text~ ") must be positive");
			}
			body {/*...}*/
				return ℕ[0..samples].map!(i => 2*π*i/samples) 
					.map!(t => vector (cos(t), sin(t)))
					.map!(v => radius*v + center);
			}
	}

/* get the distance of a polygon's furthest point from its centroid 
*/
auto radius (T)(T geometry)
	if (is_geometric!T)
	{/*...}*/
		 auto c = geometry.mean;

		 return geometry[].map!(v => (v-c).norm).reduce!max;
	}
	unittest {/*...}*/
		assert (circle.radius == 1.0);			
		assert (square.radius.approx (SQRT2/2));
	}

/* get the area of a polygon 
*/
auto area (R)(R polygon)
	if (is_geometric!R)
	{/*...}*/
		return 0.5 * Σ (polygon
			.adjacent_pairs
			.map!((u,v) => u.det (v))
		).abs;
	}
	unittest {/*...}*/
		assert (square (1.0).area.approx (1));
		assert (square (2.0).area.approx (4));
		assert (circle!1000 (1.0).area.approx (π));
		assert (circle!1000 (2.0).area.approx (4*π));

		// http://www.mathsisfun.com/geometry/area-irregular-polygons.html
		auto irregular = [
			vec(2.66, 4.71),
			vec(5, 3.5),
			vec(3.63, 2.52),
			vec(4, 1.6),
			vec(1.9, 1),
			vec(0.72, 2.28)
		];
		auto known_area = 8.3593;
		assert (irregular.area.approx (known_area));

		static if (__traits(compiles, {import evx.math.units;}))
			{/*...}*/
				import evx.math.units;

				assert (square (2.meters).area.approx (4.squared!meters));
				assert (circle!1000 (1.meter).area.approx (π.squared!meters));
				assert (
					irregular.map!(v => vector (v.x.meters, v.y.meters))
					.area.approx (known_area.squared!meters)
				);
			}
	}

/* reflect a polygon over a "direction" axis passing through its centroid 
*/
auto flip (string direction, T)(T geometry)
	if (is_geometric!T && (direction == `vertical` || direction == `horizontal`))
	{/*...}*/
		alias Vector = ElementType!T;
		alias one = unity!(ElementType!Vector);

		static if (direction == `vertical`)
			auto w = Vector (one, -one) / one;
		else auto w = Vector (-one, one) / one;

		auto c = geometry.mean;

		return geometry[].map!(v => (v - c) * w + c);
	}
	unittest {/*...}*/
		static if (__traits(compiles, {import evx.math.geometry.aabb;}))
			{/*...}*/
				import evx.math;//				import evx.math.geometry.aabb;

				assert (not (square.flip!`vertical`.equal (square)));
				assert (equal (
					square.flip!`vertical`.bounding_box[],
					square.bounding_box[]
				));  // BUG was:
				/*assert (square.flip!`vertical`.bounding_box[]
					.equal (square.bounding_box[])
				);
					but UFCS fails... says Error: template std.algorithm.equal cannot deduce function from argument types !()(Sub!0)... wtf? non-UFCS rewrite works
				*/

				assert (not (square.flip!`horizontal`.equal (square)));
				assert (equal (
					square.flip!`horizontal`.bounding_box[],
					square.bounding_box[]
				));
			}

		auto triangle = [-î!vec, ĵ!vec, î!vec];
		assert (triangle.flip!`horizontal`.equal (triangle.retro));

		assert (triangle.flip!`vertical`
			.approx ([-î!vec, -ĵ!vec, î!vec].map!(v => v + vec(0, 2.0/3)))
		);

		static if (__traits(compiles, {import evx.math.units;}))
			{/*...}*/
				import evx.math.units;
				alias Position = Vector!(2, Meters);
				auto triangle2 = [-î!Position, ĵ!Position, î!Position];

				assert (triangle2.flip!`horizontal`.equal (triangle2.retro));
				assert (triangle2.flip!`vertical`
					.approx ([-î!Position, -ĵ!Position, î!Position].map!(v => v + vector (0.meters, 2.0.meters/3)))
				);
			}
	}

/* translate a polygon by a vector 
*/
auto translate (T, Vec = ElementType!T)(T geometry, Vec displacement)
	if (is_geometric!T)
	{/*...}*/
		auto Δv = displacement;

		return geometry.map!(v => v + Δv);
	}

/* rotate a polygon about a given point or its centroid 
*/
auto rotate (T, U = ElementType!(ElementType!T), V = ElementType!T)(T geometry, U θ, V pivot = V.init)
	if (is_geometric!T)
	{/*...}*/
		import evx.math;//		import evx.math.geometry.vectors;

		auto c = pivot.bytes == V.init.bytes? geometry.mean: pivot;

		return geometry.map!(v => (v-c).rotate (θ) + c);
	}
	unittest {/*...}*/
		static if (0)
		foreach (v; [vec(0,1), vec(0,2), vec(3,9)].rotate (12))
			assert (not!any (v.each!isNaN[])); // BUG each(v) cannot be sliced with []

	}

/* scale a polygon without moving its centroid 
*/
auto scale (T1, T2)(T1 geometry, T2 scale)
	if (is_geometric!T1 && __traits(compiles, geometry.front * scale))
	{/*...}*/
		auto c = geometry.mean;
		auto s = scale;

		return geometry.map!(v => s*(v-c) + c);
	}

/* test if a polygon is degenerate (zero area) 
*/
bool is_degenerate (R)(R polygon)
	{/*...}*/
		return polygon[].area == 0.squared!meters;
	}

/* an edge consisting of 2 vertices 
*/
template Edge (T)
	{/*...}*/
		alias Edge = Vector!(2,T)[2];
	}
auto edge (V)(V u, V v)
	{/*...}*/
		return Edge!(ElementType!V)([u,v]);
	}

/* construct the set of edges of a polygon 
*/
auto edges (R)(R range)
	{/*...}*/
		return range.adjacent_pairs.map!edge;
	}

/* test if a vertex lies to the left of an edge 
*/
bool is_left_of (V, T = ElementType!V)(V v, Edge!T e)
	{/*...}*/
		return is_left_turn (e[0], e[1], v);
	}

static if (__traits(compiles, {import evx.math.units;}))
	unittest {/*with units}*/
		import evx.math.units;

		static assert (__traits(compiles, square (1.meter)));
		static assert (__traits(compiles, circle (1.meter)));
	}
