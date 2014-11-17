module evx.range.primitives;

private {/*imports}*/
	import std.range;
}

/* retrieve the front of a range 
*/
alias front = std.range.front;

/* retrieve the back of a range 
*/
alias back = std.range.back;

/* remove the front of a range 
*/
alias popFront = std.range.popFront;

/* remove the back of a range 
*/
alias popBack = std.range.popBack;

/* test if a range is empty
*/
alias empty = std.range.empty;

/* put an element in a range 
*/
alias put = std.range.put;
