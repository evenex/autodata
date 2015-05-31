module autodata.traversal;

private {//import
	import autodata.functional;
	import autodata.spaces.sequence;
}

/* generate a foreach index for a custom range 
	this exploits the automatic tuple foreach index unpacking trick which is obscure and under controversy
	reference: https://issues.dlang.org/show_bug.cgi?id=7361
*/
auto enumerate (R)(R range)
if (is_input_range!R && has_length!R)
{
	return zip (Nat[0..range.length], range);
}
