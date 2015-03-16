module spacecadet.sequence.query;

private {/*imports}*/
	import std.range;
	import std.algorithm;
	import std.conv;
}

/* check if a range contains a value 
*/
alias contains = std.algorithm.canFind;

/* check if a value is contained in a range 
*/
alias contained_in = std.functional.reverseArgs!contains;

/* check if any elements in a range meet a given criteria 
*/
alias any = std.algorithm.any;

/* check if all elements in a range meet a given criteria 
*/
alias all = std.algorithm.all;

/* explicitly count the number of elements in an input_range 
*/
size_t count (alias criteria = exists => true, R)(R range)
	if (is_input_range!R)
	{/*...}*/
		size_t count;

		foreach (_; range)
			++count;

		return count;
	}

/* count the number of elements in an input_range until a given element is found 
*/
alias count_until = std.algorithm.countUntil;
