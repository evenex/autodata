module spacecadet.operators.buffer;

/* generate RAII ctor/dtor and copy/free assignment operators from allocate function, with TransferOps 
	move/copy semantics are customizable via composition with lifetime templates

	Requires:
		TransferOps requirements.
		The allocate symbol must resolve to a function (which may be a template and/or an overload set)
		which takes the measure types, in order, as parameters (same as access).
		After invoking the allocate symbol, the limits of the dataset must be consistent with the parameters passed.
*/
template BufferOps (alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		private {/*imports}*/
			import spacecadet.meta;
			import spacecadet.operators.transfer;
		}

		this (Domain!allocate dimensions)
			{/*...}*/
				allocate (dimensions);
			}
		this (S)(auto ref S space)
			{/*...}*/
				this = space;
			}
		~this ()
			{/*...}*/
				this = null;
			}

		ref opAssigne ()(auto ref this space)
			{/*...}*/
				import spacecadet.memory;

				space.move (this);

				return this;
			}
		ref opAssign (S)(S space)
			in {/*...}*/
				enum error_header = full_name!(typeof(this)) ~ `: `;

				enum cannot_assign_error = error_header
					~ `cannot assign ` ~ S.stringof ~
					` to ` ~ typeof(this).stringof;

				enum parameter_mismatch_error = error_header
					~ `access parameters ` ~ Domain!access.stringof ~
					` do not match allocate parameters ` ~ Domain!allocate.stringof;

				static assert (is (Domain!allocate == Domain!access),
					parameter_mismatch_error
				);

				static if (is (typeof(space.limit!0)))
					{/*...}*/
						foreach (i, LimitType; Domain!allocate)
							static assert (is (typeof(space.limit!i.left) : LimitType),
								cannot_assign_error ~ ` (dimension or type mismatch)`
							);

						static assert (not (is (typeof(space.limit!(Domain!access.length)))),
							cannot_assign_error ~ `(` ~ S.stringof ~ ` has too many dimensions)`
						);
					}
				else static if (is (typeof(space.length)) && not (is (typeof(this[selected].limit!1))))
					{/*...}*/
						static assert (is (typeof(space.length.identity) : Domain!allocate[0]),
							cannot_assign_error ~ ` (length is incompatible)`
						);
					}
				else static assert (0, cannot_assign_error);
			}
			body {/*...}*/
				Domain!allocate size;

				auto read_limits ()()
					{/*...}*/
						foreach (i; Count!(Domain!access))
							size[i] = space.limit!i.width;
					}
				auto read_length ()()
					{/*...}*/
						size[0] = space.length;
					}

				Match!(read_limits, read_length);

				allocate (size);

				this[] = space;

				return this;
			}
		ref opAssign (typeof(null))
			out {/*...}*/
				foreach (i, T; Domain!access)
					assert (this[].limit!i.width == T(0));
			}
			body {/*...}*/
				Domain!access zeroed;

				foreach (ref size; zeroed)
					size = typeof(size)(0);

				allocate (zeroed);

				return this;
			}

		mixin TransferOps!(pull, access, LimitsAndExtensions);
	}
	unittest {/*...}*/
		import spacecadet.memory;

		import spacecadet.operators.slice;
		import spacecadet.operators.range;

		import std.conv;
		import std.algorithm: map;
		import std.range: enumerate;

		static struct Nat
			{/*...}*/
				static access (size_t i)
					{/*...}*/
						return i;
					}
				enum length = size_t.max;

				static mixin SliceOps!(access, length, RangeOps);
			}

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
						foreach (i, j; enumerate (Nat[limits.left..limits.right]))
							data[j] = range[i];
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				mixin BufferOps!(allocate, pull, access, length);
			}

		auto N = Nat[500..525].map!(to!int);

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

		// buffers are deallocated upon going out of scope
		Basic.destroyed = false;
		{/*...}*/
			Basic z = N;
		}
		assert (Basic.destroyed);

		// direct assignment (not slice) produces a shallow copy. if care is not taken, this will eventually cause multiple deallocation.
		// BufferOps does not attempt to manage lifetimes in order that the internal implementation or a top-level wrapper can define a management strategy
		y = x;
		assert (x.length == 25);
		assert (y.length == 25);


		// buffers which have been shallow-copied run the risk of having their information going out of sync when one is destroyed
		Basic.destroyed = false;
		Basic z;
		Basic w = N;
		z = w;
		assert (w.length == 25);
		assert (z.length == 25);
		w = null;
		assert (Basic.destroyed);
		assert (w.length == 0);
		assert (z.length == 25);
		z = null;
		assert (z.length == 0);

		// to control deallocation, a resource management strategy may be defined by the host struct.
		struct MoveOnly
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
						foreach (i, j; enumerate (Nat[limits.left..limits.right]))
							data[j] = range[i];
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				mixin BufferOps!(allocate, pull, access, length) buffer_ops;

				// prevent copying
				@disable this (this);

				// overload assignment to enable move semantics
				auto ref opAssign ()(auto ref this that)
					{/*...}*/
						if (&this != &that)
							that.move (this);

						return this;
					}
				auto ref opAssign (S)(S space)
					{/*...}*/
						return buffer_ops.opAssign (space);
					}
			}
		MoveOnly a, b;
		a = N;
		assert (a.length == 25);
		b = a;
		assert (b.length == 25);
		assert (a.length == 0);
		b = null;
		assert (b.length == 0);

		// alternatively, this can be accomplished through the use of lifetime management wrappers
		Lifetime.Unique!Basic c, d;
		c = N;
		assert (c.length == 25);
		d = c;
		assert (d.length == 25);
		assert (c.length == 0);
		d = null;
		assert (d.length == 0);
	}
