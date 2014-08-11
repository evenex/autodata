module evx.geometry;

private {/*import std}*/
	import std.algorithm: 
		copy, min, max,
		canFind, countUntil,
		setIntersection;

	import std.traits: 
		isFloatingPoint, isIntegral, isUnsigned,
		Unqual, EnumMembers;

	import std.typetuple:
		allSatisfy;

	import std.conv:
		to, text;

	import std.range:
		repeat,
		isInputRange,
		ElementType;

	import std.math:
		atan2, SQRT2;
}
private {/*import evx}*/
	import evx.utils: 
		τ, vary, Aⁿ;

	import evx.traits: 
		is_sliceable, is_type_of;

	import evx.range:
		adjacent_pairs;

	import evx.meta:
		ArrayInterface;

	import evx.functional:
		map, zip, reduce;

	import evx.logic: 
		not;

	import evx.ordinal:
		ℕ;

	import evx.arithmetic: 
		Σ;

	import evx.statistics: 
		mean;

	import evx.vectors;
	import evx.units;
}

pure nothrow:
public {/*traits}*/
	/* test if a type can be used by this library 
	*/
	template is_geometric (T)
		{/*...}*/
			enum is_geometric = is_vector!(ElementType!T);
		}

	/* test if a type can be used as a vector 
	*/
	bool is_vector (T)()
		{/*...}*/
			const T vector = T.init;

			static if (is (T.is_basis_vector == enum))
				return true;
			else return __traits(compiles, 
				(-vector.x, -vector.y),
				(+vector.x, +vector.y),

				(vector.x + vector.y), 
				(vector.x - vector.y),
				(vector.x * vector.y),
				(vector.x / vector.y)
			);
		}
}
public {/*vectors}*/
	/* basis vectors 
	*/
	struct BasisVector (real base_x, real base_y)
		{/*...}*/
			enum is_basis_vector;
				
			static immutable x = base_x;
			static immutable y = base_y;

			static auto opDispatch (string op)()
				{/*...}*/
					static if (mixin(q{is (} ~op~ q{)}))
						{/*...}*/
							mixin(q{
								alias Construct = } ~op~ q{;
							});

							static if (__traits(compiles, Construct (x,y)))
								return Construct (x, y);
							else static if (__traits(compiles, Construct (x)))
								return vector (Construct (x), Construct (y));
							else pragma (msg, `couldn't construct anything from ` ~op);
						}
					else mixin(q{
						return vector (x.} ~op~ q{, y.} ~op~ q{);
					});
				}
		}

	/* standard basis 
	*/
	immutable î = BasisVector!(1,0)();
	immutable ĵ = BasisVector!(0,1)();
	unittest {/*...}*/
		static assert (î.vec == vec(1,0));
		static assert (ĵ.vec == vec(0,1));
		
		import evx.units;
		static assert (î.meters == Vector!(2, Meters) (1.meter, 0.meters));
		static assert (ĵ.meters == Vector!(2, Meters) (0.meters, 1.meter));
	}

	/* common vector types 
	*/
	alias vec  = Vector!(2, double);
	alias fvec = Vector!(2, float);
	alias ivec = Vector!(2, int);
	alias uvec = Vector!(2, uint);

	/* rotate a vector 
	*/
	auto rotate (Vec, T)(Vec v, T θ) 
		if (is_vector!Vec && isFloatingPoint!T)
		{/*...}*/
			return Vec(cos(θ)*v.x-sin(θ)*v.y,  sin(θ)*v.x+cos(θ)*v.y);
		}

	/* compute the angular difference between two vectors 
	*/
	auto bearing_to (Vec)(Vec a, Vec b)
		if (is_vector!Vec)
		{/*...}*/
			static if (is_Unit!(ElementType!Vec))
				return atan2 (
					a.det (b).to_scalar,
					a.dot (b).to_scalar
				);
			else return atan2 (
				a.det (b),
				a.dot (b)
			);
		}
		unittest {/*...}*/
			assert (î.vec.bearing_to (ĵ.vec).approx (π/2));
			assert (ĵ.vec.bearing_to (î.vec).approx (-π/2));
			assert (vec(1,-1).bearing_to (î.vec).approx (π/4));
		}

	/* compute the distance between two points 
	*/
	auto distance (Vec)(Vec a, Vec b)
		if (is_vector!Vec)
		{/*...}*/
			return (a-b).norm;
		}
}
public {/*polygons}*/
	/* shape generators 
	*/
	auto square (T = double, Vec = vec)(const T side = unity!T, const Vec center = zero!Vec)
		if (isNumeric!T)
		in {/*...}*/
			assert (side > 0.0);
		}
		body {/*...}*/
			return [vec(1,1), vec(-1,1), vec(-1,-1), vec(1,-1)]
				.map!(v => v*side/2 + center);
		}
	auto circle (uint samples = 24, Vec = vec, T = ElementType!Vec)(const T radius = unity!T, const Vec center = zero!Vec)
		if (isNumeric!T)
		in {/*...}*/
			assert (radius > 0.0, "circle radius must be positive");
		}
		body {/*...}*/
			return ℕ[0..samples].map!(i => 2*π*i/samples) 
				.map!(t => Vec(cos(t), sin(t))) // XXX PERFECT case for uniform constructor syntax here
				.map!(v => radius*v + center);
		}

	/* dimensioned shape generators
	*/
	auto square (T, Vec = vec)(const T side, const Vec center = zero!Vec)
		if (is_Unit!T)
		{/*...}*/
			return square (side.to_scalar, center)
				.map!(v => vector (T(v.x), T(v.y)));
		}
	auto circle (uint samples = 24, Vec = vec, T = ElementType!Vec)(const T radius, const Vec center = zero!Vec)
		if (is_Unit!T)
		{/*...}*/
			return circle!samples (radius.to_scalar, center)
				.map!(v => vector (T(v.x), T(v.y)));
		}

	/* get the distance of a polygon's furthest point from its centroid 
	*/
	auto radius (T)(T geometry)
		if (is_geometric!T)
		{/*...}*/
			 immutable c = geometry.mean;

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
				.map!(v => v[0].det (v[1]))
			).abs;
		}
		unittest {/*...}*/
			assert (square (1).area.approx (1));
			assert (square (2).area.approx (4));
			assert (circle!100 (1).area.approx (π));
			assert (circle!100 (2).area.approx (4*π));

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

			assert (square (2.meters).area.approx (4.square_meters));
			assert (circle!100 (1.meter).area.approx (π.square_meters));
			assert (
				irregular.map!(v => vector (v.x.meters, v.y.meters))
				.area.approx (known_area.square_meters)
			);
		}

	/* reflect a polygon over a "direction" axis passing through its centroid 
	*/
	auto flip (string direction, T)(T geometry)
		if (is_geometric!T && (direction == `vertical` || direction == `horizontal`))
		{/*...}*/
			alias Vector = ElementType!T;
			alias one = unity!(ElementType!Vector);

			static if (direction == `vertical`)
				immutable w = Vector (one, -one) / one;
			else immutable w = Vector (-one, one) / one;

			immutable c = geometry.mean;

			return geometry[].map!(v => (v - c) * w + c);
		}
		unittest {/*...}*/
			import std.range: 
				retro,
				equal;

			assert (not (square.flip!`vertical`.equal (square)));
			assert (square.flip!`vertical`.bounding_box[]
				.equal (square.bounding_box[])
			);

			assert (not (square.flip!`horizontal`.equal (square)));
			assert (square.flip!`horizontal`.bounding_box[]
				.equal (square.bounding_box[])
			);

			auto triangle = [-î.vec, ĵ.vec, î.vec];
			assert (triangle.flip!`horizontal`.equal (triangle.retro));

			assert (triangle.flip!`vertical`
				.approx ([-î.vec, -ĵ.vec, î.vec].map!(v => v + vec(0, 2.0/3)))
			);

			import evx.units;
			auto triangle2 = [-î.meters, ĵ.meters, î.meters];

			assert (triangle2.flip!`horizontal`.equal (triangle2.retro));
			assert (triangle2.flip!`vertical`
				.approx ([-î.meters, -ĵ.meters, î.meters].map!(v => v + vector (0.meters, 2.0.meters/3)))
			);
		}

	/* translate a polygon by a vector 
	*/
	auto translate (T, Vec = ElementType!T)(T geometry, Vec Δv)
		if (is_geometric!T)
		{/*...}*/
			return geometry.map!(v => v + Δv);
		}

	/* rotate a polygon about its centroid 
	*/
	auto rotate (T, U = ElementType!(ElementType!T))(T geometry, U θ)
		if (is_geometric!T)
		{/*...}*/
			auto c = geometry.mean;
			return geometry.map!(v => (v-c).rotate (θ) + c);
		}

	/* scale a polygon without moving its centroid 
	*/
	auto scale (T1, T2)(T1 geometry, T2 scale)
		if (is_geometric!T1 && __traits(compiles, geometry.front * scale))
		{/*...}*/
			auto c = geometry.mean;
			return geometry.map!(v => (v-c) * scale + c);
		}

	unittest {/*with evx.units}*/
		static assert (__traits(compiles, square (1.meter)));
		static assert (__traits(compiles, circle (1.meter)));
	}
}
public {/*axis-aligned bounding boxes}*/
	/* an axis-aligned bounding box 
	*/
	struct Box (T)
		{/*...}*/
			pure nothrow @property:
			const {/*corners}*/
				Vec opDispatch (string op)()
					if (op.canFind (`left`, `center`, `right`))
					{/*...}*/
						immutable upper = τ(`upper`, `top`, `hi`);
						immutable lower = τ(`lower`, `bottom`, `lo`);

						immutable center 	= [0,1,2,3];
						immutable left 		= [0,3];
						immutable right 	= [1,2];
						immutable hi 		= [2,3];
						immutable low	 	= [0,1];

						static if (op.canFind (`left`))
							immutable horizontal = left;
						else static if (op.canFind (`right`))
							immutable horizontal = right;
						else static if (op.canFind (`center`))
							immutable horizontal = center;
						else pragma (msg, `Error: Box.`~op~` failed to compile`);


						static if (op.canFind (upper.expand))
							immutable vertical = hi;
						else static if (op.canFind (lower.expand))
							immutable vertical = low;
						else static if (op.canFind (`center`))
							immutable vertical = center;
						else pragma (msg, `Error: Box.`~op~` failed to compile`);

						auto length = 0;
						auto requested_point = zero!Vec;

						foreach (i; setIntersection (horizontal, vertical))
							{/*...}*/
								++length;
								requested_point += verts[i];
							}

						return requested_point / length;
					}
			}
			@vary {/*extents}*/
				const {/*get}*/
					auto left ()
						{/*...}*/
							return this.hi_left.x;
						}
					auto right ()
						{/*...}*/
							return this.hi_right.x;
						}
					auto top ()
						{/*...}*/
							return this.hi_left.y;
						}
					auto bottom ()
						{/*...}*/
							return this.low_left.y;
						}
				}
				@vary {/*set}*/
					void left (T x)
						in {/*...}*/
							assert (x < right);
						}
						body {/*...}*/
							verts[0].x = x;
							verts[3].x = x;
						}
					void right (T x)
						in {/*...}*/
							assert (x > left);
						}
						body {/*...}*/
							verts[1].x = x;
							verts[2].x = x;
						}
					void top (T y)
						in {/*...}*/
							assert (y > bottom);
						}
						body {/*...}*/
							verts[2].y = y;
							verts[3].y = y;
						}
					void bottom (T y)
						in {/*...}*/
							assert (y < top);
						}
						body {/*...}*/
							verts[0].y = y;
							verts[1].y = y;
						}
				}
			}
			@vary {/*dimensions}*/
				const {/*get}*/
					auto width ()
						{/*...}*/
							return right-left;
						}
					auto height ()
						{/*...}*/
							return top-bottom;
						}
					auto dimensions ()
						{/*...}*/
							return Vec(width, height);
						}
				}
				@vary {/*set}*/
					void width (T w)
						{/*...}*/
							auto Δw = w - this.width;
							this.left  = this.left  - Δw/2;
							this.right = this.right + Δw/2;
						}
					void height (T h)
						{/*...}*/
							auto Δh = h - this.height;
							this.top 	= this.top 	  + Δh/2;
							this.bottom = this.bottom - Δh/2;
						}
					void dimensions (Vec dims)
						{/*...}*/
							width = dims.x;
							height = dims.y;
						}
				}
			}
			const {/*tuples}*/
				auto vertex_tuple ()
					{/*...}*/
						alias v = verts;
						return τ(v[0], v[1], v[2], v[3]);
					}
				auto bounds_tuple ()
					{/*...}*/
						return τ(left, bottom, right, top);
					}
			}

			this (R)(R geometry)
				if (is_geometric!R && is (ElementType!R == Vec))
				in {/*...}*/
					assert (geometry.length > 1);
				}
				body {/*...}*/
					auto result = geometry.reduce!(
						(a,b) => Vec(min (a.x, b.x), min (a.y, b.y)),
						(a,b) => Vec(max (a.x, b.x), max (a.y, b.y))
					);
					Vec low_left = result[0];
					Vec hi_right = result[1];

					Vec dims = (low_left - hi_right).abs;
					verts[] = [low_left, low_left + Vec(dims.x, zero!T), hi_right, low_left + Vec(zero!T, dims.y)];
				}

			private:
			private {/*defs}*/
				alias Vec = Vector!(2, T);
			}
			private {/*range}*/
				@property auto length () const
					{/*...}*/
						return verts.length;
					}

				private Vec[4] verts;

				mixin ArrayInterface!(verts, length);
			}
		}
		unittest {/*...}*/
			import evx.analysis: all_approx_equal;

			auto box = bounding_box (circle (1));

			assert (all_approx_equal (box.upper_left, box.top_left, box.hi_left));
			assert (all_approx_equal (box.upper_right, box.top_right, box.hi_right));

			assert (all_approx_equal (box.lower_left, box.bottom_left, box.lo_left));
			assert (all_approx_equal (box.lower_right, box.bottom_right, box.lo_right));

			assert (box.left.approx (-1));
			assert (box.right.approx (1));
			assert (box.top.approx (1));
			assert (box.bottom.approx (-1));

			assert (box.width.approx (2));
			assert (box.height.approx (2));

			box.left = 0.0;
			assert (box.left == 0.0);

			box.right = 0.1;
			assert (box.right == 0.1);

			box.top = 100;
			assert (box.top == 100);

			box.bottom = -100;
			assert (box.bottom == -100);

			assert (box.width.approx (0.1));
			assert (box.height.approx (200));
		}

	/* compute the bounding box of a polygon 
	*/
	auto bounding_box (T)(auto ref T geometry)
		if (is_geometric!T)
		in {/*...}*/
			assert (geometry.length > 1);
		}
		body {/*...}*/
			static if (is (T == Box!U, U))
				return geometry;
			else return Box!(ElementType!(ElementType!T)) (geometry);
		}

	/* enum to specify a bounding box alignment 
	*/
	enum Alignment 
		{/*...}*/
			top_left,		top_center, 	top_right,
			center_left, 	center, 		center_right,
			bottom_left,	bottom_center,	bottom_right
		}

	/* compute the offset from a point in one bounding box to the corresponding point in another 
	*/
	auto offset_to (T)(Box!T from, Alignment alignment, Box!T to)
		{/*...}*/
			const string enumerate_alignment_cases ()
				{/*...}*/
					string code;

					foreach (position; EnumMembers!Alignment)
						{/*...}*/
							immutable pos = position.text;

							code ~= q{
								case } ~pos~ q{: return to.} ~pos~ q{ - from.} ~pos~ q{;
							};
						}

					return code;
				}

			final switch (alignment)
				{/*...}*/
					with (Alignment) 
						mixin(enumerate_alignment_cases);
				}
		}
		unittest {/*...}*/
			auto compute_offset (Alignment alignment) pure nothrow
				{return circle (1).bounding_box.offset_to (alignment, circle (2).bounding_box);}
			
			with (Alignment)
				{/*...}*/
					assert (compute_offset (center) 		==	0.vec);
					assert (compute_offset (top_right) 		== 	1.vec);
					assert (compute_offset (bottom_left) 	== -1.vec);

					assert (compute_offset (center_right) 	== 	î.vec);
					assert (compute_offset (top_center) 	== 	ĵ.vec);
					assert (compute_offset (center_left) 	== -î.vec);
					assert (compute_offset (bottom_center) 	== -ĵ.vec);
				}
		}

	/* moves a bounding box so that a given alignment point on it has the given position 
	*/
	auto move_to (T)(ref Box!T box, Alignment alignment, Vector!(2, T) position)
		{/*...}*/
			immutable offset = box.offset_to (alignment, bounding_box(position.repeat (2)));

			return box.verts[].map!(v => v + offset).copy (box.verts[]);
		}
		unittest {/*...}*/
			auto a = square (1).bounding_box;

			assert (a.center.approx (0.vec));

			a.move_to (Alignment.center, ĵ.vec);
			assert (a.center.approx (ĵ.vec));

			a.move_to (Alignment.top_center, ĵ.vec);
			assert (a.center.approx (ĵ.vec / 2));
			assert (a.bottom_center.approx (0.vec));

			a.move_to (Alignment.top_right, 1.vec);
			assert (a.bottom_left.approx (0.vec));
		}

	/* scale and translate the inner polygon to fit inside the outer polygon's bounding box 
	*/
	auto into_bounding_box_of (T1, T2)(auto ref T1 inner, auto ref T2 outer)
		if (allSatisfy!(is_geometric, T1, T2))
		{/*...}*/
			immutable interior = inner.bounding_box,
				 exterior = outer.bounding_box;
			immutable in_c = interior.center, 
				 ex_c = exterior.center;
			immutable s = exterior.dimensions / interior.dimensions;

			return inner[].map!(v => (v - in_c) * s + ex_c);
		}
		unittest {/*...}*/
			auto a = square (1);
			auto b = square (0.5).map!(v => v * vec(2.0, 1.0));

			auto c = a.into_bounding_box_of (b);

			assert (c.bounding_box.width.approx (1.0));
			assert (c.bounding_box.height.approx (0.5));
		}

	unittest {/*with evx.units}*/
		import evx.units;

		alias Pos = Vector!(2, Meters);

		auto box = [Pos(0.meters, 1.meter), Pos(1.meter, 0.meters)].bounding_box;

		assert (box.top_left == Pos(0.meters, 1.meter));
		assert (box.bottom_right == Pos(1.meter, 0.meters));

		assert (box.center == Pos(0.5.meters, 0.5.meters));

		auto compute_offset (Alignment alignment) pure nothrow
			{return circle (1.meter).bounding_box.offset_to (alignment, circle (2.meters).bounding_box);}
		
		with (Alignment)
			{/*...}*/
				assert (compute_offset (center) 		==	zero!Pos);
				assert (compute_offset (top_right) 		== 	unity!Pos);
				assert (compute_offset (bottom_left) 	==  -unity!Pos);
			}
	}
}
