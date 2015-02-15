module evx.math.geometry.aabb;

private {/*imports}*/
	import std.conv;
	import std.traits;

	import evx.math.geometry.traits;
	import evx.math.geometry.vectors;

	import evx.operators;
	import evx.range;

	import evx.math.algebra;
	import evx.math.intervals;
	import evx.math.functional;
	import evx.math.vector;
	import evx.math.ordinal;
	import evx.math.overloads;
	import evx.math.logic;

	import evx.misc.tuple;
}

/* an axis-aligned bounding box 
*/
struct Box (T)
	{/*...}*/
		public:
		@property {/*}*/
			public {/*corners}*/
				Vec opDispatch (string op)()
					if (op.contains (`left`, `center`, `right`))
					{/*...}*/
						immutable upper = τ(`upper`, `top`, `hi`);
						immutable lower = τ(`lower`, `bottom`, `lo`);

						immutable center 	= [0,1,2,3];
						immutable left 		= [0,3];
						immutable right 	= [1,2];
						immutable hi 		= [2,3];
						immutable low	 	= [0,1];

						static if (op.contains (`left`))
							immutable horizontal = left;
						else static if (op.contains (`right`))
							immutable horizontal = right;
						else static if (op.contains (`center`))
							immutable horizontal = center;
						else pragma (msg, `Error: Box.`~op~` failed to compile`);


						static if (op.contains (upper.expand))
							immutable vertical = hi;
						else static if (op.contains (lower.expand))
							immutable vertical = low;
						else static if (op.contains (`center`))
							immutable vertical = center;
						else pragma (msg, `Error: Box.`~op~` failed to compile`);

						auto length = 0;
						auto requested_point = zero!Vec;

						foreach (i; std.algorithm.setIntersection (horizontal, vertical))
							{/*...}*/
								++length;
								requested_point += verts[i];
							}

						return requested_point / length;
					}
			}
			public {/*extents}*/
				public {/*get}*/
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
				public {/*set}*/
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
							assert (y > bottom,
								`bounding box exceeded bounds (` ~y.text~ ` <= ` ~bottom.text~ `)`
							);
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
			public {/*dimensions}*/
				public {/*get}*/
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
				public {/*set}*/
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
			public {/*tuples}*/
				auto corners ()
					{/*...}*/
						alias v = verts;
						return τ(v[0], v[1], v[2], v[3]);
					}
				auto extents ()
					{/*...}*/
						return τ(left, bottom, right, top);
					}
			}
		}
		public {/*affine transform}*/
			auto ref translate ()(Vec Δv)
				{/*...}*/
					this[] = this[].map!(v => v + Δv);

					return this;
				}
			auto ref scale ()(T s)
				{/*...}*/
					immutable c = this.center;

					this[] = this[].map!(v => (v - c) * s + c);

					return this;
				}
		}
		public {/*ctor}*/
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

					Vec dims = (low_left - hi_right).each!abs;
					verts[] = [low_left, low_left + Vec(dims.x, zero!T), hi_right, low_left + Vec(zero!T, dims.y)];
				}
		}
		private:
		private {/*defs}*/
			alias Vec = Vector!(2, T);

			enum size_t n_verts = 4;
			Vec[n_verts] verts;

			void pull (R)(R range, size_t[2] interval)
				{/*...}*/
					auto i = interval.left, j = interval.right;

					foreach (k; i..j)
						verts[k] = range[k-i];
				}
			Vec access (size_t i)
				{/*...}*/
					return verts[i];
				}
		}

		public mixin TransferOps!(pull, access, n_verts, RangeOps);
	}
	unittest {/*...}*/
		import evx.math;//		import evx.math.geometry.polygons;
		import evx.math;//		import evx.math.floatingpoint;

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
alias BoundingBox = Box!double;

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
auto offset_to (T,U)(Box!T from, Alignment alignment, Box!U to)
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
		import evx.math;//		import evx.math.geometry.polygons;

		auto compute_offset (Alignment alignment)
			{return circle (1).bounding_box.offset_to (alignment, circle (2).bounding_box);}
		
		with (Alignment)
			{/*...}*/
				assert (compute_offset (center) 		==	0.vec);
				assert (compute_offset (top_right) 		== 	1.vec);
				assert (compute_offset (bottom_left) 	== -1.vec);

				assert (compute_offset (center_right) 	== 	î!vec);
				assert (compute_offset (top_center) 	== 	ĵ!vec);
				assert (compute_offset (center_left) 	== -î!vec);
				assert (compute_offset (bottom_center) 	== -ĵ!vec);
			}
	}

/* moves a bounding box so that a given alignment point on it has the given position 
*/
auto align_to (T)(Box!T box, Alignment alignment, Vector!(2, T) position)
	{/*...}*/
		auto offset = box.offset_to (alignment, bounding_box (position.repeat (2)));

		return box.verts[].map!(v => v + offset).bounding_box;
	}
	unittest {/*...}*/
		import evx.math;

		auto a = square (1.0).bounding_box;

		assert (a.center.approx (0.vec));

		a = a.align_to (Alignment.center, ĵ!vec);
		assert (a.center.approx (ĵ!vec));

		a = a.align_to (Alignment.top_center, ĵ!vec);
		assert (a.center.approx (ĵ!vec / 2));
		assert (a.bottom_center.approx (0.vec));

		a = a.align_to (Alignment.top_right, 1.vec);
		assert (a.bottom_left.approx (0.vec));
	}

/* scale and translate the inner polygon to fit inside the outer polygon's bounding box 
*/
auto into_bounding_box_of (R,S)(auto ref R inner, auto ref S outer)
	if (All!(is_geometric, R,S))
	{/*...}*/
		auto interior = inner.bounding_box,
			 exterior = outer.bounding_box;
		auto in_c = interior.center,
			 ex_c = exterior.center;
		auto s = exterior.dimensions / interior.dimensions;

		return inner.map!(v => (v - in_c) * s + ex_c);
	}
	unittest {/*...}*/
		import evx.math;

		auto a = square (1.0);
		auto b = square (0.5).map!(v => v * vec(2.0, 1.0));

		auto c = a.into_bounding_box_of (b);

		assert (c.bounding_box.width.approx (1.0));
		assert (c.bounding_box.height.approx (0.5));
	}

static if (__traits(compiles, {import evx.math.units;}))
	version (X86_64) unittest {/*with units}*/
		import evx.math;
		import evx.math.units;

		alias Pos = Vector!(2, Meters);

		auto box = [Pos(0.meters, 1.meter), Pos(1.meter, 0.meters)].bounding_box;

		assert (box.top_left == Pos(0.meters, 1.meter));
		assert (box.bottom_right == Pos(1.meter, 0.meters));

		assert (box.center == Pos(0.5.meters, 0.5.meters));

		auto compute_offset (Alignment alignment)
			{return circle (1.meter).bounding_box.offset_to (alignment, circle (2.meters).bounding_box);}
		
		with (Alignment)
			{/*...}*/
				assert (compute_offset (center) 		==	zero!Pos);
				assert (compute_offset (top_right) 		== 	unity!Pos);
				assert (compute_offset (bottom_left) 	==  -unity!Pos);
			}
	}
