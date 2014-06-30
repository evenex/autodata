module resource.directory;

import std.conv;
import std.traits;
import std.algorithm;
import std.range;

import utils;
import math;

/** 
	O(log(n)) lookup.
	O(n) insertion/removal.
	never reallocates.
	entries unique with respect to sorting function.
	capable of foreach iteration.
*/
class Directory (T, alias sorted = less_than!T)
	if (__traits(compiles, sorted (T.init, T.init)))
	{/*...}*/
		debug T* entries_ptr;

		T[] entries;
		invariant (){/*...}*/
			assert (entries.ptr == entries_ptr);
			assert (entries.isSorted!sorted,
				`entries became unsorted: ` ~entries.text
			);
		}

		this (size_t capacity)
			{/*...}*/
				entries.reserve (capacity);
				debug entries_ptr = entries.ptr;
			}

		public:
		public {/*iteration}*/
			int opApply (int delegate(ref T) op)
				{/*...}*/
					int result;

					foreach (ref entry; entries)
						{/*...}*/
							result = op (entry);

							if (result) 
								break;
						}

					return result;
				}
			int opApplyReverse (int delegate(ref T) op)
				{/*...}*/
					int result;

					foreach (ref entry; entries.retro)
						{/*...}*/
							result = op (entry);

							if (result) 
								break;
						}

					return result;
				}
		}
		public {/*mutation}*/
			auto append (T entry)
				in {/*...}*/
					assert (entries.capacity);
					assert (entries.length? sorted (entries.back, entry) : true,
						`attempted to append element out of order`
					);
					assert (not (this.contains (entry)),
						`attempted to add duplicate element ` ~entry.text
					);
				}
				body {/*...}*/
					entries ~= entry;
				}
			auto add (T entry)
				in {/*...}*/
					assert (entries.capacity);
					assert (not (this.contains (entry)),
						`attempted to add duplicate element ` ~entry.text
					);
				}
				body {/*...}*/
					auto i = search_for (entry);

					++entries.length;

					for (size_t j = entries.length-1; j > i; --j)
						entries[j] = entries[j-1];

					entries[i] = entry;
				}
			auto add (U...)(U entries)
				if (U.length > 1)
				in {/*...}*/
					foreach (u; U)
						static assert (is (u == T));
					assert (U.length <= this.entries.capacity);
				}
				body {/*...}*/
					foreach (ref entry; entries)
						add (entry);
				}
			auto remove (T entry)
				in {/*...}*/
					assert (this.contains (entry));
				}
				body {/*...}*/
					auto i = index_of (entry);
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
				}
		}
		public {/*access}*/
			ref auto get (T entry)
				in {/*...}*/
					assert (this.contains (entry));
				}
				body {/*...}*/
					return entries[index_of(entry)];
				}
		}
		public {/*search}*/
			auto index_of (T entry)
				{/*...}*/
					if (entries.empty)
						return -1L;

					auto i = search_for (entry);

					if (i == entries.length)
						return -1;
					else return entries[i].reflexively_equal (entry)? i : -1;
				}
			auto contains (T entry)
				{/*...}*/
					return index_of (entry) != -1;
				}
			auto up_to (T entry)
				{/*...}*/
					auto i = search_for (entry);
					return entries [0..i];
				}
			auto after (T entry)
				{/*...}*/
					auto i = search_for (entry);
					return i+1 < entries.length ?
						entries[i+1..$]:
						T[].init;
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
			override string toString ()
				{/*...}*/
					return entries.text;
				}
		}
		private:
		private {/*search}*/
			auto search_for (ref T entry) const
				{/*...}*/
					if (entries.empty)
						return 0;

					long min = 0;
					long max = entries.length;

					while (min < max)
						{/*...}*/
							auto mid = (max + min)/2;
							if (entries[mid].reflexively_equal (entry))
								return mid;
							else if (sorted (entry, entries[mid]))
								max = mid;
							else min = mid + 1;
						}

					return min;
				}
		}
	}

/**
	convenience function for sorting
*/
bool less_than (T)(const T a, const T b)
	{/*...}*/
		return a < b;
	}

unittest
	{/*...}*/
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
