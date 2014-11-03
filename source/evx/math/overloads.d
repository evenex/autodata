module evx.math.overloads;

private {/*imports}*/
	import evx.math.vectors;
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
mixin math_op!q{power};
mixin math_op!q{sqrt};
mixin math_op!q{cbrt};

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
						return resolve_call!op (args);
					}`}`q{

				auto vector_} ~op~ q{ (T...)(T args)
					}`{`q{
						return args[0].each!scalar_} ~op~ q{ (args[1..$]);
					}`}`q{
			});
		}

	auto ref resolve_call (string op, Args...)(Args args)
		{/*...}*/
			static if (__traits(hasMember, Args[0], op))
				mixin(q{
					static if (T.length == 1)
						return args[0].} ~op~ q{;
					else return args[0].} ~op~ q{ (args[1..$]);
				});
			else mixin(q{
				static if (is(typeof(evx.math.arithmetic.} ~op~ q{ (args))))
					return evx.math.arithmetic} ~op~ q{ (args);
				else static if (is(typeof(std.math.} ~op~ q{(args))))
					return std.math.} ~op~ q{ (args);
			});
		}
}
