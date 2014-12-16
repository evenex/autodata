module evx.range.classification;

private {/*...}*/
	import std.range;
	import std.traits;

	import evx.math.logic;
}

alias is_string = std.traits.isSomeString;
alias is_input_range = std.range.isInputRange;
alias is_output_range = std.range.isOutputRange;
alias is_forward_range = std.range.isForwardRange;
alias is_bidirectional_range = std.range.isBidirectionalRange;
alias is_random_access_range = std.range.isRandomAccessRange;

template Element (R) // TODO deprecate ElementType, substitute Element, watch out for ICE
	{/*...}*/
		static if (is (R.Element == T, T))
			{}
		else static if (not (is (ElementType!R == void))) // TEMP until ElementType fully deprecated
			alias T = ElementType!R;
		else alias T = R;

		alias Element = T;
	}
alias ElementType = std.range.ElementType; // BUG ICE in template.c when this is replaced with a custom def, can't reproduce using dmd, only dub
alias has_length = std.range.hasLength;
