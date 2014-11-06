module evx.math.vectors;

private {/*imports}*/
	import std.conv;

	import std.traits;

	import std.algorithm;
	import std.range;
	import std.math;

	import evx.math.logic;
}

// CTORS
template vector (size_t n)
	{/*...}*/
		auto vector (T)(T that)
			{/*...}*/
				Vector!(n,T) lhs;
				alias rhs = that;

				mixin(vector_assignment!(n-1, ArgType.scalar));

				return lhs;
			}
	}
template vector ()
	{/*...}*/
		auto vector (V)(V that)
			if (is_vector_array!V)
			{/*...}*/
				static if (is(V == VectorTraits!V.VectorType))
					return that;
				else {/*...}*/
					alias T = ElementType!V;
					enum n = V.sizeof / T.sizeof;

					Vector!(n,T) lhs;
					alias rhs = that;

					mixin(vector_assignment!(n-1, ArgType.vector));

					return lhs;
				}
			}

		auto vector (V)(V that)
			if (is_vector_struct!V)
			{/*...}*/
				alias T = CommonType!(FieldTypeTuple!V);
				enum n = that.tupleof.length;

				Vector!(n,T) lhs;
				auto rhs = that.tupleof;

				mixin(vector_assignment!(n-1, ArgType.vector));

				return lhs;
			}

		auto vector (Args...)(Args args)
			if (Args.length > 1)
			{/*...}*/
				alias T = CommonType!Args;
				enum n = Args.length;

				Vector!(n,T) lhs;
				alias rhs = args;

				mixin(vector_assignment!(n-1, ArgType.vector));

				return lhs;
			}
	}

// POLICY
version (none)
enum Storage {padded, packed} // TODO unlocking potential autovectorization: RepresentationTypeTuple!Component gives us the fundamental backing type, which we can use to attempt to compile a __vector(RTT!C[ceil_pow2!n])... if its ok, then we check to see if they're both padded, and in that case we do the arithmeticOp on the storage instead of the components

// DEFINITION
struct Vector (size_t n, Component = double)
	//if (supports_arithmetic!Component)
	{/*...}*/
		Component[n] components;
		alias components this;

		public {/*ctors}*/
			this (Args...)(Args args)
				if (Args.length == length)
				{/*...}*/
					alias lhs = components;
					alias rhs = args;

					mixin(vector_assignment!(n-1, ArgType.vector));
				}

			this (Component component)
				{/*...}*/
					alias lhs = components;
					alias rhs = component;

					mixin(vector_assignment!(n-1, ArgType.scalar));
				}

			this (Component[n] components)
				{/*...}*/
					this.components = components;
				}
		}
		public {/*ops}*/
			auto opUnary (string op)()
				if (op.length == 1)
				{/*...}*/
					static if (op == `+`)
						return this;
					else static if (op == `-`)
						{/*...}*/
							Vector ret;

							mixin(q{
								ret[] = } ~op~ q{ this[];
							});

							return ret;
						}
					else static assert (0, op~ ` not yet implemented for vectors`);
				}
			ref opUnary (string op)()
				if (op.length == 2)
				{/*...}*/
					mixin(q{
						} ~op~ q{ this[];
					});

					return this;
				}

			auto opBinary (string op, V)(V that)
				if (is_vector_like!V)
				{/*...}*/
					auto lhs = this;
					auto rhs = vector (that);

					mixin(vector_arithmetic!(op, n-1, ArgType.vector, ArgType.vector));
				}
			auto opBinary (string op, T)(T that)
				if (not (is_vector_like!T))
				{/*...}*/
					auto lhs = this;
					alias rhs = that;

					mixin(vector_arithmetic!(op, n-1, ArgType.vector, ArgType.scalar));
				}

			auto opBinaryRight (string op, V)(V that)
				if (is_vector_like!V)
				{/*...}*/
					auto lhs = vector (that);
					auto rhs = this;

					mixin(vector_arithmetic!(op, n-1, ArgType.vector, ArgType.vector));
				}
			auto opBinaryRight (string op, T)(T that)
				if (not (is_vector_like!T))
				{/*...}*/
					alias lhs = that;
					auto rhs = this;

					mixin(vector_arithmetic!(op, n-1, ArgType.scalar, ArgType.vector));
				}

			ref opOpAssign (string op, U)(U that)
				{/*...}*/
					mixin(q{
						this = this } ~op~ q{ that;
					});

					return this;
				}

			auto opCast (V)()
				{/*...}*/
					auto attempt_ctors (Strings...)()
						{/*...}*/
							foreach (code; Strings)
								static if (__traits(compiles, mixin(code)))
									mixin(q{
										return } ~code~ q{;
									});

							assert (0, `no conversion from ` ~Vector.stringof~ ` to ` ~V.stringof);
						}

					return attempt_ctors!(
						q{V (this.tuple.expand)},
						q{V (this)},
						q{V (this[])},
					);
				}

			auto ref opDispatch (string swizzle)()
				{/*...}*/
					enum xyzw = `xyzw`;
					enum rgba = `rgba`;
					enum stpq = `stpq`;

					alias Sets = TypeTuple!(xyzw, rgba, stpq);
					
					static code (string set)()
						{/*...}*/
							string code;

							foreach (component; swizzle)
								if (set.countUntil (component) >= 0)
									code ~= q{components[} ~set.countUntil (component).text~ q{], };
								else return ``;

							code = code[0..$ - min($,2)];

							static if (swizzle.length == 1)
								return q{
									return } ~code~ q{;
								};
							else return q{
								return vector (std.typecons.tuple (} ~code~ q{).expand);
							}; 
						}

					foreach (i, Set; Sets)
						static if (code!Set.empty)
							continue;
						else mixin(code!Set);

					template swizzle_from (string set)
						{/*...}*/
							enum swizzle_from = code!set.not!empty;
						}
					static assert (Any!(swizzle_from, Sets), `no property ` ~swizzle~ ` for ` ~typeof(this).stringof);

					assert (0);
				}
		}
		@property {/*}*/
			enum length = n;

			auto tuple ()
				{/*...}*/
					static code ()
						{/*...}*/
							string code;

							foreach (i; 0..n)
								code ~= q{this[} ~i.text~ q{], };

							return code[0..$-2];
						}

					mixin(q{
						return std.typecons.tuple (} ~code~ q{);
					});
				}
		}
	}
	unittest {/*...}*/
		alias vec3 = Vector!(3, float);
		alias vec4 = Vector!(4, float);

		// ctors
		float[4] x;
		x[] = [1,2,3,4];
		struct Col {int r,g,b,a;}
		Col y;

		auto u = x.vector;
		auto v = y.vector;

		static assert (is(typeof(u) == vec4));

		assert (vector!2 (1)[].equal ([1,1]));

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

// MAPPING
auto each (alias func, V, Args...)(V vector, Args args)
	if (is(VectorTraits!V.VectorType == V))
	{/*...}*/
		mixin(vector_mapping!(V.length-1));
	}

/// TRAITS
template is_vector_like (T)
	{/*...}*/
		enum is_vector_like = is_vector_struct!T || is_vector_array!T;
	}
template is_vector_struct (T)
	{/*...}*/
		alias Components = FieldTypeTuple!T;
		alias U = CommonType!Components;

		template implicitly_convertible (V)
			{/*...}*/
				enum implicitly_convertible = isImplicitlyConvertible!(V, U);
			}

		enum is_vector_struct = Components.length > 1
			&& All!(implicitly_convertible, Components)
			&& not(isInputRange!U || isStaticArray!U)
			&& __traits(compiles, T.init.tupleof);
	}
template is_vector_array (T)
	{/*...}*/
		alias Components = RepresentationTypeTuple!T;
		alias U = Components[0];

		static if (isStaticArray!U)
			enum is_vector_array = U.length > 1;
		else enum is_vector_array = false;
	}

struct VectorTraits (T)
	if (is_vector_like!T)
	{/*...}*/
		static if (is_vector_struct!T)
			alias Components = CommonType!(FieldTypeTuple!T)[T.init.tupleof.length];
		else static if (is_vector_array!T)
			alias Components = RepresentationTypeTuple!T[0];

		enum length = Components.length;

		alias VectorType = Vector!(length, ElementType!Components);
		alias UnwrappedVectorType = Vector!(length, Unwrapped!(ElementType!Components));
	}

// METAPROGRAMMING TOOLS
template ceil_power_of_two (uint n)
	{/*...}*/
		static if (n < 1)
			enum m = 0;
		else static if (n < 2)
			enum m = 1;
		else static if (n < 3)
			enum m = 2;
		else static if (n < 5)
			enum m = 4;
		else static if (n < 9)
			enum m = 8;
		else static if (n < 17)
			enum m = 16;
		else static if (n < 33)
			enum m = 32;
		else static assert (0, "vectors of length > 32 not supported");

		enum ceil_power_of_two = m;
	}

template Unwrapped (T)
	{/*...}*/
		static assert (RepresentationTypeTuple!T.length == 1, `only single-data-unit wrappers supported`);

		alias Unwrapped = RepresentationTypeTuple!T[0];
	}

union VectorCast (V)
	{/*...}*/
		V wrapped;
		VectorTraits!V.UnwrappedVectorType unwrapped;
	}
auto unwrapped (V)(V vector)
	if (is_vector_like!V)
	{/*...}*/
		return VectorCast!V (vector).unwrapped;
	}
auto unwrapped (T)(T scalar)
	if (not (is_vector_like!T))
	{/*...}*/
		union Cast
			{/*...}*/
				T wrapped;
				Unwrapped!T unwrapped;
			}

		return Cast(scalar).unwrapped;
	}

enum ArgType {vector, scalar}

string vector_arithmetic (string op, long n, ArgType lhs_type, ArgType rhs_type)()
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
					else return vector_arithmetic!(i-1) ~ q{

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
			alias VectorType = typeof(vector!n (lhs} ~il~q{ }~op~ q{ rhs} ~ir~ q{));
			VectorType ret;

			} ~vector_arithmetic!n~ q{

			return ret;
		};
	}
string vector_assignment (long n, ArgType rhs_type)()
	{/*...}*/
		static vector_assignment (long i)()
			{/*...}*/
				enum index = `[` ~i.text~ `]`;

				static if (rhs_type is ArgType.vector)
					enum ir = index;
				else enum ir = ``;

				static if (i < 0)
					return ``;
				else return vector_assignment!(i-1) ~ q{

					lhs} ~index~ q{ = rhs} ~ir~ q{;
				};
			}

		return vector_assignment!n;
	}
string vector_equality (long n)()
	{/*...}*/
		static vector_equality (long i)()
			{/*...}*/
				static if (i < 0)
					return ``;
				else return vector_equality!(i-1) ~q{

					lhs[} ~i.text~ q{] == rhs[} ~i.text~ q{]
				}
					~q{&&};
			}

		return q{
			if (lhs.length != rhs.length)
				return false;
			else return } ~vector_equality!n[0..$-2]~ q{;
		};
	}
string vector_mapping (long n)()
	{/*...}*/
		static vector_mapping (long i)()
			{/*...}*/
				static if (i < 0)
					return ``;
				else return vector_mapping!(i-1) ~q{
					ret[} ~i.text~ q{] = func (vector[} ~i.text~ q{], args);
				};
			}

		return q{
			Vector!(} ~(n+1).text~ q{, typeof(func(vector[0], args))) ret;

			} ~vector_mapping!n~ q{

			return ret;
		};
	}
// /////////////// /////
