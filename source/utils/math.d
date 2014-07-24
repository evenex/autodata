import std.algorithm;
import std.traits;
import std.range;
import std.math;
import std.mathspecial;
import utils;

public {/*constants}*/
	alias π = PI;
	alias e = E;
}
public {/*logic}*/
	/* (¬(a < b || b < a) ⇒ a == b) */
	bool antisymmetrically_equivalent (alias cmp, T,U)(inout T a, inout U b)
		if (__traits(compiles, cmp (a, b)))
		{/*...}*/
			return not (cmp (a,b) || cmp (b,a));
		}
	bool antisymmetrically_equivalent (T,U)(inout T a, inout U b)
		if (__traits(compiles, a < b))
		{/*...}*/
			return not (a < b || b < a);
		}
	bool less_than (T)(inout T a, inout T b) nothrow
		{/*...}*/
			return a < b;
		}
}
public {/*arithmetic}*/
	/* get an array of natural numbers from 0 to max-1 */
	auto ℕ (uint max)()
		{/*↓}*/
			return ℕ (max);
		}
	auto ℕ (T)(T count)
		if (isIntegral!T)
		{/*...}*/
			return sequence!((i,n) => i[0]+n)(0)
				.map!(n => cast(T)n)
				.take (count.to!size_t);
		}
	/* compute the product of a sequence */
	auto Π (T)(T sequence)
		{/*...}*/
			return sequence.reduce!((Π,x) => Π*x);
		}
	/* compute the sum of a sequence */
	auto Σ (T)(T sequence)
		{/*...}*/
			return sequence.sum;
		}
	auto sum (T)(T sequence)
		{/*...}*/
			return sequence.reduce!((Σ,x) => Σ+x);
		}
}
public {/*combinatorics}*/
	auto factorial (T)(T n)
		if (isIntegral!T)
		{/*...}*/
			pure static real fac (real n)
				{/*...}*/
					if (n <= 1) return 1;
					else return n*fac (n-1);
				}
			return std.functional.memoize!fac (n);
		}
	auto binomial (T1, T2)(T1 n, T2 k)
		if (allSatisfy!(isIntegral, TypeTuple!(T1, T2)))
		{/*...}*/
			return n.factorial / (k.factorial * (n-k).factorial);
		}
	alias choose = binomial;
}
public {/*probability}*/
	/* sample a gaussian distribution */
	auto gaussian ()
		{/*...}*/
			import std.mathspecial;
			import std.random;
			return normalDistributionInverse (uniform (0.0, 1.0));
		}
}
public {/*statistics}*/
	/* compute the mean value over a set */
	auto mean (T)(T set)
		{/*...}*/
			auto n = set.length;
			return set.sum/n;
		}
	/* compute the standard deviation of a value over a set */
	auto std_dev (T)(T set)
		{/*...}*/
			return set.std_dev (set.mean);
		}
	/* supplying a precomputed mean will accelerate the calculation */
	auto std_dev (T, E_T = T.ElementType)(T set, E_T mean)
		{/*...}*/
			alias μ = mean;
			return sqrt (set.map!(x => (x-μ)^^2).mean);
		}
}
public {/*analysis}*/
	/* compute the derivative of f at x */
	real derivative (alias f, real Δx = 0.01)(real x)
		if (isCallable!f)
		{/*...}*/
			return (f(x)-f(x-Δx))/Δx;
		}
	/* test if t0 <= t <= t1 */
	bool between (T, T0, T1) (T t, T0 t0, T1 t1) 
		{/*...}*/
			return t0 <= t && t <= t1;
		}
	/* clamp a value between two other values */
	auto clamp (T1, T2, T3)(T1 value, T2 min, T3 max)
		{/*...}*/
			value = value < min? min: value;
			value = value > max? max: value;
			return value;
		}
	/* intervals TODO */
	struct Interval (Index)
		{/*...}*/
			Index start;
			Index end;
			@property size () const
				{/*...}*/
					return end - start;
				}
			@property empty () const
				{/*...}*/
					return not (end - start);
				}
		}
	alias Index = size_t; // REFACTOR these are discrete numbers, they don't belong in analysis
	alias Indices = Interval!Index;
	bool ends_before_end (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.end < b.end;
		}
	bool ends_before_start (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.end < b.start;
		}
	bool starts_before_end (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.start < b.end;
		}
	bool starts_before_start (T)(Interval!T a, Interval!T b)
		{/*...}*/
			return a.start < b.start;
		}
	/* tag a floating point value as only holding values between -1.0 and 1.0 */
	struct Normalized {}
	/* ensure that values tagged Normalized are between -1.0 and 1.0 */
	mixin template NormalizedInvariance ()
		{/*...}*/
			invariant ()
				{/*...}*/
					alias This = typeof(this);

					foreach (member; __traits(allMembers, This))
						static if (has_attribute!(This, member, Normalized))
							mixin(q{assert (}~member~q{.between (-1.0, 1.0), member~` is not normalized (value `~}~member~q{.to!string~`)`);});
				}
		}
}
public {/*2D geometry}*/
	/* test if a type can be used by this library */
	const bool is_geometric (T)()
		{/*...}*/
			return __traits(compiles, 0.vec + T.init.reduce!((a,b) => a+b));
		}
	public {/*vectors}*/
		// TODO bring Vec2 and Units into compatibility
		/* test if a type can be used as a vector */
		const bool is_vector (T)()
			{/*...}*/
				const T vector = T.init;
				return __traits(compiles, (-vector.x + vector.y - vector.x) * vector.x / vector.y / vector.x * vector.y);
			}
		struct Vec2 (T)
			{/*...}*/
				static assert (is_vector!Vec2);

				import std.math;
				public:
				struct {T x, y;}
				@property {/*}*/
					T norm (uint p = 2)() pure
						if (isFloatingPoint!T)
						{/*...}*/
							return (x^^p + y^^p) ^^ (1.0/p);
						}
					Vec2 unit ()() pure
						if (isFloatingPoint!T)
						{/*...}*/
							if (norm == 0)
								return vec(0);
							else return vec(x/norm, y/norm);
						}
					Vec2 abs () pure
						{/*...}*/
							import std.math;
							return Vec2(x.abs, y.abs);
						}
					T min () pure
						{/*...}*/
							return std.algorithm.min (x, y);
						}
					T max () pure
						{/*...}*/
							return std.algorithm.max (x, y);
						}
				}
				public {/*ops}*/
					auto det (Vec2 v) pure
						{/*...}*/
							return x*v.y - y*v.x;
						}
					auto dot (Vec2 v) pure
						{/*...}*/
							return x*v.x + y*v.y;
						}
					Vec2 proj ()(Vec2 v) pure
						if (isFloatingPoint!T)
						{/*...}*/
							return this.dot (v.unit) * v.unit;
						}
					Vec2 rej ()(Vec2 v) pure
						if (isFloatingPoint!T)
						{/*...}*/
							return this - this.proj (v);
						}
					bool approx (U)(U rhs)
						if (is_vector!U)
						{/*...}*/
							return x.approxEqual (rhs.x) && y.approxEqual (rhs.y);
						}
					Vec2 opUnary (string op) () pure
						{/*...}*/
							mixin(`return Vec2 (`~op~`x, `~op~`y);`);
						}
					Vec2 opBinary (string op, U) (U rhs) pure
						{/*...}*/
							Vec2 ret = this;
							mixin(`ret `~op~`= rhs;`);
							return ret;
						}
					Vec2 opBinaryRight (string op, U) (U lhs) pure
						{/*...}*/
							static if (is_vector!U)
								mixin(q{return vec(lhs) }~op~q{ this;});
							else mixin(q{return this }~op~q{ lhs;});
						}
					Vec2 opOpAssign (string op, U) (U rhs) pure
						{/*...}*/
							static if (is_vector!U)
								{/*...}*/
									mixin(`x`~op~`= rhs.x;`);
									mixin(`y`~op~`= rhs.y;`);
									return this;
								}
							else static if (is (U: T))
								{/*...}*/
									mixin(`x`~op~`= rhs;`);
									mixin(`y`~op~`= rhs;`);
									return this;
								}
							else static assert (null, `incompatible types for operation: `
								~Vec2.stringof~` `~op~` `~U.stringof
							);
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
				public {/*misc}*/
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
					auto toString ()
						{/*...}*/
							import std.conv;
							return `Vec2!(` ~T.stringof~ `)(` ~x.text~ `, ` ~y.text~ `)`;
						}
				}
				public {/*☀}*/
					this (U)(U that)
						{/*...}*/
							static if (is_vector!U)
								{/*...}*/
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
			}
		alias vec  = Vec2!float;
		alias ivec = Vec2!int;
		alias uvec = Vec2!uint;
		/* basis vectors */
		alias î = Aⁿ!(1,0);
		alias ĵ = Aⁿ!(0,1);
		/* rotate a vector */
		vec rotate (vec v, float θ) 
			{/*...}*/
				return vec(cos(θ)*v.x-sin(θ)*v.y,  sin(θ)*v.x+cos(θ)*v.y);
			}
		/* compute the angular difference between two vectors */
		auto bearing_to (vec a, vec b)
			{/*...}*/
				auto δ = b-a;
				auto θ = acos (δ.unit.dot (î.vec));
				if (δ.y < 0.0)
					θ *= -1;
				return θ;
			}
		/* compute the distance between two points */
		float distance (vec a, vec b)
			{/*...}*/
				return (a-b).norm;
			}
	}
	public {/*polygons}*/
		/* generators */
		auto square (float side = 1.0, vec center = vec(0))
			in {/*...}*/
				assert (side > 0.0);
			}
			body {/*...}*/
				return [vec(1,1), vec(-1,1), vec(-1,-1), vec(1,-1)]
					.map!(v => v*side/2 + center);
			}
		auto circle (uint samples = 24) (float radius = 1.0, vec center = vec(0))
			in {/*...}*/
				assert (radius > 0.0, "circle radius must be positive");
			}
			body {/*...}*/
				return ℕ!samples.map!(i => 2*π*i/samples)
					.map!(t => vec(cos(t), sin(t)))
					.map!(v => radius*v + center);
			}
		/* get the distance of a polygon's furthest point from its centroid */
		auto radius (T)(T geometry)
			if (is_geometric!T)
			{/*...}*/
				 auto c = geometry.mean;
				 return geometry.map!(v => (v-c).norm).reduce!max;
			}
		/* get the area of a polygon */
		auto area (R)(R polygon)
			if (is_geometric!R)
			{/*...}*/
				return 0.5 * abs (Σ (polygon.adjacent_pairs.map!(v => v[0].det (v[1]))));
			}
		/* reflect a polygon over a "direction" axis passing through its centroid */
		auto flip (string direction, T)(T geometry)
			if (is_geometric!T && (direction == `vertical` || direction == `horizontal`))
			{/*...}*/
				auto c = geometry.mean;

				static if (direction == `vertical`)
					auto p = ElementType!T(1,-1);
				else auto p = ElementType!T(-1,1);

				return geometry.map!(v => (v-c)*p+c);
			}
		/* translate a polygon by a vector */
		auto translate (T)(T geometry, vec Δv)
			if (is_geometric!T)
			{/*...}*/
				return geometry.map!(v => v + Δv);
			}
		/* rotate a polygon about its centroid */
		auto rotate (T)(T geometry, float θ)
			if (is_geometric!T)
			{/*...}*/
				auto c = geometry.mean;
				return geometry.map!(v => (v-c).rotate (θ) + c);
			}
		/* scale a polygon without moving its centroid */
		auto scale (T1, T2)(T1 geometry, T2 scale)
			if (is_geometric!T1 && __traits(compiles, geometry.front * scale))
			{/*...}*/
				auto c = geometry.mean;
				return geometry.map!(v => (v-c)*scale + c);
			}
	}
	public {/*axis-aligned bounding boxes}*/
		/* an axis-aligned bounding box */
		struct Box
			{/*...}*/
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
						void left (float x)
							{/*...}*/
								verts[0].x = x;
								verts[3].x = x;
							}
						void right (float x)
							{/*...}*/
								verts[1].x = x;
								verts[2].x = x;
							}
						void top (float y)
							{/*...}*/
								verts[2].y = y;
								verts[3].y = y;
							}
						void bottom (float y)
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
						void width (float w)
							{/*...}*/
								auto Δw = w - this.width;
								this.left  = this.left  - Δw/2;
								this.right = this.right + Δw/2;
							}
						void height (float h)
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
							auto c = this.mean;
							return verts[].map!(v => v-c+x).copy (verts[]);
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
						verts[] = [low_left, low_left + vec(dims.x,0), hi_right, low_left + vec(0,dims.y)];
					}
				@property {/*input range}*/
					auto popFront ()
						{/*...}*/
							++iterator;
						}
					auto front ()
						{/*...}*/
							return verts[iterator];
						}
					auto empty ()
						{/*...}*/
							if (length == 0)
								{/*...}*/
									iterator = 0;
									return true;
								}
							else return false;
						}
					auto length ()
						{/*...}*/
							return 4 - iterator;
						}
				}

				private {/*...}*/
					vec[4] verts;
					size_t iterator;
				}
			}
		/* compute the bounding box of a polygon */
		auto bounding_box (T)(T geometry)
			if (is_geometric!T)
			in {/*...}*/
				assert (geometry.length > 1);
			}
			body {/*...}*/
				static if (is (T == Box))
					return geometry;
				else return Box (geometry);
			}
		/* enum to specify a bounding box alignment */
		enum Alignment {/*...}*/
			top_left,		top_center, 	top_right,
			center_left, 	center, 		center_right,
			bottom_left,	bottom_center,	bottom_right
		}
		/* scale a polygon so that its bounding box is equal to another's */
		auto in_bounding_box_of (T1, T2)(T1 inner, T2 outer)
			if (allSatisfy!(is_geometric, TypeTuple!(T1, T2)))
			{/*...}*/
				auto interior = inner.bounding_box,
					 exterior = outer.bounding_box;
				auto in_c = interior.mean, 
					 ex_c = exterior.mean;
				auto s = exterior.dimensions / interior.dimensions;
				return inner.map!(v => (v - in_c) * s + ex_c);
			}
	}
}
