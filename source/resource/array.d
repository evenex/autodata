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
			mixin ForwardForEach!opSlice;
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

					static if (isInputRange!(T[]))
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
		public {/*iteration}*/
			int opApply (int delegate(ref T) op)
				{/*...}*/
					int result;

					for (auto i = 0; i < length; ++i)
						{/*...}*/
							result = op (array[i]);

							if (result) 
								break;
						}

					return result;
				}
			int opApply (int delegate(size_t, ref T) op)
				{/*...}*/
					int result;

					for (auto i = 0; i < length; ++i)
						{/*...}*/
							result = op (i, array[i]);

							if (result) 
								break;
						}

					return result;
				}
			int opApply (int delegate(ref const T) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(ref T)) op);
				}
			int opApply (int delegate(const size_t, ref const T) op) const
				{/*...}*/
					return (cast()this).opApply (cast(int delegate(size_t, ref T)) op);
				}
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

					static if (isInputRange!(T[]))
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
			assert (this.length <= array.length);
		}
	}
