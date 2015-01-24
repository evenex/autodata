module evx.misc.string;

private {/*imports}*/
	import std.string;
	import std.algorithm;
	import std.ascii;
}

auto extract_number ()(string input)
	{/*...}*/
		enum accepted_chars = `-.0123456789`;

		auto i = input.indexOfAny (accepted_chars);
		auto j = input.lastIndexOfAny (accepted_chars);

		return input[i..min($, j+1)];
	}

auto find_occurrences ()(string text, string word)
	{/*...}*/
		long[] indices;

		auto remaining = text;

		while (remaining.length)
			{/*...}*/
				auto found = remaining.find (word);

				if (found.length == 0)
					break;
				else remaining = found[1..$];

				auto word_start = long (text.length) - long (found.length);
				auto prev_char = word_start - 1;
				auto next_char = word_start + word.length;

				if (prev_char > 0 && text[prev_char].isAlphaNum)
					continue;
				else if (next_char < text.length && text[next_char].isAlphaNum)
					continue;
				else indices ~= word_start;
			}

		return indices;
	}
