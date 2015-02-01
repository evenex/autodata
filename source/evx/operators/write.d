module evx.operators.write;

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
			import evx.operators.slice;
			import evx.type;
		}

		auto opIndexAssign (S, Selected...)(S space, Selected selected)
			in {/*...}*/
				this[selected];

				static assert (
					is (typeof(pull (space, selected))) 
					|| is (typeof(pull (space, this[].bounds)))
					|| is (typeof(access (selected) = space)),

					typeof(this).stringof ~ ` cannot pull ` ~ S.stringof
					~ ` through ` ~ Selected.stringof
				);
			}
			body {/*...}*/
				void push_selected ()() {space[].push (this[selected]);}
				void access_assign ()() {access (selected) = space;}
				void pull_selected ()() {pull (space, selected);}
				void pull_complete ()() if (Selected.length == 0) {pull (space, this[].bounds);}

				Match!(push_selected, access_assign, pull_selected, pull_complete);

				return this[selected];
			}

		template SubWriteOps ()
			{/*...}*/
				auto ref opIndexAssign (S, Selected...)(S space, Selected selected)
					in {/*...}*/
						this[selected];

						static if (not (
							is (typeof(source.opIndexAssign (space, selected))) 
							|| is (typeof(source.opIndexAssign (space, this[].bounds))),
						)) pragma(msg, `warning: rejected assignment of `, S, ` to `, typeof(this), `[`, Selected ,`]`);
					}
					body {/*...}*/
						static if (Selected.length > 0)
							alias Selection (int i) = Select!(Contains!(i, Dimensions),
								Select!(
									is (Selected[IndexOf!(i, Dimensions)] == T[2], T),
									typeof(bounds[i]),
									typeof(bounds[i].left)
								),
								typeof(bounds[i].left)
							);
						else alias Selection (int i) = Select!(Contains!(i, Dimensions),
							typeof(bounds[i]),
							typeof(bounds[i].left)
						);

						Map!(Selection, Count!bounds)
							selection;

						foreach (i; Count!bounds)
							static if (is (typeof(selection[i]) == T[2], T))
								{/*...}*/
									static if (Selected.length == 0)
										selection[i] = bounds[i];

									else selection[i][] = bounds[i].left;
								}
							else selection[i] = bounds[i].left;

						static if (Selected.length > 0)
							{/*...}*/
								foreach (i,j; Dimensions)
									static if (is (typeof(selection[j]) == T[2], T))
										selection[j][] += selected[i][] - limit!i.left;
									else selection[j] += selected[i] - limit!i.left;
							}

						return source.opIndexAssign (space, selection);
					}

				auto push (S)(S space)
					{/*...}*/
						return source.push (space, this[].bounds);
					}
			}

		mixin SliceOps!(access, LimitsAndExtensions, SubWriteOps);
	}
	unittest {/*...}*/
		import std.conv: to, text;

		import evx.math;
		import evx.misc.test;
		import evx.range;

		static struct Basic
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				auto pull (int x, size_t i)
					{/*...}*/
						data[i] = x;
					}
				auto pull (R)(R range, size_t[2] limits)
					{/*...}*/
						foreach (i, j; enumerate (ℕ[limits.left..limits.right]))
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
				void pull (R)(R range, size_t[2] limit)
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
				auto pull (R)(R range, size_t[2] limits)
					{/*...}*/
						foreach (i, j; enumerate (ℕ[limits.left..limits.right]))
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
		q[0..100] = ℕ[800..900].map!(to!int);
		assert (q[0] == 800);
		assert (q[99] == 899);
		assert (z[100] == 800);
		assert (z[199] == 899);
		q[$/2..$] = ℕ[120..170].map!(to!int);
		assert (q[0] == 800);
		assert (q[50] == 120);
		assert (q[99] == 169);
		assert (z[100] == 800);
		assert (z[150] == 120);
		assert (z[199] == 169);
		q[] = ℕ[1111..1211].map!(to!int);
		assert (q[0] == 1111);
		assert (q[50] == 1161);
		assert (q[99] == 1210);
		assert (z[100] == 1111);
		assert (z[150] == 1161);
		assert (z[199] == 1210);

		z[] = ℕ[0..z.length].map!(to!int);

		foreach (i; 0..z.length)
			assert (z[i] == i);
	}
