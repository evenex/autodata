module evx.containers.m_array;

private {/*imports}*/
	import std.range;

	import evx.operators;
}


struct MallocBuffer (T)
	{/*...}*/
		import core.stdc.stdlib;

		private size_t _length;
		T* ptr;

		auto length () const
			{/*...}*/
				return _length;
			}
		auto allocate (size_t new_length)
			{/*...}*/
				free;

				ptr = cast(T*) malloc (new_length * T.sizeof);

				_length = new_length;
			}

		auto free ()
			{/*...}*/
				if (ptr)
					core.stdc.stdlib.free (ptr);

				_length = 0;
			}
	}

struct MArray (T)
	{/*...}*/
		MallocBuffer!T buffer;
		alias buffer this;
		
		mixin BufferOps!buffer;
	}
auto m_array (R)(R range)
	if (IterationTraits!R.is_iterable)
	{/*...}*/
		return MArray!(ElementType!R)(range);
	}
