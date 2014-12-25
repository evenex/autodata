module evx.operators.buffer;

/* generate RAII ctor/dtor and move/copy/free assignment operators from allocate and own functions, with TransferOps 
*/
template BufferOps (alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import evx.operators.transfer;
		}

		this (S)(auto ref S space)
			{/*...}*/
				this = space;
			}
		~this ()
			{/*...}*/
				//this = null; // BUG https://issues.dlang.org/show_bug.cgi?id=13886
				{/*HACK}*/
					ParameterTypeTuple!access zeroed;

					foreach (ref size; zeroed)
						size = zero!(typeof(size));

					allocate (zeroed);
				}
			}
		@disable this (this);

		ref opAssign ()(auto ref typeof(this) space)
			{/*...}*/
				import evx.misc.memory;

				if (&space != &this)
					space.move (this);

				return this;
			}
		ref opAssign (S)(S space)
			in {/*...}*/
				enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

				enum cannot_assign_error = error_header
					~ `cannot assign ` ~ S.stringof ~
					` to ` ~ typeof(this).stringof;

				static if (is (typeof(space.limit!0)))
					{/*...}*/
						foreach (i, LimitType; ParameterTypeTuple!access)
							static assert (is (typeof(space.limit!i.left) : LimitType),
								cannot_assign_error ~ ` (dimension or type mismatch)`
							);

						static assert (not (is (typeof(space.limit!(ParameterTypeTuple!access.length)))),
							cannot_assign_error ~ `(` ~ S.stringof ~ ` has too many dimensions)`
						);
					}
				else static if (is (typeof(space.length)) && not (is (typeof(this[selected].limit!1))))
					{/*...}*/
						static assert (is (typeof(space.length.identity) : ParameterTypeTuple!access[0]),
							cannot_assign_error ~ ` (length is incompatible)`
						);
					}
				else static assert (0, cannot_assign_error);
			}
			body {/*...}*/
				ParameterTypeTuple!access size;

				auto read_limits ()()
					{/*...}*/
						foreach (i; Count!(ParameterTypeTuple!access))
							size[i] = space.limit!i.width;
					}
				auto read_length ()()
					{/*...}*/
						size[0] = space.length;
					}

				Match!(read_limits, read_length);

				allocate (size);

				pull (space, this[].bounds);

				return this;
			}
		ref opAssign (typeof(null))
			out {/*...}*/
				foreach (i, T; ParameterTypeTuple!access)
					assert (this[].limit!i.width == zero!T);
			}
			body {/*...}*/
				ParameterTypeTuple!access zeroed;

				foreach (ref size; zeroed)
					size = zero!(typeof(size));

				allocate (zeroed);

				return this;
			}

		mixin TransferOps!(pull, access, LimitsAndExtensions);
	}
	unittest {/*...}*/
		import evx.math;
		import std.conv;

		static struct Basic
			{/*...}*/
				int[] data;
				auto length () const {return data.length;}
				static bool destroyed;

				void allocate (size_t length)
					{/*...}*/
						if (length == 0 && this.length != 0)
							destroyed = true;
							
						data.length = length;
					}

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

				mixin BufferOps!(allocate, pull, access, length);
			}

		auto N = ℕ[500..525].map!(to!int);

		// can initialize via assignment or constructor from any element-compatible range
		Basic x = N;
		auto y = Basic (N);

		// y is equivalent to x
		assert (x == y);

		// y is equivalent to x
		assert (x.length == 25);
		assert (x[0] == 500);
		assert (x[1] == 501);
		assert (x[$-1] == 524);

		// y is equivalent to x
		assert (y.length == 25);
		assert (y[0] == 500);
		assert (y[1] == 501);
		assert (y[$-1] == 524);

		// slice assignment copies data
		y = x[10..12]; 
		assert (y.length == 2);
		assert (y[0] == 510);
		assert (y[$-1] == 511);

		// null assignment allocates 0, freeing data
		y = null;
		assert (y.length == 0);
		assert (y[].limit!0 == [0,0]);
		
		// x is independent of y
		assert (x.length == 25);

		 // direct assignment (not slice) changes ownership
		y = x;
		assert (x.length == 0);
		assert (y.length == 25);

		// RAII
		Basic.destroyed = false;
		{/*...}*/
			Basic z = N;
		}
		assert (Basic.destroyed);

		Basic.destroyed = false;

		// changing ownership prevents premature destruction of data
		Basic z;
		{/*...}*/
			Basic w = N;

			z = w;
			
			assert (z.length);
		}
		assert (not (Basic.destroyed));
		assert (z.length);

		// to avoid double free, copying a buffer is not allowed
		auto f ()(Basic a)
			{/*...}*/
				Basic x = a;

				return x;
			}
		assert (not (is (typeof(f (z)))));

		auto g ()(ref Basic a)
			{/*...}*/
				Basic x = a;

				return x;
			}
		assert (not (is (typeof(g (z)))));

		auto h ()(Basic a)
			{return a;}
		assert (not (is (typeof(h (z)))));

		auto φ ()(ref Basic a)
			{return a;}
		assert (not (is (typeof(h (z)))));

		// passing by reference is allowed
		ref γ ()(ref Basic a)
			{return a;}
		z = γ (z);
		assert (not (Basic.destroyed));
		assert (z.length);

		// transferring ownership is allowed
		auto χ ()(ref Basic a)
			{/*...}*/
				Basic x;

				x = a;

				return x;
			}
		z = χ (z);
		assert (not (Basic.destroyed));
		assert (z.length);

		z = null;
		assert (Basic.destroyed);
	}
