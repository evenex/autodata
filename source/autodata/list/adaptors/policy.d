module autodata.list.adaptors.policy;

/**
    policy to determine how an adaptor reacts to appending past the capacity.
*/
enum OnOverflow {reallocate, discard, error}

package template OverflowPolicy ()
{
	auto exit_on_overflow (size_t extension)
	{
		import std.conv: text;

		if (this.length + extension > capacity)
		with (OnOverflow) {
			static if (overflow_policy is discard)
				return true;
			else static if (overflow_policy is reallocate)
				capacity = max (capacity + extension, capacity * 2);
			else static if (overflow_policy is error)
				assert (0, 
					typeof(this).stringof ~ ` overflowed ` ~ (this.length + extension).text ~ ` exceeds ` ~ capacity.text
				);
		}

		return false;
	}
}
