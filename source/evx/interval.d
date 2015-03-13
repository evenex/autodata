module evx.interval;

private {/*import}*/
	import evx.logic;
}

/* generic interval type 
*/

/* convenience constructor 
*/
CommonType!(T,U)[2] interval (T,U)(T left, U right)
	if (not (is(CommonType!(T,U) == void)))
	{/*...}*/
		return [left, right];
	}
auto interval (T)(T[2] bounds)
	{/*...}*/
		return bounds;
	}
	unittest {/*...}*/
		auto A = interval (0, 10);
		assert (A.width == 10);

		A.left = 9;
		assert (A.width == 1);

		A.right = 9;
		assert (A.width == 0);
	}

/* test if two intervals overlap 
*/
bool overlaps (T)(const T[2] A, const T[2] B)
	{/*...}*/
		if (A.left < B.left)
			return B.left < A.right;
		else return A.left < B.right;
	}
	unittest {/*...}*/
		auto A = interval (0, 10);
		auto B = interval (11, 13);

		assert (A.left < B.left);
		assert (A.right < B.left);

		assert (A.not!overlaps (B));
		A.right = 11;
		assert (A.not!overlaps (B));
		A.right = 12;
		assert (A.overlaps (B));
		B.left = 13;
		assert (A.not!overlaps (B));
	}

/* test if an interval is contained within another 
*/
bool is_contained_in (T)(T[2] A, T[2] B)
	{/*...}*/
		return A.left >= B.left && A.right <= B.right;
	}
	unittest {/*...}*/
		auto A = interval (0, 10);
		auto B = interval (1, 5);
		auto C = interval (10, 11);
		auto D = interval (9, 17);

		assert (A.not!is_contained_in (B));
		assert (A.not!is_contained_in (C));
		assert (A.not!is_contained_in (D));

		assert (B.is_contained_in (A));
		assert (B.not!is_contained_in (C));
		assert (B.not!is_contained_in (D));

		assert (C.not!is_contained_in (A));
		assert (C.not!is_contained_in (B));
		assert (C.is_contained_in (D));

		assert (D.not!is_contained_in (A));
		assert (D.not!is_contained_in (B));
		assert (D.not!is_contained_in (C));
	}

/* test if a point is contained within an interval 
*/
bool is_contained_in (T)(T x, T[2] I)
	{/*...}*/
		return x.between (I.left, I.right);
	}

/* clamp a value to an interval
*/
auto clamp (T,U)(T value, U[2] interval)
	{/*...}*/
		value = max (value, interval.left);
		value = min (value, interval.right);

		return value;
	}

/* named access to left and right elements of T[2] 
*/
auto ref left (T)(auto ref T[2] bounds)
	{/*...}*/
		return bounds[0];
	}
auto ref right (T)(auto ref T[2] bounds)
	{/*...}*/
		return bounds[1];
	}
auto width (T)(T[2] bounds)
	{/*...}*/
		return bounds.right - bounds.left;
	}
