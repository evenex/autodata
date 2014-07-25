module resource.array;

import std.c.stdlib;

import meta;

struct Array (T)
	{/*...}*/
		public const size_t length;

		this (size_t length)
			{/*...}*/
				this.length = length;

				array = cast(T*)malloc (length * T.sizeof);
			}
		~this ()
			{/*...}*/
				free (cast(void*)array);
			}
		@disable this (this);

		mixin ArrayInterface!(array, length);

		private T* array;
	}
