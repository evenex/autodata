import std.stdio;
import std.typetuple;
import std.typecons;
import std.functional: to_delegate = toDelegate;
import std.traits;
import std.conv;
import evx.traits;
import evx.math;
import evx.range;
import evx.type;
import evx.misc.tuple;

alias Identity = evx.type.Identity; // TEMP

/* mixin a variadic overload function 
	which will route calls to the given symbol 
		to the first given mixin alias which can complete the call
	useful for controlling mixin overload sets
*/
static overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		string[] attempts;

		foreach (Alias; MixinAliases)
			attempts ~= q{
				static if (is (typeof(} ~ __traits(identifier, Alias) ~ q{.} ~ symbol ~ q{ (args))))
					return } ~ __traits(identifier, Alias) ~ q{.} ~ symbol ~ q{ (args);
			};

		attempts ~= q{static assert (0, typeof(this).stringof ~ `: no overloads for `}`"` ~ symbol ~ `"`q{` found`);};

		return q{auto } ~symbol~ q{ (Args...)(Args args)}
			`{` 
				~ join (attempts, q{else }).to!string ~ 
			`}`;
	}

template StandardErrorMessages ()
	{/*...}*/
		alias Element (T) = ElementType!(Select!(is (T == U[2], U), T, T[2]));

		enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

		enum type_mismatch_error = error_header
			~ Map!(Element, Selected).stringof ~ ` does not convert to ` ~ Map!(Element, typeof(limits)).stringof;

		auto out_of_bounds_error (T, U)(T arg, U limit) 
			{return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in ` ~ limit.text;}
	}

/* generate an indexing operator from an access function and a set of index limits
	access must be a function which returns an element of type E

	limits must be aliases to single variables or arrays of two,
	whose types (or element types, if any are arrays), given in order, 
	match the argument types for access
*/
template IndexOps (alias access, limits...)
	{/*...}*/
		ReturnType!access opIndex (ParameterTypeTuple!access selected)
			in {/*...}*/
				static assert  (limits.length == ParameterTypeTuple!access.length);

				version (all)
					{/*error messages}*/
						enum error_header = typeof(this).stringof ~ `: `;

						enum array_error = error_header ~ `limit types must be singular or arrays of two`
						`: ` ~ typeof(limits).stringof;

						enum type_error = error_header ~ `limit base types must match access parameter types`
						`: ` ~ typeof(limits).stringof
						~ ` != ` ~ ParameterTypeTuple!access.stringof;

						auto bounds_inverted_error (T)(T limit) 
							{return error_header ~ `bounds inverted! ` ~ limit.left.text ~ ` >= ` ~ limit.right.text;}

						auto out_of_bounds_error (T, U)(T arg, U limit) 
							{return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in ` ~ limit.text;}
					}

				foreach (i, limit; limits)
					{/*type check}*/
						static if (is (typeof(limit.identity) == T[n], T, size_t n))
							static assert (n == 2, array_error);

						static if (is (T))
							static assert (is (ParameterTypeTuple!access[i] == T), type_error);

						else static assert (is (ParameterTypeTuple!access[i] == typeof(limit.identity)), type_error);
					}

				foreach (i, limit; limits)
					{/*bounds check}*/
						static if (is (typeof(limit.identity) == T[2], T))
							assert (limit.left < limit.right, bounds_inverted_error (limit));

						static if (is (T))
							assert (
								selected[i] >= limit.left
								&& selected[i] < limit.right,
								out_of_bounds_error (selected[i], limit)
							);
						else assert (
							selected[i] >= zero!(typeof(limit.identity))
							&& selected[i] < limit,
							out_of_bounds_error (selected[i], [zero!(typeof(limit.identity)), limit])
						);
					}
			}
			body {/*...}*/
				return access (selected);
			}
	}

/* generate slicing operators from an access function, a set of index limits, 
	and (optionally) a set of uninstantiated, parameterless mixin templates to extend the Sub structure
*/
template SliceOps (alias access, LimitsAndExtensions...)
	{/*...}*/
		alias limits = Filter!(has_identity, LimitsAndExtensions); // having this out here is fucking you up, turns into an overloadset

		template SubGenerator (Dimensions...)
			{/*...}*/
				public {/*source}*/
					ReturnType!access delegate(ParameterTypeTuple!access)
						source; 
				}
				public {/*bounds}*/
					Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])}, typeof(limits)) 
						bounds;
				}
				public {/*limits}*/
					auto limit (size_t dim = 0)()
						{/*...}*/
							static if (is (typeof(this.origin.identity) == ParameterTypeTuple!access))
								{/*...}*/
									auto boundary = unity!(typeof(bounds[Dimensions[dim]]));

									boundary[] *= -origin!(Dimensions[dim]);
								}
							else auto boundary = zero!(typeof(bounds[Dimensions[dim]]));

							boundary.right += bounds[Dimensions[dim]].difference;

							return boundary;
						}
				}
				public {/*opIndex}*/
					mixin IndexOps!(source, bounds) indexing;

					typeof(this) opIndex ()
						{/*...}*/
							return this;
						}
					auto opIndex (Selected...)(Selected selected)
						in {/*...}*/
							mixin StandardErrorMessages;

							version (all)
								{/*type check}*/
									mixin LambdaCapture;

									static assert (
										All!(Pair!().both!is_implicitly_convertible,
											Zip!(
												Map!(Element, Selected),
												Map!(Element, 
													Map!(Λ!q{(size_t i) = typeof(limits)[i]}, Dimensions)
												),
											)
										), type_mismatch_error
									);
								}

							foreach (i, limit; selected)
								{/*bounds check}*/
									// TODO
								}
						}
						body {/*...}*/
							static if (is (typeof(this.origin.identity) == ParameterTypeTuple!access))
								{/*...}*/
									auto origin = this.origin;

									foreach (i, j; Dimensions)
										static if (is (T == U[2], U))
											selected[i].left += origin[j];
										else selected[i] += origin[j];
								}

							static if (Any!(λ!q{(T) = is (T == U[2], U)}, Selected))
								{/*...}*/
									auto bounds = unity!(typeof(bounds));
									
									foreach (i, ref boundary; bounds)
										boundary *= this.bounds[i].left;

									foreach (i, j; Dimensions)
										static if (is (typeof(selected[i]) == T[2], T))
											bounds[j][] += selected[i][];
										else static if (is (typeof(selected[i]) == T, T))
											bounds[j][] += [selected[i], selected[i] + unity!T];

									return Sub!(
										Map!(Pair!().first!Identity,
											Filter!(Pair!().second!Identity,
												Zip!(Dimensions,
													Map!(λ!q{(T) = is (T == U[2], U)}, 
														Selected
													)
												)
											)
										)
									)(source, bounds);
								}
							else {/*...}*/
								Map!(ElementType, typeof(bounds))
									point;

								foreach (i, ref coordinate; point)
									coordinate = bounds[i].left;

								foreach (i, j; Dimensions)
									point[j] += selected[i];

								return indexing.opIndex (point);
							}
						}
				}
				public {/*ctor}*/
					this (typeof(source) source, typeof(bounds) bounds)
						{/*...}*/
							this.source = source;
							this.bounds = bounds;
						}
					@disable this ();
				}
			}

		struct Sub (Dimensions...)
			{/*...}*/
				mixin SubGenerator!Dimensions sub;

				static extensions ()
					{/*...}*/
						string[] code;

						foreach (i, extension; Filter!(not!has_identity, LimitsAndExtensions))
							static if (is_string_param!extension)
								code ~= q{
									mixin(} ~ __traits(identifier, extension) ~ q{);
								};
							else code ~= q{
								mixin } ~ __traits(identifier, extension) ~ q{;
							};

						return code.join.to!string;
					}

				mixin(extensions);
			}

		public {/*opIndex}*/
			mixin IndexOps!(access, limits) indexing;

			auto opIndex (Selected...)(Selected selected)
				in {/*...}*/
					mixin StandardErrorMessages;

					static if (Selected.length > 0)
						{/*type check}*/
							static assert (Selected.length == limits.length, type_mismatch_error);

							static assert (
								All!(Pair!().both!is_implicitly_convertible,
									Zip!(
										Map!(Element, Selected),
										Map!(Element, typeof(limits)),
									)
								), type_mismatch_error
							);
						}

					foreach (i, limit; selected)
						{/*bounds check}*/
							alias T = typeof(limits[i].identity);

							static if (is (T == U[2], U))
								U[2] boundary = limits[i];

							else T[2] boundary = [zero!T, limits[i]];

							static if (is (typeof(limit.identity) == typeof(boundary)))
								assert (
									boundary.left <= limit.left
									&& limit.right <= boundary.right,
									out_of_bounds_error (limit, boundary)
								);
							else static if (is (typeof(limit.identity) : ElementType!(typeof(boundary))))
								assert (
									boundary.left <= limit
									&& limit < boundary.right,
									out_of_bounds_error (limit, boundary)
								);
							else static assert (0, T.stringof);
						}
				}
				body {/*...}*/
					enum is_proper_sub = Any!(λ!q{(T) = is (T == U[2], U)}, Selected);
					enum is_trivial_sub = Selected.length == 0;

					static T[2] point (T)(T limit) 
						{return [limit, limit + unity!T];}

					static if (is_proper_sub || is_trivial_sub)
						{/*...}*/
							static if (is_proper_sub)
								alias Subspace = Sub!(
									Map!(Pair!().first!Identity,
										Filter!(Pair!().second!Identity,
											Zip!(Iota!(0, Selected.length),
												Map!(λ!q{(T) = is (T == U[2], U)},
													Selected
												)
											)
										)
									)
								);
							else alias Subspace = Sub!(Iota!(0, limits.length));

							typeof(Subspace.bounds) bounds;

							static if (is_proper_sub)
								alias selection = selected;
							else alias selection = limits;
								
							foreach (i, limit; selection)
								static if (is (typeof(limit) == T[2], T))
									bounds[i] = limit;
								else bounds[i] = [zero!(typeof(limit)), limit];

							return Subspace ((&access).to_delegate, bounds);
						}
					else return indexing.opIndex (selected);
				}
		}
		public {/*opSlice}*/
			alias Parameter (size_t i) = ParameterTypeTuple!access[i];

			Parameter!d[2] opSlice (size_t d)(Parameter!d i, Parameter!d j)
				{/*...}*/
					return [i,j];
				}
		}
	}

void index_ops_tests () // TODO assert bad bounds throws and bad type doesn't compile
	{/*...}*/
		static struct Basic
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length = 100;

				mixin IndexOps!(access, length);
			}
		assert (Basic()[40]);

		static struct NegativeIndex
			{/*...}*/
				auto access (int) {return true;}

				int[2] bounds = [-99, 100];

				mixin IndexOps!(access, bounds);
			}
		assert (NegativeIndex()[-25]);

		static struct FloatingPointIndex
			{/*...}*/
				auto access (float) {return true;}

				float[2] bounds = [-1,1];

				mixin IndexOps!(access, bounds);
			}
		assert (FloatingPointIndex()[0.5]);

		static struct StringIndex
			{/*...}*/
				auto access (string) {return true;}

				string[2] bounds = [`aardvark`, `zebra`];

				mixin IndexOps!(access, bounds);
			}
		assert (StringIndex()[`monkey`]);

		static struct MultipleOperatorSets
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				mixin IndexOps!(access_one, bounds_one) A;
				mixin IndexOps!(access_two, length_two) B;

				mixin(overload_priority!(`opIndex`, B, A));
			}
		assert (MultipleOperatorSets()[5]);
		assert (MultipleOperatorSets()[-1.0]);

		static struct LocalOverload
			{/*...}*/
				auto access (size_t) {return true;}

				size_t length = 100;

				mixin IndexOps!(access, length) 
					mixed_in;

				auto opIndex () {return true;}

				mixin(overload_priority!(`opIndex`, mixed_in));
			}
		assert (LocalOverload()[]);
		assert (LocalOverload()[1]);

		static struct MultiDimensional
			{/*...}*/
				auto access (size_t, size_t) {return true;}

				size_t rows = 3;
				size_t columns = 3;

				mixin IndexOps!(access, rows, columns);
			}
		assert (MultiDimensional()[1,2]);
	}
void main () // TODO assert bad bounds throws and bad type doesn't compile
	{/*...}*/
		index_ops_tests;

		static struct Basic
			{/*...}*/
				auto access (size_t i)
					{/*...}*/
						return true;
					}

				size_t length = 100;

				mixin SliceOps!(access, length);
			}
		assert (Basic()[0]);
		assert (Basic()[][0]);
		assert (Basic()[0..10][0]);

		static struct NegativeIndex
			{/*...}*/
				auto access (int) {return true;}

				int[2] bounds = [-99, 100];

				mixin SliceOps!(access, bounds);
			}
		assert (NegativeIndex()[-99]);
		assert (NegativeIndex()[][0]);
		assert (NegativeIndex()[-40..10][0]);

		static struct FloatingPointIndex
			{/*...}*/
				auto access (float) {return true;}

				float[2] bounds = [-1,1];

				mixin SliceOps!(access, bounds);
			}
		assert (FloatingPointIndex()[-0.5]);
		assert (FloatingPointIndex()[][0.0]);
		assert (FloatingPointIndex()[-0.2..1][0]);

		static struct StringIndex
			{/*...}*/
				auto access (string) {return true;}

				string[2] bounds = [`aardvark`, `zebra`];

				mixin SliceOps!(access, bounds);
			}
		assert (StringIndex()[`monkey`]);
		assert (is (typeof(StringIndex()[`fox`..`rabbit`])));
		assert (not (is (typeof(StringIndex()[`fox`..`rabbit`][`kitten`]))));

		static struct MultipleOperatorSets
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				mixin SliceOps!(access_one, bounds_one) A;
				mixin SliceOps!(access_two, length_two) B;

				mixin(overload_priority!(`opIndex`, B, A));
			}
		assert (MultipleOperatorSets()[5]);
		assert (MultipleOperatorSets()[-1.0]);

		assert (MultipleOperatorSets()[][7]);
		assert (not (is (typeof(MultipleOperatorSets()[][7.0]))));

	static if (0) {/*}*/
		assert (MultipleOperatorSets()[-0.2..1][0.0]); // TODO need template overload and function overload priority
		assert (MultipleOperatorSets()[-0.2..1][0]);
		assert (MultipleOperatorSets()[2..4][0.0]);
		assert (MultipleOperatorSets()[2..4][0]);
	}

		static struct LocalOverload
			{/*...}*/
				auto access (size_t) {return true;}

				size_t length = 100;

				mixin IndexOps!(access, length) 
					mixed_in;

				auto opIndex () {return true;}

				mixin(overload_priority!(`opIndex`, mixed_in));
			}

		static struct MultiDimensional
			{/*...}*/
				auto access (size_t, size_t) {return true;}

				size_t rows = 3;
				size_t columns = 3;

				mixin IndexOps!(access, rows, columns);
			}

		static struct ExtendedSub
			{/*...}*/
				auto access (size_t i)
					{/*...}*/
						return true;
					}

				size_t length = 100;

				template Length ()
					{/*...}*/
						@property length () const
							{/*...}*/
								return bounds[0].right - bounds[0].left;
							}
					}

				mixin SliceOps!(access, length,	Length);
			}
		assert (ExtendedSub()[].length == 100);
		assert (ExtendedSub()[][].length == 100);
		assert (ExtendedSub()[0..10].length == 10);
		assert (ExtendedSub()[10..20].length == 10);

		static struct SubOrigin
			{/*...}*/
				
			}
	}
