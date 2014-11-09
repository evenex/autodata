module evx.range.slicing;

private {/*imports}*/
	import std.algorithm;
	import std.range;
}

/* slice a range before a mark 
*/
auto ref before (R,S)(R range, S mark)
	{/*...}*/
		return range.up_to (mark)[0..$-1];
	}
auto ref before (alias condition, R)(R range)
	{/*...}*/
		return range.up_to!condition[0..$-1];
	}

/* split a range before and including a mark 
*/
auto ref up_to (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitAfter (mark)[0];
	}
auto ref up_to (alias condition, R)(R range)
	{/*...}*/
		auto L = range.find!condition.length;

		return range[0..$-L+1];
	}

/* split a range after a mark 
*/
auto ref after (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitAfter (mark)[1];
	}
auto ref after (alias condition, R)(R range)
	{/*...}*/
		return range.find!condition[1..$];
	}

/* slice a range including and after a mark 
*/
auto ref up_from (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitBefore (mark)[1];
	}
auto ref up_from (alias condition, R)(R range)
	{/*...}*/
		return range.find!condition;
	}

/* take a slice of a range that matches a given mark 
*/
auto ref containing (R,S)(R range, S mark)
	{/*...}*/
		return range.up_from (mark).up_to (mark);
	}
