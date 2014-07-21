module resource.array;

import std.range;
import utils;
import std.c.stdlib;

struct StaticArray (T)
	{/*...}*/
		public:
		public {/*[┄]}*/
			ref auto opIndex (size_t i) inout
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
		}
		public {/*range}*/
			ref auto front ()
				in {/*...}*/
					assert (length);
				}
				body {/*...}*/
					return this[].front;
				}
			ref auto back ()
				in {/*...}*/
					assert (length);
				}
				body {/*...}*/
					return this[].back;
				}
		}
		public {/*iteration}*/
			mixin IterateOver!opSlice;
		}
		public {/*ctor/dtor}*/
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
		}
		public {/*text}*/
			auto toString () const
				{/*...}*/
					import std.conv;

					static if (__traits(compiles, array[0..length].text))
						return array[0..length].text;
					else return `[` ~T.stringof~ `...]`;
				}
			auto text () const
				{/*...}*/
					return toString;
				}
		}
		public {/*data}*/
			const size_t length;
		}
		private:
		private {/*data}*/
			T* array;
		}
	}

struct DynamicArray (T)
	{/*...}*/
		public:
		public {/*[┄]}*/
			ref auto opIndex (size_t i) inout
				in {/*...}*/
					import std.conv;
					assert (i < length,
						i.text ~ ` exceeds DynamicArray! ` ~T.stringof~ ` length ` ~length.text
					);
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
		}
		public {/*~=}*/
			auto opOpAssign (string op: `~`)(ref T item)
				{/*...}*/
					++length;
					this[$-1] = item;
				}
			auto opOpAssign (string op: `~`)(lazy T item)
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
		}
		public {/*range}*/
			ref auto front ()
				in {/*...}*/
					assert (length);
				}
				body {/*...}*/
					return array.front;
				}
			ref auto back ()
				in {/*...}*/
					assert (length);
				}
				body {/*...}*/
					return array[length - 1];
				}
		}
		public @property {/*}*/
			auto capacity () const
				{/*...}*/
					return array.length;
				}
		}
		public {/*clear}*/
			auto clear ()
				{/*...}*/
					length = 0;
				}
		}
		public {/*iteration}*/
			mixin IterateOver!opSlice;
		}
		public {/*ctor}*/
			this (size_t capacity)
				{/*...}*/
					array = StaticArray!T (capacity);
				}
		}
		public {/*text}*/
			auto toString () const
				{/*...}*/
					import std.conv;

					static if (__traits(compiles, array[0..length].text))
						return array.array[0..length].text;
					else return `[` ~T.stringof~ `...]`;
				}
			auto text () const
				{/*...}*/
					return toString;
				}
		}
		public {/*data}*/
			size_t length = 0;
		}
		private:
		private {/*data}*/
			StaticArray!T array;
		}
		invariant () {/*...}*/
			import std.conv;
			assert (this.length <= array.length,
				`DynamicArray!` ~T.stringof~ ` of length ` ~this.length.text~ ` exceeded capacity ` ~array.length.text
			);
		}
	}
