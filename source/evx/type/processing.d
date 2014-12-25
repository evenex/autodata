module evx.type.processing;

private {/*import}*/
	import std.typecons;
	import std.typetuple;

	import evx.type.classification;
	import evx.math.logic;
	import evx.math.algebra;
}

// TODO doc and organize, REFACTOR to metafunctional

alias Identity (T...) = T[0];

alias Cons = TypeTuple;

alias Map = staticMap;

alias Filter = std.typetuple.Filter;

alias Select = std.typecons.Select;

alias Iota (size_t n) = staticIota!(0,n);
alias Iota (size_t l, size_t r) = staticIota!(l,r);

alias Count (T...) = Iota!(T.length);

alias Indexed (T...) = Zip!(Count!T, T);
alias IndexOf = staticIndexOf;

enum Contains (T...) = IndexOf!(T[0], T[1..$]) > -1;

alias Repeat (size_t n, T...) = Cons!(T, Repeat!(n-1, T));
alias Repeat (size_t n : 1, T...) = Cons!T;
alias Repeat (size_t n : 0, T...) = Cons!();

template Reduce (alias f, T...)
	if (T.length > 1)
	{/*...}*/
		static if (T.length == 2)
			alias Reduce = f!T;

		else alias Reduce = f!(T[0], Reduce!(f, T[1..$]));
	}

alias Sum (T...) = Reduce!(λ!q{(long a, long b) = a + b}, T);
	static assert (Sum!(0,1,2,3,4,5) == 15);

template Scan (alias f, T...)
	{/*...}*/
		template Sweep (size_t i)
			{/*...}*/
				static if (i == 0)
					alias Sweep = Cons!(T[i]);

				else alias Sweep = Reduce!(f, T[0..i+1]);
			}

		alias Scan = Map!(Sweep, Count!T);
	}
	static assert (Scan!(Sum, 0,1,2,3,4,5) == Cons!(0,1,3,6,10,15));

template LambdaCapture ()
	{/*...}*/
		static template Λ (string op)
			{/*...}*/
				mixin(q{
					alias Λ } ~ op ~ q{;
				});
			}
		static template λ (string op)
			{/*...}*/
				mixin(q{
					enum λ } ~ op ~ q{;
				});
			}
	}
mixin LambdaCapture;

template Pair ()
	{/*...}*/
		template First (alias predicate)
			{/*...}*/
				alias First (alias pair) = predicate!(pair.first);
			}

		template Second (alias predicate)
			{/*...}*/
				alias Second (alias pair) = predicate!(pair.second);
			}

		template Both (alias predicate)
			{/*...}*/
				alias Both (alias pair) = predicate!(pair.first, pair.second);
			}
	}
template Pair (T...)
	if (T.length == 2)
	{/*...}*/
		static if (is_enumerable!(T[0]))
			enum first = T[0];
		else alias first = T[0];
		
		static if (is_enumerable!(T[1]))
			enum second = T[1];
		else alias second = T[1];
	}

template Zip (T...)
	if (T.length % 2 == 0)
	{/*...}*/
		alias ToPair (size_t i) = Pair!(T[i], T[$/2 + i]);

		alias Zip = Map!(ToPair, Iota!(T.length/2));
	}

alias Interleave (T...) = Map!(Pair!().Both!Cons, Zip!T);
	static assert (Interleave!(1,2,3,4,5,6) == Cons!(1,4,2,5,3,6));
template Deinterleave (T...)
	if (T.length % 2 == 0)
	{/*...}*/
		alias Even = Map!(λ!q{(uint i) = 2*i}, Iota!(T.length/2));
		alias Odd = Map!(λ!q{(uint i) = i + 1}, Even);
		alias Get (uint i) = Cons!(T[i]);

		alias Deinterleave = Cons!(Map!(Get, Even, Odd));
	}
	static assert (Deinterleave!(1,4,2,5,3,6) == Cons!(1,2,3,4,5,6));

template Sort (alias compare, T...)
	{/*...}*/
		static if (T.length > 1)
			{/*...}*/
				alias Remaining = Cons!(T[0..$/2], T[$/2 +1..$]);
				enum is_before (U...) = compare!(U[0], T[$/2]);

				alias Sort = Cons!(
					Sort!(compare, Filter!(is_before, Remaining)),
					T[$/2],
					Sort!(compare, Filter!(not!is_before, Remaining)),
				);
			}
		else alias Sort = T;
	}
	static assert (Sort!(λ!q{(T...) = T[0] < T[1]}, 5,4,2,7,4,3,1) == Cons!(1,2,3,4,4,5,7));

/* given a set of zero-parameter templates, invoke the first which successfully compiles 
*/
template Match (patterns...)
	{/*...}*/
		import std.algorithm: find; // REVIEW how am i handling local vs global imports?
		import std.array: replace; // REVIEW

		alias Filtered = Filter!(λ!q{(alias pattern) = __traits(compiles, pattern!())}, patterns);

		static if (Filtered.length == 0)
			static assert (0, 
				`none of ` ~ patterns.stringof
				.find (`(`).replace (`(`,``).replace (`)`,``)
				~ ` could be matched`
			);

		else alias Match = Instantiate!(Filtered[0]);
	}

alias Instantiate (alias symbol) = symbol!();

alias NoDuplicates = std.typetuple.NoDuplicates;

////REFACTOR /////////////////////////////

template type_of (T...)
	if (T.length == 1)
	{/*...}*/
		static if (is(T[0]))
			alias type_of = T[0];
		else alias type_of = typeof(T[0]);
	}

/* T → T* 
*/
template pointer_to (T)
	{/*...}*/
		alias pointer_to = T*;
	}

/* T → T[] 
*/
template array_of (T)
	{/*...}*/
		alias array_of = T[];
	}

/* perform search and replace on a typename 
*/
string replace_in_template (Type, Find, ReplaceWith)() // TODO deprecate
	{/*...}*/
		import std.algorithm: findSplit;

		string type = Type.stringof;
		string find = Find.stringof;
		string repl = ReplaceWith.stringof;

		string left  = findSplit (type, find)[0];
		string right = findSplit (type, find)[2];

		return left ~ repl ~ right;
	}
	unittest {/*...}*/
		alias T1 = Tuple!string;

		mixin(q{
			alias T2 = } ~replace_in_template!(T1, string, int)~ q{;
		});

		static assert (is (T2 == Tuple!int));
	}
