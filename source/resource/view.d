module resource.view;

import std.stdio;
import std.traits;
import std.typetuple;
import std.range;
import std.conv;
import utils;

import resource.allocator;

/* Views
Views are an opaque type-generic layer over certain types of Ranges. They bring
	safe portability to Resources, offer read-only RandomAccessRange semantics, 
	and need not be backed by addressable data. Views are essentially lightweight
	range-based functors and can serve as emplaced nodes in range-based	
	computational graphs. They can be created, copied, consumed and destroyed 
	without affecting their source data.

The IdentityView wraps a Resource, Array or Generator (function on ℕ) into a View.
The MapView transforms a View by a function.
The ZipView merges multiple Views into one.
TODO The InterceptView is a variation of the IdentityView that does not attempt to minimize indirection.

Filter and Reduce are unimplemented, as it is currently unclear how to compute the 
	length of a FilterView without eager evaluation, and a ReduceView would return 
	a single data element, which would disqualify it as a Range and therefore as a 
	View.
*/

alias View = IdentityView;

public:
public {/*identity}*/
	/*
	The IdentityView provides a uniformly-typed wrapper over certain types of Ranges:
		Arrays, Generators (functions of one unsigned integer), and Functors (objects
		callable with one unsigned integer). The details of the source are hidden 
		behind a type-erasure mechanism which allows the View's type to depend only on 
		its ElementType.

	IdentityViews will always attempt to minimize the length of their indirection path,
		meaning	that if IdentityView A is constructed over IdentityView B, A will not 
		source from B, but directly from B's source. This eliminates unnecessary 
		indirection and improves the robustness of the pathway, making IdentityViews
		safe and efficient to use liberally.
	*/
	auto view (T)(ref IdentityView!T view)
		{/*...}*/
			return view;
		}
	auto view (T)(T[] array)
		{/*...}*/
			return IdentityView!T (array);
		}
	auto view (T)(T function(Index) generator, Index start = 0, Index end = Index.max)
		{/*...}*/
			return IdentityView!T (generator, start, end);
		}
	auto view (F)(ref F functor)
		if (is_Functor!F && not (is_IdentityView!F))
		{/*...}*/
			return IdentityView!(F.ElementType) (functor);
		}
	struct IdentityView (T)
		{/*...}*/
			public:
			public {/*☀}*/
				this (T[] array)
					{/*...}*/
						this.source = Source.array;
						this.array = array;
						this.access_range (0, array.length.to!Index);
					}
				this (F)(ref F functor)
					if (is_Functor!F)
					{/*...}*/
						this.source = Source.functor;
						this.functor = std.functional.toDelegate (&functor.opAccess);
						this.access_range (functor.start, functor.end);
					}
				this (T function(Index) generator, Index start = 0, Index end = Index.max)
					{/*...}*/
						this.source = Source.generator;
						this.generator = generator;
						this.access_range (start, end);
					}
			}
			public {/*=}*/ // REVIEW do i need this?
				void opAssign (U)(U that)
					{/*...}*/
						this.__ctor (that); // XXX
					}
			}
			private:
			private {/*data}*/
				union {/*...}*/
					T[] array;
					T function(Index) generator;
					T delegate(Index) functor;
				}
				Source source;
				enum Source {none, array, functor, generator}
			}
			private {/*access}*/
				T opAccess (Index i)
					{/*...}*/
						final switch (source)
							{/*...}*/
								case Source.array:
									return array [i];

								case Source.functor:
									return functor (i);

								case Source.generator:
									return generator (i);
								
								case Source.none:
									assert (0, `view is unavailable`);
							}
					}
			}
			enum IdentityViewTrait;
			mixin ViewFunctor;
		}
	bool is_IdentityView (T)()
		{/*...}*/
			return __traits(compiles, T.IdentityViewTrait);
		}
}
public {/*map}*/
	/*
	The MapView transforms a View using a function. 
		It takes a View as its domain, and provides a View of the function's 
		resulting codomain. Because the function is implemented as a function 
		pointer, the MapView's type depends only on its domain and codomain 
		ElementTypes.	
	*/
	auto map_view (R, U, T = ElementType!R)(R range, U function(T) map)
		{/*...}*/
			return MapView!(T,U)(range, map);
		}
	struct MapView (T,U)
		{/*...}*/
			public {/*☀}*/
				this (R)(R range, U function(T) map)
					{/*...}*/
						this.domain = view (range);
						this.map = map;
						this.access_range (0, domain.length);
					}
			}
			private:
			private {/*data}*/
				U function(T) map;
				IdentityView!T domain;
			}
			private {/*access}*/
				auto opAccess (Index i)
					{/*...}*/
						return map (domain [i]);
					}
			}
			mixin ViewFunctor;
		}
	/* the identity map = convenience function for forwarding indices */
	auto identity (size_t that)
		{/*...}*/
			return that;
		}
}
public {/*zip}*/
	/*
	The ZipView merges multiple Views into a single View
		(of Tuples of the ElementTypes of the input Views).
	*/
	auto zip_view (R...)(R ranges)
		if (R.length > 1
		&& allSatisfy!(templateOr!(isRandomAccessRange, isArray), R))
		{/*...}*/
			return ZipView!(staticMap!(ElementType, R)) (ranges);
		}
	struct ZipView (T...)
		if (T.length > 1)
		{/*...}*/
			public:
			public {/*☀}*/
				mixin (ctor);
			}
			private:
			private {/*data}*/
				mixin (view_declarations);
			}
			private {/*access}*/
				auto opAccess (Index i)
					{/*...}*/
						mixin(q{return } ~ opAccess_build_tuple);
					}
			}
			private {/*code generation}*/
				static string ctor ()
					{/*...}*/
						return q{
							this } ~ctor_template_args ~ ctor_function_args~ q{
								in }`{`q{
									} ~ctor_in_contract~ q{
								}`}`q{
								body }`{`q{
									} ~ctor_set_views~ q{
									this.access_range (0, _0.length);
								}`}`q{
						};
					}
				static string ctor_template_args ()
					{/*...}*/
						string code;

						foreach (i, Type; T)
							code ~= q{R} ~i.text~ q{, };

						return `(` ~code[0..$-2]~ `)`;
					}
				static string ctor_function_args ()
					{/*...}*/
						string code;

						foreach (i, Type; T)
							code ~= q{R} ~i.text~ q{ _} ~i.text~ q{, };

						return `(` ~code[0..$-2]~ `)`;
					}
				static string ctor_in_contract ()
					{/*...}*/
						string code;

						foreach (i, Type; T)
							code ~= q{assert (_0.length == _} ~i.text~ q{.length); };

						return code;
					}
				static string ctor_set_views ()
					{/*...}*/
						string code;

						foreach (i, Type; T)
							code ~= q{this._} ~i.text~ q{ = _} ~i.text~ q{.view; 
									};

						return code;
					}
				static string view_declarations ()
					{/*...}*/
						string code;

						foreach (i, Type; T)
							code ~= q{IdentityView!(T[} ~i.text~ q{]) _} ~i.text~ q{; };

						return code;
					}
				static string opAccess_build_tuple ()
					{/*...}*/
						string code;
						
						foreach (i, Type; T)
							code ~= q{_} ~i.text~ q{[i], };

						return q{ tuple (} ~code[0..$-2]~ q{); };
					}
			}
			mixin ViewFunctor;
		}
}

private:
private {/*functor}*/
	mixin template ViewFunctor ()
		{/*...}*/
			public: 
			alias ElementType = ReturnType!opAccess;

			public:
			@property {/*input}*/
				bool empty ()
					{/*...}*/
						return length == 0;
					}
				auto front ()
					{/*...}*/
						return this[0];
					}
				void popFront ()
					{/*...}*/
						++start;
					}
			}
			@property {/*forward}*/
				auto save ()
					{/*...}*/
						return this;
					}
			}
			@property {/*bidirectional}*/
				auto back ()
					in {/*...}*/
						assert (end < Index.max, `attempted to access back of unbounded view`);
					}
					body {/*...}*/
						return this[$-1];
					}
				void popBack ()
					in {/*...}*/
						assert (end < Index.max, `attempted to pop back of unbounded view`);
					}
					body {/*...}*/
						--end;
					}
			}
			@property {/*random access}*/
				auto opIndex (Index i)
					in {/*...}*/
						assert (i < length, `range violation`);
					}
					body {/*...}*/
						return opAccess (start + i);
					}
			}
			@property {/*length}*/
				auto length ()
					{/*...}*/
						return end - start;
					}
				auto opDollar ()
					{/*...}*/
						return length;
					}
			}
			public {/*slicing}*/
				auto opSlice (Index start, Index end)
					in {/*...}*/
						assert (start <= end, `range reversed`);
						assert (end <= length, `range violation`);
					}
					body {/*...}*/
						auto clone = this;
						clone.start = start;
						clone.end = end;
						return clone;
					}
				auto opSlice ()
					{/*...}*/
						return this[0..$];
					}
			}

			private:
			private {/*settings}*/
				void access_range (Index start, Index end)
					{/*...}*/
						this.start = start;
						this.end = end;
					}
			}
			private {/*data}*/
				Index start;
				Index end;
			}
			unittest {/*...}*/
				alias This = typeof(this);
				mixin(report_test!(This.stringof ~ ` ViewFunctor`));

				static assert (isRandomAccessRange!This);
				static assert (is (std.range.ElementType!This == ElementType));
				//static assert (not (hasMobileElements!This)); BUG moveFront doesn't compile, but hasMobileElements is true
				static assert (not (hasSwappableElements!This));
				static assert (not (hasAssignableElements!This));
				static assert (not (hasLvalueElements!This));
				static assert (hasLength!This);
				static assert (not (isInfinite!This));
				static assert (hasSlicing!This);
			}
		}
	bool is_Functor (T)()
		{/*...}*/
			static if (hasMember!(T, `opAccess`))
				static if (isSomeFunction!(T.opAccess))
					static if (is (ParameterTypeTuple!(T.opAccess) == TypeTuple!(Index)))
						return true;
					else return false;
				else return false;
			else return false;
		}
}

unittest
	{/*...}*/
		mixin(report_test!q{view});

		alias Source = IdentityView!int.Source;

		int[] data1 = [0, 1, 2];
		string[] data2 = [`a`, `bb`, `ccc`];
		static short data3 (size_t i) 
			{return i.to!short;}

		// VIEW TESTS
		auto array_view = view (data1);
		assert (array_view.source == Source.array);
		assert (array_view.equal (data1));

		// indirection path minimization
		auto b = view (array_view);
		assert (b.source == Source.array);
		assert (b.equal (array_view));

		auto generator_view = view (&data3, 0, 3);
		assert (generator_view.source == Source.generator);
		assert (generator_view.equal (array_view));

		// ZIP TESTS
		auto g = zip_view (array_view, data2);
		assert (g._0.source == Source.array);
		assert (g._1.source == Source.array);
		assert (g.equal (zip (array_view, data2)));

		auto i = data2.view;
		auto j = zip_view (generator_view, i);
		assert (j.equal (g));
		assert (i.source == Source.array);

		auto h = view (g);
		assert (h.source == Source.functor);
		assert (h.equal (g));
		assert (h.equal (zip (array_view, data2)));
		assert (h.functor == &g.opAccess);

		// MAP TEST
		auto k = data2.map_view ((string str) => str.length.to!int - 1);
		assert (k.domain.source == Source.array);
		assert (k.equal (array_view));
	}
