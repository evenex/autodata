module evx.math.geometry.aabb;

private {/*imports}*/
	import std.algorithm;
	import std.conv;
	import std.range;
	import std.traits;

	import evx.math.geometry.traits;
	import evx.math.geometry.vectors;
	import evx.math.units.overloads;

	import evx.operators.transfer;

	import evx.math.algebra;
	import evx.math.functional;
	import evx.math.analysis;

	import evx.misc.tuple;

	mixin(FunctionalToolkit!());
}

/* an axis-aligned bounding box 
*/
struct Box (T)
	{/*...}*/
		public:
		@property {/*}*/
			public {/*corners}*/
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

			Vec[4] verts;

			mixin TransferOps!verts;
		}
	}
	unittest {/*...}*/
		import evx.math.analysis: all_approx_equal;
		import evx.math.geometry.polygons;

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
		import evx.math.geometry.polygons;

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
		auto offset = box.offset_to (alignment, bounding_box (position.repeat (2))); // BUG this was immutable... but we can't have immutable anymore... this really sucks!!!

		return box.verts[].map!(v => v + offset).bounding_box;
	}
	unittest {/*...}*/
		import evx.math.geometry.polygons;

		auto a = square (1).bounding_box;

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
auto into_bounding_box_of (T1, T2)(auto ref T1 inner, auto ref T2 outer)
	if (allSatisfy!(is_geometric, T1, T2))
	{/*...}*/
		auto interior = inner.bounding_box, // BUG was immutable
			 exterior = outer.bounding_box;
		auto in_c = interior.center,  // BUG was immutable
			 ex_c = exterior.center;
		auto s = exterior.dimensions / interior.dimensions; // BUG was immutable

		return inner.map!(v => (v - in_c) * s + ex_c); // REVIEW [] operator for priming ranges
	}
	unittest {/*...}*/
		import evx.math.geometry.polygons;
		mixin(FunctionalToolkit!());

		auto a = square (1);
		auto b = square (0.5).map!(v => v * vec(2.0, 1.0));

		auto c = a.into_bounding_box_of (b);

		assert (c.bounding_box.width.approx (1.0));
		assert (c.bounding_box.height.approx (0.5));
	}

version (X86_64) unittest {/*with units}*/
	import evx.math.units;
	import evx.math.geometry.polygons;

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
