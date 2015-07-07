/**
   supplies a flexible vector functor with arithmetic operators
*/
module autodata.functor.vector;

private {/*import}*/
	import std.conv: to, text;
	import std.range.primitives: empty;
	import std.algorithm: count_until = countUntil;
	import std.range: join, ElementType;
	import std.traits: CommonType;
	import evx.meta;
	import autodata.functor.tuple;
}

/** convenience constructors
*/
template vector ()
{
	auto vector (T, uint n)(T[n] v)
    {
        return Vector!(n,T)(v);
    }
	auto vector (V)(V v)
    if (is (V : Vector!(n,T), T, size_t n))
    {
        return v;
    }
	auto vector (V)(V v)
    if (is (typeof(v.tupleof) == T, T))
    {
        alias T = typeof(v.tupleof);

        return Vector!(T.length, CommonType!T)(v.tupleof);
    }
	auto vector (T...)(T args)
    {/*...}*/
        return Vector!(T.length, CommonType!T)(args);
    }
}
/**
   ditto 
*/
template vector (size_t n)
{
	auto vector (V)(V v) // REFACTOR FOR OVERLOAD ROUTING
	{
		static if (is (V : Vector!(n,T), T))
		{
			return v;
		}
		else static if (is (V : T[n], T))
		{
			return Vector!(n,T)(v);
		}
		else static if (not (is (ElementType!V == void)))
		{
			return Vector!(n, ElementType!V)(v);
		}
		else static if (is (typeof(v + v * v)))
		{
			return Vector!(n,V)(v);
		}
		else static if (is (typeof(v.tupleof) == T, T))
		{
			return Vector!(n, CommonType!T)(v.tupleof);
		}
		else static assert (0, `cannot construct vector from ` ~V.stringof);
	}
	auto vector (T...)(T args)
	{
		return Vector!(n, CommonType!T)(args);
	}
}
///
unittest
{
    import std.algorithm: equal;

    struct Col {int r,g,b,a;}

    float[4] x = [1,2,3,4];
    Col y;
    float[] r = [1,2,3,4];

    // construction
    auto u = x.vector;
    auto v = y.vector;
    auto w = vector(1,2,3,4);

    static assert (is(typeof(u) == Vector!(4, float)));

    assert (vector!2 (1)[].equal ([1,1]));
    assert (vector!2 ([1,2])[].equal ([1,2]));

    auto p = r.vector!4;
    assert (p == w);

    // conversion
    auto z = cast(Col)v;
    assert (z == y);
}

/** functor map for vectors
    Returns:
        a new vector with f applied componentwise with optional curried arguments
*/
auto fmap (alias f, size_t n, T, Args...)(Vector!(n,T) v, Args args)
{
	Vector!(n, typeof(f (v[0], args))) mapped;

	foreach (i; Iota!n)
		mapped[i] = f(v[i], args);

	return mapped;
}
///
unittest 
{
    import std.math;

    auto u = [-2, -3, -4, -5].vector;

    assert (u.fmap!abs == [2, 3, 4, 5]);
    assert (vector (1, -2, 3, -4).fmap!sgn == [1, -1, 1, -1]);

    static sq = (int x) => x^^2;

    assert (vector (1, -2, 3, -4).fmap!sq == [1, 4, 9, 16]);
    assert (vector (1, 2, 3, 4).fmap!(i => i/2.0) == [0.5, 1, 1.5, 2]);

    import std.conv: to;

    static assert (is (typeof(u) == Vector!(4, int)));
    static assert (is (typeof(u.fmap!(to!double)) == Vector!(4, double)));
}

/** generic vector type
*/
struct Vector (size_t n, Component)
{
	enum length = n;

	Unqual!Component[n] components;
	alias components this;
	@disable Component front ();

    /**
        arithmetic operators are lifted to work elementwise,
        can be computed at compiletime if the component type supports it,
        interop freely with any struct which can be converted with .vector,
        and support D's builtin static array vector ops

        Returns:
            a new vector resulting from the elementwise application of the arithmetic operator
            or, for assignment ops, a reference to the target vector
    */
    alias arithmetic_ops = Cons!(`+`,`-`,`*`,`/`,`^^`);
    /**
       ditto 
    */
	auto opUnary (string op)()
	{
		static if (op.length == 1)
		{
			static if (op == `+`)
				return this;
			else {
				Vector ret;

				mixin(q{
					ret.components[] = } ~op~ q{ this.components[];
			});

				return ret;
			}
		}
		else static if (op.length == 2)
		{
			mixin(q{
				} ~op~ q{ this.components[];
			});

			return this;
		}
		else static assert (0);
	}
    /**
       ditto 
    */
	auto opBinary (string op, V)(V v)
	if (Contains!(op, arithmetic_ops))
	{
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
    /**
       ditto 
    */
	auto opBinaryRight (string op, V)(V v)
	if (Contains!(op, arithmetic_ops))
	{
		auto lhs = v.vector!n;
		auto rhs = this;

		mixin(q{
			return lhs } ~op~ q{ rhs;
		});
	}
    /**
       ditto 
    */
	auto ref opOpAssign (string op, V)(V v)
	{
		mixin(q{
			this = this } ~op~ q{ v;
		});

		return this;
	}
    ///
    unittest {
        // compile-time ops
        enum a = vector (1,1);
        static assert (a == [1, 1]);

        enum b = vector (2,2);
        static assert (b == [2, 2]);

        enum c = a + b;
        static assert (c == [3, 3]);

        enum d = c + 1;
        static assert (d == [4, 4]);

        enum e = 1 + d;
        static assert (e == [5, 5]);

        enum f = 2.1 + d;
        static assert (f == [6.1, 6.1]);

        enum g = 1 - f;
        static assert (g == [-5.1, -5.1]);

        enum h = -f;
        static assert (h == [-6.1, -6.1]);

        // binary ops
        auto u = [1,2,3,4].vector;
        auto v = 0.vector!4;

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
        float[4] x = [1,2,3,4];
        assert (x + u == [3, 5, 7, 9]);
        assert (x + v == [1, 2, 3, 4]);

        struct Col {int r,g,b,a;}
        Col y;
        assert (y + u == [2, 3, 4, 5]);
        assert (y + v == [0, 0, 0, 0]);

        float[] r = [1,2,3,4];
        assert (r + u == [3, 5, 7, 9]);
        assert (r + v == [1, 2, 3, 4]);

        auto t = .tuple(1,2,3,4);
        assert (t + u == [3, 5, 7, 9]);
        assert (t + v == [1, 2, 3, 4]);

        // slice assignment and arithmetic
        u *= -1;
        u[0..3] += [1,2,3];
        assert (u == [-1,-1,-1,-5]);

        u[0..2] = [-2,-3];
        assert (u == [-2,-3,-1,-5]);

        v[] = u.fmap!(to!int);
        assert (v == [-2,-3,-1,-5]);

        u[1..4] -= v[1..4].Vector!(3, int)[];
        assert (u == [-2,0,0,0]);

        v[] *= -1;
        assert (v == [2,3,1,5]);
    }

    /**
       swizzling operations create new vectors from combinations of named elements exclusively from one SwizzleSet
    */
    alias SwizzleSets = Cons!(`xyzw`, `rgba`, `stpq`);
    /**
        ditto
    */
	auto ref swizzle (string elements)()
	{
		alias Sets = SwizzleSets;
		
		static code (string set)()
		{
			string[] code;

			foreach (component; elements)
				if (set.count_until (component) >= 0)
					code ~= q{components[} ~ set.count_until (component).text ~ q{]};
				else return ``;

			auto indices = code.join (`, `).text;

			static if (elements.length == 1)
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

		static assert (Any!(swizzle_from, Sets), `no property ` ~elements~ ` for ` ~typeof(this).stringof);

		assert (0);
	}
    /**
        ditto
    */
    alias opDispatch = swizzle;
    ///
    unittest {
        auto u = vector(-2, -3, -4, -5);

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

    /**
    */
	this (Repeat!(n, Component) args)
	{
		foreach (i; Iota!n)
			components[i] = args[i];
	}
    /**
        ditto
    */
	this (Component component)
	{
		foreach (i; Iota!n)
			components[i] = component;
	}
    /**
        ditto
    */
	this (Component[n] components)
	{
		this.components = components;
	}
    /**
        ditto
    */
	this (R)(R range)
	in {
		assert (range.length == n);
	}
	body {
		foreach (i; Iota!n)
			components[i] = range[i];
	}
    ///
    unittest {
        enum a = Cons!(1,2,3,4);
        enum b = 1; // fill constructor
        int[] c = [1,2,3,4];
        int[4] d = [1,2,3,4];

        Vector!(4,int) x = a;
        Vector!(4,int) y = b;
        Vector!(4,int) z = c;
        Vector!(4,int) w = d;

        assert (x == [1,2,3,4]);
        assert (y == [1,1,1,1]);
        assert (z == [1,2,3,4]);
        assert (w == [1,2,3,4]);
    }

    /**
        converts the vector into a binary-compatible tuple
    */
	auto tuple ()
	{
        auto component (uint i)()
        {
            return components[i];
        }

		return Map!(component, Iota!n).tuple;
	}
    ///
    unittest {
        // compile-time tuple interop
        enum ct1 = vector(1,2).tuple;
        enum ct2 = .tuple(1,2);
        static assert (ct1 == ct2);
    }
}
