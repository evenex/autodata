module evx.type.processing;

private {/*import}*/
	import std.typecons;
	import std.typetuple;

	import evx.traits;
	import evx.math.logic;
	import evx.math.algebra;
}

// TODO doc and organize

alias Identity (T...) = T[0];

alias Select = std.typecons.Select;

alias Iota = staticIota;

alias Cons = TypeTuple;

alias Map = staticMap;

alias Filter = std.typetuple.Filter;

alias IndexOf = staticIndexOf;

enum Contains (T...) = IndexOf!(T[0], T[1..$]) > -1;

alias Repeat (size_t n, T...) = Cons!(T, Repeat!(n-1, T));
alias Repeat (size_t n : 1, T...) = Cons!T;

	// TODO SORT
	// TODO INTERLEAVE

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

		alias Zip = Map!(ToPair, Iota!(0, T.length/2));
	}

alias Interleave (T...) = Map!(Pair!().Both!Cons, Zip!T);
static assert (Interleave!(1,2,3,4,5,6) == Cons!(1,4,2,5,3,6));

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
string replace_in_template (Type, Find, ReplaceWith)()
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