module evx.range.slicing;
version(none):

private {/*imports}*/
	import std.algorithm;
	import std.range;
}

/* slice a range before a mark 
*/
auto ref before (R,S)(R range, S mark)
	{/*...}*/
		auto L = range.find (mark).length;

		return range[0..$-L];
	}
auto ref before (alias condition, R)(R range)
	{/*...}*/
		auto L = range.find!condition.length;

		return range[0..$-L];
	}
	unittest {/*...}*/
		auto x = [1,2,3];

		assert (x.before (2) == [1]);
		assert (x.before (2) == x.before!(i => i == 2));
		assert (x.before (4) == x);
		assert (x.before (4) == x.before!(i => i == 4));
	}

/* split a range before and including a mark 
	if the mark is not found, 
*/
auto ref up_to (R,S)(R range, S mark)
	{/*...}*/
		auto L = range.find (mark).length;

		if (L > 0)
			return range[0..$-L+1];
		else return range;
	}
auto ref up_to (alias condition, R)(R range)
	{/*...}*/
		auto L = range.find!condition.length;

		if (L > 0)
			return range[0..$-L+1];
		else return range;
	}
	unittest {/*...}*/
		auto x = [1,2,3];

		assert (x.up_to (2) == [1,2]);
		assert (x.up_to (2) == x.up_to!(i => i == 2));
		assert (x.up_to (4) == x);
		assert (x.up_to (4) == x.up_to!(i => i == 4));
	}

/* split a range after a mark 
*/
auto ref after (R,S)(R range, S mark)
	{/*...}*/
		auto L = range.find (mark).length;

		if (L > 0)
			return range[$-L+1..$];
		else return range[0..0];
	}
auto ref after (alias condition, R)(R range)
	{/*...}*/
		auto L = range.find!condition.length;

		if (L > 0)
			return range[$-L+1..$];
		else return range[0..0];
	}
	unittest {/*...}*/
		auto x = [1,2,3];

		assert (x.after (2) == [3]);
		assert (x.after (2) == x.after!(i => i == 2));
		assert (x.after (4) == []);
		assert (x.after (4) == x.after!(i => i == 4));
	}

/* slice a range including and after a mark 
*/
auto ref up_from (R,S)(R range, S mark)
	{/*...}*/
		auto L = range.find (mark).length;

		if (L > 0)
			return range[$-L..$];
		else return range[0..0];
	}
auto ref up_from (alias condition, R)(R range)
	{/*...}*/
		auto L = range.find!condition.length;

		if (L > 0)
			return range[$-L..$];
		else return range[0..0];
	}
	unittest {/*...}*/
		auto x = [1,2,3];

		assert (x.up_from (2) == [2,3]);
		assert (x.up_from (2) == x.up_from!(i => i == 2));
		assert (x.up_from (4) == []);
		assert (x.up_from (4) == x.up_from!(i => i == 4));
	}

/* take a slice of a range that matches a given mark 
*/
auto ref containing (R,S)(R range, S mark)
	{/*...}*/
		return range.up_from (mark).up_to (mark);
	}
