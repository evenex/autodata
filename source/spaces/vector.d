module spacecadet.spaces.vector;

private {/*import}*/
	import std.conv: text;
	import std.range.primitives: empty;
	import std.algorithm: count_until = countUntil;
	import std.range: join;
	import spacecadet.core;
	import spacecadet.meta;
	import spacecadet.operators;
	import spacecadet.sequence;
}

/* convenience constructors 
*/
template vector ()
	{/*...}*/
		auto vector (V)(V that)
			{/*...}*/
				static if (is (V : Vector!(n,T), T, size_t n))
					return that;
				else static if (is (V : T[n], T, size_t n))
					return that.construct_vector!n;
				else static if (is (typeof(that.tupleof) == T, T))
					return that.construct_vector!(T.length);
				else static assert (0, V.stringof);
			}
		auto vector (T...)(T args)
			{/*...}*/
				CommonType!T[T.length] array = [args];

				return vector (array);
			}
	}
template vector (size_t n)
	{/*...}*/
		alias vector = construct_vector!n;
	}

/* componentwise map which constructs a new vector 
*/
auto each (alias f, V, Args...)(V vector, Args args)
	if (is (V == Vector!(n,T), size_t n, T))
	{/*...}*/
		mixin(unroll_vector_mapping!(V.length-1));
	}

/* generic vector type with space and algebraic operators 
*/
struct Vector (size_t n, Component = double)
	{/*...}*/
		Component[n] components;
		enum length = n;

		ref component (size_t i) 
			{/*...}*/
				return components[i];
			}
		void pull (S)(S source, size_t[2] interval)
			{/*...}*/
				foreach (i, j; ℕ[interval.left..interval.right])
					components[j] = source[i];
			}

		mixin TransferOps!(pull, component, n, RangeOps);

		auto opUnary (string op)()
			{/*...}*/
				static if (op.length == 1)
					{/*...}*/
						Vector ret;

						mixin(q{
							ret.components[] = } ~op~ q{ this.components[];
						});

						return ret;
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
		auto opBinary (string op, V)(V that)
			{/*...}*/
				auto lhs = this;
				auto rhs = that.vector!n;
				enum rhs_argtype = ArgType.vector;

				mixin(unroll_vector_arithmetic!(op, n-1, Repeat!(2, ArgType.vector)));
			}
		auto opBinaryRight (string op, V)(V that)
			{/*...}*/
				auto lhs = that.vector!n;
				auto rhs = this;
				enum lhs_argtype = ArgType.vector;

				mixin(unroll_vector_arithmetic!(op, n-1, Repeat!(2, ArgType.vector)));
			}
		ref opOpAssign (string op, U)(U that)
			{/*...}*/
				mixin(q{
					this = this } ~op~ q{ that;
				});

				return this;
			}
		auto opEquals (T)(T that)
			{/*...}*/
				return this.components == that;
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
				alias lhs = components;
				alias rhs = args;

				mixin(unroll_vector_assignment!(n-1, ArgType.vector));
			}
		this (Component component)
			{/*...}*/
				alias lhs = components;
				alias rhs = component;

				mixin(unroll_vector_assignment!(n-1, ArgType.scalar));
			}
		this (Component[n] components)
			{/*...}*/
				this.components = components;
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
	}

private {/*impl}*/
	enum ArgType {vector, scalar}

	string unroll_vector_assignment (long n, ArgType rhs_type)()
		{/*...}*/
			static vector_assignment (long i)()
				{/*...}*/
					enum index = `[` ~i.text~ `]`;

					static if (rhs_type is ArgType.vector)
						enum ir = index;
					else enum ir = ``;

					static if (i < 0)
						return ``;
					else return vector_assignment!(i-1)~ q{

						lhs} ~index~ q{ = rhs} ~ir~ q{;
					};
				}

			return vector_assignment!n;
		}
	string unroll_vector_arithmetic (string op, long n, ArgType lhs_type, ArgType rhs_type)()
		{/*...}*/
			version (all) {/*mixin pieces}*/
				static vector_arithmetic (long i)()
					{/*...}*/
						enum index = `[` ~i.text~ `]`;

						static if (lhs_type is ArgType.vector)
							enum il = index;
						else enum il = ``;

						static if (rhs_type is ArgType.vector)
							enum ir = index;
						else enum ir = ``;

						static if (i < 0)
							return ``;
						else return vector_arithmetic!(i-1)~ q{

							ret} ~index~ q{ = lhs} ~il~ q{ } ~op~ q{ rhs} ~ir~ q{;
						};
					}

				static if (lhs_type is ArgType.vector)
					{/*...}*/
						enum il = `[0]`;
						enum sl = `[]`;
					}
				else {/*...}*/
					enum il = ``;
					enum sl = ``;
				}

				static if (rhs_type is ArgType.vector)
					{/*...}*/
						enum ir = `[0]`;
						enum sr = `[]`;
					}
				else {/*...}*/
					enum ir = ``;
					enum sr = ``;
				}
			}

			return q{
				alias VectorType = typeof(vector!n (lhs} ~il~ q{ } ~op~ q{ rhs} ~ir~ q{));
				VectorType ret;

				} ~vector_arithmetic!n~ q{

				return ret;
			};
		}
	string unroll_vector_mapping (long n)()
		{/*...}*/
			static vector_mapping (long i)()
				{/*...}*/
					static if (i < 0)
						return ``;
					else return vector_mapping!(i-1) ~q{
						ret[} ~i.text~ q{] = f (vector[} ~i.text~ q{], args);
					};
				}

			return q{
				Vector!(} ~(n+1).text~ q{, typeof(f (vector[0], args))) ret;

				} ~vector_mapping!n~ q{

				return ret;
			};
		}

	template construct_vector (size_t n)
		{/*...}*/
			auto construct_vector (V)(V that)
				{/*...}*/
					static if (is (V : Vector!(n,T), T))
						{/*...}*/
							return that;
						}
					else static if (is (V : T[n], T))
						{/*...}*/
							Vector!(n,T) lhs;
							alias rhs = that;
							alias argtype = ArgType.vector;
						}
					else static if (is (typeof(that.tupleof) == T, T))
						{/*...}*/
							Vector!(n, CommonType!T) lhs;
							auto rhs = that.tupleof;
							alias argtype = ArgType.vector;
						}
					else static if (is_random_access_range!V)
						{/*...}*/
							Vector!(n, ElementType!V) lhs;
							alias rhs = that;
							alias argtype = ArgType.vector;

							assert (that.length == n);
						}
					else static if (is (typeof(that + that * that) == V))
						{/*...}*/
							Vector!(n,V) lhs;
							alias rhs = that;
							alias argtype = ArgType.scalar;
						}
					else static assert (0, `cannot construct vector from ` ~V.stringof);

					static if (is (typeof(lhs)))
						{/*...}*/
							mixin(unroll_vector_assignment!(n-1, argtype));

							return lhs;
						}
				}
		}
}
