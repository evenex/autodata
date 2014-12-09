import std.stdio;
import std.typetuple;
import std.typecons;
import std.traits;
import std.algorithm: swap;
import std.array: replace;
import std.conv;

import evx.traits.classification;
import evx.math.logic;
import evx.math.algebra;
import evx.math.intervals;

import evx.range; // REVIEW
import evx.type.processing; // TODO functional

// Index → Slice → Write → Buffer

///////////////////

alias Identity = evx.type.Identity; // TEMP
static alias FinalType (alias symbol) = typeof(symbol.identity);

///////////////////

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

///////////////////

template StandardErrorMessages ()
	{/*...}*/
		alias Element (T) = ElementType!(Select!(is (T == U[2], U), T, T[2]));

		enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

		enum type_mismatch_error = error_header
			~ Map!(Element, Selected).stringof ~ ` does not convert to ` ~ Map!(Element, Map!(FinalType, limits)).stringof;

		auto out_of_bounds_error (T, U)(T arg, U limit) 
			{return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in ` ~ limit.text;}
	}

///////////////////

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
					Any!(Pair!().Both!(λ!q{(T,U) = is (U : T)}),
						Zip!(T, Repeat!(T.length, U))
					),
					U.stringof ~ ` does not convert to any ` ~ T.stringof
				);
			}
			body {/*...}*/
				Map!(Pair!().First!Identity,
					Filter!(Pair!().Both!(λ!q{(T,U) = is (U : T)}),
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
						static assert  (limits.length == ParameterTypeTuple!access.length,
							type_error
						);

						static if (is (typeof(limit.identity) == T[n], T, size_t n))
							static assert (n == 2, 
								array_error
							);

						static if (is (T))
							static assert (is (ParameterTypeTuple!access[i] == T),
								type_error
							);

						else static assert (is (ParameterTypeTuple!access[i] == typeof(limit.identity)), 
							type_error
						);
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

/* generate slicing operators with IndexOps
	(optionally) using a set of uninstantiated, parameterless templates to extend the Sub structure
	templates which resolve to a string upon instantiation will be mixed in as strings
	otherwise they are mixed in as mixin templates
*/
template SliceOps (alias access, LimitsAndExtensions...)
	{/*...}*/
		public:
		public {/*opIndex}*/
			mixin IndexOps!(access, limits) indexing;

			auto ref opIndex (Selected...)(Selected selected)
				in {/*...}*/
					mixin StandardErrorMessages;

					static if (Selected.length > 0)
						{/*type check}*/
							static assert (Selected.length == limits.length, 
								type_mismatch_error
							);

							static assert (
								All!(Pair!().Both!is_implicitly_convertible,
									Zip!(
										Map!(Element, Selected),
										Map!(Element, Map!(FinalType, limits)),
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
									~ ` (in)`
								);
							else static if (is (typeof(limit.identity) : ElementType!(typeof(boundary))))
								assert (
									boundary.left <= limit
									&& limit < boundary.right,
									out_of_bounds_error (limit, boundary)
									~ ` (in)`
								);
							else static assert (0, T.stringof);
						}
				}
				out (result) {/*...}*/
					mixin StandardErrorMessages;

					static if (is (typeof(result) == Sub!T, T...))
						{/*...}*/
							foreach (i, limit; selected)
								static if (is (typeof(limit) == U[2], U))
									assert (limit == result.bounds[i],
										out_of_bounds_error (limit, result.bounds[i])
										~ ` (out)`
									);
								else assert (
									limit == result.bounds[i].left
									&& limit == result.bounds[i].right,
									out_of_bounds_error (limit, result.bounds[i])
									~ ` (out)`
								);
						}
				}
				body {/*...}*/
					enum is_proper_sub = Any!(λ!q{(T) = is (T == U[2], U)}, Selected);
					enum is_trivial_sub = Selected.length == 0;

					static if (is_proper_sub || is_trivial_sub)
						{/*...}*/
							static if (is_proper_sub)
								alias Subspace = Sub!(
									Map!(Pair!().First!Identity,
										Filter!(Pair!().Second!Identity,
											Zip!(Count!Selected,
												Map!(λ!q{(T) = is (T == U[2], U)},
													Selected
												)
											)
										)
									)
								);
							else alias Subspace = Sub!(Count!limits);

							typeof(Subspace.bounds) bounds;

							static if (is_proper_sub)
								alias selection = selected;
							else alias selection = limits;
								
							foreach (i, limit; selection)
								static if (is (typeof(limit.identity) == T[2], T))
									bounds[i] = limit;
								else static if (is_proper_sub)
									bounds[i][] = limit;
								else bounds[i] = [zero!(typeof(limit.identity)), limit];

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
		public {/*Sub}*/
			template SubGenerator (Dimensions...)
				{/*...}*/
					public {/*source}*/
						Source* source;
					}
					public {/*bounds}*/
						Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])}, Map!(FinalType, limits))
							bounds;
					}
					public {/*limits}*/
						auto limit (size_t dim)() const
							{/*...}*/
								static if (is (TypeTuple!(typeof(this.origin.identity)) == ParameterTypeTuple!access))
									{/*...}*/
										auto boundary = unity!(typeof(bounds[Dimensions[dim]]));

										static if (is (typeof(origin[0])))
											boundary[] *= -origin[(Dimensions[dim])];

										else boundary[] *= -origin;
									}
								else auto boundary = zero!(typeof(bounds[Dimensions[dim]]));

								boundary.right += bounds[Dimensions[dim]].difference;

								return boundary;
							}
						auto limit ()() const if (Dimensions.length == 1) {return limit!0;}

						auto opDollar (size_t i)() const
							{/*...}*/
								return Limit!(typeof(limit!i.left))(limit!i);
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
										static if (Selected.length > 0)
											static assert (Selected.length == Dimensions.length,
												type_mismatch_error
											);

										mixin LambdaCapture;

										static assert (
											All!(Pair!().Both!is_implicitly_convertible,
												Zip!(
													Map!(Element, Selected),
													Map!(Element, 
														Map!(Λ!q{(size_t i) = typeof(limits[i].identity)}, Dimensions)
													),
												)
											), type_mismatch_error
										);
									}

								foreach (i,_; selected)
									{/*bounds check}*/
										static if (is (typeof(selected[i]) == T[2], T))
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
											Map!(Pair!().First!Identity,
												Filter!(Pair!().Second!Identity,
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

							foreach (i, extension; Filter!(Not!has_identity, LimitsAndExtensions))
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
	}
		private:
		private {/*aliases}*/
			alias Source = typeof(this);
			alias limits = Filter!(has_identity, LimitsAndExtensions);
		}
	}

/* generate index assignment from a pull template, with SliceOps 
*/
template WriteOps (alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
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
				static if (is (typeof(space.push (this[selected]))))
					{/*...}*/
						space.push (this[selected]);
					}
				else static if (Selected.length > 0)
					{/*...}*/
						static if (is (typeof(&access (selected))))
							access (selected) = space;
						else pull (space, selected);
					}
				else pull (space, this[].bounds);

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
							alias Selection (size_t i) = Select!(Contains!(i, Dimensions),
								Select!(
									is (Selected[IndexOf!(i, Dimensions)] == T[2], T),
									typeof(bounds[i]),
									typeof(bounds[i].left)
								),
								typeof(bounds[i].left)
							);
						else alias Selection (size_t i) = Select!(Contains!(i, Dimensions),
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
			}

		mixin SliceOps!(access, LimitsAndExtensions, SubWriteOps);
	}

/* generate WriteOps with input bounds checking
*/
template TransferOps (alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		auto verified_limit_pull (S, Selected...)(S space, Selected selected)
			in {/*...}*/
				version (all)
					{/*error messages}*/
						enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

						enum type_mismatch_error (size_t i) = error_header
							~ `cannot transfer ` ~ i.text ~ `-d ` ~ S.stringof ~ ` to `
							~ Filter!(λ!q{(T) = is (T == U[2], U)}, Selected).text
							~ ` subspace`;
					}

				static if (not (Any!(λ!q{(T) = is (T == U[2], U)}, Selected)))
					{}
				else static if (is (typeof(space.limit!0)))
					{/*...}*/
						foreach (i; Iota!(0, 999))
							static if (is (typeof(space.limit!i)) || is (typeof(this[selected].limit!i)))
								static assert (is (typeof(space.limit!i.left == this[selected].limit!i.left)),
									type_mismatch_error
								);
							else break;
					}
				else static if (is (typeof(space.length)) && not (is (typeof(this[selected].limit!1))))
					{/*...}*/
						assert (space.length == this[selected].limit!0.difference,
							error_header
							~ `assignment size mismatch `
							~ S.stringof ~ `.length != ` ~ typeof(this[selected]).stringof ~ `.limit `
							`(` ~ space.length.text ~ ` != ` ~ this[selected].limit!0.difference.text ~ `)`
						);
					}
				else static assert (0, type_mismatch_error);
			}
			body {/*...}*/
				return pull (space, selected);
			}

		mixin WriteOps!(verified_limit_pull, access, LimitsAndExtensions);
	}

/* generate RAII ctor/dtor and assignment operators from an allocate function, with TransferOps 
*/
template BufferOps (alias allocate, alias pull, alias access, LimitsAndExtensions...)
	{/*...}*/
		this (S)(S space)
			{/*...}*/
				this = space;
			}
		~this ()
			{/*...}*/
				this = null;
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

				static if (is (typeof(space.limit!0)))
					foreach (i; Count!(ParameterTypeTuple!access))
						size[i] = space.limit!i.difference;

				else size[0] = space.length;

				allocate (size);

				this[] = space;

				return this;
			}
		ref opAssign (typeof(null))
			out {/*...}*/
				foreach (i, T; ParameterTypeTuple!access)
					assert (this[].limit!i.difference == zero!T);
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

/* generate an `in` operator from a search function
*/
template SearchOps (alias search)
	{/*...}*/
		auto opBinaryRight (string op: `in`)(ParameterTypeTuple!search query)
			in {/*...}*/
				void dereference (T)(T q){auto p = *q;}
				void address (T)(ref T q){auto p = &q;}

				enum error_header = fullyQualifiedName!(typeof(this)).stringof ~ `: `;

				static assert (query.length == 1,
					error_header
					~ `search function can have only one argument`
				);

				static assert (
					is (typeof(dereference!(ReturnType!search))) 
					|| is (typeof(address!(ReturnType!search))),
					error_header
					~ `search return value must be pointer or reference`
				);
			}
			body {/*...}*/
				return search (query);
			}
	}

/* generate random access range primitives
	note that the resulting range only qualifies as bidirectional
	because std.range.isRandomAccessRange does not handle template or non-property range primitives
	though the range does meet the definition of random access
*/
template RangeOps ()
	{/*...}*/
		static if (Dimensions.length == 1)
			@property {/*...}*/
				auto ref front () {return this[~$];}
				auto ref back () {return this[$-1];}
				auto popFront () {++bounds[Dimensions[0]].left;}
				auto popBack () {--bounds[Dimensions[0]].right;}
				auto empty () {return length == 0;}
				auto length () {return bounds[Dimensions[0]].difference;}
				alias save = this;
			}
	}

///////////////////

import std.exception; // TODO versio n(unittest)
void error (T)(lazy T event) {assertThrown!Error (event);}
void no_error (T)(lazy T event) {assertNotThrown!Error (event);}

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

		static struct LengthFunction
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length () {return 100;}

				mixin IndexOps!(access, length);
			}
		assert (LengthFunction()[40]);
		error (LengthFunction()[101]);
		assert (LengthFunction()[$-1]);
		assert (LengthFunction()[~$]);
		error (LengthFunction()[$]);

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

		static struct LengthFunction
			{/*...}*/
				auto access (size_t) {return true;}
				size_t length () {return 100;}

				mixin SliceOps!(access, length);
			}
		assert (LengthFunction()[0]);
		assert (LengthFunction()[][0]);
		assert (LengthFunction()[0..10][0]);
		assert (LengthFunction()[][0..10][0]);
		assert (LengthFunction()[~$..$][0]);
		assert (LengthFunction()[~$..$][~$]);
		error (LengthFunction()[~$..2*$][0]);

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
		assert (is (typeof(StringIndex()[~$..$])));
		assert (not (is (typeof(StringIndex()[~$..$][~$]))));

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
		assert (not (is (typeof(MultiIndex()[2..4][0.0]))));
		assert (MultiIndex()[2..4][0]);

		assert (MultiIndex()[~$]);
		assert (MultiIndex()[~$ + 7]);
		error (MultiIndex()[~$ + 8]);
		assert (MultiIndex()[~$ + 9.999]);
		error (MultiIndex()[~$ + 10.0]);
		assert (MultiIndex()[float(~$)]);
		assert (is (typeof(MultiIndex()[cast(size_t)(~$)..cast(size_t)($)])));
		assert (is (typeof(MultiIndex()[cast(float)(~$)..cast(float)($)])));
		assert (not (is (typeof(MultiIndex()[cast(int)(~$)..cast(int)($)]))));

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
void write_ops_tests ()
	{/*...}*/
		import evx.math;

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
						void push (R)(auto ref R range)
							{/*...}*/
								auto ptr = range.ptr;

								foreach (i; 0..range.length)
									ptr[i] = 2;
							}
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
						auto length ()
							{/*...}*/
								return limit!0.difference;
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
void transfer_ops_tests ()
	{/*...}*/
		import evx.math;

		template Basic ()
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

				auto pull (string[], size_t[2]){}
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

				auto pull (R)(R r, int[2] x)
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

				alias Slice = size_t[2];

				void pull (R)(R r, size_t[2] y, size_t x)
					{/*...}*/
						foreach (i; y.left..y.right)
							access (i,x) = r[i - y.left];
					}
				void pull (R)(R r, size_t y, size_t[2] x)
					{/*...}*/
						foreach (j; x.left..x.right)
							access (y,j) = r[j - x.left];
					}
				void pull (R)(R r, size_t[2] y, size_t[2] x)
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
		assert (not (is (typeof( (z[0..2, 0..3] = y[0..3, 1])))));
		assert (not (is (typeof( (z[1, 0..3] = y[0..3, 0..2])))));

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
				auto pull (R)(R range, double[2] domain)
					{/*...}*/
						if (domain.left == 0.0 && domain.right == 1.0)
							maps = null;

						maps ~= (t) => domain.left <= t && t < domain.right? 
							range[t - domain.left] : t;
					}

				mixin TransferOps!(pull, access, length);
			}
		static struct Domain
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

		Domain b;
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
void buffer_ops_tests ()
	{/*...}*/
		import evx.math;

		static struct Basic
			{/*...}*/
				int[] data;
				auto length () {return data.length;}

				void allocate (size_t length)
					{/*...}*/
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

		Basic x = N;
		auto y = Basic (N);

		assert (x == y);

		assert (x.length == 25);
		assert (x[0] == 500);
		assert (x[1] == 501);
		assert (x[$-1] == 524);

		assert (y.length == 25);
		assert (y[0] == 500);
		assert (y[1] == 501);
		assert (y[$-1] == 524);

		y = x[10..12];
		assert (y.length == 2);
		assert (y[0] == 510);
		assert (y[$-1] == 511);

		y = null;
		assert (y.length == 0);
		assert (y[].limit!0 == [0,0]);
	}
void search_ops_tests ()
	{/*...}*/
		import std.algorithm: find;

		static struct ByPtr
			{/*...}*/
				int[] data = [1,2,4,6,9];

				auto search (int x)
					{/*...}*/
						auto result = data.find (x);

						if (result.empty)
							return null;
						else return result.ptr;
					}

				mixin SearchOps!search;
			}
		static struct ByRef
			{/*...}*/
				string[] data = [`one`, `two`, `four`, `seven`];

				const string not_found;

				ref search (string i)
					{/*...}*/
						if (data.find (i).empty)
							return not_found;
						else return data.find (i).front;
					}

				mixin SearchOps!search;
			}

		if (auto x = 4 in ByPtr())
			assert (*x == 4);

		if (auto x = 3 in ByPtr())
			assert (0);

		if (auto x = `four` in ByRef())
			assert (x == `four`);

		if (auto x = `five` in ByRef())
			assert (0);

		assert ((3 in ByPtr()) == null);
		assert ((`three` in ByRef()) == null);
	}
void range_ops_tests ()
	{/*...}*/
		static struct Basic
			{/*...}*/
				int[] data = [1,2,3,4];

				auto access (size_t i) {return data[i];}
				auto length () {return data.length;}

				mixin SliceOps!(access, length, RangeOps);
			}
		assert (Basic()[].length == 4);
		assert (Basic()[0..$/2].length == 2);
		foreach (_; Basic()[]){}
		foreach_reverse (_; Basic()[]){}

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

				mixin SliceOps!(access, rows, columns, RangeOps);
			}
		assert (MultiDimensional()[0..$, 0].length == 3);
		assert (MultiDimensional()[0, 0..$].length == 3);
		foreach (_; MultiDimensional()[0..$, 0]){}
		foreach (_; MultiDimensional()[0, 0..$]){}
		foreach_reverse (_; MultiDimensional()[0..$, 0]){}
		foreach_reverse (_; MultiDimensional()[0, 0..$]){}
	}

///////////////////
	
void all_ops_tests ()
	{/*...}*/
		index_ops_tests;
		slice_ops_tests;
		write_ops_tests;
		transfer_ops_tests;
		buffer_ops_tests;
		search_ops_tests;
		range_ops_tests;
	}

///////////////////

struct Mapped (Domain, alias f, Parameters...)
	{/*...}*/
		Domain domain;
		Parameters parameters;

		auto opIndex (Args...)(Args args)
			{/*...}*/
				auto slice_all ()() if (Args.length == 0) {return domain;}
				auto get_point ()() {return domain[args];}
				auto get_space ()() {return domain.opIndex (args);}
				auto get_range ()() if (Args.length == 1) {return domain[args[0].left..args[0].right];}

				auto subdomain = Filter!(has_identity,
					slice_all, get_point, get_space, get_range
				)[0];

				auto map_point ()() {return apply (subdomain);}
				auto map_tuple ()() {return apply (subdomain.expand);}
				auto map_space ()() {return remap (subdomain);}

				return Filter!(has_identity,
					map_point, map_tuple, map_space
				)[0];
			}
		auto opSlice (size_t d, Args...)(Args args)
			{/*...}*/
				auto multi ()() {return domain.opSlice!d (args);}
				auto single ()() if (d == 0) {return domain.opSlice (args);}
				CommonType!Args[2] index ()() {return [args];}

				return Filter!(has_identity,
					multi, single, index
				)[0];
			}
		auto opDollar (size_t d)()
			{/*...}*/
				auto multi ()() {return domain.opDollar!d;}
				auto single ()() if (d == 0) {return domain.opDollar;}
				auto length ()() if (d == 0) {return domain.length;}

				return Filter!(has_identity,
					multi, single, length
				)[0];
			}
		auto opEquals (S)(S that)
			{/*...}*/
				return this.equal (that);
			}

		@property:

		auto front ()()
			{/*...}*/
				auto single_front ()() {return f (domain.front, parameters);}
				auto tuple_front  ()() {return f (domain.front.expand, parameters);}

				return Filter!(has_identity,
					single_front, tuple_front
				)[0];
			}
		auto back ()()
			{/*...}*/
				auto single_back ()() {return f (domain.back);}
				auto tuple_back  ()() {return f (domain.back.expand);}

				return Filter!(has_identity,
					single_back, tuple_back
				)[0];
			}
		auto popFront ()()
			{/*...}*/
				domain.popFront;
			}
		auto popBack ()()
			{/*...}*/
				domain.popBack;
			}
		auto empty ()()
			{/*...}*/
				return domain.empty;
			}
		auto save ()()
			{/*...}*/
				return this;
			}
		auto length ()() const
			{/*...}*/
				return domain.length;
			}
		auto limit (size_t d)() const
			{/*...}*/
				return domain.limit!d;
			}

		private {/*...}*/
			auto apply (Point...)(Point point)
				{/*...}*/
					return f (point, parameters);
				}
			auto remap (Subdomain...)(Subdomain subdomain)
				{/*...}*/
					return Mapped!(Subdomain, f, Parameters)(subdomain, parameters);
				}
			void _context_pointer ()
				{/*...}*/
					template Dimensions (size_t i = 0)
						{/*...}*/
							static if (is (typeof(Domain.limit!i)))
								alias Dimensions = Cons!(i, Dimensions!(i+1));
							else alias Dimensions = Cons!();
						}

					alias Coord (size_t i) = ElementType!(typeof(Domain.limit!i.identity));

					static if (is (typeof(domain.limit!0)))
						auto subdomain = domain[Map!(Coord, Dimensions!()).init];
					else static if (is (typeof(domain.front)))
						auto subdomain = domain.front;
					else static assert (0, `map error: `
						~ Domain.stringof ~ ` is not a range (no front) or a space (no limit!i)`
					);

					static if (is (typeof (f (subdomain))))
						cast(void) f (subdomain);
					else static if (is (typeof (f (subdomain.expand))))
						cast(void) f (subdomain.expand);

					assert (0, `this function exists only to force the compiler`
						` to capture the context of local functions`
						` or functions using local symbols,`
						` and is not meant to be invoked`
					);
				}
		}
	}

auto map (alias f, Domain, Parameters...)(Domain domain, Parameters parameters)
	{/*...}*/
		return Mapped!(Domain, f, Parameters)(domain, parameters);
	}

void map_test () // TODO multidim slices
	{/*...}*/
		int[8] x = [1,2,3,4,5,6,7,8];

		{/*ranges}*/
			auto y = x[].map!(i => 2*i);

			assert (x[0] == 1);
			assert (y[0] == 2);

			assert (x[$-1] == 8);
			assert (y[$-1] == 16);

			assert (x[0..4] == [1, 2, 3, 4]);
			assert (y[0..4] == [2, 4, 6, 8]);

			assert (x[] == [1, 2, 3, 4, 5, 6, 7, 8]);
			assert (y[] == [2, 4, 6, 8, 10, 12, 14, 16]);

			assert (x.length == 8);
			assert (y.length == 8);
		}
		{/*spaces}*/
			static struct Basic
				{/*...}*/
					int[] data = [1,2,3,4];

					auto access (size_t i) {return data[i];}
					auto length () {return data.length;}

					mixin SliceOps!(access, length, RangeOps);
				}
			auto z = Basic()[].map!(i => 2*i);

			assert (z[] == [2,4,6,8]);

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

					mixin SliceOps!(access, rows, columns, RangeOps);
				}
			auto m = MultiDimensional()[];
			auto w = MultiDimensional()[].map!(i => 2*i);

			assert (m[0,0] == 1);
			assert (w[0,0] == 2);
			assert (m[2,2] == 9);
			assert (w[2,2] == 18);

			assert (w[0..$, 0] == [2, 8, 14]);
			assert (w[0, 0..$] == [2, 4, 6]);

			static struct FloatingPoint
				{/*...}*/
					auto access (double x)
						{/*...}*/
							return x;
						}

					enum double length = 1;

					mixin SliceOps!(access, length);
				}
			auto sq = FloatingPoint()[].map!(x => x*x);
			assert (sq[0.5] == 0.25);
		}
		{/*local}*/
			static static_variable = 7;
			assert (x[].map!(i => i + static_variable)[0..4] == [8,9,10,11]);

			static static_function (int x) {return x + 2;}
			assert (x[].map!static_function[0..4] == [3,4,5,6]);

			static static_template (T)(T x) {return 3*x;}
			assert (x[].map!static_template[0..4] == [3,6,9,12]);

			auto local_variable = 9;
			assert (x[].map!(i => i + local_variable)[0..4] == [10,11,12,13]);

			auto local_function (int x) {return x + 1;}
			assert (x[].map!local_function[0..4] == [2,3,4,5]);

			auto local_function_local_variable (int x) {return x * local_variable;}
			assert (x[].map!local_function_local_variable[0..4] == [9,18,27,36]);

			auto local_template (T)(T x) {return 3*x;}
			// assert (x[].map!local_template[0..4] == [3,6,9,12]); BUG cannot capture context pointer for local template
		}
		{/*ctfe}*/
			static ctfe_func (int x) {return x + 2;}

			enum a = [1,2,3].map!(i => i + 100);
			enum b = [1,2,3].map!ctfe_func;

			static assert (a == [101, 102, 103]);
			static assert (b == [3, 4, 5]);
			static assert (typeof(a).sizeof == (int[]).sizeof + (void*).sizeof); // template lambda makes room for the context pointer but doesn't save it... weird.
			static assert (typeof(b).sizeof == (int[]).sizeof); // static function omits context pointer
		}
		{/*params}*/
			static r () @nogc {return only (1,2,3).map!((a,b,c) => a + b + c)(3, 2);}

			assert (r == [6,7,8]);
		}
	}

///////////////////

struct Zipped (Spaces...)
	{/*...}*/
		Spaces spaces;

		auto opIndex (Args...)(Args args)
			{/*...}*/
				auto point (size_t i)() {return spaces[i].map!identity[args];}

				Map!(ReturnType, 
					Map!(point, Count!Spaces)
				) zipped;

				foreach (i,_; zipped)
					zipped[i] = point!i;

				static if (not (Any!(λ!q{(T) = is (T == U[2], U)}, Args)))
					return tuple (zipped);
				else return Zipped!(typeof(zipped))(zipped);
			}
		auto opSlice (size_t d, Args...)(Args args)
			{/*...}*/
				auto attempt ()
					{/*...}*/
						foreach (i; Count!Spaces)
							{/*...}*/
								auto multi ()() {return domain.opSlice!d (args);}
								auto single ()() if (d == 0) {return domain.opSlice (args);}

								alias Attempt = Filter!(has_identity,
									multi, single
								);

								static if (Attempt.length)
									return Attempt[0];
								else continue;
							}
						assert (0);
					}
				CommonType!Args[2] array ()() {return [args];}

				static if (is (typeof (attempt.identity)))
					return attempt;
				else return array;
			}
		auto opDollar (size_t d)()
			{/*...}*/
				foreach (i; Count!Spaces)
					{/*...}*/
						auto multi  ()() {return spaces[i].opDollar!d;}
						auto single ()() if (d == 0) {return spaces[i].opDollar;}
						auto length ()() if (d == 0) {return spaces[i].length;}

						alias Attempt = Filter!(has_identity,
							multi, single, length
						);

						static if (Attempt.length)
							return Attempt[0];
						else continue;
					}
				assert (0);
			}
		auto opEquals (S)(S that)
			{/*...}*/
				return this.equal (that);
			}

		@property:

		auto front ()()
			{/*...}*/
				auto get (size_t i)() {return spaces[i].front;}

				Map!(ReturnType,
					Map!(get, Count!Spaces)
				) front;

				foreach (i; Count!Spaces)
					front[i] = get!i;

				return front.tuple;
			}
		auto back ()()
			{/*...}*/
				auto get (size_t i)() {return spaces[i].back;}

				Map!(ReturnType,
					Map!(get, Count!Spaces)
				) back;

				foreach (i; Count!Spaces)
					back[i] = get!i;

				return back.tuple;
			}
		auto popFront ()()
			{/*...}*/
				foreach (ref space; spaces)
					space.popFront;
			}
		auto popBack ()()
			{/*...}*/
				foreach (ref space; spaces)
					space.popBack;
			}
		auto empty ()()
			{/*...}*/
				return spaces[0].empty;
			}
		auto save ()()
			{/*...}*/
				return this;
			}
		auto length ()()
			{/*...}*/
				return spaces[0].length;
			}
		auto limit (size_t i)()
			{/*...}*/
				return spaces[0].limit!i;
			}

		invariant ()
			{/*...}*/
				mixin LambdaCapture;

				template dimensionality (size_t i)
					{/*...}*/
						template count (size_t d = 0)
							{/*...}*/
								static if (is (typeof(spaces[i].limit!d)))
									enum count = 1 + count!(d+1);

								else static if (d == 0 && is (typeof(spaces[i].length)))
									enum count = 1;

								else enum count = 0;
							}

						enum dimensionality = count!();
					}

				alias Dimensionalities =  Map!(dimensionality, Count!Spaces);

				static assert (All!(λ!q{(size_t d) = d == Dimensionalities[0]}, Dimensionalities),
					`zip error: dimension mismatch! ` 
					~ Interleave!(Spaces, Dimensionalities)
						.stringof[`tuple(`.length..$-1]
						.replace (`),`, `):`)
				);

				foreach (d; Iota!(0, Dimensionalities[0]))
					foreach (i; Count!Spaces)
						{/*bounds check}*/
							enum no_measure_error (size_t i) = `zip error: `
								~ Spaces[i].stringof ~ ` has no length or limit`;

							static if (is (typeof(spaces[0].limit!d)))
								auto base = spaces[0].limit!d;

							else static if (d == 0 && is (typeof(spaces[0].length)))
								size_t[2] base = [0, spaces[0].length];

							else static assert (0, no_measure_error!i);


							static if (is (typeof(spaces[i].limit!d)))
								auto lim = spaces[i].limit!d;

							else static if (d == 0 && is (typeof(spaces[i].length)))
								size_t[2] lim = [0, spaces[i].length];

							else static assert (0, no_measure_error!i);


							assert (base == lim, `zip error: `
								`mismatched limits! ` ~ lim.text ~ ` != ` ~ base.text
								~ ` in ` ~ Spaces[i].stringof
							);
						}
			}
		this (Spaces spaces) {this.spaces = spaces;}
	}

auto zip (Spaces...)(Spaces spaces)
	{/*...}*/
		return Zipped!Spaces (spaces);
	}

void zip_test () // TODO do multidim test, assert thrown there too, do various indices, do multidim slices
	{/*...}*/
		int[4] x = [1,2,3,4], y = [4,3,2,1];

		auto z = zip (x[], y[]);

		assert (z[0] == tuple (1,4));
		assert (z[$-1] == tuple (4,1));
		assert (z[0..$] == [
			tuple (1,4),
			tuple (2,3),
			tuple (3,2),
			tuple (4,1),
		]);

		{/*bounds check}*/
			error (zip (x[], [1,2,3]));
			error (zip (x[], [1,2,3,4,5]));
		}
		{/*multidimensional}*/
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

					mixin SliceOps!(access, rows, columns, RangeOps);
				}

			auto a = MultiDimensional();
			auto b = MultiDimensional()[].map!(x => x*2);

			auto c = zip (a[], b[]);

			assert (c[1, 1] == tuple (5, 10));
		}
		{/*map's automatic tuple expansion}*/
			static tuple_sum (T)(T t){return t[0] + t[1];}
			static binary_sum (T)(T a, T b){return a + b;}

			assert (z.map!tuple_sum == [5,5,5,5]);
			assert (z.map!binary_sum == [5,5,5,5]);
			assert (z.map!(t => t[0] + t[1]) == [5,5,5,5]);
			assert (z.map!((a,b) => a + b) == [5,5,5,5]);
		}
	}

///////////////////

void main ()
	{/*...}*/
		all_ops_tests;
		map_test;
		zip_test;
	}
