module spacecadet.memory.transfer;

private {/*imports}*/
	import std.algorithm;
	import std.conv;

	import spacecadet.math;
}

/* convenience structure for representing structs as byte arrays 
*/
struct Bytes (T)
	{/*...}*/
		byte[T.sizeof] data;
		alias data this;

		auto bytes ()
			{/*...}*/
				return data[];
			}

		auto opEquals (byte[] that)
			{/*...}*/
				return bytes[].equal (that[]);
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
	in {/*...}*/
		assert (src.length == tgt.length,
			src.length.text ~ ` != ` ~ tgt.length.text
		);
	}
	body {/*...}*/
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
void move (T)(T src, ref T tgt)
	{/*...}*/
		swap (src, tgt);

		T.init.bytes.blit (src.bytes);
	}

/* overwrite an lvalue with an initialized state, bypassing RAII 
*/
void neutralize (T)(ref T target)
	{/*...}*/
		T.init.move (target);
	}

unittest {/*stacked mixin postblit}*/
		static bool one, two;

		template CopyOne ()
			{/*...}*/
				this (this)
					{/*...}*/
						one = true;
					}
			}
		template CopyTwo ()
			{/*...}*/
				this (this)
					{/*...}*/
						two = true;
					}
			}

		static struct Test
			{/*...}*/
				mixin CopyOne;
				mixin CopyTwo;
			}

		Test t1;

		auto t2 = t1;

		assert (one && two);
	}
unittest {/*stacked mixin dtors}*/
	static bool one, two;

	template DtorOne ()
		{/*...}*/
			~this ()
				{/*...}*/
					one = true;
				}
		}
	template DtorTwo ()
		{/*...}*/
			~this ()
				{/*...}*/
					two = true;
				}
		}

	static struct Test
		{/*...}*/
			mixin DtorOne;
			mixin DtorTwo;
		}

	{/*test scope}*/
		Test test;
	}

	assert (one && two);
}
