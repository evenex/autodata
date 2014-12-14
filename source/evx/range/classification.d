module evx.range.classification;

private {/*...}*/
	import std.range;
	import std.traits;
}

alias is_string = std.traits.isSomeString;
alias is_input_range = std.range.isInputRange;
alias is_output_range = std.range.isOutputRange;
alias is_forward_range = std.range.isForwardRange;
alias is_bidirectional_range = std.range.isBidirectionalRange;
alias is_random_access_range = std.range.isRandomAccessRange;

alias ElementType = std.range.ElementType; // BUG ICE in template.c when this is replaced with a custom def
alias has_length = std.range.hasLength;
