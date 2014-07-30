module evx.geometry;

private {/*import std}*/
	import std.algorithm: 
		canFind,
		setIntersection;
	import std.traits: 
		isFloatingPoint, isIntegral, isUnsigned,
		Unqual, EnumMembers;
	import std.conv:
		to;
}
private {/*import evx}*/
	import evx.utils: 
		Aⁿ, τ, not;
	import evx.meta:
		ArrayInterface;
	import evx.math; // TEMP
}

void main (){
	import std.stdio;
			import std.exception:
				assertThrown;
			import std.range:
				ElementType;

			static void basic_type (Type)()
				{/*...}*/
					alias Vec = Vec2!Type;

					static assert (is (ElementType!Vec == Type));

					Vec a = Vec (î);			
					Vec b = Vec (ĵ);

					static if (isFloatingPoint!Type)
						{/*...}*/
							assert (a.norm == 1);
							assert (b.norm == 1);

							assert (a.unit == a);
							assert (b.unit == b);
						}

					assert (a.abs == a);
					assert (b.abs == b);

					assert (a.min == 0);
					assert (b.min == 0);

					assert (a.max == 1);
					assert (b.max == 1);

					static if (not (isUnsigned!Type))
						{/*...}*/
							assert (a.det (b) == 1);
							assert (b.det (a) == -1);
						}

					assert (a.dot (b) == 0);
					assert (b.dot (a) == 0);

					static if (isFloatingPoint!Type)
						{/*...}*/
							assert (a.proj (b) == Vec(0));
							assert (b.proj (a) == Vec(0));

							assert (a.rej (b) == a);
							assert (b.rej (a) == b);
						}

					assert (a.approx (a));
					assert (b.approx (b));

					assert (not (b.approx (a)));
					assert (not (a.approx (b)));

					static if (not (isUnsigned!Type))
						{/*...}*/
							assert (-a == Vec(-1, 0));
							assert (-b == Vec(0, -1));
						}
					
					assert (+a == a);
					assert (+b == b);

					assert (a + b == Vec(1));
					assert (b + a == Vec(1));

					static if (not (isUnsigned!Type))
						{/*...}*/
							assert (a - b == Vec(1,-1));
							assert (b - a == Vec(-1,1));
						}

					assert (a * b == Vec(0));
					assert (b * a == Vec(0));

					static if (isFloatingPoint!Type)
						{/*...}*/
							assert (a / b == Vec(infinity, 0));
							assert (b / a == Vec(0, infinity));
						}
					else static if (isIntegral!Type) 
						try {/*...}*/
							assertThrown!Error (a / b);
							assertThrown!Error (b / a);
						} catch (Exception) assert (0);
				}
			static void conversion (UpType, DownType)()
				{/*...}*/
					auto a = Vec2!UpType (î);
					
					assert (Vec2!DownType (a) == Vec2!DownType (î));
					assert (Vec2!DownType (a) == cast(Vec2!DownType) a);
				}

			{/*basic types}*/
				// floating point
				basic_type!real;
				basic_type!double;
				basic_type!float;

				// signed integral
				basic_type!long;
				basic_type!int;
				basic_type!short;
				basic_type!byte;

				// unsigned integral
				basic_type!ulong;
				basic_type!uint;
				basic_type!ushort;
				basic_type!ubyte;
			}
			{/*conversion}*/
				conversion!(double, float);
				conversion!(float, double);
				conversion!(real, float);

				static assert (not (__traits(compiles, conversion!(real, int))));
				conversion!(int, real);

				// cannot implicitly convert from signed to unsigned
				static assert (not (__traits(compiles, conversion!(int, uint))));
				// such conversion may be accomplished with a cast
				static assert (__traits(compiles, cast(Vec2!uint)(Vec2!int.init)));
				// unsigned to signed is ok
				conversion!(uint, int);

				static assert (not (__traits(compiles, conversion!(int, short))));
				conversion!(short, int);
			}
			{/*units}*/
				alias Position = Vec2!Meters;
				alias Velocity = Vec2!(typeof(meters/second));

				auto a = Position (3.meters, 4.meters);

				assert (2*a == Position (6.meters, 8.meters));
				assert (a*a == typeof(a*a)(9.meter*meters, 16.meter*meters));
				assert (a/a == 1.vec);

				assert (Velocity (10.meters/second, 7.meters/second) * 0.5.seconds == Position (5.meters, 3.5.meters));

				assert (a.norm == 5.meters);
				assert (a.unit == vec(0.6, 0.8));

				auto b = 12.meters * a.unit;

				try std.stdio.writeln (a.proj (b));
				catch (Throwable) assert (0);

				try std.stdio.writeln (a.norm * a.unit);
				catch (Throwable) assert (0);

				assert (a.proj (b).approx (a.norm * a.unit));
			}
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

			return __traits(compiles, 

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
	/* generic vector type 
	*/
	struct Vec2 (T)
		{/*...}*/
			struct {T x, y;}

			public nothrow:
			pure const @property {/*}*/
				T norm (uint p = 2)() 
					if (isFloatingPoint!T)
					{/*...}*/
						return (x^^p + y^^p) ^^ (1.0/p);
					}
				T norm (uint p = 2)() 
					if (is_Unit!T)
					{/*...}*/
						return T (vectorize (x/T(1), y/T(1)).norm!p);
					}
				Vec2 unit ()() 
					if (isFloatingPoint!T)
					{/*...}*/
						auto norm = this.norm;

						if (norm == 0)
							return Vec2(0);
						else return Vec2(x/norm, y/norm);
					}
				auto unit ()() 
					if (is_Unit!T)
					{/*...}*/
						auto norm = this.norm;

						if (norm != T(0))
							return vectorize (x/norm, y/norm);
						else return vectorize (0 * T(1)/T(1), 0 * T(1)/T(1));
					}
				Vec2 abs () 
					{/*...}*/
						return Vec2(x.abs, y.abs);
					}
				T min () 
					{/*...}*/
						return std.algorithm.min (x, y);
					}
				T max () 
					{/*...}*/
						return std.algorithm.max (x, y);
					}
				T front ()
					{/*...}*/
						return x;
					}
				T back ()
					{/*...}*/
						return y;
					}
			}
			pure const {/*geometry}*/
				auto det (V)(V v) 
					if (is_vector!V)
					{/*...}*/
						return x*v.y - y*v.x;
					}
				auto dot (V)(V v) 
					if (is_vector!V)
					{/*...}*/
						return x*v.x + y*v.y;
					}
				auto proj ()(Vec2 v) 
					if (isFloatingPoint!T || is_Unit!T)
					{/*...}*/
						return this.dot (v.unit) * v.unit;
					}
				auto rej ()(Vec2 v) 
					if (isFloatingPoint!T)
					{/*...}*/
						return this - this.proj (v);
					}
			}
			pure const {/*comparison}*/
				bool approx (U)(U rhs)
					if (is_vector!U)
					{/*...}*/
						return x.approxEqual (rhs.x) && y.approxEqual (rhs.y);
					}
				bool opEquals (U)(U that)
					if (is_vector!U)
					{/*...}*/
						return this.x == that.x && this.y == that.y;
					}
			}
			pure const {/*arithmetic}*/
				auto opUnary (string op)() 
					{/*...}*/
						mixin(q{
							return Vec2 (} ~op~ q{ x, } ~op~ q{y);
						});
					}
				auto opBinary (string op, U)(U rhs) 
					{/*...}*/
						static if (is_vector!U)
							{/*...}*/
								static if (op is `/` && isIntegral!T)
									assert (rhs.x * rhs.y != 0, `can't divide ` ~T.stringof~ ` by 0`);
									
								mixin(q{
									return vectorize (x } ~op~ q{ rhs.x, y } ~op~ q{ rhs.y);
								});
							}
						else static if (__traits(compiles, mixin(q{x } ~op~ q{ rhs})))
							{/*...}*/
								static if (op is `/` && isIntegral!T)
									assert (rhs != 0, `can't divide ` ~T.stringof~ `by 0`);

								mixin(q{
									return vectorize (x } ~op~ q{ rhs, y } ~op~ q{ rhs);
								});
							}
						else static assert (null, `incompatible types for operation: `
							~Vec2.stringof~` `~op~` `~U.stringof
						);
					}
				auto opBinaryRight (string op, U)(U lhs) 
					{/*...}*/
						static if (is_vector!U) mixin(q{
							return Vec2(lhs) } ~op~ q{ this;
						}); else mixin(q{
							return this } ~op~ q{ lhs;
						});
					}
			}
			pure const {/*conversion}*/
				U opCast (U)()
					{/*...}*/
						U ret;

						static if (__traits(compiles, ret.x == this.x))
							{/*...}*/
								ret.x = this.x;
								ret.y = this.y;
								return ret;
							}
						else static assert (null, `incompatible types for cast: `
							~Vec2.stringof~` to ` ~U.stringof
						);
					}
			}
			pure {/*assignment}*/
				Vec2 opOpAssign (string op, U) (U rhs) 
					{/*...}*/
						mixin(q{
							this = this } ~op~ q{ rhs;
						});

						return this;
					}
				Vec2 opAssign (U)(U rhs)
					{/*...}*/
						static if (is_vector!U)
							{/*...}*/
								this.x = rhs.x;
								this.y = rhs.y;
							}
						else static if (is (U:T))
							{/*...}*/
								this.x = rhs;
								this.y = rhs;
							}
						else static assert (null, `incompatible types for operation: `
							~Vec2.stringof~` = `~U.stringof
						);
						return this;
					}
			}
			pure {/*ctor}*/
				this (U)(U that)
					{/*...}*/
						static if (is_vector!U)
							{/*...}*/
								static if (isUnsigned!T)
									static assert (isUnsigned!(typeof(U.x)),
										`automatic conversion from signed to unsigned is disallowed`
									);

								this.x = that.x;
								this.y = that.y;

								return this;
							}
						else static assert (null, `incompatible type for construction: `
							~Vec2.stringof~` from `~U.stringof
						);
					}
				this (T x, T y)
					{/*...}*/
						this.x = x;
						this.y = y;
					}
				this (T s)
					{/*...}*/
						this.x = this.y = s;
					}
			}
			static assert (is_vector!Vec2);
		}
		unittest {/*demo}*/
			vec a = 1;
			vec b = 2;

			a += 1;
			assert (a == 2.vec);

			a += b;
			assert (a == 4.vec);

			a /= b;
			assert (a == 2.vec);

			a /= 2;
			assert (a == 1.vec);

			auto c = a + b;
			assert (c == 3.vec);
		}
		//unittest {/*...}*/

	/* common vector types 
	*/
	alias vec  = Vec2!double;
	alias fvec = Vec2!float;
	alias ivec = Vec2!int;
	alias uvec = Vec2!uint;

	/* convenience ctor 
	*/
	auto vectorize (T)(T x, T y)
		{/*...}*/
			return Vec2!(Unqual!T) (x,y);
		}

	/* standard basis vectors 
	*/
	alias î = Aⁿ!(1,0);
	alias ĵ = Aⁿ!(0,1);

	/* rotate a vector 
	*/
	auto rotate (Vec = vec, T = ElementType!Vec)(Vec v, T θ) 
		if (is (T == ElementType!Vec))
		{/*...}*/
			return Vec(cos(θ)*v.x-sin(θ)*v.y,  sin(θ)*v.x+cos(θ)*v.y);
		}

	/* compute the angular difference between two vectors 
	*/
	auto bearing_to (Vec = vec)(Vec a, Vec b)
		{/*...}*/
			auto δ = b-a;
			auto θ = acos (δ.unit.dot (î.Vec));
			if (δ.y < 0.0)
				θ *= -1;
			return θ;
		}
		unittest {/*TODO*/}

	/* compute the distance between two points 
	*/
	auto distance (Vec = vec)(Vec a, Vec b)
		{/*...}*/
			return (a-b).norm;
		}
}
public {/*polygons}*/
	/* shape generators 
	*/
	auto square (Vec = vec, T = ElementType!Vec)(T side = 1.0, Vec center = 0.Vec)
		if (is (T == ElementType!Vec))
		in {/*...}*/
			assert (side > 0.0);
		}
		body {/*...}*/
			return [vec(1,1), vec(-1,1), vec(-1,-1), vec(1,-1)]
				.map!(v => v*side/2 + center);
		}
	auto circle (uint samples = 24, Vec = vec, T = ElementType!Vec)(T radius = 1.0, Vec center = 0.Vec)
		if (is (T == ElementType!Vec))
		in {/*...}*/
			assert (radius > 0.0, "circle radius must be positive");
		}
		body {/*...}*/
			return ℕ!samples.map!(i => 2*π*i/samples)
				.map!(t => Vec(cos(t), sin(t)))
				.map!(v => radius*v + center);
		}

	/* get the distance of a polygon's furthest point from its centroid 
	*/
	auto radius (T)(T geometry)
		if (is_geometric!T)
		{/*...}*/
			 auto c = geometry.mean;
			 return geometry.map!(v => (v-c).norm).reduce!max;
		}

	/* get the area of a polygon 
	*/
	auto area (R)(R polygon)
		if (is_geometric!R)
		{/*...}*/
			return 0.5 * abs (Σ (polygon.adjacent_pairs.map!(v => v[0].det (v[1]))));
		}
		unittest {/*TODO*/}

	/* reflect a polygon over a "direction" axis passing through its centroid 
	*/
	auto flip (string direction, T)(T geometry)
		if (is_geometric!T && (direction == `vertical` || direction == `horizontal`))
		{/*...}*/
			auto c = geometry.mean;

			static if (direction == `vertical`)
				auto p = ElementType!T(1,-1);
			else auto p = ElementType!T(-1,1);

			return geometry.map!(v => (v-c)*p+c);
		}
		unittest {/*TODO*/}

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
			return geometry.map!(v => (v-c)*scale + c);
		}
}
public {/*axis-aligned bounding boxes}*/
	/* an axis-aligned bounding box 
	*/
	struct Box
		{/*...}*/
			pure nothrow:
			@property {/*corners}*/
				vec opDispatch (string op)()
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
						auto requested_point = 0.vec;
						foreach (i; setIntersection (horizontal, vertical))
							{/*...}*/
								++length;
								requested_point += verts[i];
							}

						return requested_point / length;
					}
			}
			@property {/*extents}*/
				@property {/*get}*/
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
				@property {/*set}*/
					void left (double x)
						{/*...}*/
							verts[0].x = x;
							verts[3].x = x;
						}
					void right (double x)
						{/*...}*/
							verts[1].x = x;
							verts[2].x = x;
						}
					void top (double y)
						{/*...}*/
							verts[2].y = y;
							verts[3].y = y;
						}
					void bottom (double y)
						{/*...}*/
							verts[0].y = y;
							verts[1].y = y;
						}
				}
			}
			@property {/*dimensions}*/
				@property {/*get}*/
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
							return vec(width, height);
						}
				}
				@property {/*set}*/
					void width (double w)
						{/*...}*/
							auto Δw = w - this.width;
							this.left  = this.left  - Δw/2;
							this.right = this.right + Δw/2;
						}
					void height (double h)
						{/*...}*/
							auto Δh = h - this.height;
							this.top 	= this.top 	  + Δh/2;
							this.bottom = this.bottom - Δh/2;
						}
					void dimensions (vec dims)
						{/*...}*/
							width = dims.x;
							height = dims.y;
						}
				}
			}
			@property {/*alignment}*/
				vec offset_to (Alignment alignment, Box outer)
					{/*...}*/
						const string enumerate_alignment_cases ()
							{/*...}*/
								alias AlignEnum = typeof(Alignment.center);

								string code;
								foreach (position; EnumMembers!AlignEnum)
									{/*...}*/
										const pos = position.to!string;
										code ~= q{case }~pos~q{: return outer.}~pos~q{ - this.}~pos~q{;};
									}

								return code;
							}

						final switch (alignment)
							{/*...}*/
								with (Alignment) 
									mixin(enumerate_alignment_cases);
							}
					}
				auto move_to (vec x)
					{/*...}*/
						auto c = verts[].mean;
						return verts[].map!(v => v-c+x).copy (verts[]);
					}
			}
			@property {/*tuples}*/
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

			this (T)(T geometry)
				if (is_geometric!T)
				{/*...}*/
					auto result = geometry.reduce!(
						(a,b) => vec(min (a.x, b.x), min (a.y, b.y)),
						(a,b) => vec(max (a.x, b.x), max (a.y, b.y))
					);
					vec low_left = result[0];
					vec hi_right = result[1];

					vec dims = (low_left - hi_right).abs;
					verts[] = [low_left, low_left + vec(dims.x,0), hi_right, low_left + vec(0,dims.y)]; // REVIEW can i assign to a range this way? is it faster or slower than std.algo.copy?
				}

			private {/*range}*/
				@property auto length () const
					{/*...}*/
						return verts.length;
					}
				private vec[4] verts;
				mixin ArrayInterface!(verts, length);
			}
		}
		unittest {/*TODO*/}

	/* compute the bounding box of a polygon 
	*/
	auto bounding_box (T)(auto ref T geometry)
		if (is_geometric!T)
		in {/*...}*/
			assert (geometry.length > 1);
		}
		body {/*...}*/
			static if (is (T == Box))
				return geometry;
			else return Box (geometry);
		}

	/* enum to specify a bounding box alignment 
	*/
	enum Alignment 
		{/*...}*/
			top_left,		top_center, 	top_right,
			center_left, 	center, 		center_right,
			bottom_left,	bottom_center,	bottom_right
		}

	/* scale and translate the inner polygon to fit inside the outer polygon's bounding box 
	*/
	auto into_bounding_box_of (T1, T2)(auto ref T1 inner, auto ref T2 outer)
		if (allSatisfy!(is_geometric, T1, T2))
		{/*...}*/
			auto interior = inner.bounding_box,
				 exterior = outer.bounding_box;
			auto in_c = interior.mean, 
				 ex_c = exterior.mean;
			auto s = exterior.dimensions / interior.dimensions;
			return inner.map!(v => (v - in_c) * s + ex_c);
		}
}
