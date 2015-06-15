module autodata.operators.slice;

/* generate slicing operators with IndexOps

	Requires:
		IndexOps requirements.
		In order to use indexing on sliced structures (referred to as Sub structures), 
			the measure type must form a group under addition (i.e. + and - operators are supported, and return a value of the measure type)

	Optional:
		A set of uninstantiated, parameterless templates to extend the Sub structure.
		Templates which resolve to a string upon instantiation will be mixed in as strings,
		otherwise they are mixed in as templates.
		Since symbols defined by string mixins have a higher resolution priority than template mixins,
		this can be used to gain an additional degree of control over the semantics of the Sub structure.
*/

private {//imports
	import evx.meta;
	import evx.interval;
}

struct Limit (T,U)
{
// mixin Interval!(T,U).Definition;
// alias right this;
// opUnary
	Interval!(T,U) limit;

	auto left () {return limit.left;}
	auto right () {return limit.right;}

	alias right this;

	auto opUnary (string op)()
	{
		static if (op is `~`)
			return left;
		else return mixin(op ~ q{right});
	}
}
struct Axis (uint axis_index, AxisType)
{
	enum index = axis_index;

	enum is_free = is_interval!AxisType;

	static if (is_free)
		alias Interval = AxisType;
	else alias Interval = evx.interval.Interval!AxisType;
}
struct Sub (Source, Axes...)
{
	mixin template Definition ()
	{
		mixin LambdaCapture;

		alias FreeAxes = Filter!(λ!q{(Axis) = Axis.is_free}, Axes);

		public {//source
			Source source;
		}
		public {//bounds
			Lens!(q{Interval}, 
				SortBy!(λ!q{(T,U) = T.index < U.index},
					Cons!(
						FreeAxes,
						Filter!(λ!q{(Axis) = not (Contains!(Axis.index, Lens!(q{index}, FreeAxes)))},
							Map!(Axis,
								Enumerate!(Domain!(typeof(source.opIndex)))
							),
						)
					)
				)
			)
				bounds;
		}
		public {//limits
			auto limit (size_t dim)() const
			{
				import evx.interval;
				import evx.infinity;
				import autodata.traits;

				enum i = FreeAxes[dim].index;

				alias T = Unqual!(ElementType!(typeof(bounds)[i]));

				auto multi    ()() {return -origin[i];}
				auto uni      ()() {return -origin;}
				auto inf_zero ()() {return bounds[i].left.is_infinite? bounds[i].left : T(0);}
				auto inf_only ()() {assert (bounds[i].left.is_infinite); return bounds[i].left;}

				alias left = Match!(multi, uni, inf_zero, inf_only);

				return interval (left,
					bounds[i].right.is_infinite? 
						bounds[i].right
						: left + bounds[FreeAxes[dim].index].width
				);

			}
			auto limit ()() const if (FreeAxes.length == 1) {return limit!0;}

			auto opDollar (size_t i)() const
			{
				return Limit!(typeof(limit!i.tupleof))(limit!i);
			}
		}
		public {//opIndex
			typeof(this) opIndex ()
			{
				return this;
			}
			auto ref opIndex (Selected...)(Selected selected)
			in {
				import std.typecons;
				import autodata.traits;

				alias Error = ErrorMessages!(Source, Tuple!Selected, Map!(ElementType, typeof(bounds)));

				version (all)
				{//type check
					static if (Selected.length > 0)
						static assert (Selected.length == FreeAxes.length,
							Error.type_mismatch
						);

					static assert (
						All!(is_implicitly_convertible,
							Zip!(
								Pack!(Map!(Error.Element, Selected)),
								Pack!(Map!(Error.Element, Lens!(q{Interval}, FreeAxes)))
							)
						), Error.type_mismatch
					);
				}

				foreach (i,_; selected)
				{//bounds check
					assert (
						selected[i].is_contained_in (limit!i),
						Error.out_of_bounds (i, selected[i], limit!i)
					);
				}
			}
			body {
				import evx.interval;
				import evx.infinity;
				import autodata.traits;

				auto selection (uint i)()
				{
					enum j = IndexOf!(i, Lens!(q{index}, FreeAxes));

					auto inf_check (T)(T value)
					{
						auto zero ()() {return value.is_infinite? Finite!(ExprType!value)(0) : value;}
						auto pass ()() {return value;}

						return Match!(zero, value);
					}

					auto left_bound ()() {return inf_check (bounds[i].left);}
					auto left_limit ()() {return inf_check (this.limit!j.left);}

					auto offset ()() {return selected[j] - left_limit + left_bound;}
					auto stable ()() {return left_bound;}

					return Match!(offset, stable);
				}

				return source.opIndex (Map!(selection, Iota!(dimensionality!Source)));
			}
		}
		public {//opSlice
			auto opSlice (size_t d, T,U)(T i, U j)
			{
				return source.opSlice!d (i,j);
			}
		}
		public {//ctor
			this (typeof(source) source, typeof(bounds) bounds)
			{
				this.source = source;
				this.bounds = bounds;
			}
			@disable this ();
		}
	}

	mixin Definition sub;

	mixin((){//extensions
		import std.conv: to;
		import std.range: join;

		string[] code;

		foreach (i, extension; Source.Extensions)
			static if (is (typeof(extension!().identity) == string))
				code ~= q{
					mixin(Instantiate!(Source.Extensions[} ~i.to!string~ q{]));
				};
			else code ~= q{
				mixin Mixin!(Source.Extensions[} ~i.to!string~ q{]);
			};

		return code.join.to!string;
	}());
}

template SliceOps (T...)
{
	private {//imports
		import evx.meta;
	}

	mixin SubOps!(Λ!q{(U) = U*}, T);
}
template AdaptorOps (T...)
{
	private {//imports
		import evx.meta;
	}

	mixin SubOps!(Identity, T);
}

template SubOps (alias SourceTransform, alias access, LimitsAndExtensions...)
{
	private {//imports
		import evx.meta;
	}
	public:
	public {//opIndex
		auto ref Codomain!access opIndex (Domain!access selected)
		in {
			import std.conv: text;
			import evx.interval;
			import evx.infinity;
			import autodata.traits;

			version (all)
				{//error messages
					enum error_header = typeof(this).stringof~ `: `;

					enum element_type_error = error_header~ `access primitive must return a non-void value`;

					enum array_error = error_header~ `limit types must be singular or arrays of two`
					`: ` ~Map!(ExprType, limits).stringof;

					enum type_error = error_header~ `limit base types must match access parameter types`
					`: ` ~Map!(ExprType, limits).stringof
					~ ` !→ ` ~Domain!access.stringof;

					auto out_of_bounds_error (Arg, Lim)(uint dim, Arg arg, Lim limit) 
						{return error_header~ `bounds exceeded on dimensions ` ~dim.text~ `! ` ~arg.text~ ` not in ` ~limit.text;}
				}

			static assert (not (is (Codomain!access == void)), 
				element_type_error
			);

			foreach (i, limit; limits)
			{//type check
				static assert  (limits.length == Domain!access.length,
					type_error
				);

				static if (is (ExprType!limit == LimitType[n], LimitType, size_t n))
					static assert (n == 2, 
						array_error
					);

				static if (is (LimitType))
					static assert (is (Domain!access[i] == LimitType),
						type_error
					);

				else static assert (
					is (Unqual!(Domain!access[i]) == Unqual!(Finite!(ExprType!limit)))
					|| is (Unqual!(Domain!access[i]) == Unqual!(ElementType!(ExprType!limit))),
					type_error
				);
			}

			foreach (i, limit; limits)
			{//bounds check
				static if (is (ElementType!(ExprType!limit) == void))
					auto bounds = interval (Finite!(ExprType!limit)(0), limit);
				else auto bounds = interval (limit);

				assert (
					selected[i].is_contained_in (bounds),
					out_of_bounds_error (i, selected[i], bounds)
				);
			}
		}
		body {
			return access (selected);
		}

		auto ref opIndex (Selected...)(Selected selected)
		in {
			import std.typecons;
			import autodata.traits;
			import evx.interval;
			import evx.infinity;

			alias Error = ErrorMessages!(Source, Tuple!Selected, Map!(ExprType, limits));

			static if (Selected.length > 0)
			{//type check
				static assert (Selected.length == limits.length, 
					Error.type_mismatch
				);

				static assert (
					All!(is_implicitly_convertible,
						Zip!(
							Pack!(Map!(Error.Element, Selected)),
							Pack!(Domain!access)
						)
					), Error.type_mismatch
				);
			}

			foreach (i,_; selected)
			{//bounds check
				alias T = Unqual!(ExprType!(limits[i]));

				static if (is (ElementType!T == void))
					auto boundary = interval (Finite!T(0), limits[i]);
				else auto boundary = interval (limits[i]);

				alias U = ElementType!(typeof(boundary));

				assert (
					boundary.width > U(0),
					Error.zero_width_boundary!i ~ ` (in)`
				);
				assert (
					selected[i].is_contained_in (boundary),
					Error.out_of_bounds (i, selected[i], boundary)
					~ ` (in)`
				);
			}
		}
		out (result) {
			import std.typecons: Tuple;
			import evx.interval;
			import autodata.traits;

			alias Error = ErrorMessages!(Source, Tuple!Selected, Map!(ExprType, limits));

			static if (is (typeof(result) == Sub!(Source, T), T...))
			{
				foreach (i, limit; selected)
					static if (is_interval!(typeof(limit)))
						assert (limit == result.bounds[i],
							Error.out_of_bounds (i, limit, result.bounds[i])
							~ ` (out)`
						);
					else assert (
						limit == result.bounds[i].left
						&& limit == result.bounds[i].right,
						Error.out_of_bounds (i, limit, result.bounds[i])
						~ ` (out)`
					);
			}
		}
		body {
			import evx.interval;
			import evx.infinity;
			import autodata.traits;

			enum is_proper_sub = Any!(is_interval, Selected);
			enum is_trivial_sub = Selected.length == 0;

			static if (is_proper_sub || is_trivial_sub)
			{
				template IntervalType (T)
					{/*...}*/
						alias Point () = typeof(T.init.interval);
						alias Zero () = typeof(interval (Finite!T(0), T.init));
					
						alias IntervalType = Match!(Point, Zero);
					}
				template AxisType (uint i, T)
					{/*...}*/
						static if (is_interval!T)
							alias Shape = Interval;
						else alias Shape = First;

						alias Coord = Domain!access[i];

						static if (is (T.Right == Infinite!U, U))
							alias Right = Infinite;
						else alias Right = Identity;

						static if (is (T.Left == Infinite!V, V))
							alias Left = Infinite;
						else alias Left = Identity;

						alias AxisType = Axis!(
							i, Shape!(Left!Coord, Right!Coord)
						);
					}

				alias Subspace = Sub!(SourceTransform!Source,
					Map!(AxisType,
						Enumerate!(
							Select!(is_proper_sub,
								Pack!Selected, 
								/*else*/
								Pack!(Map!(IntervalType,
									Map!(ExprType, limits)
								))
							).Unpack
						)
					)
				);

				typeof(Subspace.bounds) bounds;

				foreach (i, limit; Unpack!(Select!(is_proper_sub,
					Pack!selected, /*else*/ Pack!limits
				)))
					static if (is_trivial_sub && is (ElementType!(ExprType!limit) == void))
						bounds[i] = interval (Finite!(ExprType!limit)(0), limit);
					else 
						bounds[i] = interval (limit);

				auto ref_access ()() {return Subspace (&this, bounds);}
				auto value_access ()() {return Subspace (this, bounds);}
				auto static_ref_access ()() {return Subspace (null, bounds);}
				auto static_value_access ()() {return Subspace (Source (), bounds);}

				return Match!(ref_access, value_access, static_value_access, static_ref_access);
			}
			else return opIndex (selected);
		}
	}
	public {//opSlice
		static auto opSlice (size_t d, T,U)(T i, U j)
		{
			import std.conv: to;
			import evx.interval;

			alias Left = T;

			static if (is (U == Limit!(_0, Right), _0, Right))
				{}
			else alias Right = U;

			alias Bounds = typeof(this[].bounds[d]);

			static if (is (Bounds.Left == Infinite!V, V) && not (is (Left == Infinite!_, _)))
				auto left = i.to!V;
			else auto left = i.to!(Bounds.Left);

			static if (is (Bounds.Right == Infinite!W, W) && not (is (Right == Infinite!_, _)))
				auto right = j.to!W;
			else auto right = j.to!(Bounds.Right);

			return interval (left, right);
		}
	}
	public {//opDollar
		auto opDollar (size_t i)() // BUG const - cannot be const without 'this', it happens in static methods... 
		{
			import autodata.traits;
			import evx.interval;
			import evx.infinity;

			alias T = Unqual!(ExprType!(limits[i]));

			static if (is (ElementType!T == void))
				auto limit ()() {return interval (Finite!T(0), limits[i]);}
			else auto limit ()() {return interval (limits[i]);}

			return Limit!(typeof(limit.left), typeof(limit.right))(limit);
		}
	}
	public {//diagnostic
		template Diagnostic ()
		{
			pragma(msg, `slice diagnostic: `, typeof(this));

			pragma(msg, "\t", typeof(this), `[`, Domain!access.stringof[1..$-1], `] → `, typeof(this.opIndex (Domain!access.init)));
			pragma(msg, "\t", typeof(this), `[] → `, typeof(this.opIndex ()));
			pragma(msg, "\t", typeof(this), `[][] → `, typeof(this.opIndex ().opIndex ()));
		}
	}
	private:
	private {//aliases
		alias Source = typeof(this);
		alias limits = Filter!(has_identity, LimitsAndExtensions);
		alias Extensions = Filter!(Not!has_identity, LimitsAndExtensions);
	}
	private {//verification
		struct Verification
		{
			import std.traits: Select, fullyQualifiedName;
			import autodata.traits;

			mixin LambdaCapture;

			static assert (All!(is_const_function, Filter!(is_function, limits)),
				fullyQualifiedName!(typeof(this))~ ` LimitOps: limit functions must be const`
			);
			static assert (
				All!(is_comparable, 
					Map!(Λ!q{(T) = Select!(
						is (ElementType!T == void),
						T, ElementType!T
					)}, 
						Map!(ExprType, limits)
					)
				),
				fullyQualifiedName!(typeof(this))~ ` LimitOps: limit types must support comparison (<. >, <=, >=)`
			);
		}
	}
}

unittest {
	import std.exception;
	import evx.infinity;

	auto error (T)(lazy T stmt){assertThrown!Error (stmt);}
	auto no_error (T)(lazy T stmt){assertNotThrown!Error (stmt);}

	static struct Basic
	{
		auto access (size_t i)
		{
			return true;
		}

		size_t length = 100;

		mixin SliceOps!(access, length);
	}

	assert (Basic()[40]);
	error (Basic()[101]);
	assert (Basic()[$-1]);
	assert (Basic()[~$]);
	error (Basic()[$]);
	assert (Basic()[0]);
	assert (Basic()[][0]);
	assert (Basic()[0..10][0]);
	assert (Basic()[][0..10][0]);
	assert (Basic()[~$..$][0]);
	assert (Basic()[~$..$][~$]);
	error (Basic()[~$..2*$][0]);

	static struct RefAccess
	{
		enum size_t length = 256;

		int[length] data;

		ref access (size_t i)
		{
			return data[i];
		}

		mixin SliceOps!(access, length);
	}
	RefAccess ref_access;
	assert (ref_access[5] == 0);
	ref_access[3..10][2] = 1;
	assert (ref_access[5] == 1);

	static struct LengthFunction
	{
		auto access (size_t) {return true;}
		size_t length () const {return 100;}

		mixin SliceOps!(access, length);
	}
	assert (LengthFunction()[40]);
	error (LengthFunction()[101]);
	assert (LengthFunction()[$-1]);
	assert (LengthFunction()[~$]);
	error (LengthFunction()[$]);
	assert (LengthFunction()[0]);
	assert (LengthFunction()[][0]);
	assert (LengthFunction()[0..10][0]);
	assert (LengthFunction()[][0..10][0]);
	assert (LengthFunction()[~$..$][0]);
	assert (LengthFunction()[~$..$][~$]);
	error (LengthFunction()[~$..2*$][0]);

	static struct NegativeIndex
	{
		auto access (int) {return true;}

		int[2] bounds = [-99, 100];

		mixin SliceOps!(access, bounds);
	}
	assert (NegativeIndex()[-25]);
	error (NegativeIndex()[-200]);
	assert (NegativeIndex()[$-25]);
	assert (NegativeIndex()[~$]);
	error (NegativeIndex()[$]);
	assert (NegativeIndex()[-99]);
	assert (NegativeIndex()[-40..10][0]);
	assert (NegativeIndex()[][0]);
	assert (NegativeIndex()[][0..199][0]);
	assert (NegativeIndex()[~$..$][~$]);
	error (NegativeIndex()[~2*$..$][0]);

	static struct FloatingPointIndex
	{
		auto access (float) {return true;}

		float[2] bounds = [-1,1];

		mixin SliceOps!(access, bounds);
	}
	assert (FloatingPointIndex()[0.5]);
	error (FloatingPointIndex()[-2.0]);
	assert (FloatingPointIndex()[$-0.5]);
	assert (FloatingPointIndex()[~$]);
	error (FloatingPointIndex()[$]);
	assert (FloatingPointIndex()[-0.5]);
	assert (FloatingPointIndex()[-0.2..1][0]);
	assert (FloatingPointIndex()[][0.0]);
	assert (FloatingPointIndex()[][0.0..0.8][0]);
	assert (FloatingPointIndex()[~$..$][~$]);
	error (FloatingPointIndex()[2*~$..2*$][~$]);

	static struct MultiDimensional
	{
		auto access (size_t, size_t) {return true;}

		size_t rows = 3;
		size_t columns = 3;

		mixin SliceOps!(access, rows, columns);
	}
	assert (MultiDimensional()[$-1, 2]);
	assert (MultiDimensional()[1, $-2]);
	assert (MultiDimensional()[$-1, $-2]);
	assert (MultiDimensional()[~$, ~$]);
	error (MultiDimensional()[$, 2]);
	error (MultiDimensional()[1, $]);
	error (MultiDimensional()[$, $]);
	assert (MultiDimensional()[1,2]);
	assert (MultiDimensional()[][1,2]);
	assert (MultiDimensional()[][][1,2]);
	assert (MultiDimensional()[0..3, 1..2][1,0]);
	assert (MultiDimensional()[0..3, 1][1]);
	assert (MultiDimensional()[0, 2..3][0]);
	assert (MultiDimensional()[][0..3, 1..2][1,0]);
	assert (MultiDimensional()[][0..3, 1][1]);
	assert (MultiDimensional()[][0, 2..3][0]);
	assert (MultiDimensional()[0..3, 1..2][1..3, 0..1][1,0]);
	assert (MultiDimensional()[0..3, 1][1..3][1]);
	assert (MultiDimensional()[0, 2..3][0..1][0]);
	assert (MultiDimensional()[~$..$, ~$..$][~$, ~$]);
	assert (MultiDimensional()[~$..$, ~$][~$]);
	assert (MultiDimensional()[~$, ~$..$][~$]);

	static struct ExtendedSub
	{
		auto access (size_t i)
		{
			return true;
		}

		size_t length = 100;

		template Length ()
		{
			@property length () const
			{
				return bounds[0].right - bounds[0].left;
			}
		}

		mixin SliceOps!(access, length,	Length);
	}
	assert (ExtendedSub()[].length == 100);
	assert (ExtendedSub()[][].length == 100);
	assert (ExtendedSub()[0..10].length == 10);
	assert (ExtendedSub()[10..20].length == 10);
	assert (ExtendedSub()[~$/2..$/2].length == 50);
	assert (ExtendedSub()[][0..10].length == 10);
	assert (ExtendedSub()[][10..20].length == 10);
	assert (ExtendedSub()[][~$/2..$/2].length == 50);

	static struct SubOrigin
	{
		auto access (double i)
		{
			return true;
		}

		double measure = 10;

		template Origin ()
		{
			@property origin () const
			{
				return bounds.width/2;
			}
		}

		mixin SliceOps!(access, measure, Origin);
	}
	assert (SubOrigin()[].origin == 5);
	assert (SubOrigin()[].limit == [-5,5]);
	assert (SubOrigin()[][-5]);
	assert (SubOrigin()[0..3].origin == 1.5);
	assert (SubOrigin()[0..3].limit == [-1.5, 1.5]);
	assert (SubOrigin()[0..3][-1.5]);
	assert (SubOrigin()[][0..3].origin == 1.5);
	assert (SubOrigin()[][0..3].limit == [-1.5, 1.5]);
	assert (SubOrigin()[][0..3][-1.5]);
	assert (SubOrigin()[~$..$][-$]);

	static struct IntervalSub
	{
		auto access (size_t i)
		{
			return true;
		}

		auto bounds = interval!size_t (50, 75);

		mixin SliceOps!(access, bounds);
	}
	assert (IntervalSub()[].limit!0.width == 25);

	static struct InfiniteSub
	{
		auto access (size_t i)
		{
			return true;
		}

		auto bounds = interval (0UL, infinity);

		mixin SliceOps!(access, bounds);
	}
	assert (InfiniteSub()[].limit!0.width == infinity);
}

package {//error
	struct ErrorMessages (This, Selected, Limits...)
	{
		import std.conv;
		import evx.meta;
		import autodata.traits;

		alias Element (T) = Select!(is (ElementType!T == void), T, /*else*/ ElementType!T);

		enum error_header = `██ ` ~This.stringof~ ` ██ `;

		enum type_mismatch = error_header
			~Map!(Element, Selected.Types).stringof~ ` does not convert to ` ~Map!(Element, Limits).stringof;

		static out_of_bounds (T, U)(uint dim, T arg, U limit) 
			{return error_header~ `bounds exceeded on dimension ` ~dim.text~ `! ` ~arg.text~ ` not in ` ~limit.text;}

		enum zero_width_boundary (size_t dim) = error_header~ ` dimension ` ~dim.text~ ` has zero width`;
	}
}
