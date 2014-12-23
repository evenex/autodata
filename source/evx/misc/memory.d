module evx.misc.memory;

private {/*imports}*/
	import std.algorithm;
}

/* convenience structure for representing structs as byte arrays 
*/
struct Bytes (T)
	{/*...}*/
		byte[T.sizeof] data;
		alias data this;

		auto ref bytes ()
			{/*...}*/
				return data[];
			}

		auto opEquals (byte[] that)
			{/*...}*/
				return bytes[].equal (that[]);
			}

		this (byte[] that)
			{/*...}*/
				bytes[] = that;
			}
	}

/* convert values into bytes, or references into byte views 
*/
auto bytes (T)(ref T x)
	{/*...}*/
		return (*cast(Bytes!T*)&x)[];
	}
auto bytes (T)(T x)
	{/*...}*/
		return (*cast(Bytes!T*)&x);
	}

/* byte-by-byte copy, circumventing all ctors/dtors/assign 
*/
void blit (byte[] src, byte[] tgt)
	{/*...}*/
		src.copy (tgt);
	}
void blit (T)(ref T src, ref T tgt)
	{/*...}*/
		src.bytes.blit (tgt.bytes);
	}

/* swap bytes in memory, circumventing ctors/dtors/assign 
*/
void swap (T)(ref T a, ref T b)
	{/*...}*/
		Bytes!T t;

		bytes (a).blit (bytes (t)); // BUG UFCS Error: cannot resolve type for a.bytes(T)(T x)
		bytes (b).blit (bytes (a));
		bytes (t).blit (bytes (b));
	}

/* swap in memory, circumcenting ctors/assign, invoking dtor 
*/
void move (T)(ref T src, ref T tgt)
	{/*...}*/
		swap (src, tgt);

		destroy (src);
	}
