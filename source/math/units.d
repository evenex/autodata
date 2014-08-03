module evx.units;

private {/*import std}*/
	import std.conv:
		to, text;

	import std.typetuple:
		allSatisfy,
		staticIndexOf,
		Filter;

	import std.traits:
		isNumeric, isIntegral,
		ReturnType;

	import std.range: 
		empty;

	import std.algorithm:
		zip, sort,
		countUntil;

	import std.math: 
		std_abs = abs;
}
private {/*import evx}*/
	import evx.logic: 
		not,
		Or;

	import evx.arithmetic:
		add, subtract;

	import evx.traits: 
		is_numerical_param;

	import evx.meta:
		CompareBy;
}
unittest
	{/*demo}*/
		auto x = 10.meters;
		auto y = 5.seconds;

		static assert (not (is_equivalent_Unit!(typeof(x), typeof(y))));
		static assert (not (__traits(compiles, x + y)));
		static assert (__traits(compiles, x * y));

		auto z = 1.meter/second;

		auto w = z + x/y;

		assert (w == 3.meters/second);

		static assert (is (typeof(meter/meter) == Scalar));
		assert (x/x == 1.0);

		assert (x.power!2 == 100.meter*meters);
		assert (x.power!(-1) == 1.0 / 10.meters);
		assert (x.power!0 == 1.0);
	}

pure nothrow:

alias Scalar = double;

public:
public {/*mass}*/
	alias Kilograms = ReturnType!kilogram;
	alias Grams = ReturnType!gram;
	alias kilograms = kilogram;
	alias grams = gram;

	auto kilogram (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Mass, 1)(scalar);
		}
	auto gram (Scalar scalar = 1)
		{/*...}*/
			return (scalar/1000).kilogram;
		}
}
public {/*space}*/
	alias Meters = ReturnType!meter;
	alias Kilometers = ReturnType!kilometer;
	alias meters = meter;
	alias kilometers = kilometer;

	auto meter (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Space, 1)(scalar);
		}
	auto kilometer (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1000.meter;
		}
	auto square_meters (Scalar scalar = 1)
		{/*...}*/
			return scalar * meter*meters;
		}
}
public {/*time}*/
	alias Seconds = ReturnType!second;
	alias Minutes = ReturnType!minute;
	alias Hours = ReturnType!hour;
	alias seconds = second;
	alias minutes = minute;
	alias hours = hour;

	auto second (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Time, 1)(scalar);
		}
	auto minute (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Time, 1)(scalar/60.0);
		}
	auto hour (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Time, 1)(scalar/3600.0);
		}
}
public {/*force}*/
	alias Newtons = ReturnType!newton;
	alias newtons = newton;

	auto newton (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram*meter/second/second;
		}
}
public {/*frequency}*/
	alias Hertz = ReturnType!hertz;

	auto hertz (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1.0/second;
		}
}

public:
public {/*traits}*/
	template is_Unit (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_Unit = __traits(compiles, T[0].UnitTrait);
		}
}
public {/*math}*/
	auto abs (T)(const T quantity)
		{/*...}*/
			static if (is_Unit!T)
				return quantity.abs;
			else return std_abs (quantity);
		}
	auto approx (T, U)(const T a, const U b)
		{/*...}*/
			static if (is_Unit!T && is_Unit!U)
				return evx.analysis.approx (a.scalar, b.scalar);
			else return evx.analysis.approx (a, b);
		}
}
 
private:
private {/*unit}*/
	struct Unit (T...)
		if (allSatisfy!(Or!(is_Dimension, is_numerical_param), T))
		{/*...}*/
			public nothrow:
			pure const {/*math}*/
				auto opDispatch (string op)()
					{/*...}*/
						mixin(q{
							static if (__traits(compiles, Unit (} ~op~ q{ (scalar))))
								return Unit (} ~op~ q{ (scalar));
							else static assert (0);
						});
					}
				auto opDispatch (string op)(const auto ref Unit that)
					{/*...}*/
						mixin(q{
							static if (__traits(compiles, Unit (this.scalar.} ~op~ q{ (that.scalar))))
								return Unit (this.scalar.} ~op~ q{ (that.scalar));
							else static if (__traits(compiles, this.scalar.} ~op~ q{ (that.scalar)))
								return this.scalar.} ~op~ q{ (that.scalar);
							else static assert (0);
						});
					}
			}
			pure const {/*comparison}*/
				mixin CompareBy!to_scalar;
			}
			pure const {/*operators}*/
				auto opUnary (string op)()
					{/*...}*/
						Unit ret;
						mixin(q{
							ret.scalar = } ~ op ~ q{ this.scalar;
						});
						return ret;
					}
				auto opBinary (string op, U)(U rhs)
					{/*...}*/
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
								else static if (isNumeric!U)
									{/*...}*/
										Unit ret;

										mixin(q{
											ret.scalar = this.scalar } ~op~ q{ rhs;
										});

										return ret;
									}
								else static if (__traits(compiles, rhs.opBinaryRight!op (this)))
									{/*...}*/
										return rhs.opBinaryRight!op (this);
									}
								else static assert (0, `incompatible types for ` ~Unit.stringof~ ` ` ~op~ ` ` ~U.stringof);
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
							static assert (0, `use unit.power!n or unit.pow!n instead of unit^^n`);
					}
				auto opBinaryRight (string op, U)(U lhs)
					{/*...}*/
						static assert (not (op == `^^`));

						static if (op is `/` && isNumeric!U)
							{/*...}*/
								auto ret = reciprocate_dimension!Unit;

								ret.scalar = lhs / this.scalar;
									
								return ret;
							}
						else mixin(q{
							return this } ~ op ~ q{ lhs;
						});
					}
				auto power (long exponent)()
					{/*...}*/
						static if (exponent > 0)
							auto ret = raise_dimension!(Unit, exponent);
						else static if (exponent < 0)
							auto ret = raise_dimension!(typeof(1/this), -exponent);

						static if (exponent == 0)
							Scalar ret = 1.0;
						else ret.scalar = this.scalar^^exponent;

						return ret;
					}
				alias pow = power;
			}
			pure {/*assignment}*/
				auto opOpAssign (string op, U)(U rhs)
					{/*...}*/
						mixin(q{
							this = this } ~op~ q{ rhs;
						});
					}
				auto opAssign (Unit that)
					{/*...}*/
						this.scalar = that.scalar;
					}
			}
			const @property {/*text}*/
				auto toString ()
					{/*...}*/
						try {/*...}*/
							alias Dims = Filter!(is_Dimension, T);

							string[] dims;
							foreach (Dim; Dims)
								{/*...}*/
									static if (is (Dim == Space))
										dims ~= `m`;
									else static if (is (Dim == Time))
										dims ~= `s`;
									else static if (is (Dim == Mass))
										dims ~= `kg`;
								}

							auto powers = [Filter!(is_numerical_param, T)];

							auto sorted_by_descending_power = zip (dims, powers)
								.sort!((a,b) => a[1] > b[1]);
							
							auto n_positive_powers = sorted_by_descending_power
								.countUntil!(a => a[1] < 0);

							if (n_positive_powers < 0)
								n_positive_powers = dims.length;

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

							dstring output = scalar.to!dstring ~ ` `;

							foreach (dim; numerator)
								output ~= dim[0].to!dstring ~ to_superscript (dim[1]);

							output ~= denominator.length? `/` : ``;

							foreach (dim; denominator)
								output ~= dim[0].to!dstring ~ to_superscript (dim[1]);

							return output;
						}
						catch (Exception) assert (0);
					}
			}
			pure const @property {/*conversion}*/
				Scalar to_scalar ()
					{/*...}*/
						return scalar;
					}
			}

			private:
			private {/*...}*/
				alias In_Dim = Filter!(is_Dimension, T);
				alias In_Pow = Filter!(is_numerical_param, T);
				static assert (In_Dim.length == In_Pow.length,
					`dimension/power mismatch`
				);
			}

			Scalar scalar;
			enum UnitTrait;
			alias Dimension = T;

			this (T)(T value)
				if (isNumeric!T)
				{/*...}*/
					scalar = value;
				}

		}
}
private {/*base dimensions}*/
	struct Mass
		{/*...}*/
			enum DimensionTrait;
		}
	struct Space
		{/*...}*/
			enum DimensionTrait;
		}
	struct Time
		{/*...}*/
			enum DimensionTrait;
		}
}
private {/*code generation}*/
	auto combine_dimension (alias op, T, U)()
		if (allSatisfy!(is_Unit, T, U))
		{/*...}*/
			static auto code ()()
				{/*...}*/
					alias TDim = Filter!(is_Dimension, T.Dimension);
					alias TPow = Filter!(is_numerical_param, T.Dimension);
					alias UDim = Filter!(is_Dimension, U.Dimension);
					alias UPow = Filter!(is_numerical_param, U.Dimension);

					string code;

					foreach (i, Dim; TDim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, UDim);
							static if (j >= 0)
								{/*...}*/
									static if (op (TPow[i], UPow[j]) != 0)
										code ~= Dim.stringof ~ q{, } ~ op (TPow[i], UPow[j]).text ~ q{, };
								}
							else code ~= Dim.stringof ~ q{, } ~ TPow[i].text ~ q{, };
						}
					foreach (i, Dim; UDim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, TDim);
							static if (j < 0)
								code ~= Dim.stringof ~ q{, } ~ op (0, UPow[i]).text ~ q{, };
						}

					return code;
				}

			static if (code.empty)
				return Scalar.init;
			else mixin(q{
				return Unit!(} ~ code ~ q{).init;
			});
		}
	auto reciprocate_dimension (T)()
		if (is_Unit!T)
		{/*...}*/
			static auto code ()()
				{/*...}*/
					alias TDim = Filter!(is_Dimension, T.Dimension);
					alias TPow = Filter!(is_numerical_param, T.Dimension);

					string code;

					foreach (i, Dim; TDim)
						code ~= Dim.stringof~ q{, } ~(-TPow[i]).text~ q{, };

					return code;
				}

			static assert (not (code.empty));
			mixin(q{
				return Unit!(} ~code~ q{).init;
			});
		}
	auto raise_dimension (T, size_t exponent)()
		{/*...}*/
			auto raise_dimension (Accumulator, size_t pow)()
				{/*...}*/
					static if (pow == 1)
						return Accumulator.init;
					else return raise_dimension!(
						typeof(combine_dimension!(add, Accumulator, T)()),
						pow-1
					);
				}

			return raise_dimension!(T, exponent);
		}
}
private {/*traits}*/
	template is_Dimension (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_Dimension = __traits(compiles, T[0].DimensionTrait);
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
private {/*forwarding}*/
	auto ref Scalar scalar ()(auto ref Scalar s)
		{/*...}*/
			return s;
		}
}
