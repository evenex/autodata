module evx.math.vectors;

private {/*imports}*/
	private {/*std}*/
		import std.algorithm; 
		import std.traits; 
		import std.range;
		import std.math; 
		import std.conv;
	}
	private {/*evx}*/
		import evx.operators.transfer;

		import evx.misc.tuple; 
		import evx.misc.string; 

		import evx.math.logic; 
		import evx.math.constants; 
		import evx.math.algebra; 
		import evx.math.arithmetic.traits;
		import evx.math.functional; 
	}

	mixin(FunctionalToolkit!());
	alias sum = evx.math.arithmetic.sum;
}

template is_vector_like (T)
	{/*...}*/
		enum is_vector_like = is_vector_tuple!T || is_vector_array!T;
	}

struct Vector (size_t n, Component = double)
	if (n > 1 && supports_arithmetic!Component)
	{/*...}*/
		enum length = n;

		public:
		inout @property {/*components}*/
			ref x () {/*...}*/
				return components[0];
			}
			ref y () {/*...}*/
				return components[1];
			}
			ref z ()() if (n > 2) {/*...}*/
				return components[2];
			}
			ref w ()() if (n > 3) {/*...}*/
				return components[3];
			}

			alias r = x;	alias s = x;	alias u = x;
			alias g = y;	alias t = y;	alias v = y;
			alias b = z;	alias p = z;
			alias a = w;	alias q = w;
		}
		public {/*swizzling}*/
			auto swizzle (string components)()
				{/*...}*/
					static code ()
						{/*...}*/
							string code;

							foreach (component; components)
								code ~= q{this.} ~component.text~ `, `;

							return code;
						}

					mixin(q{
						return vector (} ~code[0..$-2]~ q{);
					});
				}
		}
		public {/*dispatch}*/
			template opDispatch (string op)
				if (is_vector_swizzle!op)
				{/*...}*/
					auto opDispatch ()
						{/*...}*/
							return swizzle!op;
						}
				}
		}
		public {/*math operators}*/
			auto opEquals (V)(V that)
				if (is_vector_tuple!V || is_vector_array!V || isInputRange!V)
				{/*...}*/
					static if (is_vector_tuple!V)
						return this[].equal (that.vector[]);
					else static if (is_vector_array!V)
						return this[].equal (that[]);
					else static if (isInputRange!V)
						return this[].equal (that);
					else static assert (0);
				}

			auto opAssign (U)(U s)
				{/*...}*/
					static if (is_vector_tuple!U)
						foreach (i, ref c; components[])
							c = s.tupleof[i];
					else this[] = s;

					return this;
				}

			auto opUnary (string op)()
				{/*...}*/
					mixin(q{
						return vector!n (this[].map!(c => } ~op~ q{ c));
					});
				}

			auto opBinary (string op, V)(V v)
				if (is_vectorwise_operable!(op, V))
				in {/*...}*/
					assert (v.length == n);
				}
				body {/*...}*/
					auto u = vector!n (v[]);

					mixin(q{
						return vector!n (zip (this[], u[]).map!((a, b) => a } ~op~ q{ b));
					});
				}
			auto opBinaryRight (string op, V)(V v)
				if (is_vectorwise_operable!(op, V))
				in {/*...}*/
					assert (v.length == n);
				}
				body {/*...}*/
					auto u = vector!n (v[]);

					mixin(q{
						return vector!n (zip (u[], this[]).map!((a,b) => a } ~op~ q{ b));
					});
				}
			auto opOpAssign (string op, V)(V v)
				if (is_vectorwise_operable!(op, V))
				{/*...}*/
					static if (isInputRange!V)
						auto u = vector!n (v);
					else auto u = vector!n (v[]);

					mixin(q{
						this = zip (this[], u[]).map!((a,b) => a } ~op~ q{ b);
					});

					return this;
				}

			auto opBinary (string op, U)(U s)
				if (is_componentwise_operable!(op, U))
				{/*...}*/
					immutable t = s;
					mixin(q{
						return vector!n (this[].map!(c => c } ~op~ q{ t));
					});
				}
			auto opBinaryRight (string op, U)(U s)
				if (is_componentwise_operable!(op, U))
				{/*...}*/
					immutable t = s;
					mixin(q{
						return vector!n (this[].map!(c => t } ~op~ q{ c));
					});
				}
			auto opOpAssign (string op, U)(U s)
				if (is_componentwise_operable!(op, U))
				{/*...}*/
					mixin(q{
						components[] } ~op~ q{= s;
					});

					return this;
				}
		}
		public {/*data operators}*/
			mixin TransferOps!components;
		}
		public {/*ctor}*/
			this (R)(R range)
				if (isInputRange!R)
				in {/*...}*/
					assert (range.length == n,
						`input range/vector length mismatch`
					);
				}
				body {/*...}*/
					this = range;
				}

			this (Component[n] components)
				{/*...}*/
					this.components = components;
				}

			this (Components...)(Components components)
				if (Components.length == n)
				{/*...}*/
					foreach (i, component; components)
						this.components[i] = component;
				}

			this (Component component)
				{/*...}*/
					this.components[] = component;
				}

			this ()(string input)
				if (__traits(compiles, input.extract_number.to!Component))
				{/*...}*/
					foreach (ref i; components)
						{/*...}*/
							auto i_string = input.findSplitBefore (`,`)[0];
							input = input.findSplitAfter (`,`)[1];

							if (i_string.empty)
								assert (0, `bad string → vector conversion`);

							i = i_string.extract_number.to!Component;
						}
				}
		}
		public {/*conv}*/
			@property array ()
				{/*...}*/
					return components;
				}
			@property tuple ()
				{/*...}*/
					static code ()
						{/*...}*/
							string code;

							foreach (i; 0..n)
								code ~= q{this[} ~i.text~ q{], };

							return code[0..$-2];
						}

					mixin(q{
						return τ(} ~code~ q{);
					});
				}
			auto opCast (T)()
				{/*...}*/
					static if (__traits(compiles, T (this.tuple.expand)))
						return T (this.tuple.expand);
					else static if (__traits(compiles, T (this[])))
						return T (this[]);
					else static assert (0, `cannot convert ` ~Vector.stringof~ ` to ` ~T.stringof);
				}
		}
		public {/*text}*/
			@property toString ()
				{/*...}*/
					string output;

					foreach (component; this[])
						{/*...}*/
							output ~= component.text~ `, `;
						}
					
					return `[` ~output[0..$-2]~ `]`;
				}
		}

		private:
		private {/*components}*/
			Component[n] components;

			enum ComponentGroup {xyzw, rgba, stpq, uv}
		}
		private {/*traits}*/
			template is_vector_function (string func, Args...)
				{/*...}*/
					void over_vector ()(Args args)
						{/*...}*/
							mixin(q{
								} ~func~ q{ (Vector.init, args);
							});
						}
					void over_components ()(Args args)
						{/*...}*/
							mixin(q{
								Component.init.} ~func~ q{ (args);
							});
						}
					enum is_vector_function = __traits(compiles, over_vector (Args.init))
						|| not(__traits(compiles, over_components (Args.init)));
				}
			public template is_vector_swizzle (string components) // HACK opDispatch fails if this is private... why?
				{/*...}*/
					static if (components.length > 1)
						{/*...}*/
							template in_group (ComponentGroup group)
								{/*...}*/
									static in_this_group (dchar c)
										{/*...}*/
											return group.text.canFind (c);
										}

									enum in_group = components.all!in_this_group;
								}

							enum is_vector_swizzle = anySatisfy!(in_group, EnumMembers!ComponentGroup);
						}
					else enum is_vector_swizzle = false;
				}
			template is_vectorwise_operable (string op, T)
				{/*...}*/
						enum is_vector_like = isInputRange!T || is_vector_array!T || is_vector_tuple!T;

						static if (__traits(compiles, T.init.vector))
							enum has_same_length = typeof(T.init.vector).length == n;
						else static if (__traits(compiles, T.init.vector!2))
							enum has_same_length = true;
						else enum has_same_length = false;

						static if (not(is(ElementType!T == void)))
							alias U = ElementType!T;
						else static if (is(typeof(T.init.tupleof)))
							alias U = CommonType!(τ(T.init.tupleof).Types);
						else alias U = void;

					enum is_vectorwise_operable = is_vector_like && has_same_length 
						&& __traits(compiles, mixin(q{
							Component.init } ~op~ q{ unity!U
						}));
				}
			template is_componentwise_operable (string op, T)
				{/*...}*/
					enum is_componentwise_operable = not(is_vectorwise_operable!(op, T)) && __traits(compiles, mixin(q{
						Component.init } ~op~ q{ unity!T
					}));
				}
		}
	}
	unittest {/*construction and conversion}*/
		void test (T)()
			{/*...}*/
				static if (allSatisfy!(isFloatingPoint, FieldTypeTuple!T))
					enum value = unity!T;
				else enum value = T.init;

				{/*foreign vector types}*/
					struct ForeignVec
						{T x = value, y = value, z = value;}
					ForeignVec v;

					auto a = v.vector;
					assert (a[0] == v.x);
					assert (a[1] == v.y);
					assert (a[2] == v.z);

					auto w = cast(ForeignVec)a;

					assert (w == v);
				}
				{/*range types}*/
					// dynamic array
					auto a = [value, value, value].vector!3;
					assert (a[].equal ([value, value, value]));

					// mapresult
					auto result = [value, value, value].map!(c => value + c);
					auto b = result.vector!3;
					assert (b[].equal (result));

					// vector slice 
					auto c = vector!3 (a[]);
					assert (c[].equal (a[]));
				}
				{/*vector-like structs}*/
					// static arrays
					T[4] a = [value, value, value, value];
					auto b = a.vector;
					assert (b[].equal (a[]));

					auto a1 = b.array;
					static assert (is (typeof(a1) == T[4]));
					assert (a1[].equal (a[]));

					// tuples
					auto c = τ(value,value,value).vector;
					assert (c[0] == value);
					assert (c[1] == value);
					assert (c[2] == value);

					assert (c.tuple == τ(value, value, value));
				}
				{/*per-component construction}*/
					/* variadic: 
					*/
					auto a = vector (value, value);
					assert (a[0] == value);
					assert (a[1] == value);
					assert (a.length == 2);

					/*filled: 
					*/
					auto b = vector!4 (value);
					assert (b == vector (value, value, value, value));

					/* minimum length: 
					*/
					static assert (not(__traits(compiles, vector (value))));
					static assert (__traits(compiles, vector!2 (value)));
				}
				{/*identity}*/
					auto a = vector (value, value);

					auto b = a.vector;
					assert (b[] == a[]);

					auto c = vector (a);
					assert (c[] == a[]);
				}
			}

		test!dchar;

		test!byte;
		test!short;
		test!int;
		test!long;

		test!ubyte;
		test!ushort;
		test!uint;
		test!ulong;

		test!real;
		test!double;
		test!float;

		struct T1
			{/*...}*/
				int i;
				string s;

				auto opBinary (string op)(T1 val)
					{/*...}*/
						return T1 (i * val.i, s);
					}
			}

		test!T1;

		struct T2 {T1 a, b, c;}

		static assert (supports_arithmetic!T1);
		static assert (not(supports_arithmetic!T2));
		static assert (not(__traits(compiles, test!T2)));
	}
	unittest {/*component access}*/
		auto v = vector (1, 2, 3, 4);

		assert (v.x == 1);
		assert (v.y == 2);
		assert (v.z == 3);
		assert (v.w == 4);

		assert (v.r == 1);
		assert (v.g == 2);
		assert (v.b == 3);
		assert (v.a == 4);

		assert (v.s == 1);
		assert (v.t == 2);
		assert (v.p == 3);
		assert (v.q == 4);

		assert (v.u == 1);
		assert (v.v == 2);

		v.u = 9;
		assert (v.x == 9);

		v.g += 12;
		assert (v.y == 14);

		v.b *= v.w;
		assert (v.p == 12);
	}
	unittest {/*component swizzling}*/
		auto v = vector (1, 2, 3, 4);

		assert (v.xyzw == v);
		assert (v.xy == vector (1, 2));
		assert (v.zyx == vector (3, 2, 1));
		assert (v.xxx == vector (1, 1, 1));
		assert (v.xyzzy == vector (1, 2, 3, 3, 2));

		assert (v.rgba == v);
		assert (v.bgra == vector (3, 2, 1, 4));
		static assert (not(__traits(compiles, v.rgxy)));
	}
	unittest {/*arithmetic operations}*/
		// when constructed per-component, vectors take the common type of their arguments
		static assert (not(__traits(compiles, vector (τ(1,`c`)))));
		static assert (__traits(compiles, vector (τ(1, 2f, 'c'))));
		static assert (is(ElementType!(typeof(vector(τ(1, 2f, 'c')))) == float));

		// example:
		auto u = vector (1,2,3f);
		auto v = vector (-1,-2,-3);
		auto w = vector!3 (0);

		assert (-v == u);
		assert (-u == v);

		// vector-vector ops apply per index-paired component
		assert (u + v == w);
		assert (u + w == u);
		assert (v + w == v);
		assert (v * w == w);
		assert (u * w == w);
		assert (u / v == vector!3 (-1));

		assert (v + v == 2*v);
		assert (u + u == 2*u);
		assert (u - v == u*2);
		assert (v - u == v*2);

		// vector-scalar ops apply the scalar operator per-component
		assert (u + 1 == vector (2, 3, 4));
		assert (u - 1 == vector (0, 1, 2));
		assert (u * 2 == vector (2, 4, 6));
		assert (u / 2 == vector (0.5, 1, 1.5));
		assert (1 + u == vector (2, 3, 4));
		assert (1 - u == vector (0, -1, -2));
		assert (2 * u == vector (2, 4, 6));
		assert (2 / u == vector (2, 1, 2f/3));

		// vector ops may be performed between a vector and any vector-like structure, including ranges
		real[3] s = [1,2,3];

		assert (u == [1,2,3]);
		assert (u == τ(1,2,3));
		assert (u == s);
		assert (u == s[]);
		assert (u == s[].map!(s => s));

		assert (u * [1,2,3] == only (1,4,9));

		assert (u * τ(1,1,1) == u);
		assert (τ(1,1,1) * u == u);

		assert (u * [2,2,2] == u * 2);
		assert ([2,2,2] * u == u * 2);

		assert (u * only (3,3,3) == u * 3);
		assert (only (3,3,3) * u == u * 3);

		// assignment follows the same application pattern as other binary operations
		u = 3;
		assert (u == τ(3,3,3));

		u = [9,9,9];
		assert (u == only (9,9,9));

		u = only (6,6,6);
		assert (u == [6,6,6]);

		u = w;
		assert (u == w);

		u = -v;
		assert (u == -1 * v);

		// as does operator assignment
		assert ((u += v) == vector (0,0,0));
		assert (u == only (0,0,0));
		assert ((u -= v) == τ(1,2,3));
		assert (u == [1,2,3]);

		u /= [-1,-1,-1];
		assert (u == v);

		u *= only (0,0,0);
		assert (u == w);

		u += s[];
		assert (u == [1,2,3]);

		u *= 2;
		assert (u == [2,4,6]);

		u -= u[].map!(x => x/2);
		assert (u == [1,2,3]);
	}
	unittest {/*vector functions}*/
		import evx.math.analysis;
		import evx.math.geometry;
		alias sum = evx.math.arithmetic.sum; // REVIEW

		auto u = vector (1, 2.);

		assert (norm (u).approx (sqrt (5.)));
		version (X86_64) 
			assert (norm (u) == u.norm);

		assert (u.norm!0 == double.infinity);
		assert (u.norm!1 == u[].sum);
		version (X86_64) {/*...}*/
			assert (u.norm!2 == u.norm);
			assert (u.norm!3.approx (2.08008));
			assert (u.norm!4.approx (2.03054));
			assert (u.norm!5.approx (2.01235));
		}

		assert (u.unit.approx ([0.447214, 0.894427]));

		assert (u.dot (u) == 5);

		auto v = vector (2.,3,4);

		assert (u.det (u) == 0);
		assert (u.det (vector (-2, 1)).approx (u.norm^^2));

		assert (v.cross (vector (6,4,2)) == [-10, 20, -10]);

		assert (v.proj (vector (6.,4,2)).approx ([3.42857, 2.28571, 1.14286]));
		assert (v.rej (vector (6.,4,2)).approx ([-1.42857, 0.714286, 2.85714]));
		
	}
	unittest {/*algebraic identity elements}*/
		auto v = vector (1,2,3);
		static assert (zero!(typeof(v)) == [0,0,0]);
		static assert (unity!(typeof(v)) == [1,1,1]);
	}
	unittest {/*dimensioned geometry}*/
		import evx.math.analysis;
		import evx.math.units;
		import evx.math.geometry;

		alias Position = Vector!(2, Meters);
		alias Velocity = Vector!(2, typeof(meters/second));

		auto a = Position (3.meters, 4.meters);

		assert (+a == a);
		assert (a - a == zero!Position);
		assert (-a + a == Position (0.meters));
		assert (2*a == Position (6.meters, 8.meters));
		assert (a*a == typeof(a*a)(9.meter*meters, 16.meter*meters));
		assert (a/a == 1.Vector!2);

		assert (Velocity (10.meters/second, 7.meters/second) * 0.5.seconds == Position (5.meters, 3.5.meters));

		assert (a.norm.approx (5.meters));
		assert (a.unit.approx (Vector!2 (0.6, 0.8)));

		auto b = 12.meters * a.unit;
		assert (a.dot (b).approx (a.norm * b.norm));
		assert (a.det (b).approx (0.squared!meters));
		assert (a.proj (b).approx (a));
		assert (a.rej (b).approx (Position (0.meters)));

		auto c = a.rotate (π/2);
		assert (c.approx (Position (-4.meters, 3.meters)));
		assert (a.dot (c).approx (0.squared!meters));
		assert (a.det (c).approx (a.norm * c.norm));
		assert (a.proj (c).approx (Position (0.meters)));
		assert (a.rej (c).approx (a));

		assert (a.bearing_to (c).approx (π/2));
		assert (distance (a, b).approx (7.meters));
	}
	unittest {/*string parsing}*/
		enum x = `[3, 2, 1]`;

		assert (Vector!(3, int)(x)[] == [3,2,1]);

		import evx.math.units;
		enum y = `[0.001 kg, 0.002 kg, 0.003 kg, 0.005 kg]`;
		assert (Vector!(4, Kilograms)(y) == [1.grams, 2.grams, 3.grams, 5.grams]);
	}
	static if (0) // TEMP
	unittest {/*finiteness check}*/
		assert (vector (infinity, infinity).is_infinite);
		assert (vector (infinity, 1.0, 2.0).is_infinite);
		assert (vector (0.0, 1.0, 2.0).is_finite);
	}

template vector (size_t length)
	if (length > 1)
	{/*...}*/
		auto vector (R)(R range)
			if (isInputRange!R)
			{/*...}*/
				return vector_from_range!length (range);
			}

		auto vector (T)(T component)
			if (not(isInputRange!T))
			{/*...}*/
				return vector_from_range!length (component.repeat (length));
			}

		auto vector (Args...)(Args components)
			if (Args.length == length && is_vector_tuple!(Tuple!Args))
			{/*...}*/
				return vector_from_variadic (components);
			}
	}
template vector ()
	{/*...}*/
		auto vector (V)(V tuple)
			if (is_vector_tuple!V)
			{/*...}*/
				return vector_from_tuple (tuple);
			}

		auto vector (T)(T array)
			if (is_vector_array!T)
			{/*...}*/
				return vector_from_array (array);
			}

		auto vector (Args...)(Args components)
			if (Args.length > 1 && is_vector_tuple!(Tuple!Args))
			{/*...}*/
				return vector_from_variadic (components);
			}
	}

auto each (alias func, V, Args...)(V v, Args args)
	{/*...}*/
		return vector!(V.length) (v[].map!func);
	}

public {/*explicit conversion}*/
	auto vector_from_tuple (V)(V v)
		{/*...}*/
			return vector_from_variadic (v.tupleof);
		}
	auto vector_from_array (T)(T array)
		{/*...}*/
			alias U = FieldTypeTuple!T[0];

			enum length = U.sizeof/ElementType!U.sizeof;

			return Vector!(length, Unqual!(ElementType!U))(array[]);
		}
	auto vector_from_range (size_t length, R)(R range)
		{/*...}*/
			return Vector!(length, Unqual!(ElementType!R))(range);
		}
	auto vector_from_variadic (Args...)(Args components)
		{/*...}*/
			return Vector!(Args.length, Unqual!(CommonType!Args))(components);
		}
}
private {/*identification traits}*/
	template is_vector_tuple (T)
		{/*...}*/
			alias Components = FieldTypeTuple!T;
			alias U = CommonType!Components;

			template implicitly_convertible (V)
				{/*...}*/
					enum implicitly_convertible = isImplicitlyConvertible!(V, U);
				}

			enum is_vector_tuple = Components.length > 1
				&& allSatisfy!(implicitly_convertible, Components)
				&& not(isInputRange!U || isStaticArray!U)
				&& __traits(compiles, T.tupleof);
		}
	template is_vector_array (T)
		{/*...}*/
			alias Components = FieldTypeTuple!T;
			alias U = Components[0];

			static if (isStaticArray!U)
				enum is_vector_array = U.length > 1;
			else enum is_vector_array = false;
		}
}
