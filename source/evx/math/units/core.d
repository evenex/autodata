module evx.math.units.core;

private {/*imports}*/
	static import std.datetime;
	private {/*std}*/
		import std.conv;
		import std.typetuple;
		import std.traits;
		import std.range; 
		import std.algorithm;
		import std.format;
//		import std.array;
	}
	private {/*evx}*/
		//import evx.misc.utils; 
		import evx.misc.string; 
//		import evx.traits; 
		import evx.meta;

//		import evx.operators.comparison;

		import evx.math.logic;
		import evx.math.arithmetic;
	}
}

unittest {/*demo}*/
	import evx.math.units.metric;
	import evx.math.units.overloads;

	auto x = 10.meters;
	auto y = 5.seconds;

	static assert (not (is (typeof(x) == typeof(y))));
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

public:
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

	auto dimensionless (U)(U unit)
		{/*...}*/
			return unit.dimensionless;
		}
}
 
alias Scalar = double;

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
		if (allSatisfy!(Or!(is_Dimension, is_numerical_param), T))
		{/*...}*/
			public:
			pure const nothrow {/*comparison}*/
				mixin ComparisonOps!scalar;
			}
			pure const nothrow {/*operators}*/
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
						static if (`/``*`.canFind (op))
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
								else static if (isNumeric!U)
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
						else static if (`+``-``%`.canFind (op))
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

						static if (op is `/` && isNumeric!U)
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
			pure nothrow {/*assignment}*/
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

								auto sorted_by_descending_power = zip (dims, powers).array
									.sort!((a,b) => (a[1] > 0 && 0 > b[1]) || (a[1] * b[1] > 0 && a[0][0] < b[0][0]));
								
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
										uint n = std.math.abs(num).to!uint;
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
						return Unit (input.extract_number.to!double);
					}
			}
			pure const nothrow @property {/*cast}*/
				auto opCast (T : Scalar)()
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

			this (U)(U value)
				if (isNumeric!U)
				{/*...}*/
					scalar = value;
				}

			this (Unit quantity)
				{/*...}*/
					this.scalar = quantity.scalar;
				}

			this (String)(String input)
				if (isSomeString!String)
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

package:
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
static {/*code generation}*/
	auto combine_dimension (alias op, T, U)()
		if (allSatisfy!(is_Unit, T, U))
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
							const auto j = staticIndexOf!(Dim, UDim);

							static if (j >= 0)
								{/*...}*/
									static if (op (TPow[i], UPow[j]) != 0)
										dims ~= Dim.stringof ~ q{, } ~ op (TPow[i], UPow[j]).text ~ q{, };
								}
							else dims ~= Dim.stringof ~ q{, } ~ TPow[i].text ~ q{, };
						}
					foreach (i, Dim; UDim)
						{/*...}*/
							const auto j = staticIndexOf!(Dim, TDim);
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
	auto raise_dimension (T, ulong exponent)()
		{/*...}*/
			auto raise_dimension (Accumulator, ulong pow)()
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