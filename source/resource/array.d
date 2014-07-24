module resource.array;

import std.traits;
import std.range;
import utils;
import std.c.stdlib;

mixin template ArrayInterface (alias pointer, alias length)
	{/*...}*/
		public {/*assertions}*/
			static assert (is_indexable!(typeof(array)),
				`backing array must support indexing`
			);
			static assert (is_sliceable!(typeof(array)),
				`backing array must support slicing`
			);
		}
		public:
		public {/*[┄]}*/
			ref auto opIndex (size_t i) inout
				in {/*...}*/
					assert (i < length);
				}
				body {/*...}*/
					return this.array[i];
				}
			auto opSlice (size_t i, size_t j)
				in {/*...}*/
					assert (i <= j && j <= length);
				}
				body {/*...}*/
					return this.array[i..j];
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
		public {/*text}*/
			auto toString () const
				{/*...}*/
					import std.conv;

					static if (__traits(compiles, this.array[0..length].text))
						return this.array[0..length].text;
					else return `[` ~ElementType!(typeof(array)).stringof~ `...]`;
				}
			auto text () const
				{/*...}*/
					return toString;
				}
		}
	}

mixin template Malloc (alias pointer, alias size)
	if (is (typeof(pointer) == T*, T)
	&& is (typeof(size): size_t)
	&& is (typeof(size) == const))
	{/*...}*/
		public:

		this (size_t length)
			{/*...}*/
				alias T = typeof(*pointer);

				pointer = cast(T*)malloc (length * T.sizeof);

				size = length;
			}
		~this ()
			{/*...}*/
				free (cast(void*)pointer);
			}
		@disable this (this);
	}

struct Array (T)
	{/*...}*/
		public const size_t length;
		private T* array;

		mixin ArrayInterface!(array, length);
		mixin Malloc!(array, length);
	}

enum Destruction {immediate, deferred}
struct Dynamic (Array, Destruction destruction = Destruction.deferred)
	if (hasLength!Array)
	{/*...}*/
		alias T = ElementType!Array;
		public:
		public {/*[┄]}*/
			ref auto opIndex (size_t i) inout
				in {/*...}*/
					import std.conv;
					assert (i < length,
						i.text ~ ` exceeds Dynamic!(` ~Array.stringof~ `) length ` ~length.text
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
					static if (destruction == Destruction.immediate)
						foreach (ref item; this)
							item.destroy;
						
					length = 0;
				}
		}
		public {/*iteration}*/
			mixin IterateOver!opSlice;
		}
		public {/*ctor}*/
			static if (__traits(hasMember, Array, `__ctor`))
				this (ParameterTypeTuple!(Array.__ctor) args)
					in {/*}*/
						assert (length == 0);
					}
					out {/*}*/
						assert (length == 0);
					}
					body {/*...}*/
						array = Array (args);
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
			Array array;
		}
		invariant () {/*...}*/
			import std.conv;
			assert (this.length <= array.length,
				`Dynamic!(` ~T.stringof~ `) of length ` ~this.length.text~ ` exceeded capacity ` ~array.length.text
			);
		}
	}

unittest
	{/*...}*/
		mixin(report_test!`array`);
		import std.exception;

		auto S = Array!int (10);

		[0,1,2,3,4,5,6,7,8,9].copy (S[]);

		foreach (j, i; S)
			assert (i == j);

		auto D = Dynamic!(Array!int) (10);
		auto E = Dynamic!(int[10])();

		assert (E.length == 0 && D.length == 0);
		D ~= 1;
		assert (D.length == 1);
		E ~= [1,2,3];
		assert (E.length == 3);

		assert (D[].equal ([1]));
		assert (E[].equal ([1,2,3]));

		D.clear;
		assert (D.length == 0);

		D ~= S[];
		assert (D[].equal (S[]));
		assertThrown!Error (D ~= S[]);
	}
