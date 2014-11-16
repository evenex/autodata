module evx.misc.binary;

private {/*imports}*/
	import std.algorithm;
}

template Binary (T)
	{/*...}*/
		alias Binary = ubyte[T.sizeof];
	}

auto binary_view (T)(ref T x)
	{/*...}*/
		return (*cast(Binary!T*)&x)[];
	}
bool binary_equal (T,U)(T a, U b)
	{/*...}*/
		if (T.sizeof != U.sizeof)
			return false;

		else return a.binary_view.equal (b.binary_view);
	}
void binary_copy (T,U)(ref T src, ref U tgt)
	{/*...}*/
		static assert (T.sizeof == U.sizeof);

		binary_view (src).copy (binary_view (tgt));
	}
