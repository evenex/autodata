module evx.range.slicing;

private {/*imports}*/
	import std.algorithm;
}

/* slice a range before a mark 
*/
auto ref before (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitBefore (mark)[0];
	}

/* split a range before and including a mark 
*/
auto ref up_to (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitAfter (mark)[0];
	}

/* split a range after a mark 
*/
auto ref after (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitAfter (mark)[1];
	}

/* slice a range including and after a mark 
*/
auto ref up_from (R,S)(R range, S mark)
	{/*...}*/
		return range.findSplitBefore (mark)[1];
	}
