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

/* generate an indexing operator from an access function and a set of index limits
	access must be a function which returns an element of type E

	limits must be aliases to single variables or arrays of two,
	whose types (or element types, if any are arrays), given in order, 
	match the argument types for access
*/
template IndexOps (alias access, limits...)
	{/*...}*/
		ReturnType!access opIndex (ParameterTypeTuple!access args)
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

						auto bounds_inverted_error (T)(T limit) {return error_header ~ `bounds inverted! ` ~ limit.left.text ~ ` >= ` ~ limit.right.text;}

						auto out_of_bounds_error (T)(T arg) {return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in `;}
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
								args[i] >= limit.left
								&& args[i] < limit.right,
								out_of_bounds_error (args[i]) ~ limit.text
							);
						else assert (
							args[i] >= zero!(typeof(limit.identity))
							&& args[i] < limit,
							out_of_bounds_error (args[i]) ~ `[` ~ zero!(typeof(limit.identity)).text ~ `, ` ~ limit.text ~ `]`
						);
					}
			}
			body {/*...}*/
				return access (args);
			}
	}

/* generate slicing operators TODO
*/
template SliceOps (alias access, LimitsAndExtensions...)
	{/*...}*/
		alias limits = Filter!(has_identity, LimitsAndExtensions);

		struct Sub (Dimensions...)
			{/*...}*/
				public {/*source}*/
					ReturnType!access delegate(ParameterTypeTuple!access)
						source; 
				}
				public {/*opIndex}*/
					mixin IndexOps!(source, bounds)
						index_ops;

					mixin(overload_priority!(`opIndex`, index_ops)); // REVIEW

					Sub opIndex ()
						{/*...}*/
							return this;
						}
				}
				public {/*bounds}*/
					Map!(Λ!q{(T) = Select!(is (T == U[2], U), T, T[2])}, typeof(limits)) 
						bounds;
				}
				public {/*ctor}*/
					this (typeof(source) source, typeof(bounds) bounds)
						{/*...}*/
							this.source = source;
							this.bounds = bounds;
						}
					@disable this ();
				}
				public {/*extensions}*/
					static extensions ()
						{/*...}*/
							string[] code;

							foreach (i, extension; Filter!(not!has_identity, LimitsAndExtensions))
								code ~= q{
									mixin } ~ __traits(identifier, extension) ~ q{;
								};

							return code.join.to!string;
						}

					mixin(extensions);
				}
			}

		public {/*opIndex}*/
			mixin IndexOps!(access, limits) indexing;

			auto opIndex ()
				{/*...}*/
					alias Sub = typeof(this).Sub!(Repeat!(true, limits.length));

					typeof(Sub.bounds) bounds;

					foreach (i, limit; limits)
						static if (is (typeof(limit) == T[2], T))
							bounds[i] = limit;
						else bounds[i] = [zero!(typeof(limit)), limit];

					return Sub ((&access).to_delegate, bounds);
				}
			auto opIndex (Limits...)(Limits limits)
				{/*...}*/
					static if (Any!(is_static_array, Limits)) // TODO
						{/*...}*/
							return 1;
						}
					else return indexing.opIndex (limits);
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

void index_ops_tests ()
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
void main ()
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
		//assert (Basic()[0..10][0]);

		static struct Extended
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
		writeln (Extended()[].length);
		writeln (Extended()[][].length);
		//writeln (Extended()[0..10].length);
		//writeln (Extended()[10..20].length);
	}
