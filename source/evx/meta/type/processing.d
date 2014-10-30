module evx.type.processing;

private {/*import}*/
	import std.typecons;
}

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