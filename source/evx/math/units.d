module evx.math.units;

private {/*imports}*/
	import std.math;
	import std.conv;
	import std.algorithm;

	import evx.type;
	import evx.operators;
	import evx.range;

	import evx.math.logic;
	import evx.math.floatingpoint;
	import evx.math.infinity;
	import evx.math.arithmetic;
}

unittest {/*demo}*/
	auto x = 10.meters;
	auto y = 5.seconds;

	static assert (not (is (typeof(x) == typeof(y))));
	static assert (not (is (typeof(x + y))));
	static assert (is (typeof(x * y)));

	auto z = 1.meter/second;

	auto w = z + x/y;

	assert (w == 3.meters/second);

	static assert (is (typeof(meter/meter) == Scalar));
	assert (x/x == 1.0);

	assert (x.power!2 == 100.meter*meters);
	assert (x.power!(-1) == 1.0 / 10.meters);
	assert (x.power!0 == 1.0);
}

public:
public {/*traits}*/
	template is_Unit (T...)
		if (T.length == 1)
		{/*...}*/
			alias U = T[0];
			enum is_Unit = is (U.UnitTrait == enum);
		}
	template is_Dimension (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_Dimension = __traits(compiles, T[0].DimensionTrait);
		}
}
public {/*Time ↔ std.datetime.Duration}*/
	auto to_duration (Seconds time)
		{/*...}*/
			return std.datetime.nsecs ((time.to!Scalar * 1_000_000_000).to!long);
		}
	auto to_evx_time (std.datetime.Duration duration)
		{/*...}*/
			return duration.total!`nsecs`.nanoseconds;
		}
}
public {/*convenience functions}*/
	auto squared (alias unit)(Scalar scalar)
		{/*...}*/
			return unit (scalar) * unit;
		}

	auto cubic (alias unit)(Scalar scalar)
		if (is_Unit!(ReturnType!unit))
		{/*...}*/
			return unit (scalar) * unit * unit;
		}
}
 
version (FLOAT_UNITS)
	alias Scalar = float;
else alias Scalar = double;

immutable string[string] abbreviation_map; 
shared static this ()
	{/*...}*/
		abbreviation_map = [
			`kgm²/As³`: `V`,
			`kgm/s²`: `N`,
			`/s`: `Hz`,
		];
	}

pure nothrow:
public {/*unit}*/
	struct Unit (T...)
		if (All!(or!(is_Dimension, is_numerical_param), T))
		{/*...}*/
			public:
			const {/*math}*/
				const {/*unary}*/
					auto abs ()
						{/*...}*/
							return Unit (.abs (this.scalar));
						}
					auto sgn ()
						{/*...}*/
							return scalar < 0.0? -1: 1;
						}
				}
				const {/*approx}*/
					auto approx (Unit a, real tolerance = 1./10_000)
						{/*...}*/
							return this.scalar.approx (a.scalar, tolerance);
						}
				}
				const {/*exponents}*/
					auto squared ()()
						{/*...}*/
							return this.pow!2;
						}
					alias sq = squared;

					auto sqrt ()()
						if (All!(is_even, In_Pow))
						{/*...}*/
							template div2 (T...)
								if (T.length == 1)
								{/*...}*/
									enum div2 = T[0]/2;
								}

							auto ret = combine_dimension!(subtract, Unit, Unit!(In_Dim, staticMap!(div2, In_Pow)));

							ret.scalar = .sqrt (this.scalar);

							return ret;
						}

					auto cubed ()()
						{/*...}*/
							return this.pow!3;
						}
					alias cu = cubed;

					auto cbrt ()()
						if (All!(is_multiple_of!3, In_Pow))
						{/*...}*/
							template div3 (T...)
								if (T.length == 1)
								{/*...}*/
									enum div3 = T[0]/3;
								}

							auto ret = combine_dimension!(subtract, Unit, Unit!(In_Dim, staticMap!(div3, In_Pow)));

							ret.scalar = .cbrt (this.scalar);

							return ret;
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
				const {/*NaN}*/
					auto isNaN ()
						{/*...}*/
							return .isNaN (scalar);
						}

					auto get_NaN_payload ()
						in {/*...}*/
							assert (this.isNaN);
						}
						body {/*...}*/
							return getNaNPayload (scalar);
						}

					auto set_NaN_payload (ulong payload)
						in {/*...}*/
							assert (payload >= 0x3_FFFF_FFFF_FFFF);
						}
						out {/*...}*/
							assert (this.isNaN);
						}
						body {/*...}*/
							return Unit (NaN (payload));
						}
				}
				const {/*next}*/
					auto next_up ()
						{/*...}*/
							return Unit (nextUp (scalar));
						}
					auto next_down ()
						{/*...}*/
							return Unit (nextDown (scalar));
						}
				}
				const {/*rounding}*/
					auto floor ()
						{/*...}*/
							return Unit (.floor (scalar));
						}

					auto ceil ()
						{/*...}*/
							return Unit (.ceil (scalar));
						}

					auto round ()
						{/*...}*/
							return Unit (.round (scalar));
						}
				}
				const {/*is_infinite}*/
					auto is_infinite ()
						{/*...}*/
							return .is_infinite (scalar);
						}
				}
			}
			const {/*comparison}*/
				mixin ComparisonOps!dimensionless;
			}
			const {/*operators}*/
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
						static if (`/``*`.contains (op))
							{/*...}*/
								static if (is_Unit!U)
									{/*...}*/
										static if (op == `*`)
											auto ret = combine_dimension!(add, Unit, U);
										else auto ret = combine_dimension!(subtract, Unit, U);

										static if (is_Unit!(typeof(ret))) mixin(q{
											ret.scalar = this.scalar } ~op~ q{ rhs.scalar;
										}); else mixin(q{
											ret = this.scalar } ~op~ q{ rhs.scalar;
										});


										return ret;
									}
								else static if (is_numeric!U)
									{/*...}*/
										mixin(q{
											return Unit (this.scalar } ~op~ q{ rhs);
										});
									}
								else static if (__traits(compiles, rhs.opBinaryRight!op (this)))
									{/*...}*/
										return rhs.opBinaryRight!op (this);
									}
								else static assert (0, `incompatible types for ` ~Unit.stringof~ ` ` ~op~ ` ` ~U.stringof);
							}
						else static if (`+``-``%`.contains (op))
							{/*...}*/
								static assert (is_Unit!U, `cannot add dimensionless quantity to ` ~ Unit.stringof);

								static if (is (Unit: U))
									{/*...}*/
										mixin(q{
											return Unit (this.scalar } ~op~ q{ rhs.scalar);
										});
									}
								else static assert (0, `attempted linear combination of non-equivalent `
									~ Unit.stringof ~ ` and ` ~ U.stringof
								);
							}
						else static if (op == `^^`)
							static assert (0, `use unit.power!n or unit.pow!n instead of unit^^n`);
					}
				auto opBinaryRight (string op, U)(U lhs)
					{/*...}*/
						static assert (not (op == `^^`));

						static if (op is `/` && is_numeric!U)
							{/*...}*/
								auto ret = reciprocate_dimension!Unit;

								ret.scalar = lhs.to!Scalar / this.scalar;
									
								return ret;
							}
						else mixin(q{
							return this } ~ op ~ q{ lhs;
						});
					}
			}
			public {/*assignment}*/
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
				string toString (size_t precision)
					{/*...}*/
						return toString (``, precision);
					}

				string toString (string abbreviation = ``, size_t precision = 6)
					{/*...}*/
						import std.array: appender;
						import std.format: formattedWrite;
						import std.range: zip;

						if (abbreviation.empty)
							{/*...}*/
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
										else static if (is (Dim == Current))
											dims ~= `A`;
										else static assert (0, Dim.stringof~ ` to string unimplemented`);
									}

								auto powers = [Filter!(is_numerical_param, T)];

								auto sorted_by_descending_power = zip (dims, powers)
									.sort!((a,b) => (a[1] > 0 && 0 > b[1]) || (a[1] * b[1] > 0 && a[0][0] < b[0][0]));
								
								auto n_positive_powers = sorted_by_descending_power
									.count_until!(a => a[1] < 0);

								if (n_positive_powers < 0)
									n_positive_powers = dims.length;

								auto numerator   = sorted_by_descending_power
									[0..n_positive_powers];

								auto denominator = sorted_by_descending_power
									[n_positive_powers..$];

								static auto to_superscript (U)(U num)
									{/*...}*/
										uint n = .abs(num).to!uint;
										if (n < 4)
											{/*...}*/
												if (n == 1)
													return ``.text;
												else return (0x00b0 + n).to!dchar.text;
											}
										else {/*...}*/
											return (0x2070 + n).to!dchar.text;
										}
									}

								auto writer = appender!string (); // TEMP
								writer.formattedWrite ("%." ~precision.text~ "g ", scalar);
								string output = writer.data;

								foreach (dim; numerator)
									output ~= dim[0].text ~ to_superscript (dim[1]);

								output ~= denominator.length? `/` : ``;

								foreach (dim; denominator)
									output ~= dim[0].text ~ to_superscript (dim[1]);

								auto split = output.findSplitAfter (` `);

								if (auto translated = split[1] in abbreviation_map)
									return split[0] ~ *translated;
								else return output;
							}
						else return scalar.text~ ` ` ~abbreviation;
					}

				static from_string (string input)
					{/*...}*/
						import evx.misc.string;

						return Unit (input.extract_number.to!double);
					}
			}
			const @property {/*conversion}*/
				Scalar dimensionless ()
					{/*...}*/
						return scalar;
					}

				template opCast (T : Scalar)
					{/*...}*/
						alias opCast = dimensionless;
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

			this (U)(U value)
				if (is_numeric!U)
				{/*...}*/
					scalar = value;
				}

			this (Unit quantity)
				{/*...}*/
					this.scalar = quantity.scalar;
				}

			this (String)(String input)
				if (is_string!String)
				{/*...}*/
					this = from_string (input);
				}
		}
}
public {/*base dimensions}*/
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
	struct Current
		{/*...}*/
			enum DimensionTrait;
		}
}

public {/*mass}*/
	alias Kilograms = ReturnType!kilogram;
	alias kilograms = kilogram;
	alias grams = gram;

	auto kilogram (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Mass, 1)(scalar);
		}
	auto gram (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram/1000;
		}
}
public {/*space}*/
	alias Meters = ReturnType!meter;

	alias meters = meter;
	alias kilometers = kilometer;
	alias millimeters = millimeter;

	auto meter (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Space, 1)(scalar);
		}
	auto kilometer (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1000.meter;
		}
	auto millimeter (Scalar scalar = 1)
		{/*...}*/
			return scalar * 0.001.meter;
		}
}
public {/*time}*/
	alias Seconds = ReturnType!second;
	alias seconds = second;
	alias minutes = minute;
	alias hours = hour;
	alias milliseconds = millisecond;
	alias nanoseconds = nanosecond;

	auto second (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Time, 1)(scalar);
		}
	auto minute (Scalar scalar = 1)
		{/*...}*/
			return scalar * 60.seconds;
		}
	auto hour (Scalar scalar = 1)
		{/*...}*/
			return scalar * 60.minutes;
		}
	auto millisecond (Scalar scalar = 1)
		{/*...}*/
			return scalar * second/1000;
		}
	auto nanosecond (Scalar scalar = 1)
		{/*...}*/
			return scalar * second/1_000_000_000;
		}
}
public {/*current}*/
	alias Amperes = ReturnType!ampere;
	alias amperes = ampere;

	auto ampere (Scalar scalar = 1)
		{/*...}*/
			return Unit!(Current, 1)(scalar);
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
public {/*energy}*/
	alias Joules = ReturnType!joule;
	alias joules = joule;

	auto joule (Scalar scalar = 1)
		{/*...}*/
			return scalar * newton*meters;
		}
}
public {/*torque}*/
	alias NewtonMeters = ReturnType!newton_meter;
	alias newton_meters = newton_meter;

	alias newton_meter = joule;
}
public {/*frequency}*/
	alias Hertz = ReturnType!hertz;

	auto hertz (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1.0/second;
		}
	auto kilohertz (Scalar scalar = 1)
		{/*...}*/
			return scalar * 1000.0/second;
		}
}
public {/*voltage}*/
	alias Volts = ReturnType!volt;
	alias volts = volt;

	auto volt (Scalar scalar = 1)
		{/*...}*/
			return scalar * kilogram * meters.pow!2 * seconds.pow!(-3) * amperes.pow!(-1);
		}
}

private:
private {/*code generation}*/
	auto combine_dimension (alias op, T, U)()
		if (All!(is_Unit, T, U))
		{/*...}*/
			static code ()
				{/*...}*/
					alias TDim = Filter!(is_Dimension, T.Dimension);
					alias TPow = Filter!(is_numerical_param, T.Dimension);
					alias UDim = Filter!(is_Dimension, U.Dimension);
					alias UPow = Filter!(is_numerical_param, U.Dimension);

					string[] dims;

					foreach (i, Dim; TDim)
						{/*...}*/
							const auto j = IndexOf!(Dim, UDim);

							static if (j >= 0)
								{/*...}*/
									static if (op (TPow[i], UPow[j]) != 0)
										dims ~= Dim.stringof ~ q{, } ~ op (TPow[i], UPow[j]).text ~ q{, };
								}
							else dims ~= Dim.stringof ~ q{, } ~ TPow[i].text ~ q{, };
						}
					foreach (i, Dim; UDim)
						{/*...}*/
							const auto j = IndexOf!(Dim, TDim);
							static if (j < 0)
								dims ~= Dim.stringof ~ q{, } ~ op (0, UPow[i]).text ~ q{, };
						}

					string code;

					foreach (dim; dims.sort!((s,t) => s[0] < t[0]))
						code ~= dim;

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
			static code ()
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