module evx.range.query;

private {/*imports}*/
	import std.range;
	import std.algorithm;
	import std.conv;

	import evx.range.classification;
}

/* check if a range contains a value 
*/
alias contains = std.algorithm.canFind;

/* get the subrange beginning with a given element or meeting a given criteria 
*/
alias find = std.algorithm.find;

/* check if any elements in a range meet a given criteria 
*/
alias any = std.algorithm.any;

/* check if all elements in a range meet a given criteria 
*/
alias all = std.algorithm.all;

/* check if two ranges are equal
*/
alias equal = std.algorithm.equal;

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

/* verify that the declared length of a range is its true length 
*/
debug void verify_length (R)(R range)
	{/*...}*/
		auto length = range.length;
		auto count = range.count;

		if (length != count)
			assert (0, R.stringof~ ` length (` ~count.text~ `) doesn't match reported length (` ~length.text~ `)`);
	}
