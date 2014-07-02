module resource.directory;

import std.conv;
import std.traits;
import std.typetuple;
import std.algorithm;
import std.range;

import resource.array;

import utils;
import math;

// TODO document sorting options
/** Directory
	O(log(n)) lookup.
	O(n) insertion/removal.
	never reallocates.
	entries unique with respect to sorting function.
	capable of foreach iteration.
*/

struct Directory (T, Arg...)
	if (Arg.length == 0 
	|| (Arg.length == 1 && allSatisfy!(templateOr!(is_comparable, is_comparison_function), Arg)))
	{/*...}*/
		private {/*definitions}*/
			/* Key */
			static if (Arg.length == 0)
				alias Key = T;
			else static if (is_comparable!(Arg[0]))
				alias Key = Arg[0];
			else alias Key = T;

			/* sorted */
			static if (Arg.length == 0)
				alias sorted = less_than!T;
			else static if (not (is (Key == T)))
				alias sorted = less_than!Key;
			else static if (is_comparison_function!(Arg[0]))
				alias sorted = Arg[0];
			else static assert (0);
		}

		this (size_t capacity)
			{/*...}*/
				entries = StaticArray!Entry (capacity);
			}

		public:
		public {/*iteration}*/
			int opApply (int delegate(ref T) op)
				{/*...}*/
					int result;

					foreach (ref element; entries)
						{/*...}*/
							result = op (element);

							if (result) 
								break;
						}

					return result;
				}
			int opApplyReverse (int delegate(ref T) op)
				{/*...}*/
					int result;

					foreach (ref element; entries.retro)
						{/*...}*/
							result = op (element);

							if (result) 
								break;
						}

					return result;
				}
		}
		public {/*mutation}*/
			auto append (T element)
				in {/*...}*/
					assert (entries.capacity);
					assert (entries.length? sorted (entries.back, element) : true,
						`attempted to append element out of order`
					);
					assert (not (this.contains (element)),
						`attempted to add duplicate element ` ~element.text
					);
				}
				body {/*...}*/
					entries ~= element;
				}
			auto add (T element)
				in {/*...}*/
					assert (entries.capacity);
					assert (not (this.contains (element)),
						`attempted to add duplicate element ` ~element.text~
						` (existing: ` ~get (element).text~ `)`
					);
				}
				body {/*...}*/
					auto result = search_for (element);
					assert (result[0] == before);
					auto i = result[1];

					++entries.length;

					for (size_t j = entries.length-1; j > i; --j)
						entries[j] = entries[j-1];

					entries[i] = element;
				}
			auto add (U...)(U entries)
				if (U.length > 1)
				in {/*...}*/
					foreach (u; U)
						static assert (is (u == T));
					assert (U.length <= this.entries.capacity,
						`added length ` ~U.length.text~ ` exceeds capacity ` ~this.entries.capacity.text
					);
				}
				body {/*...}*/
					foreach (ref element; entries)
						add (element);
				}
			auto remove (T element)
				in {/*...}*/
					assert (this.contains (element),
						`attempt to remove nonexistent element ` ~element.text~ `
							current entries: ` ~entries.text
						
					);
				}
				body {/*...}*/
					auto i = index_of (element);
					this.remove_at (i);
				}
			auto remove_at (size_t index)
				in {/*...}*/
					assert (index < entries.length);
				}
				body {/*...}*/
					for (size_t i = index; i < entries.length-1; ++i)
						entries[i] = entries[i+1];
						
					--entries.length;
				}
			auto clear ()
				{/*...}*/
					entries.length = 0;
					assert (entries.capacity);
				}
		}
		public {/*access}*/
			ref auto get (T element)
				in {/*...}*/
					assert (this.contains (element));
				}
				body {/*...}*/
					return *entries.binary_search (element).found;
				}
		}
		public {/*search}*/
			auto index_of (T element)
				{/*...}*/
					auto entry = entries.binary_search (element);

					if (entry.found)
						return entry.position;
					else return -1;
				}
			auto contains (T element)
				{/*...}*/
					return entries.binary_search (element).found;
				}
			auto up_to (T element)
				{/*...}*/
					auto result = entries.binary_search (element);

					assert (result.found);

					return entries [0..result.position];
				}
			auto after (T element)
				{/*...}*/
					auto result = entries.binary_search (element);

					auto i = result.position;

					if (result.found)
						return entries [i+1..$];
					else entries [i..$];
				}
		}
		const @property {/*}*/
			auto size ()
				{/*...}*/
					return entries.length;
				}
			auto capacity ()
				{/*...}*/
					return entries.capacity;
				}
			string toString ()
				{/*...}*/
					return entries.text;
				}
		}
		private:
		private {/*data}*/
			@property auto entries ()
				{/*...}*/
					return _entries[];
				}
			alias Entry = Tuple!(Key, T);
			DynamicArray!Entry _entries;
		}
		debug {/*}*/
		//version (unittest) {/*}*/ TODO
			public auto view_entries () const
				{/*...}*/
					return entries[];
				}
		}
	}

unittest//void main ()
	{/*search}*/
		scope test = new Directory!(int, (int a, int b) => a < b) (5);

		test.add (1,2,3,4,5);

		assert (test.up_to (0).empty);
		assert (test.up_to (1).empty);
		assert (test.up_to (2).equal ([1]));
		assert (test.up_to (3).equal ([1, 2]));
		assert (test.up_to (4).equal ([1, 2, 3]));
		assert (test.up_to (5).equal ([1, 2, 3, 4]));
		assert (test.up_to (6).equal ([1, 2, 3, 4, 5]));
		assert (test.after (0).equal ([1, 2, 3, 4, 5]));
		assert (test.after (1).equal ([2, 3, 4, 5]));
		assert (test.after (2).equal ([3, 4, 5]));
		assert (test.after (3).equal ([4, 5]));
		assert (test.after (4).equal ([5]));
		assert (test.after (5).empty);
		assert (test.after (6).empty);

		test.clear;

		test.add (2,4,6,8);
		assert (test.up_to (1).empty);
		assert (test.up_to (2).empty);
		assert (test.up_to (3).equal ([2]));
		assert (test.up_to (4).equal ([2]));
		assert (test.up_to (5).equal ([2, 4]));
		assert (test.up_to (6).equal ([2, 4]));
		assert (test.up_to (8).equal ([2, 4, 6]));
		assert (test.after (1).equal ([2, 4, 6, 8]));
		assert (test.after (2).equal ([4, 6, 8]));
		assert (test.after (3).equal ([4, 6, 8]));
		assert (test.after (4).equal ([6, 8]));
		assert (test.after (5).equal ([6, 8]));
		assert (test.after (6).equal ([8]));
		assert (test.after (8).empty);
	}

unittest
	{/*add/remove}*/
		import std.exception;

		scope test = new Directory!(int, (int a, int b) => a < b) (8);
		assert (test.capacity >= 8);

		test.append (4);
		assertThrown!Error (test.append (3));
		test.append (5);

		test.add (3);
		test.add (7);
		assertThrown!Error (test.add (4));
		test.add (2,1,8,6);

		assert (test.entries.equal ([1,2,3,4,5,6,7,8]));

		foreach (i; 1..9)
			if (i%2) test.remove (i);

		assert (test.entries.equal ([2,4,6,8]));

		test.clear;

		foreach (i; 0..test.capacity)
			test.add (i.to!int);

		assert (test.capacity == 0);
		assertThrown!Error (test.append (9999));
	}
