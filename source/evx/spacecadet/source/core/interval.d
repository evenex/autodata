module spacecadet.core.interval;

private {/*import}*/
	import std.algorithm: min, max;
	import spacecadet.core.logic;
	import spacecadet.meta;
}

/* convenience constructor 
*/
CommonType!(T,U)[2] interval (T,U)(T left, U right)
	if (not (is (CommonType!(T,U) == void)))
	out (result) {/*...}*/
		assert (result.is_valid_interval);
	}
	body {/*...}*/
		return [left, right];
	}
auto interval (T)(T[2] interval)
	out (result) {/*...}*/
		assert (result.is_valid_interval);
	}
	body {/*...}*/
		return interval;
	}
auto interval (T)(T right)
	if (not (is (T == U[2], U)))
	out (result) {/*...}*/
		assert (result.is_valid_interval);
	}
	body 	{/*...}*/
		return interval (T(0), right);
	}
	unittest {/*...}*/
		auto a = interval (0, 10);
		assert (a.width == 10);

		a.left = 9;
		assert (a.width == 1);

		a.right = 9;
		assert (a.width == 0);

		auto b = [-10, 5].interval;
		assert (b.width == 15);

		auto c = interval (6);
		assert (c.left == 0);
		assert (c.right == 6);
		assert (c.width == 6);
	}

/* named access to first and second elements of T[2] 
*/
auto ref left (T)(auto ref T[2] interval)
	in {/*...}*/
		assert (interval.is_valid_interval);
	}
	body {/*...}*/
		return interval[0];
	}
auto ref right (T)(auto ref T[2] interval)
	in {/*...}*/
		//assert (interval.is_valid_interval);
	}
	body {/*...}*/
		return interval[1];
	}

/* distance between the endpoints of an interval
*/
auto width (T)(T[2] interval)
	in {/*...}*/
	//	assert (interval.is_valid_interval);
	}
	body {/*...}*/
		return interval.right - interval.left;
	}

/* test if two intervals overlap 
*/
bool overlaps (T)(T[2] a, T[2] b)
	in {/*...}*/
		assert (a.is_valid_interval);
		assert (b.is_valid_interval);
	}
	body {/*...}*/
		if (a.left < b.left)
			return b.left < a.right;
		else return a.left < b.right;
	}
	unittest {/*...}*/
		auto a = interval (0, 10);
		auto b = interval (11, 13);

		assert (a.left < b.left);
		assert (a.right < b.left);

		assert (a.not!overlaps (b));
		a.right = 11;
		assert (a.not!overlaps (b));
		a.right = 12;
		assert (a.overlaps (b));
		b.left = 13;
		assert (a.not!overlaps (b));
	}

/* test if an interval is contained within another 
*/
bool is_contained_in (T)(T[2] a, T[2] b)
	in {/*...}*/
		assert (a.is_valid_interval);
		assert (b.is_valid_interval);
	}
	body {/*...}*/
		return a.left >= b.left && a.right <= b.right;
	}
	unittest {/*...}*/
		auto a = interval (0, 10);
		auto b = interval (1, 5);
		auto C = interval (10, 11);
		auto D = interval (9, 17);

		assert (a.not!is_contained_in (b));
		assert (a.not!is_contained_in (C));
		assert (a.not!is_contained_in (D));

		assert (b.is_contained_in (a));
		assert (b.not!is_contained_in (C));
		assert (b.not!is_contained_in (D));

		assert (C.not!is_contained_in (a));
		assert (C.not!is_contained_in (b));
		assert (C.is_contained_in (D));

		assert (D.not!is_contained_in (a));
		assert (D.not!is_contained_in (b));
		assert (D.not!is_contained_in (C));
	}

/* test if a point is contained within an interval 
*/
bool is_contained_in (T)(T x, T[2] interval)
	in {/*...}*/
		//assert (interval.is_valid_interval);
	}
	body {/*...}*/
		return (interval.left <= x && x < interval.right)
			|| (interval.left == interval.right && x == interval.left);
	}

/* test if an interval's endpoints are ordered 
*/
bool is_valid_interval (T)(T[2] interval)
	{/*...}*/
		return interval[0] <= interval[1];
	}

/* clamp a value to an interval
*/
auto clamp (T,U)(T value, U[2] interval)
	in {/*...}*/
		//assert (interval.is_valid_interval);
	}
	body {/*...}*/
		value = max (value, interval.left);
		value = min (value, interval.right);

		return value;
	}
