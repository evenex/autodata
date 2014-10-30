module evx.math.units.overloads;

private {/*imports}*/
	import std.traits;
//	import std.math;
	import std.conv;
	import std.typetuple;

//	import evx.math.logic;
	import evx.math.units.core;
	import evx.math.vectors;
	import evx.math.arithmetic;
}

public: import std.math: cos, sin, SQRT2;

mixin math_op!q{abs};
mixin math_op!q{sgn};
mixin math_op!q{isNaN};
mixin math_op!q{getNaNPayload};
mixin math_op!q{nextUp};
mixin math_op!q{nextUp};
mixin math_op!q{nextDown};
mixin math_op!q{floor};
mixin math_op!q{ceil};
mixin math_op!q{round};

// TODO approx

auto sqrt (T)(T value)
	{/*...}*/
		static if (is_Unit!T)
			{/*...}*/
				static assert (allSatisfy!(is_even, T.In_Pow), `cannot take square root of ` ~T.stringof);

				template div2 (T...)
					if (T.length == 1)
					{/*...}*/
						enum div2 = T[0]/2;
					}

				alias U = typeof(combine_dimension!(subtract, T, Unit!(T.In_Dim, staticMap!(div2, T.In_Pow)))());

				return U (std.math.sqrt (value.to!double));
			}
		else return std.math.sqrt (value);
	}

auto cbrt (T)(T value)
	{/*...}*/
		static if (is_Unit!T)
			{/*...}*/
				static assert (allSatisfy!(is_multiple_of!3, In_Pow),
					`cannot take cube root of ` ~T.stringof
				);

				template div3 (T...)
					if (T.length == 1)
					{/*...}*/
						enum div3 = T[0]/3;
					}

				auto ret = combine_dimension!(subtract, Unit, Unit!(In_Dim, staticMap!(div3, In_Pow)));

				ret.scalar = std.math.cbrt (this.scalar);

				return ret;
			}
		else return std.math.cbrt (value);
	}

auto squared (T)(T value)
	{/*...}*/
		return value.pow!2;
	}
alias sq = squared;

auto cubed (T)(T value)
	{/*...}*/
		return value.pow!3;
	}
alias cu = cubed;

auto power (long exponent, T)(T value)
	{/*...}*/
		static if (is_Unit!T)
			{/*...}*/
				static if (exponent > 0)
					auto ret = raise_dimension!(T, exponent);
				else static if (exponent < 0)
					auto ret = raise_dimension!(typeof(1/value), -exponent);

				static if (exponent == 0)
					Scalar ret = 1.0;
				else ret = typeof(ret)(value.to!double^^exponent);

				return ret;
			}
		else return value^^exponent;
	}
alias pow = power;

private {/*implementation}*/
	mixin template math_op (string op)
		{/*...}*/
			mixin(q{
				auto } ~op~ q{ (T...)(T args)
					}`{`q{
						static if (is_vector_like!(T[0]))
							return vector_} ~op~ q{ (vector (args[0]), args[1..$]);
						else return scalar_} ~op~ q{ (args);
					}`}`q{

				auto scalar_} ~op~ q{ (T...)(T args)
					}`{`q{
						static if (isBuiltinType!(T[0]))
							auto value = args[0];
						else auto value = args[0].to!double;

						static if (T.length == 1)
							return T[0] (std.math.} ~op~ q{ (value));
						else return std.math.} ~op~ q{ (value, args[1..$]);
					}`}`q{

				auto vector_} ~op~ q{ (T...)(T args)
					}`{`q{
						return args[0].each!scalar_} ~op~ q{ (args[1..$]);
					}`}`q{
			});
		}
}