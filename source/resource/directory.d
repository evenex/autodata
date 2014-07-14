module resource.directory;

import std.conv;
import std.traits;
import std.typetuple;
import std.algorithm;
import std.range;

import resource.array;

import utils;
import math;

/** Directory
	O(log(n)) lookup.
	O(n) insertion/removal.
	never reallocates.
	entries unique with respect to sorting function.
	capable of foreach iteration.

	the second template parameter may either be a comparison function on T
	or a Key type which has a < operator
*/

struct Directory (T, Arg...)
	if (Arg.length == 0 
	|| (Arg.length == 1 && allSatisfy!(Or!(is_comparable, is_comparison_function), Arg)))
	{/*...}*/
		public {/*definitions}*/
			/* Key */
			static if (Arg.length == 0)
				{enum lookup = `by item`;/*}*/
					alias Key = T;
				}
			else static if (is_comparable!(Arg[0]) && not (is_comparison_function!(Arg[0])))
				{enum lookup = `by key`;/*}*/
					alias Key = Arg[0];
				}
			else {enum lookup = `by item`;/*}*/
				alias Key = T;
			}

			/* Entry */
			static if (lookup is `by item`)
				{/*...}*/
					alias Entry = T;
				}
			else static if (lookup is `by key`)
				{/*...}*/
					alias Entry = Tuple!(Key, T);
				}
			else static assert (0);

			/* compare */
			static if (lookup is `by item`)
				{/*...}*/
					static if (Arg.length == 0)
						alias compare = less_than!T;

					else static if (is_comparison_function!(Arg[0]))
						alias compare = Arg[0];
					
					else static assert (0);
				}
			else static if (lookup is `by key`)
				{/*...}*/
					static auto compare (ref const Entry a, ref const Entry b)
						{/*...}*/
							return a[0] < b[0];
						}
				}
			else static assert (0);

			/* search */
			auto search_for (Key key)
				{/*...}*/
					static if (lookup is `by item`)
						{/*...}*/
							return entries.binary_search!compare (key);
						}
					else static if (lookup is `by key`)
						{/*...}*/
							return entries.binary_search!(compare, EqualityPolicy.reflexive) (Entry (key, T.init));
						}
					else static assert (0);
				}
		}

		this (size_t capacity)
			{/*...}*/
				_entries = DynamicArray!Entry (capacity);
			}

		public:
		public {/*iteration}*/
			int opApply (int delegate(ref T) op)
				{/*...}*/
					int result;

					foreach (ref entry; entries)
						{/*...}*/
							static if (lookup is `by item`)
								result = op (entry);
							else static if (lookup is `by key`)
								result = op (entry[1]);
							else static assert (0);

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
							static if (lookup is `by item`)
								result = op (entry);
							else static if (lookup is `by key`)
								result = op (entry[1]);
							else static assert (0);

							if (result) 
								break;
						}

					return result;
				}
		}
		public {/*mutation}*/
			static if (lookup is `by key`)
				{/*add/append}*/
					auto append (Key key, T entry)
						{/*...}*/
							append (τ(key, entry));
						}
					auto add (Key key, T entry)
						{/*...}*/
							add (τ(key, entry));
						}
				}

			auto append (Entry entry)
				in {/*...}*/
					assert (_entries.capacity);
					assert (entries.length? compare (entries.back, entry) : true,
						`attempted to append entry out of order `
						~entries.back.text~ ` ~ ` ~entry.text
					);
					static if (lookup is `by item`)
						auto exists = this.contains (entry);
					else static if (lookup is `by key`)
						auto exists = this.contains (entry[0]);
					else static assert (0);

					assert (not (exists),
						`attempted to add duplicate entry ` ~entry.text
					);
				}
				body {/*...}*/
					_entries ~= entry;
				}

			auto add (Entry entry)
				in {/*...}*/
					assert (_entries.capacity);

					static if (lookup is `by item`)
						auto exists = this.contains (entry);
					else static if (lookup is `by key`)
						auto exists = this.contains (entry[0]);
					else static assert (0);

					assert (not (exists),
						`attempted to add duplicate entry ` ~entry.text
					);
				}
				body {/*...}*/
					static if (lookup is `by item`)
						auto result = search_for (entry);
					else static if (lookup is `by key`)
						auto result = search_for (entry[0]);
					else static assert (0);

					auto i = result.position;
					
					_entries.shift_up_from (i);

					entries[i] = entry;
				}

			auto add (U...)(U entries)
				if (U.length > 1)
				in {/*...}*/
					foreach (u; U)
						static assert (is (u == Entry));
					assert (U.length <= _entries.capacity,
						`added length ` ~U.length.text~ ` exceeds capacity ` ~_entries.capacity.text
					);
				}
				body {/*...}*/
					foreach (ref entry; entries)
						add (entry);
				}

			auto remove (Key key)
				in {/*...}*/
					assert (this.contains (key),
						`attempt to remove nonexistent entry ` ~key.text~ `
							current entries: ` ~entries.text
					);
				}
				body {/*...}*/
					auto i = index_of (key);
					this.remove_at (i);
				}

			auto remove_at (size_t index)
				in {/*...}*/
					assert (index < entries.length);
				}
				body {/*...}*/
					_entries.shift_down_on (index);
				}

			auto clear ()
				{/*...}*/
					_entries.length = 0;
					assert (_entries.capacity);
				}
		}
		public {/*access}*/
			ref auto opIndex (U...)(U key)
				if (__traits(compiles, Key (key)))
				{/*...}*/
					return get (Key (key));
				}
			ref auto opIndex (Key key)
				{/*...}*/
					return get (key);
				}
			ref auto get (Key key)
				in {/*...}*/
					assert (this.contains (key));
				}
				body {/*...}*/
					static if (lookup is `by item`)
						return *search_for (key).found;
					else static if (lookup is `by key`)
						return (*search_for (key).found)[1];
					else static assert (0);
				}
			ref auto front ()
				in {/*...}*/
					assert (size > 0);
				}
				body {/*...}*/
					return _entries[0];
				}
			ref auto back ()
				in {/*...}*/
					assert (size > 0);
				}
				body {/*...}*/
					return _entries[$-1];
				}
		}
		public {/*search}*/
			auto index_of (Key key)
				{/*...}*/
					auto entry = search_for (key);

					if (entry.found)
						return entry.position;
					else return -1;
				}
			auto opBinaryRight (string op: `in`, U)(U key)
				{/*...}*/
					static if (is (U: Key))
						return search_for (key).found;
					else static if (__traits(compiles, Key (key)))
						return search_for (Key (key)).found;

					else static assert (0, `cannot lookup ` ~U.stringof~ ` in ` ~typeof(this).stringof);
				}
			auto contains (Key key)
				{/*...}*/
					return key in this;
				}
			auto up_to (Key key)
				{/*...}*/
					auto result = search_for (key);

					return entries [0..result.position];
				}
			auto after (Key key)
				{/*...}*/
					auto result = search_for (key);

					auto i = result.position;

					if (result.found)
						return entries [i+1..$];
					else return entries [i..$];
				}
		}
		const @property {/*}*/
			auto size ()
				{/*...}*/
					return _entries.length;
				}
			auto capacity ()
				{/*...}*/
					return _entries.capacity;
				}
			auto toString ()
				{/*...}*/
					return _entries.toString;
				}
			auto text ()
				{/*...}*/
					return toString;
				}
		}
		private:
		private {/*data}*/
			@property auto entries ()
				{/*...}*/
					return _entries[];
				}
			DynamicArray!Entry _entries;
		}
		debug {/*}*/
		//version (unittest) {/*}*/ TODO
			public auto view_entries ()
				{/*...}*/
					return _entries[];
				}
		}
	}

unittest
	{/*search}*/
		auto test = Directory!(int, (int a, int b) => a < b) (5);

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
		mixin(report_test!`directory add/remove`);

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

		foreach (i; test.size..test.capacity)
			test.add (i.to!int);

		assert (test.size == test.capacity);
		assertThrown!Error (test.append (9999));
	}
