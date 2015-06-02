module autodata.traversal;

private {//import
	import evx.meta;
	import evx.interval;

	import autodata.traits;
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

/* lexicographic traversal
*/
struct Lexicographic (S)
{
	S space;

	Repeat!(dimensionality!S, size_t) index;

	auto front ()
	{
		auto idx (uint i)()
		{
			return index[i] + space.limit!i.left;
		}

		return space[Map!(idx, Ordinal!index)];
	}
	auto popFront ()
	{
		void advance (uint i = 0)()
		{
			if (++index[i] >= space.limit!i.width)
				static if (i+1 < index.length)
				{
					index[i] = 0;
					advance!(i+1);
				}
		}

		advance;
	}
	auto empty ()
	{
		return index[$-1] >= space.limit!(index.length-1).width;
	}

	auto opEquals (R)(R range)
	{
		import std.algorithm: equal;

		return this.equal (range);
	}
}
auto lexicographic (S)(S space)
{
	return Lexicographic!S (space);
}
alias lexi = lexicographic;
unittest {
	import autodata.spaces;

	auto test = Array!(int, 2)(
		[1,2,3].extrude (3)
	);

	assert (test.lexi == [1,2,3,1,2,3,1,2,3]);
}
