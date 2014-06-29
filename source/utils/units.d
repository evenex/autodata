module units;

import std.conv;
import std.typetuple;
import std.traits;
import utils;

public {/*mass}*/
	auto kilogram (double scalar = 1)
		{/*...}*/
			return Unit!(Kilogram, 1)(scalar);
		}
	auto gram (double scalar = 1)
		{/*...}*/
			return (scalar/1000).kilogram;
		}
}
public {/*space}*/
	auto meter (double scalar = 1)
		{/*...}*/
			return Unit!(Meter, 1)(scalar);
		}
	auto kilometer (double scalar = 1) // TODO into doubles
		{/*...}*/
			return scalar*1000.meter;
		}
}
public {/*time}*/
	auto second (double scalar = 1)
		{/*...}*/
			return Unit!(Second, 1)(scalar);
		}
}
public {/*force}*/
	auto newton (double scalar = 1)
		{/*...}*/
			return kilogram*meter/second/second;
		}
}
 
private {/*unit analysis}*/
	struct Unit (T...)
		if (allSatisfy!(templateOr!(is_Dimension, is_numerical_param), T))
		{/*...}*/
			private {/*...}*/
				alias In_Dim = Filter!(is_Dimension, T);
				alias In_Pow = Filter!(is_numerical_param, T);
				static assert (In_Dim.length == In_Pow.length,
					`dimension/power mismatch`
				);
			}

			double scalar;
			enum UnitTrait;
			alias Dimension = T;

			this (T)(T value)
				if (isNumeric!T)
				{/*...}*/
					scalar = value;
				}
			auto opUnary (string op)() const
				{/*...}*/
					Unit ret;
					mixin(q{
						ret.scalar = } ~ op ~ q{ this.scalar;
					});
					return ret;
				}
			auto opBinary (string op, U)(U rhs) const
				{/*...}*/
					static int add (int a, int b) {return a + b;}
					static int subtract (int a, int b) {return a - b;}

					static if (op == `/` || op ==  `*`)
						{/*...}*/
							static if (is_Unit!U)
								{/*...}*/
									static if (op == `*`)
										auto ret = combine_dimension!(add, Unit, U);
									else auto ret = combine_dimension!(subtract, Unit, U);

									mixin(q{
										ret.scalar = this.scalar } ~ op ~ q{ rhs.scalar;
									});
									return ret;
								}
							else {/*...}*/
								Unit ret;
								mixin(q{
									ret.scalar = this.scalar } ~ op ~ q{ rhs;
								});
								return ret;
							}
						}
					else static if (op == `+` || op == `-`)
						{/*...}*/
							static assert (is_Unit!U, `cannot add dimensionless quantity to ` ~ Unit.stringof);
							static if (is_equivalent_Unit!(Unit, U))
								{/*...}*/
									Unit ret;
									mixin(q{
										ret.scalar = this.scalar} ~ op ~ q{ rhs.scalar;
									});
									return ret;
								}
							else static assert (0, `attempt to linearly combine non-equivalent `
								~ Unit.stringof ~ ` and ` ~ U.stringof
							);
						}
					else static if (op == `^^`)
						{/*...}*/
							// TODO double all the dimensions and then square the scalar
						}
				}
			auto opBinaryRight (string op, U)(U lhs) const
				{/*...}*/
					static assert (not (op == `^^`));
					mixin(q{
						return this } ~ op ~ q{ lhs;
					});
				}
			/*TODO - opAssign, opOpAssign */
			auto toString () const
				{/*...}*/
					import std.algorithm;
					import std.range;
					import std.math;
					import std.string;

					alias Dims = Filter!(is_Dimension, T);

					string[] dims;
					foreach (Dim; Dims)
						dims ~= ` ` ~ Dim.stringof.toLower;
					auto powers = [Filter!(is_numerical_param, T)];

					auto sorted_by_descending_power = zip (dims, powers)
						.sort!((a,b) => a[1] > b[1]);
					
					auto n_positive_powers = sorted_by_descending_power
						.countUntil!(a => a[1] < 0);

					auto numerator   = sorted_by_descending_power
						[0..n_positive_powers];

					auto denominator = sorted_by_descending_power
						[n_positive_powers..$];

					static auto to_superscript (U)(U num)
						{/*...}*/
							uint n = abs(num).to!uint;
							if (n < 3)
								{/*...}*/
									if (n == 1)
										return ``.to!dstring;
									else return (0x00b0 + n).to!dchar.to!dstring;
								}
							else {/*...}*/
								return (0x2070 + n).to!dchar.to!dstring;
							}
						}

					dstring output = scalar.to!dstring;

					foreach (dim; numerator)
						output ~= dim[0].to!dstring ~ to_superscript (dim[1]);

					output ~= denominator.length? ` /` : ``;

					foreach (dim; denominator)
						output ~= dim[0].to!dstring ~ to_superscript (dim[1]);

					return output;
				}
		}
}
private {/*code generation}*/
	auto combine_dimension (alias op, T, U)()
		if (allSatisfy!(is_Unit, T, U))
		{/*...}*/
			static auto code ()()
				{/*...}*/
					alias T_Dim = Filter!(is_Dimension, T.Dimension);
					alias T_Pow = Filter!(is_numerical_param, T.Dimension);
					alias U_Dim = Filter!(is_Dimension, U.Dimension);
					alias U_Pow = Filter!(is_numerical_param, U.Dimension);

					string code;

					foreach (i, Dim; T_Dim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, U_Dim);
							static if (j >= 0)
								{/*...}*/
									static if (op (T_Pow[i], U_Pow[j]) != 0)
										code ~= Dim.stringof ~ q{, } ~ op (T_Pow[i], U_Pow[j]).text ~ q{, };
								}
							else code ~= Dim.stringof ~ q{, } ~ T_Pow[i].text ~ q{, };
						}
					foreach (i, Dim; U_Dim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, T_Dim);
							static if (j < 0)
								code ~= Dim.stringof ~ q{, } ~ op (0, U_Pow[i]).text ~ q{, };
						}

					return code;
				}

			mixin(q{
				Unit!(} ~ code ~ q{) ret;
			});
			return ret;
		}
}
private {/*dimensions}*/
	struct Kilogram
		{/*...}*/
			enum DimensionTrait;
		}
	struct Meter
		{/*...}*/
			enum DimensionTrait;
		}
	struct Second
		{/*...}*/
			enum DimensionTrait;
		}
}
private {/*traits}*/
	template is_Dimension (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_Dimension = __traits(compiles, T[0].DimensionTrait);
		}
	template is_Unit (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_Unit = __traits(compiles, T[0].UnitTrait);
		}
	template is_equivalent_Unit (T, U)
		if (allSatisfy!(is_Unit, T, U))
		{/*...}*/
			const bool is_equivalent_Unit ()
				{/*...}*/
					alias T_Dim = Filter!(is_Dimension, T.Dimension);
					alias T_Pow = Filter!(is_numerical_param, T.Dimension);
					alias U_Dim = Filter!(is_Dimension, U.Dimension);
					alias U_Pow = Filter!(is_numerical_param, U.Dimension);

					foreach (i, Dim; T_Dim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, U_Dim);
							static if (j < 0)
								return false;
							else static if (T_Pow[i] != U_Pow[j])
								return false;
						}
					foreach (i, Dim; U_Dim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, T_Dim);
							static if (j < 0)
								return false;
							else static if (U_Pow[i] != T_Pow[j])
								return false;
						}

					return true;
				}
		}
}

unittest
	{/*...}*/
		auto x = 10.meter;
		auto y = 5.second;

		static assert (not (is_equivalent_Unit!(typeof(x), typeof(y))));
		static assert (not (__traits(compiles, x + y)));
		static assert (__traits(compiles, x * y));

		auto z = 600.meter/second;

		auto w = z + x/y;

		assert (w == 602.meter/second);
	}
