module evx.move;

private {/*import std}*/
	import std.typetuple:
		allSatisfy;

	import std.range:
		front, popFront, empty,
		isInputRange, hasLength;
}
private {/*import evx}*/
	import evx.traits:
		is_indexable;

	import evx.arrays:
		is_dynamic_array;
}

/* move all elements in a range (starting at index) up by one position 
 leaving an empty space at the indexed position */
void shift_up_from (R)(ref R range, size_t index)
	if (hasLength!R && is_indexable!R)
	{/*...}*/
		static if (is_dynamic_array!R)
			range.grow (1);
		else ++range.length;

		for (size_t i = range.length-1; i > index; --i)
			range[i] = range[i-1];
	}

/* move all elements in a range (starting at index) down one position
	overwriting the element at the indexed position */
void shift_down_on (R)(ref R range, size_t index)
	if (hasLength!R && is_indexable!R)
	{/*...}*/
		for (auto i = index; i < range.length-1; ++i)
			range[i] = range[i+1];
			
		static if (is_dynamic_array!R)
			range.shrink (1);
		else --range.length;
	}

void move (R,S)(S source, R target)
	if (allSatisfy!(isInputRange, S, R))
	{/*...}*/
		foreach (ref item; target)
			{/*...}*/
				item = source.front;
				source.popFront;
			}
	}
