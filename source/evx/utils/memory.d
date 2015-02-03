module evx.utils.memory;

private {/*imports}*/
	import std.algorithm;
	import std.conv;

	import evx.math.logic;
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

		T.init.bytes.blit (src.bytes); // REVIEW commit msg: fixed latent rvalue move bug
	}

/* forward an argument, as lvalue or rvalue reference 
*/
template forward (alias symbol)
	{/*...}*/
		static if (__traits(isRef, symbol))
			alias forward = symbol;
		else auto forward ()
			{/*...}*/
				typeof(symbol) value;
				move (symbol, value);
				
				return value;
			}
	}

import evx.type;
template forward2 (Aliases...) // BUG https://issues.dlang.org/show_bug.cgi?id=14096
	{/*...}*/
		auto ref f (uint i)()
			{/*...}*/
				return forward!(Aliases[i]);
			}

		alias forward2 = Map!(f, Count!Aliases);
	}

/* a borrowed resource bypasses RAII and move semantics 
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

				return this;
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