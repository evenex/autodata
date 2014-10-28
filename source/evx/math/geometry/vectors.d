module evx.math.geometry.vectors;

private {/*imports}*/
	import std.conv;
	import std.math;
	import std.range;
	import std.traits;

	import evx.math.geometry.traits;

	import evx.math.algebra;
	import evx.math.analysis;
	import evx.math.constants;
	import evx.math.functional; // REVIEW
	import evx.math.arithmetic; // REVIEW
}
public import evx.math.vectors;

// REVIEW
mixin(FunctionalToolkit!());

/* standard basis 
*/
auto î (Vec)()
	{/*...}*/
		alias T = ElementType!Vec;

		return Vec(unity!T, zero!T);
	}
auto ĵ (Vec)()
	{/*...}*/
		alias T = ElementType!Vec;

		return Vec(zero!T, unity!T);
	}

unittest {/*...}*/
	static assert (î!vec == vec(1,0));
	static assert (ĵ!vec == vec(0,1));
	
	import evx.math.units;
	alias Position = Vector!(2, Meters);

	static assert (î!Position == Position (1.meter, 0.meters));
	static assert (ĵ!Position == Position (0.meters, 1.meter));
}

/* common vector types 
*/
alias vec  = Vector!(2, double);
alias fvec = Vector!(2, float);
alias ivec = Vector!(2, int);
alias uvec = Vector!(2, size_t);
alias rvec = Vector!(2, real);
alias lvec = Vector!(2, long);

// TODO refactor vector unary binary functions
pure {/*unary functions}*/
	auto norm (size_t p = 2, V)(V v)
		if (is_vector_like!V || isInputRange!V)
		{/*...}*/
			alias T = ElementType!V;

			return T (v[].map!(t => (t/T(1))^^p).sum ^^ (1.0/p));
		}
	auto unit (V)(V v) 
		if (is_vector_like!V)
		{/*...}*/
			alias T = ElementType!V;

			immutable norm = v.norm;

			if (norm == T(0))
				return vector!(V.length) (T(0)/T(1));
			else return vector!(V.length) (v[].map!(t => t/norm));
		}
}
pure {/*binary functions}*/
	auto dot (U, V)(U u, V v) 
		if (is_vector_like!V)
		{/*...}*/
			return (u*v)[].sum;
		}
	auto dot (U, V)(U u, V v) 
		if (isInputRange!V)
		{/*...}*/
			return u[].zip (v[])
				.map!((a,b) => a*b)
				.sum;
		}

	auto det (U, V)(U u, V v) 
		if (is (V == Vector!(2, T), T) && is(U == Vector!(2, S), S))
		{/*...}*/
			return u[0]*v[1] - u[1]*v[0];
		}

	auto cross (U, V)(U u, V v) 
		if (is (V == Vector!(3, T), T))
		{/*...}*/
			return vector (
				u[1]*v[2] - u[2]*v[1],
				u[2]*v[0] - u[0]*v[2],
				u[0]*v[1] - u[1]*v[0],
			);
		}

	auto proj (U, V)(U u, V v) 
		{/*...}*/
			return u.dot (v.unit) * v.unit;
		}

	auto rej (U, V)(U u, V v) 
		{/*...}*/
			return u - u.proj (v);
		}
}

/* rotate a vector 
*/
auto rotate (Vec, T)(Vec v, T θ) 
	if (is_vector!Vec && is(T: double))
	{/*...}*/
		return Vec(cos(θ)*v.x-sin(θ)*v.y,  sin(θ)*v.x+cos(θ)*v.y);
	}

/* compute the angular difference between two vectors 
*/
auto bearing_to (Vec)(Vec a, Vec b)
	if (is_vector!Vec)
	{/*...}*/
		return atan2 (
			a.det (b).to!double,
			a.dot (b).to!double
		);
	}
	unittest {/*...}*/
		assert (î!vec.bearing_to (ĵ!vec).approx (π/2));
		assert (ĵ!vec.bearing_to (î!vec).approx (-π/2));
		assert (vec(1,-1).bearing_to (î!vec).approx (π/4));
	}
alias angle_between = bearing_to;

/* compute the distance between two points 
*/
auto distance (Vec)(Vec a, Vec b)
	if (is_vector!Vec)
	{/*...}*/
		return (a-b).norm;
	}
alias distance_to = distance;

/* find among a set of points the one closest to the given point 
*/
auto closest_to (R, Vec)(R range, Vec point)
	if (is(ElementType!R == Vec))
	{/*...}*/
		return range.reduce!((a,b) => a.distance_to (point) < b.distance_to (point)? a: b);
	}

/* test if traversing three successive vertices constitutes a left turn 
*/
bool is_left_turn (V)(V a, V b, V c)
	{/*...}*/
		return (b-a).det (c-b) > 0;
	}
	unittest {/*...}*/
		assert (is_left_turn (0.vec, î!vec, 1.vec));
	}

/* sort a set of vertices by their polar angle about a given vertex
*/
auto sort_by_polar_angle_about (R, V = ElementType!R)(auto ref R vertices, V center)
	{/*...}*/
		enum x_axis = î!V;
		auto p = center;

		vertices[].sort!((u,v) => (u-p).bearing_to (x_axis) < (v-p).bearing_to (x_axis));
	}

/* sort a set of vertices by their polar angle about the origin
*/
auto sort_by_polar_angle (R)(auto ref R vertices)
	{/*...}*/
		vertices.sort_by_polar_angle_about (zero!(ElementType!R));
	}
