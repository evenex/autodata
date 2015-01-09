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

		a.bytes.blit (t.bytes);
		b.bytes.blit (a.bytes);
		t.bytes.blit (b.bytes);
	}

/* swap in memory, circumcenting ctors/assign, invoking dtor 
*/
void move (T)(ref T src, ref T tgt)
	{/*...}*/
		swap (src, tgt);

		destroy (src);
	}

/* a borrowed resource bypasses RAII And move semantics 
*/
struct Borrowed (T)
	{/*...}*/
		T* ptr;

		this (ref T resource)
			{/*...}*/
				this = resource;
			}

		auto ref opAssign (ref T resource)
			{/*...}*/
				ptr = &resource;
			}

		ref deref ()
			{/*...}*/
				return *ptr;
			}

		alias deref this;
	}

auto borrow (T)(ref T resource)
	{/*...}*/
		return Borrowed!T (resource);
	}
