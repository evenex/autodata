module evx.misc.string;

import std.string;
import std.algorithm;

pure extract_number (string input)
	{/*...}*/
		enum accepted_chars = `-.0123456789`;

		auto i = input.indexOfAny (accepted_chars);
		auto j = input.lastIndexOfAny (accepted_chars);

		return input[i..min($, j+1)];
	}
