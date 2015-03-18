module autodata.spaces.vector;

private {/*import}*/
	import std.conv: to, text;
	import std.range.primitives: empty;
	import std.algorithm: count_until = countUntil;
	import std.range: join;
	import autodata.core;
	import autodata.meta;
}

/* convenience constructors 
*/
template vector ()
	{/*...}*/
		auto vector (V)(V v)
			{/*...}*/
				static if (is (V : Vector!(n,T), T, size_t n))
					{/*...}*/
						return v;
					}
				else static if (is (V : T[n], T, size_t n))
					{/*...}*/
						return Vector!(n,T)(v);
					}
				else static if (is (typeof(v.tupleof) == T, T))
					{/*...}*/
						return Vector!(T.length, CommonType!T)(v.tupleof);
					}
				else static assert (0, `cannot construct vector from ` ~V.stringof);
			}
		auto vector (T...)(T args)
			{/*...}*/
				return Vector!(T.length, CommonType!T)(args);
			}
	}
template vector (size_t n)
	{/*...}*/
		auto vector (V)(V v)
			{/*...}*/
				static if (is (V : Vector!(n,T), T))
					{/*...}*/
						return v;
					}
				else static if (is (V : T[n], T))
					{/*...}*/
						return Vector!(n,T)(v);
					}
				else static if (not (is (ElementType!V == void)))
					{/*...}*/
						return Vector!(n, ElementType!V)(v);
					}
				else static if (is (typeof(v + v * v)))
					{/*...}*/
						return Vector!(n,V)(v);
					}
				else static if (is (typeof(v.tupleof) == T, T))
					{/*...}*/
						return Vector!(n, CommonType!T)(v.tupleof);
					}
				else static assert (0, `cannot construct vector from ` ~V.stringof);
			}
		auto vector (T...)(T args)
			{/*...}*/
				return Vector!(n, CommonType!T)(args);
			}
	}

/* componentwise map to a new vector 
*/
auto each (alias f, V, Args...)(V v, Args args)
	if (is (V == Vector!(n,T), size_t n, T))
	{/*...}*/
		Vector!(V.length, typeof(f (v[0], args))) mapped;

		foreach (i; Iota!(V.length))
			mapped[i] = f(v[i], args);

		return mapped;
	}

/* generic vector type with space and algebraic operators 
*/
struct Vector (size_t n, Component = double)
	{/*...}*/
		enum length = n;

		Unqual!Component[n] components;
		alias components this;
		@disable Component front ();

		auto opUnary (string op)()
			{/*...}*/
				static if (op.length == 1)
					{/*...}*/
						static if (op == `+`)
							return this;
						else {/*...}*/
							Vector ret;

							mixin(q{
								ret.components[] = } ~op~ q{ this.components[];
							});

							return ret;
						}
					}
				else static if (op.length == 2)
					{/*...}*/
						mixin(q{
							} ~op~ q{ this.components[];
						});

						return this;
					}
				else static assert (0);
			}
		auto opBinary (string op, V)(V v)
			{/*...}*/
				auto lhs = this;
				auto rhs = v.vector!n;

				alias T = typeof(mixin(q{lhs[0] } ~op~ q{ rhs[0]}));
				Vector!(n,T) ret;

				foreach (i; Iota!n)
					mixin(q{
						ret[i] = lhs[i] } ~op~ q{ rhs[i];
					});

				return ret;
			}
		auto opBinaryRight (string op, V)(V v)
			{/*...}*/
				auto lhs = v.vector!n;
				auto rhs = this;

				mixin(q{
					return lhs } ~op~ q{ rhs;
				});
			}
		auto ref opOpAssign (string op, V)(V v)
			{/*...}*/
				mixin(q{
					this = this } ~op~ q{ v;
				});

				return this;
			}

		auto ref opDispatch (string swizzle)()
			{/*...}*/
				alias Sets = Cons!(`xyzw`, `rgba`, `stpq`);
				
				static code (string set)()
					{/*...}*/
						string[] code;

						foreach (component; swizzle)
							if (set.count_until (component) >= 0)
								code ~= q{components[} ~ set.count_until (component).text ~ q{]};
							else return ``;

						auto indices = code.join (`, `).text;

						static if (swizzle.length == 1)
							return q{
								return } ~ indices ~ q{;
							};
						else return q{
							return vector (} ~ indices ~ q{);
						}; 
					}

				foreach (i, set; Sets)
					static if (code!set.empty)
						continue;
					else mixin(code!set);

				enum swizzle_from (string set) = code!set.not!empty;

				static assert (Any!(swizzle_from, Sets), `no property ` ~swizzle~ ` for ` ~typeof(this).stringof);

				assert (0);
			}

		this (Repeat!(n, Component) args)
			{/*...}*/
				foreach (i; Iota!n)
					components[i] = args[i];
			}
		this (Component component)
			{/*...}*/
				foreach (i; Iota!n)
					components[i] = component;
			}
		this (Component[n] components)
			{/*...}*/
				this.components = components;
			}
		this (R)(R range)
			in {/*...}*/
				assert (range.length == n);
			}
			body {/*...}*/
				foreach (i; Iota!n)
					components[i] = range[i];
			}

		auto toString ()
			{/*...}*/
				return components.text;
			}
	}
	unittest {/*...}*/
		import std.algorithm: equal;
		import std.math;

		alias vec3 = Vector!(3, float);
		alias vec4 = Vector!(4, float);

		// ctors
		float[4] x = [1,2,3,4];
		float[] r = [1,2,3,4];
		struct Col {int r,g,b,a;}
		Col y;

		auto u = x.vector;
		auto v = y.vector;

		static assert (is(typeof(u) == vec4));

		assert (vector!2 (1)[].equal ([1,1]));
		assert (vector!2 ([1,2])[].equal ([1,2]));

		// conversion
		auto z = cast(Col)v;
		assert (z == y);

		// ranges
		assert (u[].equal (x[]));
		assert (v[].equal ([y.r, y.g, y.b, y.a]));

		// compile-time ops
		enum a = vector (1,1);
		enum b = vector (2,2);
		enum c = a + b;
		enum d = c + 1;
		enum e = 1 + d;
		enum f = 2.1 + d;
		enum g = 1 - f;
		enum h = -f;

		static assert (a == [1, 1]);
		static assert (b == [2, 2]);
		static assert (c == [3, 3]);
		static assert (d == [4, 4]);
		static assert (e == [5, 5]);
		static assert (f == [6.1, 6.1]);
		static assert (g == [-5.1, -5.1]);
		static assert (h == [-6.1, -6.1]);

		// binary ops
		assert (u + v == u);
		assert (u * v == v);

		// misc operators
		auto w = u;
		assert ((u += 1) == w + 1);
		w = u;
		assert (u++ == w);
		assert (u == w + 1);
		assert (--u == w);
		assert (u == w);

		// cross-type interop
		assert (x + u == [3, 5, 7, 9]);
		assert (y + u == [2, 3, 4, 5]);
		assert (x + v == [1, 2, 3, 4]);
		assert (y + v == [0, 0, 0, 0]);
		assert (r + u == [3, 5, 7, 9]);
		assert (r + v == [1, 2, 3, 4]);

		// mapping
		u *= -1;
		assert (u == [-2, -3, -4, -5]);
		assert (u.each!abs == [2, 3, 4, 5]);
		assert (vector (1, -2, 3, -4).each!sgn == [1, -1, 1, -1]);
		static sq = (int x) => x^^2;
		assert (vector (1, -2, 3, -4).each!sq == [1, 4, 9, 16]);
		assert (vector (1, 2, 3, 4).each!(i => i/2.0) == [0.5, 1, 1.5, 2]);

		// components and swizzling
		assert (u.x == -2);
		assert (u.zy == vector (-4, -3));

		assert (u.r == u.x);
		assert (u.g == u.y);
		assert (u.b == u.z);
		assert (u.a == u.w);

		assert (u.s == u[0]);
		assert (u.t == u[1]);
		assert (u.p == u[2]);
		assert (u.q == u[3]);

		auto q = u.xy;
		static assert (not (__traits(compiles, q.z)));

		// slice assignment and arithmetic
		u[0..3] += [1,2,3f];
		assert (u == [-1,-1,-1,-5]);

		u[0..2] = q;
		assert (u == [-2,-3,-1,-5]);

		v[] = u.each!(to!int);
		assert (v == [-2,-3,-1,-5]);

		u[1..4] -= v[1..4].Vector!(3, float)[];
		assert (u == [-2,0,0,0]);

		v[] *= -1;
		assert (v == [2,3,1,5]);
	}
