module autodata.operators.write;

/* generate index/slice assignment from a pull template, with SliceOps 

	Requires:
		SliceOps requirements.
		The pull symbol should resolve to a function (which may be a template and/or an overload set),
		which takes a source data object as the first parameter,
		and the indices and/or intervals of assignment as subsequent parameters.

	Optional:
		If the source data set defines a "push" primitive which accepts the Sub structure of the target data set as a parameter,
		then this push will take priority over the pull, in order to enable potentially expensive-to-access source data sets
		to perform optimized writes.
*/
template WriteOps (alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import autodata.operators.slice;
		}

		auto opIndexAssign (S, Selected...)(S space, Selected selected)
			in {/*...}*/
				this[selected];

				static assert (
					is (typeof(pull (space, selected))) 
					|| is (typeof(pull (space, this[].bounds)))
					|| is (typeof(access (selected) = space)),

					typeof(this).stringof~ ` cannot pull ` ~S.stringof
					~ ` through ` ~Selected.stringof
				);
			}
			body {/*...}*/
				void push_selected ()() {space[].push (this[selected]);}
				void access_assign ()() {access (selected) = space;}
				void pull_selected ()() {pull (space, selected);}
				void pull_complete ()() if (Selected.length == 0) {pull (space, this[].bounds);}

				Match!(push_selected, access_assign, pull_complete, pull_selected);

				return this[selected];
			}

		template SubWriteOps ()
			{/*...}*/
				auto ref opIndexAssign (S, string file = __FILE__, int line = __LINE__, Selected...)(S space, Selected selected)
					in {/*...}*/
						this[selected];

						static if (not (
							is (typeof(source.opIndexAssign (space, selected))) 
							|| is (typeof(source.opIndexAssign (space, this[].bounds))),
						))
							{/*...}*/
								static if (is (typeof(*space.source) == Src, Src))
									enum from = Src.stringof~ `.` ~S.stringof;
								else enum from = S.stringof;
							}
					}
					body {/*...}*/
						alias FreeIndices = Extract!(q{index}, Filter!(λ!q{(Axis) = Axis.is_free}, Axes));

						static if (Selected.length > 0)
							alias Selection (int i) = Select!(Contains!(i, FreeIndices),
								Select!(
									is_interval!(Selected[IndexOf!(i, FreeIndices)]),
									typeof(bounds[i]),
									typeof(bounds[i].left)
								),
								typeof(bounds[i].left)
							);
						else alias Selection (int i) = Select!(Contains!(i, FreeIndices),
							typeof(bounds[i]),
							typeof(bounds[i].left)
						);

						Map!(Selection, Ordinal!bounds)
							selection;

						foreach (i; Ordinal!bounds)
							static if (Selected.length == 0)
								selection[i] = bounds[i];
							else selection[i] = bounds[i].left;

						static if (Selected.length > 0)
							foreach (i,j; FreeIndices)
								selection[j] += selected[i] - limit!i.left;

						return source.opIndexAssign (space, selection);
					}

				auto push (S)(S space)
					{/*...}*/
						return source.push (space, this[].bounds);
					}
			}

		mixin SliceOps!(access, LimitsAndExtensions, SubWriteOps)
			slice_ops;

		template Diagnostic (Space = typeof(this))
			{/*...}*/
				alias Previous = slice_ops.Diagnostic!();

				pragma(msg, `write diagnostic: `, typeof(this));

				pragma (msg, "\tpulling ", Space, ` → `, typeof (pull (Space.init[], this[].bounds)));
			}
	}
	unittest {/*...}*/
		import std.conv: to, text;

		import autodata.meta.test;

		import autodata.operators.slice;
		import autodata.operators.range;

		import autodata.sequence: enumerate;
		import autodata.functional: map;
		import autodata.core;

		import std.range: only;


		static struct Nat
			{/*...}*/
				static access (size_t i)
					{/*...}*/
						return i;
					}
				enum length = size_t.max;

				static mixin SliceOps!(access, length, RangeExt);
			}

		static struct Basic
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				auto pull (int x, size_t i)
					{/*...}*/
					version (none)
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

				mixin WriteOps!(pull, access, length);
			}

		Basic x;

		assert (x[0] == 0);
		x[0] = 1;
		assert (x[0] == 1);

		no_error (x[0..2] = only (1,2,3));
		x[0..10] = only (10,9,8,7,6,5,4,3,2,1);
		assert (x[0] == 10);
		assert (x[1] == 9);
		assert (x[2] == 8);
		assert (x[3] == 7);
		assert (x[4] == 6);

		static struct Push
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				void pull (int x, size_t i)
					{/*...}*/
						data[i] = x;
					}
				void pull (R)(R range, Interval!size_t limit)
					{/*...}*/
						foreach (i; limit.left..limit.right)
							{/*...}*/
								data[i] = range.front;
								range.popFront;
							}
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				template PushExtension ()
					{/*...}*/
						enum PushExtension = q{
							void push (R)(auto ref R range)
								{/*...}*/
									auto ptr = range.ptr;

									foreach (i; 0..range.length)
										ptr[i] = 2;
								}
						};
					}

				mixin WriteOps!(pull, access, length, PushExtension);
			}
		int[5] y = [1,1,1,1,1];
		Push()[].push (y);
		assert (y[] == [2,2,2,2,2]);

		assert (x[0] == 10);
		assert (x[9] == 1);
		x[0..10] = Push()[0..10];
		assert (x[0] == 0); // x has no ptr
		assert (x[9] == 0);

		static struct Pull
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

				template Pointer ()
					{/*...}*/
						auto ptr ()
							{/*...}*/
								return source.data.ptr + bounds[0].left;
							}
					}
				template Length ()
					{/*...}*/
						auto length () const
							{/*...}*/
								return limit!0.width;
							}
					}

				mixin WriteOps!(pull, access, length, Pointer, Length);
			}
		Pull z;
		assert (z[0] == 0);
		assert (z[9] == 0);
		z[0..10] = Push()[0..10];
		assert (z[0] == 2); // z has ptr
		assert (z[9] == 2);

		auto w = z[];
		assert (w[0] == 2);
		assert (w[1] == 2);
		assert (w[2] == 2);
		w[0..3] = only (1,2,3);
		assert (w[0] == 1);
		assert (w[1] == 2);
		assert (w[2] == 3);
		no_error (w[0..3] = only (1,2,3,4));

		auto q = z[100..200];
		q[0..100] = Nat[800..900].map!(to!int);
		assert (q[0] == 800);
		assert (q[99] == 899);
		assert (z[100] == 800);
		assert (z[199] == 899);
		q[$/2..$] = Nat[120..170].map!(to!int);
		assert (q[0] == 800);
		assert (q[50] == 120);
		assert (q[99] == 169);
		assert (z[100] == 800);
		assert (z[150] == 120);
		assert (z[199] == 169);
		q[] = Nat[1111..1211].map!(to!int);
		assert (q[0] == 1111);
		assert (q[50] == 1161);
		assert (q[99] == 1210);
		assert (z[100] == 1111);
		assert (z[150] == 1161);
		assert (z[199] == 1210);

		z[] = Nat[0..z.length].map!(to!int);

		foreach (i; 0..z.length)
			assert (z[i] == i);
	}
