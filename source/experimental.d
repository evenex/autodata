import std.stdio;
import std.typetuple;
import std.typecons;
import std.traits;
import std.algorithm: swap;
import std.array: replace;
import std.conv;
import evx.traits;
import evx.math;
import evx.range;
import evx.type;
import evx.misc.tuple;

// Index → Slice → Transfer → Buffer

alias Identity = evx.type.Identity; // TEMP

private static string attempt_overloads (string call, MixinAliases...)()
	{/*...}*/
		string[] attempts;

		foreach (Alias; MixinAliases)
			attempts ~= q{
				static if (is (typeof(} ~ __traits(identifier, Alias) ~ q{.} ~ call ~ q{)))
					return } ~ __traits(identifier, Alias) ~ q{.} ~ call ~ q{;
			};

		attempts ~= q{static assert (0, typeof(this).stringof ~ `: no overloads for `}`"` ~ call ~ `"`q{` found`);};

		return join (attempts, q{else }).to!string;
	}

/* mixin overload priority will route calls to the given symbol 
		to the first given mixin alias which can complete the call
	useful for controlling mixin overload sets
*/
/* mixin a variadic overload function 
*/
static function_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{auto } ~symbol~ q{ (Args...)(Args args)}
			`{` 
				~ attempt_overloads!(symbol ~ q{(args)}, MixinAliases) ~ 
			`}`;
	}
/* mixin a variadic overload template 
*/
static template_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{template } ~symbol~ q{ (Args...)}
			`{` 
				~ attempt_overloads!(symbol ~ q{!Args}, MixinAliases)
					.replace (q{return}, q{alias } ~ symbol ~ q{ = }) ~ 
			`}`;
	}
/* mixin a variadic overload template function
*/
static template_function_overload_priority (string symbol, MixinAliases...)()
	{/*...}*/
		return q{template } ~symbol~ q{ (CTArgs...)}
			`{` 
				q{auto } ~symbol~ q{ (RTArgs...)(RTArgs args)}
					`{` 
						~ attempt_overloads!(symbol ~ q{!CTArgs (args)}, MixinAliases) ~ 
					`}`
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

/* generate $ and ~$ right and left limit operators
*/
template LimitOps (limits...)
	{/*...}*/
		auto opDollar (size_t i)()
			{/*...}*/
				alias T = ElementType!(Select!(is (typeof(limits[i].identity) == U[2], U), typeof(limits[i].identity), typeof(limits[i].identity)[2]));

				static if (is (typeof(limits[i].identity) == T[2]))
					return Limit!T (limits[i]);

				else return Limit!T ([zero!T, limits[i]]);
			}
	}
struct Limit (T)
	{/*...}*/
		union {/*limit}*/
			T[2] limit;
			struct {T left, right;}
		}

		alias right this;

		auto opUnary (string op)()
			{/*...}*/
				static if (op is `~`)
					return left;
				else return mixin(op ~ q{right});
			}
	}

/* WARNING experimental -- 
	will probably only be usable with multiple alias this
	https://github.com/D-Programming-Language/dmd/pull/3998 
	and strict index type segregation
*/
struct MultiLimit (T...)
	{/*...}*/
		Map!(Λ!q{(U) = U[2]}, T)
			limits;

		alias alt = opCast!(T[0]);
		alias alt this;

		U opCast (U)()
			in {/*...}*/
				static assert (Contains!(U,T),
					`cannot cast ` ~ typeof(this).stringof ~ ` to ` ~ U.stringof
				);
			}
			body {/*...}*/
				return limits[IndexOf!(U, T)].right;
			}

		auto opBinary (string op, U)(U that)
			in {/*...}*/
				static assert (
					Any!(Pair!().both!(λ!q{(T,U) = is (U : T)}),
						Zip!(T, Repeat!(T.length, U))
					),
					U.stringof ~ ` does not convert to any ` ~ T.stringof
				);
			}
			body {/*...}*/
				Map!(Pair!().first!Identity,
					Filter!(Pair!().both!(λ!q{(T,U) = is (U : T)}),
						Zip!(T, Repeat!(T.length, U))
					)
				)[0] r = that;

				auto l = limits[IndexOf!(typeof(r), T)].right;

				return mixin(q{l} ~ op ~ q{r});
			}
		auto opUnary (string op)()
			{/*...}*/
				return mixin(op ~ q{limits[0].right});
			}
		auto opUnary (string op : `~`)()
			{/*...}*/
				foreach (ref limit; limits)
					swap (limit.left, limit.right);

				return this;
			}
	}
template MultiLimitOps (size_t dim, limits...)
	{/*...}*/
		auto opDollar (size_t i: dim)()
			{/*...}*/
				alias Limits = Map!(Λ!q{(T...) = typeof(T[0].identity)}, limits);

				MultiLimit!(
					Map!(ElementType,
						Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])},
							Limits
						)
					)
				) multilimit;

				foreach (i, Lim; Limits)
					static if (is (Lim == T[2], T))
						multilimit.limits[i] = limits[i];
					else multilimit.limits[i] = [zero!Lim, limits[i]];

				return multilimit;
			}
	}

/* generate an indexing operator from an access function and a set of index limits
	access must be a function which returns an element of type E

	limits must be aliases to single variables or arrays of two,
	whose types (or element types, if any are arrays), given in order, 
	match the argument types for access
*/
template IndexOps (alias access, limits...)
	{/*...}*/
		auto ref ReturnType!access opIndex (ParameterTypeTuple!access selected)
			in {/*...}*/
				version (all)
					{/*error messages}*/
						enum error_header = typeof(this).stringof ~ `: `;

						enum array_error = error_header ~ `limit types must be singular or arrays of two`
						`: ` ~ typeof(limits).stringof;

						enum type_error = error_header ~ `limit base types must match access parameter types`
						`: ` ~ typeof(limits).stringof
						~ ` != ` ~ ParameterTypeTuple!access.stringof;

						auto bounds_inverted_error (T)(T limit) 
							{return error_header ~ `bounds inverted! ` ~ limit.left.text ~ ` > ` ~ limit.right.text;}

						auto out_of_bounds_error (T, U)(T arg, U limit) 
							{return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in ` ~ limit.text;}
					}

				foreach (i, limit; limits)
					{/*type check}*/
						static assert  (limits.length == ParameterTypeTuple!access.length, type_error);

						static if (is (typeof(limit.identity) == T[n], T, size_t n))
							static assert (n == 2, array_error);

						static if (is (T))
							static assert (is (ParameterTypeTuple!access[i] == T), type_error);

						else static assert (is (ParameterTypeTuple!access[i] == typeof(limit.identity)), type_error);
					}

				foreach (i, limit; limits)
					{/*bounds check}*/
						static if (is (typeof(limit.identity) == T[2], T))
							assert (limit.left <= limit.right, bounds_inverted_error (limit));

						static if (is (T))
							assert (
								limit.left == limit.right? (
									selected[i] == limit.left
								) : (
									selected[i] >= limit.left
									&& selected[i] < limit.right
								),
								out_of_bounds_error (selected[i], limit)
							);
						else assert (
							limit == zero!(typeof(limit.identity))? (
								selected[0] == zero!(typeof(limit.identity))
							) : (
								selected[i] >= zero!(typeof(limit.identity))
								&& selected[i] < limit
							),
							out_of_bounds_error (selected[i], [zero!(typeof(limit.identity)), limit])
						);
					}
			}
			body {/*...}*/
				return access (selected);
			}

		mixin LimitOps!limits;
	}

/* generate slicing and indexing operators from an access function, a set of index limits, 
	and (optionally) a set of uninstantiated, parameterless mixin templates to extend the Sub structure
*/
template SliceOps (alias access, LimitsAndExtensions...)
	{/*...}*/
		alias Source = typeof(this);
		alias limits = Filter!(has_identity, LimitsAndExtensions); // having this out here is fucking you up, turns into an overloadset

		template SubGenerator (Dimensions...)
			{/*...}*/
				public {/*source}*/
					Source* source;
				}
				public {/*bounds}*/
					Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])}, typeof(limits)) 
						bounds;
				}
				public {/*limits}*/
					auto limit (size_t dim)()
						{/*...}*/
							static if (is (TypeTuple!(typeof(this.origin.identity)) == ParameterTypeTuple!access))
								{/*...}*/
									auto boundary = unity!(typeof(bounds[Dimensions[dim]]));

									static if (is (typeof (origin[0])))
										boundary[] *= -origin[(Dimensions[dim])];

									else boundary[] *= -origin;
								}
							else auto boundary = zero!(typeof(bounds[Dimensions[dim]]));

							boundary.right += bounds[Dimensions[dim]].difference;

							return boundary;
						}
					auto limit ()() if (Dimensions.length == 1) {return limit!0;}

					auto opDollar (size_t i)()
						{/*...}*/
							return Limit!(typeof(limit!i[0])) (limit!i);
						}
				}
				public {/*opIndex}*/
					typeof(this) opIndex ()
						{/*...}*/
							return this;
						}
					auto ref opIndex (Selected...)(Selected selected)
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

							foreach (i,_; selected)
								{/*bounds check}*/
									static if (is (typeof (selected[i]) == T[2], T))
										assert (
											limit!i.left <= selected[i].left
											&& selected[i].right <= limit!i.right,
											out_of_bounds_error (selected[i], limit!i)
										);
									else assert (
										limit!i.left <= selected[i]
										&& selected[i] < limit!i.right,
										out_of_bounds_error (selected[i], limit!i)
									);
								}
						}
						body {/*...}*/
							static if (Any!(λ!q{(T) = is (T == U[2], U)}, Selected))
								{/*...}*/
									typeof(bounds) bounds;

									foreach (i,_; bounds)
										{/*...}*/
											bounds[i] = unity!(typeof(bounds[i]));
											bounds[i][] *= this.bounds[i].left;
										}
									
									foreach (i, j; Dimensions)
										static if (is (typeof(selected[i]) == T[2], T))
											bounds[j][] += selected[i][] - limit!i.left;
										else bounds[j][] += selected[i] - limit!i.left;

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

								foreach (i,_; typeof(bounds))
									point[i] = bounds[i].left;

								foreach (i,j; Dimensions)
									point[j] += selected[i] - limit!i.left;

								return source.opIndex (point);
							}
						}
				}
				public {/*opSlice}*/
					alias Parameter (size_t i) = ParameterTypeTuple!access[(Dimensions[i])];

					Parameter!d[2] opSlice (size_t d)(Parameter!d i, Parameter!d j)
						{/*...}*/
							return [i,j];
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
							static if (is (typeof(extension!().identity) == string))
								code ~= q{
									mixin(} ~ __traits(identifier, extension) ~ q{!());
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

			auto ref opIndex (Selected...)(Selected selected)
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

							return Subspace (&this, bounds);
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

/* generate index assignment, slicing and indexing operators from a pull template,
	and the arguments for SliceOps
*/
template TransferOps (alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		template SubTransferOps ()
			{/*...}*/
				auto opIndexAssign (S, Selected...)(S space, Selected selected)
					in {/*...}*/
						this[selected];
					}
					body {/*...}*/
						Map!(Pair!().both!(Λ!q{(T, bool is_slice) = Select!(is_slice, T[2], T)}),
							Zip!(
								Map!(ElementType,
									Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])}, 
										typeof(limits)
									)
								),
								Map!(λ!q{(T) = is (T == U[2], U)},
									Selected
								)
							)
						) selection;

						foreach (i,j; Dimensions)
							{/*...}*/
								selection[i] = selected[i];

								auto offset = bounds[j].left - limit!i.left;

								static if (is (typeof(selection[i]) == T[2], T))
									selection[i][] += offset;
								else selection[i] += offset;
							}

						return source.opIndexAssign (space, selection);
					}
			}

		mixin SliceOps!(access, LimitsAndExtensions, SubTransferOps);

		auto opIndexAssign (S, Selected...)(S space, Selected selected)
			in {/*...}*/
				this[selected];
			}
			body {/*...}*/
				static if (is (typeof (space.push (this[selected]))))
					space.push (this[selected]);

				else pull (space, selected);

				return this[selected];
			}
	}

import std.exception; // TODO versio n(unittest)
void error (T)(lazy T event) {assertThrown!Error (event);}
void not_error (T)(lazy T event) {assertNotThrown!Error (event);}

void index_ops_tests ()
	{/*...}*/
		static struct Basic
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length = 100;

				mixin IndexOps!(access, length);
			}
		assert (Basic()[40]);
		error (Basic()[101]);
		assert (Basic()[$-1]);
		assert (Basic()[~$]);
		error (Basic()[$]);

		static struct RefAccess
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				auto pull ()
					{/*...}*/
						
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				mixin IndexOps!(access, length);
			}
		RefAccess ref_access;

		assert (ref_access[0] == 0);
		ref_access[0] = 1;
		assert (ref_access[0] == 1);

		static struct NegativeIndex
			{/*...}*/
				auto access (int) {return true;}

				int[2] bounds = [-99, 100];

				mixin IndexOps!(access, bounds);
			}
		assert (NegativeIndex()[-25]);
		error (NegativeIndex()[-200]);
		assert (NegativeIndex()[$-25]);
		assert (NegativeIndex()[~$]);
		error (NegativeIndex()[$]);

		static struct FloatingPointIndex
			{/*...}*/
				auto access (float) {return true;}

				float[2] bounds = [-1,1];

				mixin IndexOps!(access, bounds);
			}
		assert (FloatingPointIndex()[0.5]);
		error (FloatingPointIndex()[-2.0]);
		assert (FloatingPointIndex()[$-0.5]);
		assert (FloatingPointIndex()[~$]);
		error (FloatingPointIndex()[$]);

		static struct StringIndex
			{/*...}*/
				auto access (string) {return true;}

				string[2] bounds = [`aardvark`, `zebra`];

				mixin IndexOps!(access, bounds);
			}
		assert (StringIndex()[`monkey`]);
		error (StringIndex()[`zzz`]);
		assert (StringIndex()[$[1..$]]);
		assert (StringIndex()[~$]);
		error (StringIndex()[$]);

		static struct MultiIndex
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				mixin IndexOps!(access_one, bounds_one) A;
				mixin IndexOps!(access_two, length_two) B;

				mixin(function_overload_priority!(
					`opIndex`, B, A)
				);

				alias opDollar = B.opDollar; // TODO until MultiLimit is ready, have to settle for a manual $ selection
			}
		assert (MultiIndex()[5]);
		assert (MultiIndex()[-1.0]);
		assert (MultiIndex()[$-1]);
		error (MultiIndex()[$-1.0]);
		assert (MultiIndex()[~$]);
		error (MultiIndex()[$]);

		static struct LocalOverload
			{/*...}*/
				auto access (size_t) {return true;}

				size_t length = 100;

				mixin IndexOps!(access, length) 
					mixed_in;

				auto opIndex () {return true;}

				mixin(function_overload_priority!(
					`opIndex`, mixed_in)
				);
			}
		assert (LocalOverload()[]);
		assert (LocalOverload()[1]);
		assert (LocalOverload()[$-1]);
		error (LocalOverload()[$]);

		static struct MultiDimensional
			{/*...}*/
				auto access (size_t, size_t) {return true;}

				size_t rows = 3;
				size_t columns = 3;

				mixin IndexOps!(access, rows, columns);
			}
		assert (MultiDimensional()[1,2]);
		assert (MultiDimensional()[$-1, 2]);
		assert (MultiDimensional()[1, $-2]);
		assert (MultiDimensional()[$-1, $-2]);
		assert (MultiDimensional()[~$, ~$]);
		error (MultiDimensional()[$, 2]);
		error (MultiDimensional()[1, $]);
		error (MultiDimensional()[$, $]);
	}
void slice_ops_tests ()
	{/*...}*/
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
		assert (Basic()[][0..10][0]);
		assert (Basic()[~$..$][0]);
		assert (Basic()[~$..$][~$]);
		error (Basic()[~$..2*$][0]);

		static struct RefAccess
			{/*...}*/
				enum size_t length = 256;

				int[length] data;

				auto pull ()
					{/*...}*/
						
					}

				ref access (size_t i)
					{/*...}*/
						return data[i];
					}

				mixin SliceOps!(access, length);
			}
		RefAccess ref_access;
		assert (ref_access[5] == 0);
		ref_access[3..10][2] = 1;
		assert (ref_access[5] == 1);

		static struct NegativeIndex
			{/*...}*/
				auto access (int) {return true;}

				int[2] bounds = [-99, 100];

				mixin SliceOps!(access, bounds);
			}
		assert (NegativeIndex()[-99]);
		assert (NegativeIndex()[-40..10][0]);
		assert (NegativeIndex()[][0]);
		assert (NegativeIndex()[][0..199][0]);
		assert (NegativeIndex()[~$..$][~$]);
		error (NegativeIndex()[~2*$..$][0]);

		static struct FloatingPointIndex
			{/*...}*/
				auto access (float) {return true;}

				float[2] bounds = [-1,1];

				mixin SliceOps!(access, bounds);
			}
		assert (FloatingPointIndex()[-0.5]);
		assert (FloatingPointIndex()[-0.2..1][0]);
		assert (FloatingPointIndex()[][0.0]);
		assert (FloatingPointIndex()[][0.0..0.8][0]);
		assert (FloatingPointIndex()[~$..$][~$]);
		error (FloatingPointIndex()[2*~$..2*$][~$]);

		static struct StringIndex
			{/*...}*/
				auto access (string) {return true;}

				string[2] bounds = [`aardvark`, `zebra`];

				mixin SliceOps!(access, bounds);
			}
		assert (StringIndex()[`monkey`]);
		assert (is (typeof(StringIndex()[`fox`..`rabbit`])));
		assert (not (is (typeof(StringIndex()[`fox`..`rabbit`][`kitten`]))));
		assert (is (typeof (StringIndex()[~$..$])));
		assert (not (is (typeof (StringIndex()[~$..$][~$]))));

		static struct MultiIndex // TODO: proper multi-index support once multiple alias this allowed
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				mixin SliceOps!(access_one, bounds_one) A;
				mixin SliceOps!(access_two, length_two) B;
				mixin MultiLimitOps!(0, length_two, bounds_one) C; 
				// TODO doc order determines which one is implicitly convertible to

				mixin(function_overload_priority!(
					`opIndex`, B, A
				));
				mixin(template_function_overload_priority!(
					`opSlice`, B, A
				));

				alias opDollar = C.opDollar;
			}
		assert (MultiIndex()[5]);
		assert (MultiIndex()[-1.0]);

		assert (MultiIndex()[][7]);
		assert (not (is (typeof(MultiIndex()[][-5.0]))));

		assert (MultiIndex()[-0.2..1][0.0]);
		assert (MultiIndex()[-0.2..1][0]);
		assert (not (is (typeof (MultiIndex()[2..4][0.0]))));
		assert (MultiIndex()[2..4][0]);

		assert (MultiIndex()[~$]);
		assert (MultiIndex()[~$ + 7]);
		error (MultiIndex()[~$ + 8]);
		assert (MultiIndex()[~$ + 9.999]);
		error (MultiIndex()[~$ + 10.0]);
		assert (MultiIndex()[float(~$)]);
		assert (is (typeof (MultiIndex()[cast(size_t)(~$)..cast(size_t)($)])));
		assert (is (typeof (MultiIndex()[cast(float)(~$)..cast(float)($)])));
		assert (not (is (typeof (MultiIndex()[cast(int)(~$)..cast(int)($)]))));

		static struct MultiDimensional
			{/*...}*/
				auto access (size_t, size_t) {return true;}

				size_t rows = 3;
				size_t columns = 3;

				mixin SliceOps!(access, rows, columns);
			}
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
		assert (ExtendedSub()[~$/2..$/2].length == 50);
		assert (ExtendedSub()[][0..10].length == 10);
		assert (ExtendedSub()[][10..20].length == 10);
		assert (ExtendedSub()[][~$/2..$/2].length == 50);

		static struct SubOrigin
			{/*...}*/
				auto access (double i)
					{/*...}*/
						return true;
					}

				double measure = 10;

				template Origin ()
					{/*...}*/
						@property origin () const
							{/*...}*/
								return bounds.difference/2;
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

		static struct MultiIndexSub // TODO: proper multi-index support once multiple alias this allowed
			{/*...}*/
				auto access_one (float) {return true;}
				auto access_two (size_t) {return true;}

				float[2] bounds_one = [-5, 5];
				size_t length_two = 8;

				enum LimitRouting () = 
					q{float[2] float_limits (){return [limit!0.left * 5/4. - 5, limit!0.right * 5/4. - 5];}}
					q{size_t[2] size_t_limits (){return limit!0;}}
					q{mixin MultiLimitOps!(0, size_t_limits, float_limits) C;}
					q{alias opDollar = C.opDollar;}
				;

				template IndexMap () {auto opIndex (float) {return true;}}
				enum IndexRouting () = 
					q{mixin IndexMap mapping;}
					q{mixin(function_overload_priority!(`opIndex`, sub, mapping));}
				;

				mixin SliceOps!(access_one, bounds_one) A;
				mixin SliceOps!(access_two, length_two, IndexRouting, LimitRouting) B;
				mixin MultiLimitOps!(0, length_two, bounds_one) C; 

				mixin(function_overload_priority!(
					`opIndex`, B, A)
				);
				mixin(template_function_overload_priority!(
					`opSlice`, B, A)
				);
				alias opDollar = C.opDollar;
			}
		assert (MultiIndexSub()[][7]);
		assert (MultiIndexSub()[][-5.0]);
		assert (MultiIndexSub()[2..4][0.0]);
		assert (MultiIndexSub()[~$..$][0.0]);
		assert (MultiIndexSub()[2..4].bounds[0] == [2, 4]);
		assert (MultiIndexSub()[~$..4].bounds[0] == [0, 4]);
		assert (MultiIndexSub()[~$..1.0].bounds[0] == [0, 1]);
		assert (MultiIndexSub()[cast(float)~$..1.0].bounds[0] == [-5, 1]);
		assert (MultiIndexSub()[cast(float)~$..$].bounds[0] == [-5, 0]);
		assert (MultiIndexSub()[cast(float)~$..cast(float)$].bounds[0] == [-5, -5]);
		//assert (MultiIndexSub()[cast(size_t)(~$)..cast(size_t)$][cast(size_t)(~$)]);
		// TODO oh man
	}
void transfer_ops_tests ()
	{/*...}*/
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

				mixin TransferOps!(pull, access, length);
			}

		Basic x;

		assert (x[0] == 0);
		x[0] = 1;
		assert (x[0] == 1);

		error (x[0..10] = only (1,2,3));
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
						void push (R)(auto ref R range)
							{/*...}*/
								auto ptr = range.ptr;

								foreach (i; 0..range.length)
									ptr[i] = 2;
							}
					}

				mixin TransferOps!(pull, access, length, PushExtension);
			}
		int[5] y = [1,1,1,1,1];
		Push()[].push (y);
		assert (y[] == [2,2,2,2,2]);

		assert (x[0] == 10);
		assert (x[9] == 1);
		x[0..10] = Push()[0..10];
		assert (x[0] == 0);
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
						auto length ()
							{/*...}*/
								return limit!0.difference;
							}
					}

				mixin TransferOps!(pull, access, length, Pointer, Length);
			}
		Pull z;
		assert (z[0] == 0);
		assert (z[9] == 0);
		z[0..10] = Push()[0..10];
		assert (z[0] == 2);
		assert (z[9] == 2);

		auto w = z[];
		assert (w[0] == 2);
		assert (w[1] == 2);
		assert (w[2] == 2);
		w[0..3] = only (1,2,3);
		assert (w[0] == 1);
		assert (w[1] == 2);
		assert (w[2] == 3);
		not_error (w[0..3] = only (1,2,3,4)); // verifying the input is up to client implementation because too many contextual unknowns (limit? length? dimensions?)

		// TODO write to some offsets, verify that this shit is going where its supposed to
	}
void main ()
	{/*...}*/
		index_ops_tests;
		slice_ops_tests;
		transfer_ops_tests;
	}
