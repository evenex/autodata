module evx.operations.space_cadet;
// http://chris-taylor.github.io/blog/2013/02/10/the-algebra-of-algebraic-data-types/

import std.typetuple;
import std.typecons;
import std.traits;
import std.conv;
import evx.traits;
import evx.math;
import evx.range;
import evx.type;
import evx.misc.tuple;

/*
	TODO transforms a space into a lower-dimensional space of subspaces,
	analogous to partially currying the access function
*/

/*
	GET THIS SHIT OUT OF HERE
*/
alias Identity = evx.type.Identity; // TEMP


auto max (T,U)(T a, U b)// REFACTOR to ordinal
	{/*...}*/
		return CommonType!(T,U)(
			a > b? a : b
		);
	}
auto min (T,U)(T a, U b)// REFACTOR to ordinal
	{/*...}*/
		return CommonType!(T,U)(
			a < b? a : b
		);
	}

/*
	TYPE PROCESSING
*/

/*
	TRAITS
*/
struct MeasureTraits (Measure)
	{/*...}*/
		enum measure = Measure.init;

		mixin Traits!(
			`can_add`, 		q{Measure x = measure + measure;},
			`can_subtract`, q{Measure x = measure - measure;},
			`defines_zero`, q{auto u = zero!Measure;},
			`is_comparable`,q{bool b = measure < measure;},
		);

		enum is_measure_type = can_add && can_subtract && is_comparable && defines_zero;

		alias stringof = info;
	}
enum is_measure_type (Measure) = MeasureTraits!Measure.is_measure_type;
enum is_interval (T) = is (T == U[2], U);
enum is_space (S) = is (S.Space) || is (typeof(S.space).Space);

/*
	BASIC DEFININITIONS
*/
template BoundarySet (Space)
	{/*...}*/
		alias BoundarySet = typelist!();

		template typelist (size_t i = 0)
			{/*...}*/
				static if (i == 0)
					{/*...}*/
						static if (is(typeof(Space.init.measure.identity) == T, T))
							alias Type = T;

						else static if (is(typeof(Space.init.boundary.identity) == T[2], T))
							alias Type = T;

						else static if (is(typeof(Space.init.length.identity) : size_t))
							alias Type = size_t;
					}

				static if (not (is (Type)))
					{/*...}*/
						static if (is(typeof(Space.init.measure!i.identity) == T, T))
							alias Type = T;

						else static if (is(typeof(Space.init.boundary!i.identity) == T[2], T))
							alias Type = T;
					}

				static if (is (Type))
					alias typelist = TypeTuple!(Type, typelist!(i+1));

				else alias typelist = TypeTuple!();
			}
	}
template MeasureSet (Space)
	{/*...}*/
		template coordinate_type (T)
			{/*...}*/
				static if (is (T == U[2], U))
					alias coordinate_type = U;

				else alias coordinate_type = T;
			}

		alias MeasureSet = Map!(coordinate_type, BoundarySet!Space);
	}
enum dimensionality (Space) = BoundarySet!Space.length;
alias Dimensions (Space) = Iota!(0, dimensionality!Space);

/*
	MIXIN OPS
*/
template EqualityOps ()
	{/*...}*/
		bool opEquals (R)(R range)
			{/*...}*/
				return this.equal (range);
			}
	}
template BoundaryOps (Space)
	{/*...}*/
		enum Side {left = 0, right = 1}

		struct Boundary (size_t dim, Side side)
			{/*...}*/
				Space* space;

				auto ref Coordinate!dim measure ()
					{/*...}*/
						return space.measure!dim;
					}

				auto ref Coordinate!dim boundary ()
					{/*...}*/
						return space.boundary!dim[side];
					}

				alias boundary this;

				auto opCast (T)()
					if (
						is (T == Coordinate!dim) 
						|| has_bijective_coordinate_map!(dim, T)
					)
					{/*...}*/
						return space.coordinate_map!(dim, T)(boundary);
					}

				auto opBinary (string op, T)(T that)
					if (has_bijective_coordinate_map!(dim, T))
					{/*...}*/
						mixin(q{
							return cast(T)this } ~op~ q{ that;
						});
					}
				auto opBinaryRight (string op, T)(T that)
					if (has_bijective_coordinate_map!(dim, T))
					{/*...}*/
						mixin(q{
							return that } ~op~ q{ cast(T)this;
						});
					}

				static if (side is Side.right)
					auto opUnary (string op: `~`)()
						{/*...}*/
							return Boundary!(dim, Side.left)(space);
						}

				string toString ()
					{/*...}*/
						return boundary.text;
					}
			}

		auto opDollar (size_t dim)()
			{/*...}*/
				return Boundary!(dim, Side.right)(&this);
			}
	}
template CoordinateOps (alias space)
	{/*...}*/
		Coordinate!dim coordinate_map (size_t dim, T)(T arg)
			{/*...}*/
				static if (is (typeof (arg.boundary.identity) == Coordinate!dim))
					return arg.boundary;

				else static if (All!(is_integral, T, Coordinate!dim) || All!(is_floating_point, T, Coordinate!dim))
					return Coordinate!dim (arg);

				else static if (has_bijective_coordinate_map!(dim, T))
					{/*...}*/
						static if (is (unidimensional) && is (typeof (space.coordinate_map (arg))))
							return space.coordinate_map (arg);

						else return space.coordinate_map!dim (arg);
					}

				else static assert (0,
					usage_error~
					`no coordinate_map exists for ` ~T.stringof~ ` → ` ~Coordinate!dim.stringof~ ` for dimension ` ~dim.text
				);
			}
		Interval!dim coordinate_map (size_t dim, T)(T[2] arg)
			{/*...}*/
				static if (All!(is_integral, T, Coordinate!dim) || All!(is_floating_point, T, Coordinate!dim))
					return arg;

				else static if (has_bijective_coordinate_map!(dim, T))
					{/*...}*/
						static if (is (unidimensional) && is (typeof (space.coordinate_map (arg))))
							return [
								space.coordinate_map (arg[0]),
								space.coordinate_map (arg[1])
							];

						else return [ 
							space.coordinate_map!dim (arg[0]),
							space.coordinate_map!dim (arg[1])
						];
					}

				else static assert (0,
					usage_error~
					`no coordinate_map exists for ` ~T.stringof~ ` → ` ~Interval!dim.stringof~ ` for dimension ` ~dim.text
				);
			}

		auto coordinate_map (size_t dim, T)(Coordinate!dim arg)
			if (not (is (T == Coordinate!dim)))
			{/*...}*/
				static if (is (typeof (arg.boundary) == Coordinate!dim))
					return arg;

				else static if (All!(is_integral, T, Coordinate!dim) || All!(is_floating_point, T, Coordinate!dim))
					return T (arg);

				else static if (has_bijective_coordinate_map!(dim, T))
					{/*...}*/
						static if (is (unidimensional) && is (typeof (space.coordinate_map!T (arg))))
							return space.coordinate_map!T (arg);

						else return space.coordinate_map!(dim, T)(arg);
					}

				else static assert (0,
					usage_error~
					`invalid parameter ` ~T.stringof~ ` for dimension ` ~dim.text
				);
			}
		auto coordinate_map (size_t dim, T)(Interval!dim arg)
			if (not (is (T == Coordinate!dim)))
			{/*...}*/
				return [
					coordinate_map!(dim,T)(arg[0]),
					coordinate_map!(dim,T)(arg[1]),
				];
			}
	}
template LabelOps (Space) 
	{/*...}*/
		enum has_label (size_t dim) = is (typeof(Space.label!dim.identity) == string);

		static label (size_t dim)()
			if (has_label!dim)
			{/*...}*/
				return Space.label!dim;
			}

		static label (string dim)()
			{/*...}*/
				foreach (i; Dimensions!Space)
					static if (has_label!i)
						static if (label!i == dim)
							return i;

				assert (0);
			}
	}
template IterationOps (Dimensions...)
	{/*...}*/
		enum is_iterable
			= Dimensions.length == 1 
			&& (
				is (Coordinate!(Dimensions[0]) : size_t)
				|| has_bijective_coordinate_map!(Dimensions[0], size_t)
			);

		static if (is_iterable)
			{/*...}*/
				auto front ()()
					{/*...}*/
						return opIndex (boundary!0.left);
					}

				auto back ()()
					{/*...}*/
						return opIndex (boundary!0.right - coordinate_map!0 (size_t(1)));
					}

				auto popFront ()()
					{/*...}*/
						global_bounds[Dimensions[0]].left += space.coordinate_map!(Dimensions[0])(size_t (1));
					}
				auto popBack ()()
					{/*...}*/
						--global_bounds[Dimensions[0]].right;
					}

				auto empty ()()
					{/*...}*/
						static if (is_floating_point!(typeof(measure!0.identity))) // TEMP
							{/*...}*/
								return global_bounds[Dimensions[0]].difference.approx (0);
							}

						else return global_bounds[Dimensions[0]].left >= global_bounds[Dimensions[0]].right;
					}

				@property save ()()
					{/*...}*/
						return this;
					}

				size_t length ()()
					{/*...}*/
						return space.coordinate_map!(Dimensions[0], size_t)(measure!0);
					}
			}
	}
template Mixin (Mixins...)
	{/*...}*/
		static code ()
			{/*...}*/
				string[] code;

				foreach (M; Mixins)
					code ~= q{
						mixin(} ~fullyQualifiedName!M~ q{);
					};

				return code.join.to!string;
			}

		mixin(code);
	}
template SpaceOps (alias source, SubspaceExtensions...)
	if (All!(is_template, SubspaceExtensions))
	{/*...}*/
		alias Space = typeof(this);
		alias Source = typeof(source);

		alias Coordinate (size_t dim) = MeasureSet!Source[dim];
		alias Interval (size_t dim) = Coordinate!dim[2];

		static {/*error messages}*/
			enum generation_error = Space.stringof~ ` does not support Indexing: `;
			enum usage_error = Space.stringof~ `: `;
		}

		static {/*analysis}*/
			static if (dimensionality!Source > 1)
				enum multidimensional;

			else enum unidimensional;

			static if (__traits(hasMember, Source, `access`))
				{/*...}*/
					alias Element = ReturnType!(Source.access);

					enum access_by_function;
				}

			static if (is (typeof(*source.ptr)))
				{/*...}*/
					alias Element = typeof(*source.ptr);

					enum access_by_ptr;
				}

			enum has_length = is (typeof (source.length.identity) : size_t);

			enum has_measure (size_t dim) = 
				is (typeof (source.measure!dim.identity))
				|| (
					is (unidimensional) && dim == 0 
					&& is (typeof (source.measure.identity))
				);

			enum has_boundary (size_t dim) = 
				is (typeof (source.boundary!dim.identity))
				|| (
					is (unidimensional) && dim == 0 
					&& is (typeof (source.boundary.identity))
				);

			enum has_origin (size_t dim) 
				= is (typeof(source.origin!dim (Coordinate!dim.init)) == Coordinate!dim)
				|| (
				 	is (unidimensional) && dim == 0
					&& is (typeof(source.origin (Coordinate!0.init) == Coordinate!0))
				);

			enum has_bijective_coordinate_map (size_t dim, T)
				= is (typeof(source.coordinate_map!dim (T.init)) : Coordinate!dim)
				&& is (typeof(source.coordinate_map!(dim, T) (Coordinate!dim.init)) : T)
				|| (
				 	is (unidimensional) && dim == 0
					&& 
					is (typeof(source.coordinate_map (T.init)) : Coordinate!dim)
					&& is (typeof(source.coordinate_map!T (Coordinate!dim.init)) : T)
				);
		}
		static {/*axioms}*/
			static if (not (is_space!Source))
				{/*is initial Space}*/
					static if (is (multidimensional))
						static assert (
							Map!(has_measure, Dimensions!Source)
							== 
							Map!(not!has_boundary, Dimensions!Source),

							generation_error~"\n"
							`initial multidimensional Space must define either measure or boundary for each dimension`
						);

					static if (is (unidimensional))
						static assert (has_measure!0 + has_boundary!0 + has_length == 1,
							generation_error~"\n"
							`initial 1D Space must define either measure, boundary or length`
						);
				}

			static assert (All!(is_measure_type, MeasureSet!Source),
				generation_error~"\n"
				`measure types do not fulfill requirements:`"\n"
				~Map!(stringof, 
					Interleave!(
						Filter!(not!is_measure_type, 
							MeasureSet!Source
						),
						Map!(MeasureTraits, 
							Filter!(not!is_measure_type, 
								MeasureSet!Source
							)
						)
					)
				).only.join ("\n").to!string
			);

			static assert (is (access_by_function) != is (access_by_ptr),
				generation_error~
				`Space must define either ptr or access function`
			);

			static if (is (access_by_function))
				static assert (is (ParameterTypeTuple!(Source.access) == MeasureSet!Source),
					generation_error~
					`access function parameters must match measure types`"\n"
					`access ` ~ParameterTypeTuple!(Source.access).stringof
					~` != ` ~MeasureSet!Source.stringof
				);


			static if (is (access_by_ptr))
				static assert (All!(is_type_of!size_t, MeasureSet!Source),
					generation_error~
					`all measures and boundaries must be size_t to parameterize a ptr`
				);

			static assert (not (is (Element == void)),
				generation_error~
				(	is (access_by_ptr)? `ptr`
						: `access`
				) ~ ` must ` ~ (
					is (access_by_ptr)? `dereference to `
						: `return `
				) ~ `non-void type`
			);
		}

		static if (__traits(hasMember, Source, `equality`)) // REFACTOR
			bool equality (Args...)(Args args)
				{/*...}*/
					return source.equality (args);
				}

		public:
		public {/*primitives}*/
			static if (is (access_by_function))
				auto ref access (MeasureSet!Source point)
					{/*...}*/
						return source.access (point);
					}

			static if (is (access_by_ptr))
				auto ptr ()
					{/*...}*/
						return source.ptr;
					}
		}
		public {/*measures}*/
			T measure (size_t dim, T = Coordinate!dim)()
				if (is (multidimensional))
				{/*...}*/
					static if (has_measure!dim)
						return coordinate_map!(dim, T)(source.measure!dim);

					else static if (has_boundary!dim)
						return coordinate_map!(dim, T)(source.boundary!dim.difference);

					else static assert (0);
				}

			T measure (size_t dim : 0, T = Coordinate!dim)()
				if (is (unidimensional))
				{/*...}*/
					static if (has_measure!dim)
						return coordinate_map!(dim, T)(source.measure);

					else static if (has_boundary!dim)
						return coordinate_map!(dim, T)(source.boundary.difference);

					else static if (has_length)
						return coordinate_map!(dim, T)(source.length);

					else static assert (0);
				}
			T measure (T = Coordinate!0)()
				if (is (unidimensional))
				{/*...}*/
					return measure!(0,T);
				}

			auto measure (string label, T = void)()
				if (is (typeof (this.label!label.identity) : size_t))
				{/*...}*/
					static if (is (T == void))
						return measure!(this.label!label.identity);
					else return measure!(this.label!label.identity, T);
				}

			auto volume ()()
				if (is (multidimensional))
				{/*...}*/
					static product_of_measures ()
						{/*...}*/
							string[] code;

							foreach (i; Dimensions!Source)
								code ~= q{measure!} ~i.text;

							return code.join (` * `).to!string;
						}

					mixin(q{
						return } ~product_of_measures~ q{;
					});
				}

			size_t length ()()
				if (is (unidimensional) && has_length)
				{/*...}*/
					return coordinate_map!(0, size_t)(measure!0);
				}
		}
		public {/*boundaries}*/
			T[2] boundary (size_t dim, T = Coordinate!dim)()
				if (is (multidimensional))
				{/*...}*/
					static if (has_boundary!dim)
						return coordinate_map!(dim, T)(source.boundary!dim);

					else static if (has_measure!dim)
						return coordinate_map!(dim, T)([zero!T, measure!(dim, T)]);

					else static assert (0);
				}

			T[2] boundary (size_t dim : 0, T = Coordinate!dim)()
				if (is (unidimensional))
				{/*...}*/
					static if (has_boundary!dim)
						return coordinate_map!(dim, T)(source.boundary);

					else static if (has_measure!dim)
						return coordinate_map!(dim, T)([zero!T, measure!T]);

					else static if (has_length)
						return coordinate_map!(dim, T)([0, source.length]);

					else static assert (0);
				}
			T[2] boundary (T = Coordinate!0)()
				if (is (unidimensional))
				{/*...}*/
					return boundary!(0,T);
				}

			auto boundary (string label, T = void)()
				if (is (typeof (this.label!label.identity) : size_t))
				{/*...}*/
					static if (is (T == void))
						return boundary!(this.label!label.identity);
					else return boundary!(this.label!label.identity, T);
				}
		}
		public {/*selection}*/
			auto ref opIndex (T...)(T selection)
				if (not (Any!(is_interval, T)))
				in {/*...}*/
					static assert (T.length == dimensionality!Source,
						usage_error~
						T.stringof~ ` does not index ` ~dimensionality!Source.text~ `D space `
					);
					
					foreach (i,_; selection)
						assert (map_selections (selection[i]).expand.within (boundary!i),
							`selection ` ~selection[i].text~ ` exceeded boundary ` ~boundary!i.text
							~ ` on dimension ` ~i.text
						);
				}
				body {/*...}*/
					static if (is (access_by_function))
						return access (map_selections (selection).expand);

					else static if (is (access_by_ptr))
						{/*...}*/
							size_t offset (size_t dim = 0)()
								{/*...}*/
									static if (dim == dimensionality!Source)
										return 0;
									else return map_selection!dim (selection[dim]) + measure!dim * offset!(dim + 1);
								}

							return ptr[offset];
						}
				}

			auto opIndex (T...)(T selection)
				if (Any!(is_interval, T))
				in {/*...}*/
					static assert (T.length == dimensionality!Source);
					
					foreach (i,_; selection)
						assert (map_selections (selection[i]).expand.within (boundary!i),
							`selection ` ~selection[i].text~ ` exceeded boundary ` ~boundary!i.text
							~ ` on dimension ` ~i.text
						);
				}
				body {/*...}*/
					return Sub!(Map!(is_interval, T))(&this, map_selections (selection).expand);
				}

			auto opIndex ()()
				{/*...}*/
					enum free (T...) = true;

					enum entire_slice (size_t dim) = q{boundary!} ~dim.text;

					mixin(q{
						return Sub!(Map!(free, Dimensions!Source))(
							&this, }
								~Map!(entire_slice, Dimensions!Source)
									.only.join (`, `).to!string
								~q{
							);
					});
				}
		}
		public {/*subspaces}*/
			Coordinate!dim origin (size_t dim)(Coordinate!dim measure)
				if (has_origin!dim)
				{/*...}*/
					return source.origin!dim (measure);
				}

			Interval!dim opSlice (size_t dim, T, U)(T i, U j)
				{/*...}*/
					alias V = CommonType!(T,U);

					return [
						coordinate_map!dim (V (i)),
						coordinate_map!dim (V (j)),
					];
				}

			static struct Sub (DegreesOfFreedom...)
				if (All!(is_type_of!bool, Map!(type_of, DegreesOfFreedom)))
				{/*...}*/
					Space* space;

					public {/*primitives}*/
						auto access (Coords...)(Coords point)
							{/*...}*/
								return this[point];
							}
					}
					public {/*dimensions}*/
						alias Free = Map!(Pair!().first!Identity,
							Filter!(Pair!().second!Identity,
								Zip!(
									Dimensions!Source,
									DegreesOfFreedom
								)
							)
						);

						alias Bound = Map!(Pair!().first!Identity,
							Filter!(Pair!().second!Identity,
								Zip!(
									Dimensions!Source,
									Map!(not, DegreesOfFreedom)
								)
							)
						);
					}
					public {/*measures}*/
						T measure (size_t dim, T = Coordinate!(Free[dim]))()
							if (dim < Free.length)
							{/*...}*/
								return space.coordinate_map!(Free[dim], T)(global_bounds[Free[dim]].difference);
							}

						T measure (T = Coordinate!(Free[0]))()
							if (Free.length == 1)
							{/*...}*/
								return measure!(0, T);
							}

						auto volume ()()
							if (Free.length > 1)
							{/*...}*/
								static product_of_measures ()
									{/*...}*/
										string[] code;

										foreach (i,_; Free)
											code ~= q{measure!} ~i.text;

										return code.join (` * `).to!string;
									}

								mixin(q{
									return } ~product_of_measures~ q{;
								});
							}
					}
					public {/*boundaries}*/
						alias to_boundary (alias pair) = Select!(pair.second, Interval!(pair.first), Coordinate!(pair.first));

						Map!(to_boundary, 
							Zip!(
								Dimensions!Source,
								DegreesOfFreedom
							)
						) global_bounds;

						T[2] boundary (size_t dim, T = Coordinate!(Free[dim]))()
							{/*...}*/
								return [
									space.coordinate_map!(Free[dim], T)(-origin!dim), // BUG this is wrong
									space.coordinate_map!(Free[dim], T)(-origin!dim + global_bounds[Free[dim]].difference)
								];
							}
					}
					public {/*selection}*/
						auto origin (size_t dim)()
							{/*...}*/
								static if (has_origin!(Free[dim]))
									return space.origin!(Free[dim])(measure!dim);

								else static if (is (typeof(global_bounds)[dim] == T[2], T))
									return zero!T;

								else return zero!(typeof(global_bounds)[dim]);
							}

						auto opIndex (T...)(T selection)
							if (T.length == Free.length)
							in {/*...}*/
								foreach (i,_; selection)
									{/*...}*/
										assert (space.map_selections (selection[i]).expand.within (boundary!i),
											usage_error~
											`selection ` ~selection[i].text~ ` exceeded boundary ` ~boundary!i.text
											~ ` on dimension ` ~i.text
										);
									}
							}
							body {/*...}*/
								static code ()
									{/*...}*/
										string[] code;

										foreach (j,_; typeof(global_bounds))
											static if (Contains!(j, Free))
												code~= q{selection[IndexOf!(} ~j.text~ q{, Free)]};
											else code~= q{global_bounds[} ~j.text~ q{]};

										return code.join (", ").to!string;
									}

								foreach (i,_; typeof(selection))
									{/*...}*/
										static if (is (T[i] == U[2], U))
											{/*...}*/
												selection[i][] += origin!i;
												selection[i][] += global_bounds[Free[i]].left;
											}
										else {/*...}*/
											selection[i] += origin!i;
											selection[i] += global_bounds[Free[i]].left;
										}
									}

								mixin(q{
									return space.opIndex (} ~code~ q{);
								});
							}

						auto opIndex ()()
							{/*...}*/
								return this;
							}

						auto opSlice (size_t dim, Args...)(Args args)
							{/*...}*/
								return space.opSlice!dim (args);
							}
					}
					public {/*equality}*/
						auto opEquals (S)(S subspace)
							{/*...}*/
								enum can_flatten = is (typeof (this.flatten)) && is (typeof (subspace.flatten));

								static if (__traits(hasMember, Source, `equality`))
									pragma(msg, typeof (space.equality (subspace, global_bounds)));
								static if (is (typeof (source.equality (subspace, global_bounds)) == bool))
									{/*...}*/
										return space.equality (subspace, global_bounds);
									}

								else static if (can_flatten)
									{/*...}*/
										return this.flatten.equal (subspace.flatten);
									}

								else static assert (0, 
									usage_error~
									`unable to compare ` ~Space.stringof~ ` to ` ~S.stringof
								);
							}
					}

					mixin BoundaryOps!Sub;
					mixin CoordinateOps!space;
					mixin LabelOps!Space;
					mixin IterationOps!Free;
					mixin Mixin!SubspaceExtensions;
				}
		}

		mixin BoundaryOps!Space;
		mixin CoordinateOps!source;
		mixin LabelOps!Source;

		private:
		private {/*selection maps}*/
			auto map_selection (size_t dim, T)(T arg)
				{/*...}*/
					static if (is (T == Interval!dim))
						return arg;
					else return coordinate_map!dim (arg);
				}
			auto map_selections (T...)(T args)
				{/*...}*/
					enum long dim = dimensionality!Source - T.length;

					static if (T.length == 0)
						return τ();

					else return τ(
						map_selection!dim (args[0]),
						map_selections (args[1..$]).expand
					);
				}
		}
	}

/*
	CONSTRUCTION
*/
struct InitialSpace (Range)
	{/*...}*/
		struct Base
			{/*...}*/
				Range range;

				alias range this;

				static if (not (is (typeof(*range.ptr) == T, T)))
					auto access (size_t point)
						{/*...}*/
							return range[point];
						}
			}

		this (Range range)
			{/*...}*/
				base = Base (range);
			}

		Base base;

		alias base this;

		mixin SpaceOps!base;
	}
auto initial_space (R)(R range)
	{/*...}*/
		static if (is_space!R)
			return range;
		else return InitialSpace!R (range);
	}

/*
	TOPOLOGY
*/
struct Transposed (M) // REFACTOR
	{/*...}*/
		struct Base
			{/*...}*/
				M matrix;

				alias matrix this;

				void ptr (){} // disables matrix.ptr to allow alias this without access/ptr conflict

				auto access (size_t row, size_t column)
					{/*...}*/
						return matrix[column, row];
					}
			}

		Base base;

		mixin SpaceOps!base;
	}
auto transpose (M)(M matrix) // REFACTOR
	{/*...}*/
		return Transposed!M (Transposed!M.Base (matrix));
	}

/*
	ITERATOR
*/
struct Along (Space, Axes...)
	{/*...}*/
		enum to_dimension (size_t dim) = dim;
		enum to_dimension (string label) = Space.label!label;

		alias Dimensions = Map!(to_dimension, Axes);

		Space space;

		enum traversable (size_t dim) = Contains!(dim, Dimensions);

		mixin EqualityOps;

		Repeat!(Dimensions.length, size_t[2])
			position;

		this (Space space)
			in {/*...}*/
				foreach (d; Dimensions)
					static assert (Contains!(d, .Dimensions!Space),
						`no dimension ` ~d.text~ ` exists for ` ~dimensionality!Space.text~ `D ` ~Space.stringof
					);
			}
			body {/*...}*/
				this.space = space;

				foreach (i, dim; Dimensions)
					position[i] = space.boundary!(dim, size_t); // REVIEW was measure!(dim, size_t)... consequences?
			}

		auto get (string side)()
			if (side == `left` || side == `right`)
			in {/*...}*/
				assert (not(empty), `attempted to get ` ~(side is `left`? `front`:`back`)~ ` of empty ` ~fullyQualifiedName!Space);
			}
			body {/*...}*/
				static code ()
					{/*...}*/
						string[] code;

						foreach (i; .Dimensions!Space)
							{/*...}*/
								enum dim = i.text;

								static if (Contains!(i, Dimensions))
									code ~= q{position[IndexOf!(} ~dim~ q{, Dimensions)].} ~side ~ (side is `right`? `-1`:``);
								else code ~= q{~$..$};
							}

						return code.join (`, `).to!string;
					}

				mixin(q{
					return space[} ~code~ q{];
				});
			}

		auto advance (string side)()
			if (side == `left` || side == `right`)
			{/*...}*/
				static if (side is `left`)
					enum advancement = `++`;

				else static if (side is `right`)
					enum advancement = `--`;

				else static assert (0);

				mixin(
					advancement~ q{position[0].} ~side~ q{;}
				);

				foreach (i, dim; Dimensions[0..$-1])
					if (position[i].left == position[i].right)
						{/*...}*/
							mixin(
								advancement~ q{position[i+1].} ~side~ q{;}
							);

							position[i] = space.boundary!(dim, size_t);
						}
			}

		alias front = get!`left`;
		alias back = get!`right`;

		alias popFront = advance!`left`;
		alias popBack = advance!`right`;

		bool empty ()
			{/*...}*/
				return position[$-1].left == position[$-1].right;
			}

		auto length ()
			{/*...}*/
				static code ()
					{/*...}*/
						string[] code;

						foreach (i,_; typeof(position))
							static if (i == 0)
								code ~= q{position[} ~i.text~ q{].difference};
							else code ~= q{(volume *= space.measure!(} ~i.text~ q{-1, size_t)) * (position[} ~i.text~ q{].difference - 1)};

						return code.join (` + `).to!string;
					}

				size_t volume = 1;

				mixin(q{
					return } ~code~ q{;
				});
			}

		@property save ()
			{/*...}*/
				return this;
			}
	}
template along (Dimensions...)
	{/*...}*/
		auto along (Space)(Space space)
			{/*...}*/
				return Along!(typeof(space.initial_space), Dimensions)(space.initial_space);
			}
	}
auto flatten (Space)(Space space)
	{/*...}*/
		return along!(Dimensions!Space)(space);
	}

/*
	DEMOS
*/
void intro_demo ()
	{/*...}*/
		/*
			one way to create a space is by defining it explicitly.
			this is done by wrapping a base inside of an enclosing struct, like so:
		*/
		struct ArraySpace
			{/*...}*/
				/*
					base
				*/
				int[8] data = [8,7,6,5,4,3,2,1];

				/*
					wrapper
				*/
				mixin SpaceOps!data;
			}

		/*
			the SpaceOps mixin analyzes the int[8] base and turns ArraySpace into a Space
		*/
		ArraySpace x;

		/*
			the familiar (non-arithmetic) array operations are preserved
		*/
		assert (x[0] == 8);
		assert (x[1] == 7);
		assert (x[2] == 6);
		assert (x[3] == 5);
		assert (x[$/2..$] == [4,3,2,1]);
		assert (x[] == [8,7,6,5,4,3,2,1]);
		assert (x.length == 8);

		/*
			but a few new operators are added. for example, a type-generic range comparison
		*/
		assert (x[0..$/2] != only (1,2,3,4));
		assert (x[0..$/2] == only (8,7,6,5));

		/*
			as well as a measure and a boundary
		*/
		assert (x.measure == x.length);
		assert (x.boundary == [0, x.length]);

		/*
			so the underlying int[8] semantics are preserved, while bringing it into the SpaceCadet system.
		*/

		/*
			this is possible for any range. here is another example:
		*/
		struct OnlySpace
			{/*...}*/
				struct Base
					{/*...}*/
						auto range = only (1,2,3);

						alias range this;

						auto access (size_t i)
							{return range[i];}
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			this time required an extra wrapping layer, and an access function.
			this is because SpaceOps looks for either a ptr (which int[8] has)
			or an access function, as well as some way to measure the Space.

			aliasing the range exposed its length property,
			which provides the measurement.
		*/
		OnlySpace y;

		assert (y[] == [1,2,3]);
		assert (y[$-1] == 3);
		assert (y.length == 3);
		assert (y.boundary == [0,3]);

		/*
			let's up the stakes a little and define a multidimensional array:
		*/
		struct MultiSpace
			{/*...}*/
				struct Base
					{/*...}*/
						int[4*4] matrix = [
							16, 15, 14, 13,
							12, 11, 10,  9,
							 8,  7,  6,  5,
							 4,  3,  2,  1,
						];

						auto ptr ()
							{return matrix.ptr;}

						size_t measure (size_t dim)()
							if (dim < 2)
							{return 4;}
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			first, we exposed a ptr to make the base data accessible.

		*/
		/*
			then, we defined a measure property.

				since length is a common property of traditional, implicitly 1D ranges,
				it only exists in SpaceCadet insofar as to enable interop with those ranges.

				once we leave the 1st dimension, we work exclusively in measures and boundaries.

			the dimension of the space is determined by the maximum element of a 0-initialized sequence of indices,
				such that each element successfully instantiates a measure or boundary property

			here, we used a template constraint on our measure to reject indices greater than 1,
			which makes the resulting Space 2D.
		*/
		MultiSpace z;

		/*
			now we have created a 2D space.
		*/
		assert (z.volume == 16);
		assert (z.measure!0 == 4);
		assert (z.measure!1 == 4);
		assert (z.boundary!0 == [0,4]);
		assert (z.boundary!1 == [0,4]);

		/*
			capable of multidimensional indexing 
			(each index is called a coordinate in SpaceCadet)
			to select elements from the Space
		*/
		assert (z[0, 0] == 16);
		assert (z[2, 1] == 10);
		assert (z[0, $-1] == 4);

		/*
			and multidimensional slicing operators
			(referred to in SpaceCader as intervals)
			to select a Subspace
		*/
		assert (z[0..$, 0..$] == z[]);

		/*
			and extracting lower-dimensional subspaces
			by specifying a combination of coordinates and intervals
		*/
		assert (z[0..$, 0] == [16, 15, 14, 13]);
		assert (z[2, 0..$] == [14, 10,  6,  2]);
		assert (z[0, 0..$][2] == 8);
	}
void iteration_demo ()
	{/*...}*/
		struct Matrix
			{/*...}*/
				struct Base
					{/*...}*/
						auto matrix = [
							9,8,7,
							6,5,4,
							3,2,1
						];

						size_t measure (size_t dim)()
							if (dim < 2)
							{/*...}*/
								return 3;
							}

						alias matrix this;
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			length and bidirectional range primitives are defined for 1D spaces parameterized by size_t

			in most respects, such a space would be a random access range, but the length property of the space
			is generally not visible to Phobos.
			this is because Phobos defines having length as having a const property length,
			but many ranges in Phobos itself don't define length as being const.

			between the options of making length const and locking out any non-const-length ranges from being
			usable, subverting the type system by silently casting away constness, and making length non-const,
			the last option seemed the least restrictive and dangerous.
		*/
		assert (Matrix()[0, 0..$].length == 3);
		assert (Matrix()[0, 0..$] == [9,6,3]);
		assert (Matrix()[0, 0..$].retro.equal ([3,6,9]));
		static assert (is_bidirectional_range!(typeof(Matrix()[0, 0..$])));

		/*
			the flatten transform can be used to turn a discrete space into a bidirectional range with length
		*/
		assert (Matrix()[].flatten.length == Matrix().volume);
		static assert (is_bidirectional_range!(typeof(Matrix()[].flatten)));

		/*
			during iteration, the leftmost index changes fastest
		*/
		foreach (i, a; enumerate (Matrix()[].flatten))
			assert (a == Matrix()[i%3, i/3]);

		/*
			the underlying matrix data is stored in row-major order,
			and accessed using Cartesian conventions (i.e. [horizontal, vertical])
			which may feel a bit awkward if the space represents a matrix.
		*/
		/*
			matrices need to be transposed to use [row, column] indexing

			this can be achieved through the transpose function,
			which reverses the indices without affecting the underlying data store
			(because an underlying data store may not necessarily exist)
		*/
		assert (Matrix().transpose[0, 0..$] == [9,8,7]);
		assert (Matrix().transpose[0,2] == 7);

		/*
			note that transposition also changes iteration order,
			and since iteration of a flattened space increments the leftmost index fastest,
			the most efficient iteration of a ptr-based Space results from
			a [column, row] indexing scheme.

			to handle this, either untranpose matrices before iterating over them,
			or transpose the underlying data store to column-major order

			note that these performance concerns only apply to matrices backed by data stores;
			performance of procedurally generated matrices is generally unaffected by caching
		*/
		foreach (i, a; enumerate (Matrix()[].flatten))
			assert (a == Matrix().transpose[i/3, i%3]);

		/*
			it is possible to iterate along a specific axis, 
			over subspaces orthogonal to the axis
		*/
		foreach (i, line; enumerate (Matrix()[].along!0))
			assert (line == Matrix()[i, 0..$]);

		foreach (i, line; enumerate (Matrix()[].along!1))
			assert (line == Matrix()[0..$, i]);

		/*
			along will traverse the given dimensions, with the leftmost index changing fastest
			this can be used to control the iteration pattern
		*/
		assert (Matrix()[].along!(0,1) == Matrix().flatten);
		assert (Matrix()[].along!(1,0) == Matrix().transpose.flatten);
	}
void axis_label_demo ()
	{/*...}*/
		/*
			dimensions can be associated with strings by defining indexed label templates

			the value of the string must be readable at compile-time
		*/
		struct Matrix
			{/*...}*/
				struct Base
					{/*...}*/
						int[4*4] matrix = [
							16, 15, 14, 13,
							12, 11, 10,  9,
							8,   7,  6,  5,
							4,   3,  2,  1,
						];

						size_t measure (size_t i)()
							if (i < 2)
							{/*...}*/
								return 4;
							}

						auto access (size_t i, size_t j)
							{/*...}*/
								return matrix[4*i + j];
							}

						enum label (size_t d: 0) = `rows`;
						enum label (size_t d: 1) = `columns`;
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			labelled axes enhance readability
		*/
		assert (Matrix().measure!`rows` == 4);
		assert (Matrix().measure!`columns` == 4);
		assert (Matrix().boundary!`rows` == [0,4]);
		assert (Matrix().boundary!`columns` == [0,4]);

		assert (Matrix()[].along!`rows` == [
			[16, 15, 14, 13],
			[12, 11, 10,  9],
			[8,   7,  6,  5],
			[4,   3,  2,  1],
		]);

		assert (Matrix()[].along!`columns` == [
			[16, 12, 8, 4],
			[15, 11, 7, 3],
			[14, 10, 6, 2],
			[13,  9, 5, 1],
		]);

		/*
			combined with the along iterator, they enable declarative iteration
		*/
		assert (Matrix()[].along!(`rows`, `columns`) == Matrix()[].flatten);
		assert (Matrix()[].along!(`columns`, `rows`) == Matrix()[].transpose.flatten);
	}
void floating_point_space_demo ()
	{/*...}*/
		/*
			we construct the unit plane
		*/
		struct Plane
			{/*...}*/
				struct Base
					{/*...}*/
						auto access (double x, double y)
							{/*...}*/
								return x^^2 + y^^2;
							}

						double measure (size_t i)()
							if (i < 2)
							{/*...}*/
								return 1;
							}

						enum label (size_t i: 0) = `x`;
						enum label (size_t i: 1) = `y`;
					}

				Base base;

				mixin SpaceOps!base;
			}

		assert (Plane().measure!`x` == 1.0);
		assert (Plane().measure!`y` == 1.0);

		assert (Plane().boundary!`x` == [0.0, 1.0]);
		assert (Plane().boundary!`y` == [0.0, 1.0]);

		/*
			since intervals are open on the right, accessing [1,1] is out of bounds
		*/
		assert (Plane()[0.9999, 0.9999]);
		assert (Plane()[0.99999, 0.99999]);
		assert (Plane()[0.999999, 0.999999]);
		assert (Plane()[0.9999999, 0.9999999]);

		/*
			the plane has no size_t parameterization, and so cannot be flattened or iterated
			and therefore has no default equality comparison
				(see the section on Equality)
		*/

		/*
			spaces can define coordinate maps between any coordinate type to a canonical coordinate type
			the map must be present with its inverse, both called coordinate_map,
			and the inverse map must take a 2nd template parameter - the desired codomain type
		*/
		struct DiscretePlane
			{/*...}*/
				struct Base
					{/*...}*/
						Plane plane;

						alias plane this;

						/*
							both the map and its inverse must be present to enable coordinate mapping
						*/
						double coordinate_map (size_t dim)(size_t i)
							if (dim < 2)
							{/*...}*/
								return double (i / 10.0);
							}
						T coordinate_map (size_t dim, T)(double x)
							if (is_integral!T)
							{/*...}*/
								return (x * 10.0).to!T;
							}
					}

				Base base;

				mixin SpaceOps!base;
			}

		assert (DiscretePlane().measure!`x` == 1.0);
		assert (DiscretePlane().measure!`y` == 1.0);

		assert (DiscretePlane().boundary!`x` == [0.0, 1.0]);
		assert (DiscretePlane().boundary!`y` == [0.0, 1.0]);

		assert (DiscretePlane()[0.9999, 0.9999]);
		assert (DiscretePlane()[0.99999, 0.99999]);
		assert (DiscretePlane()[0.999999, 0.999999]);
		assert (DiscretePlane()[0.9999999, 0.9999999]);

		/*
			floating point coordinates and integral coordinates are not interchangeable
			while converting between floating point types or between integral types is implicit
		*/
		assert (DiscretePlane()[0.9, 0.4] == DiscretePlane()[9, 4]);
		/*
			even if they are mixed within the same indexing operation
		*/
		assert (DiscretePlane()[0.0, 9] == DiscretePlane()[0.0, 0.9]);

		/*
			however, mixed arguments within a slice will be converted to their common type
		*/
		assert (DiscretePlane()[0.0..1, 0.0].measure == 1.0);
		assert (DiscretePlane()[0..1, 0.0].measure == 0.1);

		/*
			once a space has a discrete parameterization, it gains builtin equality operators
		*/
		assert (DiscretePlane()[] == DiscretePlane()[]);
		/*
			and iteration
		*/
		foreach (x; DiscretePlane()[0.0, 0.1..1.0])
			assert (x);
	}
void boundary_operator_demo ()
	{/*...}*/
		enum int[10] array_data = [0,1,2,3,4,5,6,7,8,9];

		struct ArraySpace
			{/*...}*/
				int[10] array = array_data;

				mixin SpaceOps!array;
			}

		/*
			$ is called the boundary operator

			in D, $ typically represents the length of a range.
			for 1D spaces paramaterized by an unsigned integral,
			this is still the case.
		*/
		assert (ArraySpace()[0..$] == array_data[0..$]);

		/*
			several common algorithms have been generalized to accomodate $.
		*/
		assert (ArraySpace()[0..max (2,$)] == array_data[0..$]);

		/*
			$ can be converted to any coordinate type, using UCS...
		*/
		assert (ArraySpace()[0..std.algorithm.max (2, size_t($))] == array_data[0..$]);
		/*
			casting...
		*/
		assert (ArraySpace()[0..std.algorithm.max (2, cast(size_t)$)] == array_data[0..$]);
		/*
			std.conv.to...
		*/
		assert (ArraySpace()[0..std.algorithm.max (2, $.to!size_t)] == array_data[0..$]);
		/*
			or as the result of an arithmetic operation with some coordinate type.
		*/
		assert (ArraySpace()[0..std.algorithm.max (2, $ + 0)] == array_data[0..$]);

		/*
			generic algorithms which may interact with $ can convert it to a common type with any coordinates using std.traits.CommonType
		*/

		/*
			defining a boundary instead of a measure can enable negative coordinates
		*/
		struct OffsetArray
			{/*...}*/
				struct Base
					{/*...}*/
						long[2] boundary () // BUG if this was int, it would fail with cryptic messages
							{/*...}*/
								return [-5,5];
							}

						auto access (long x)
							{/*...}*/
								return array[x+5];
							}

						int[10] array = array_data;
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			then the element at 0 is not necessarily the first element
		*/
		assert (OffsetArray ()[0] != OffsetArray ()[].front);
		assert (OffsetArray ()[-5] == OffsetArray ()[].front);
		assert (OffsetArray ()[0..$] == [5,6,7,8,9]);

		/*
			instead, the left boundary operator ~$ is used to refer to the start.
		*/
		assert (OffsetArray ()[~$] == OffsetArray ()[].front);
		assert (OffsetArray ()[~$..0] == [0,1,2,3,4]);
		assert (OffsetArray ()[~$..$] == OffsetArray ()[]);

		/*
			to get the measure of a dimension, there is $.measure
		*/
		assert (OffsetArray ()[~$..~$ + $.measure] == OffsetArray ()[]);
		/*
			or ($-~$)
		*/
		assert (OffsetArray ()[~$..~$ + ($-~$)] == OffsetArray ()[]);
	}
void equality_overload_demo ()() // TODO
	{/*...}*/
		struct SquaredSpace
			{/*...}*/
				struct Base
					{/*...}*/
						double access (double x, double y)
							{/*...}*/
								return x^^2 + y^^2;
							}

						double measure (size_t i)()
							if (i < 2)
							{/*...}*/
								return 1.0;
							}

						bool equality (R, T...)(R space, T boundaries)
							{/*...}*/
								import std.math;

								foreach (i, boundary; boundaries)
									if (space.measure!i.not!approxEqual (measure!i))
										return false;
								// get a common measure type
							}
					}

				Base base;

				mixin SpaceOps!base;
			}
		struct SineSpace
			{/*...}*/
				struct Base
					{/*...}*/
						double access (double x, double y)
							{/*...}*/
								return sin (x + y);
							}

						double measure (size_t i)()
							if (i < 2)
							{/*...}*/
								return 1.0;
							}
					}

				Base base;

				mixin SpaceOps!base;
			}

		std.stdio.writeln (SquaredSpace()[] == SineSpace()[]);
	}
void origin_offset_demo ()
	{/*...}*/
		/*
			sometimes it is desirable to have slices offset their local boundaries.

			here is an example of using boundaries to create a space which is centered at 0,
			and using origin offsets to ensure that its subspaces are all centered at 0 also
		*/
		struct UnitSpace
			{/*...}*/
				struct Base
					{/*...}*/
						double[2] boundary (size_t i)()
							if (i < 2)
							{/*...}*/
								return [-1,1];
							}

						auto access (double x, double y)
							{/*...}*/
								return τ(x,y);
							}

						double origin (size_t i)(double width)
							if (i < 2)
							{/*...}*/
								return width/2;
							}
					}

				Base base;

				mixin SpaceOps!base;
			}

		/*
			first, we slice the half the range
		*/
		auto space = UnitSpace();
		auto slice = space[0.0, 0.0..$];

		/*
			now the slice is locally centered at 0.0 
		*/
		assert (slice[0.0] == space[0.0, $/2]);
		assert (slice[-0.5] == space[0.0, 0.0]);
	}
void binary_cube_demo ()
	{/*...}*/
		static struct BinaryCube
			{/*...}*/
				struct Base
					{/*...}*/
						size_t measure (size_t dim)()
							if (dim < 3)
							{/*...}*/
								return 2;
							}

						size_t access (size_t i, size_t j, size_t k)
							{/*...}*/
								return i ^ j ^ k;
							}
					}

				Base base;

				mixin SpaceOps!base;
			}

		{/*dimensions, measures and boundaries}*/
			/*
				for initial spaces (i.e. spaces which do not already have SpaceOps), dimensionality is defined
				as the maximum n for which there is defined either boundary!i or measure!i (but not both) for all i ϵ [0..n) 
				or as 1 if only measure or boundary (but not both) are defined
			*/
			/*
				measure must return a single scalar value of any type, while boundary must return a static array of length 2
			*/
			static assert (dimensionality!BinaryCube == 3);

			/*
				for non-initial spaces, both measures and boundaries are automatically defined to be consistent with one another
			*/
			/*
				boundary is defined as either the boundary given by the base space, or as an interval starting at the zero element of the measure type, and spanning the measure
			*/
			assert (BinaryCube().boundary!0 == [0,2]);
			assert (BinaryCube().boundary!1 == [0,2]);
			assert (BinaryCube().boundary!2 == [0,2]);

			/*
				measure is defined as either the measure given by the base space, or as the difference between the right and left boundary points
			*/
			assert (BinaryCube().measure!0 == 2);
			assert (BinaryCube().measure!1 == 2);
			assert (BinaryCube().measure!2 == 2);

			/*
				for 2-or-higher-dimensional spaces, volume is defined as the product of all measures, if such a product exists
			*/
			assert (BinaryCube().volume == 8);
		}
		{/*points and indices}*/
			/*
				points in a multidimensional space can be accessed using multidimensional index operators
			*/
			assert (BinaryCube()[0,0,0] == 0);
			assert (BinaryCube()[1,0,0] == 1);
			assert (BinaryCube()[0,1,0] == 1);
			assert (BinaryCube()[0,0,1] == 1);
		}
		{/*subspaces, slices, and range semantics}*/
			/*
				slices can be taken along each dimension with the familiar D semantics
			*/
			auto sliced = BinaryCube()[0..$, 0..$, 0..$];
			static assert (dimensionality!(typeof(sliced)) == 3);

			/*
				slicing a space returns a subspace, which defines its own measures and boundaries
			*/
			assert (sliced.measure!0 == 2);
			assert (sliced.measure!1 == 2);
			assert (sliced.measure!2 == 2);

			assert (sliced.volume == 8);

			assert (sliced.boundary!0 == [0,2]);
			assert (sliced.boundary!1 == [0,2]);
			assert (sliced.boundary!2 == [0,2]);

			/*
				in a subspace, a dimension can be sliced or indexed is called free, otherwise it is bound
				when slicing a space or subspace, any dimension that is indexed becomes bound, while dimensions that are sliced remain free
				binding all dimensions determines a single point in the space
			*/
			auto plane = BinaryCube()[0..$, 0..$, 0];
			static assert (dimensionality!(typeof(plane)) == 2);

			/*
				futher slicing or indexing operations do not refer to bound dimensions.
			*/
			assert (plane[0,0] == BinaryCube()[0,0,0]);
			assert (plane[0,1] == BinaryCube()[0,1,0]);
			assert (plane[1,0] == BinaryCube()[1,0,0]);
			assert (plane[1,1] == BinaryCube()[1,1,0]);

			/*
				bound dimensions have measure 0 and do not factor into the definition of volume.
			*/
			assert (plane.measure!0 == 2);
			assert (plane.measure!1 == 2);
			assert (plane.volume == 4);

			assert (plane.boundary!0 == [0,2]);
			assert (plane.boundary!1 == [0,2]);

			/*
				a subspace which has only one free dimension becomes effectively 1-dimensional.
			*/
			auto edge = BinaryCube()[0, 1, 0..$];
			static assert (dimensionality!(typeof(edge)) == 1);

			/*
				a non-indexed measure is defined for it, whereas volume is not defined.
			*/
			assert (edge.measure!0 == 2);
			assert (edge.measure == 2);

			assert (edge[0] == BinaryCube()[0,1,0]);
			assert (edge[1] == BinaryCube()[0,1,1]);
		}
		{/*boundary operators}*/
			/*
				the $ operator, normally the length operator of a D range, is the boundary operator of a space or subspace
				$ denotes the right boundary point and ~$ denotes the left boundary point
				since the left boundary is, by default, zero, the semantics of $ for most 1D spaces and subspaces are consistent with that of D ranges
			*/
			assert (BinaryCube()[~$,~$,~$] == BinaryCube()[0,0,0]);
			assert (BinaryCube()[$-1,$-1,$-1] == BinaryCube()[1,1,1]);

			/*
				~$ provides a generic way to access the left boundary of a space or subspace
			*/
			assert (BinaryCube()[~$..$, ~$..$, ~$..$] == BinaryCube()[]);
			assert (BinaryCube()[~$..$, ~$..$, ~$] == BinaryCube()[0..$, 0..$, 0]);
			assert (BinaryCube()[~$, ~$, ~$..$] == BinaryCube()[0, 0, 0..$]);

			/*
				getting a measure from the boundary operator is accomplished with $.measure or, more tersely, ($-~$)
			*/
			assert (BinaryCube()[0,0, ($-~$) == $.measure? 1:0] == 1);
		}
		////
		{/*performance}*/
			/*
				SpaceOps do not increase the size of a struct so long as it is static
			*/
			static assert (BinaryCube.sizeof == 1);
		}
	}
void rounding_cube_demo ()
	{/*...}*/
		static struct RoundingCube
			{/*...}*/
				struct Base
					{/*...}*/
						size_t measure (size_t dim)()
							if (dim < 3)
							{/*...}*/
								return 2;
							}

						size_t[3] access (size_t i, size_t j, size_t k)
							{/*...}*/
								return [i,j,k];
							}

						size_t coordinate_map (size_t d)(double x)
							{/*...}*/
								return x.round.to!size_t;
							}
						double coordinate_map (size_t d, T: double)(size_t i)
							{/*...}*/
								return i;
							}
					}

				Base base;

				mixin SpaceOps!base;
			}

		assert (RoundingCube()[0,0,0] == [0,0,0]);
		assert (RoundingCube()[0.4, 0.2, 0.9] == [0,0,1]);
		assert (RoundingCube()[0.6, 0.2, 0.9] == [1,0,1]);

		assert (RoundingCube()[$ - 1.6, 0.2, 0.9] == [0,0,1]);
		assert (RoundingCube()[$ - 1.5, 0.2, 0.9] == [1,0,1]);
	}

void main ()
	{/*...}*/
		intro_demo;
		iteration_demo;
		axis_label_demo;
		floating_point_space_demo;
		boundary_operator_demo;
		origin_offset_demo;

		binary_cube_demo;
		rounding_cube_demo;
	}
