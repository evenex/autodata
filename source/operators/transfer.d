module autodata.operators.transfer;

/* generate WriteOps with input bounds checking
	
	Requires:
		WriteOps requirements.
		Unlike with WriteOps, the element types, dimensionalities, and sizes of the transfer source and target data sets must match.
*/
template TransferOps (alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import autodata.operators.write;
		}

		auto verified_limit_pull (S, Selected...)(S source, Selected selected)
			in {/*...}*/
				import std.conv: text;
				import autodata.core.interval;

				version (all)
					{/*error messages}*/
						enum error_header = full_name!(typeof(this))~ `: `;

						enum type_mismatch_error = error_header
							~ `cannot transfer ` ~S.stringof~ ` to `
							~Filter!(is_interval, Selected).stringof
							~ ` subsource`;

						auto size_mismatch_error (T,U)(T this_size, U that_size)
							{/*...}*/
								return error_header
								~ `assignment size mismatch `
								`(` ~this_size.text~ ` != ` ~that_size.text~ `)`;
							}
					}

				static if (not (Any!(is_interval, Selected)))
					{}
				else static if (is (typeof(source.limit!0)))
					{/*...}*/
						void dimensions_check (uint i = 0)()
							{/*...}*/
								static if (is (typeof(source.limit!i)) || is (typeof(this[selected].limit!i)))
									{/*...}*/
										static assert (is (typeof(source.limit!i.left == this[selected].limit!i.left)),
											type_mismatch_error
										);

										dimensions_check!(i+1);
									}
							}

						auto bounds_check (size_t i, T)(T limit)
							{/*...}*/
								auto width = source.limit!i.width;

								static if (is (typeof(limit.width)))
									assert (width == limit.width,
										size_mismatch_error (width, limit.width)
									);
							}

						dimensions_check;

						foreach (i,j; Map!(Second, Filter!(First,
							Zip!(
								Pack!(Map!(is_interval, Selected)),
								Pack!(Ordinal!Selected)
							)
						))) bounds_check!i (selected[j]);
					}
				else static if (is (typeof(source.length.identity)) && not (is (typeof(this[selected].limit!1))))
					{/*...}*/
						assert (source.length == this[selected].limit!0.width,
							size_mismatch_error (source.length, this[selected].limit!0.width)
						);
					}
			}
			body {/*...}*/
				return pull (source, selected);
			}

		mixin WriteOps!(verified_limit_pull, access, LimitsAndExtensions)
			write_ops;
	}
	unittest {/*...}*/
		import autodata.core;
		import autodata.meta.test;
		import autodata.operators.write;
		import autodata.operators.slice;
		import autodata.operators.range;
		import autodata.sequence: enumerate;
		import std.range: only, retro;
		import std.math: approx = approxEqual;

		static struct Nat
			{/*...}*/
				static access (size_t i)
					{/*...}*/
						return i;
					}
				enum length = size_t.max;

				static mixin SliceOps!(access, length, RangeExt);
			}

		template Basic ()
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				auto pull (int x, size_t i)
					{/*...}*/
						data[i] = x;
					}
				auto pull (R)(R range, Interval!size_t limits)
					{/*...}*/
						foreach (i, j; enumerate (Nat[limits.left..limits.right]))
							data[j] = range[i];
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}
			}
		static struct WriteBasic
			{/*...}*/
				mixin Basic;
				mixin WriteOps!(pull, access, length);
			}
		static struct TransferBasic
			{/*...}*/
				mixin Basic;
				mixin TransferOps!(pull, access, length);
			}

		no_error (WriteBasic()[0..3] = [1,2,3,4]);
		error (TransferBasic()[0..3] = [1,2,3,4]);

		template AlternativePull ()
			{/*...}*/
				mixin Basic A;

				auto pull (string[], Interval!size_t){}
				auto pull (Args...)(Args args)
					{A.pull (args);}
			}
		static struct AltWrite
			{/*...}*/
				mixin AlternativePull;
				mixin WriteOps!(pull, access, length);
			}
		static struct AltTransfer
			{/*...}*/
				mixin AlternativePull;
				mixin TransferOps!(pull, access, length);
			}

		assert (is (typeof(AltWrite()[0..3] = [`hello`]))); // won't do input type check - who knows if we're assigning to a space of tagged unions?
		assert (is (typeof(AltTransfer()[0..3] = [`hello`])));

		static struct Negative
			{/*...}*/
				string[3] data = [`one`, `two`, `three`];

				int[2] limits = [-1,2];
				auto access (int i) {return data[i + 1];}

				auto pull (R)(R r, Interval!int x)
					{/*...}*/
						foreach (i; x.left..x.right)
							data[i + 1] = r[i - x.left];
					}
				auto pull (R)(R r, int x)
					{/*...}*/
						data[x + 1] = r;
					}

				mixin TransferOps!(pull, access, limits);
			}
		Negative x;
		assert (x[-1] == `one`);
		x[-1] = `minus one`;
		assert (x[-1] == `minus one`);
		assert (x[0] == `two`);
		assert (x[1] == `three`);
		x[0..$] = [`zero`, `one`];
		assert (x[0] == `zero`);
		assert (x[1] == `one`);
		error (x[~$..$] = [`1`, `2`, `3`, `4`]);

		static struct MultiDimensional
			{/*...}*/
				double[9] matrix = [
					1, 2, 3,
					4, 5, 6,
					7, 8, 9,
				];

				auto ref access (size_t i, size_t j)
					{/*...}*/
						return matrix[3*i + j];
					}

				enum size_t rows = 3, columns = 3;

				void pull (R)(R r, Interval!size_t y, size_t x)
					{/*...}*/
						foreach (i; y.left..y.right)
							access (i,x) = r[i - y.left];
					}
				void pull (R)(R r, size_t y, Interval!size_t x)
					{/*...}*/
						foreach (j; x.left..x.right)
							access (y,j) = r[j - x.left];
					}
				void pull (R)(R r, Interval!size_t y, Interval!size_t x)
					{/*...}*/
						foreach (i; y.left..y.right)
							pull (r[i - y.left, 0..$], i, x);
					}

				mixin TransferOps!(pull, access, rows, columns);
			}
		MultiDimensional y;
		assert (y.matrix == [
			1,2,3,
			4,5,6,
			7,8,9
		]);
		y[0,0] = 0; // pull (r, size_t, size_t) is unnecessary because access is ref
		assert (y.matrix == [
			0,2,3,
			4,5,6,
			7,8,9
		]);
		y[0..$, 0] = [6,6,6];
		assert (y.matrix == [
			6,2,3,
			6,5,6,
			6,8,9
		]);
		y[0, 0..$] = [9,9,9];
		assert (y.matrix == [
			9,9,9,
			6,5,6,
			6,8,9
		]);

		y.matrix = [
			0,0,1,
			0,0,1,
			1,1,1
		];

		MultiDimensional z;
		assert (z.matrix == [
			1,2,3,
			4,5,6,
			7,8,9
		]);
		z[0..2, 0..2] = y[0..2, 0..2];
		assert (z.matrix == [
			0,0,3,
			0,0,6,
			7,8,9
		]);
		z[0..2, 0..2] = y[1..3, 1..3];
		assert (z.matrix == [
			0,1,3,
			1,1,6,
			7,8,9
		]);
		z[1..3, 1..3] = y[1..3, 1..3];
		assert (z.matrix == [
			0,1,3,
			1,0,1,
			7,1,1
		]);
		z[0, 0..$] = y[0..$, 2];
		assert (z.matrix == [
			1,1,1,
			1,0,1,
			7,1,1
		]);

		error (z[0..2, 0..3] = y[0..3, 0..2]);
		error (z[0..2, 0] = y[0, 1..2]);
		static assert (not (is (typeof( (z[0..2, 0..3] = y[0..3, 1])))));
		static assert (not (is (typeof( (z[1, 0..3] = y[0..3, 0..2])))));

		static struct FloatingPoint
			{/*...}*/
				double delegate(double)[] maps;

				auto access (double x)
					{/*...}*/
						foreach (map; maps[].retro)
							if (x == map (x))
								continue;
							else return map (x);

						return x;
					}

				enum double length = 1;

				auto pull (T)(T y, double x)
					{/*...}*/
						maps ~= (t) => t == x? y : t;
					}
				auto pull (R)(R range, Interval!double domain)
					{/*...}*/
						if (domain.left == 0.0 && domain.right == 1.0)
							maps = null;

						maps ~= (t) => domain.left <= t && t < domain.right? 
							range[t - domain.left] : t;
					}

				mixin TransferOps!(pull, access, length);
			}
		static struct SqDomain
			{/*...}*/
				double factor = 1;
				double offset = 0;

				auto access (double x)
					{/*...}*/
						return factor * x + offset;
					}

				enum double length = 1;

				mixin SliceOps!(access, length);
			}
		FloatingPoint a;

		assert (a[0.00] == 0.00);
		assert (a[0.25] == 0.25);
		assert (a[0.50] == 0.50);
		assert (a[0.75] == 0.75);

		SqDomain b;
		b.factor = 2; b.offset = 1;
		assert (b[0.50] == 2.00);
		assert (b[0.75] == 2.50);

		a[0..$/2] = b[$/2..$];

		assert (a[0.75] == 0.75);
		assert (a[0.50] == 0.50);
		assert (a[0.25] == 2.50);
		assert (a[0.00] == 2.00);

		a[0.13] = 666;

		assert (a[0.12].approx (2.24));
		assert (a[0.13] == 666.0);
		assert (a[0.14].approx (2.28));
	}
