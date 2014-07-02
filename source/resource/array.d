module resource.array;

import std.c.stdlib;

struct StaticArray (T)
	{/*...}*/
		this (size_t length)
			{/*...}*/
				array = cast(T*)malloc (length * T.sizeof);
				this.length = length;
			}
		~this ()
			{/*...}*/
				free (cast(void*)array);
			}
		@disable this (this);

		ref auto opIndex (size_t i)
			in {/*...}*/
				assert (i < length);
			}
			body {/*...}*/
				return array[i];
			}
		auto opSlice (size_t i, size_t j)
			in {/*...}*/
				assert (i <= j && j <= length);
			}
			body {/*...}*/
				return array[i..j];
			}
		auto opSlice ()
			{/*...}*/
				return this[0..$];
			}
		auto opDollar () const
			{/*...}*/
				return length;
			}

		T* array;
		size_t length;
	}

struct DynamicArray (T)
	{/*...}*/
		StaticArray!T array;
		size_t length = 0;

		this (size_t capacity)
			{/*...}*/
				array = StaticArray!T (capacity);
			}
		auto capacity ()
			{/*...}*/
				return array.length;
			}

		ref auto opIndex (size_t i)
			in {/*...}*/
				assert (i < length);
			}
			body {/*...}*/
				return array[i];
			}
		auto opSlice (size_t i, size_t j)
			in {/*...}*/
				assert (i <= j && j <= length);
			}
			body {/*...}*/
				return array[i..j];
			}
		auto opSlice ()
			{/*...}*/
				return this[0..$];
			}
		auto opDollar () const
			{/*...}*/
				return length;
			}

		auto opOpAssign (string op: `~`)(T item)
			{/*...}*/
				++length;
				this[$-1] = item;
			}
		auto opOpAssign (string op: `~`, R)(R range)
			if (isForwardRange!R)
			{/*...}*/
				auto save = range.save;
				auto start = this.length;
				this.length += save.length;
				range.copy (this[start..$]);
			}

		invariant () {/*...}*/
			assert (this.length <= array.length);
		}
	}
