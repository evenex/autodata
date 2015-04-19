import std.range.primitives;

auto head (R)(R r)
	{/*...}*/
		static if (is (typeof(r.front)))
			return r.front;
	}
auto tails (R)(R r)
	{/*...}*/
		static if (is (typeof(r.popFront)))
			{/*...}*/
				r.popFront;
				return [r];
			}
	}

struct List
	{/*...}*/
		auto head ()
			{/*...}*/
				return data;
			}
		List[] tails ()
			{/*...}*/
				if (next)
					return [*next];
				else return [];
			}
		bool empty ()
			{/*...}*/
				return false;
			}

		int data;
		List* next;
	}

void traverse (alias f, R)(R r)
	{/*...}*/
		if (r.empty)
			return;

		f (r.head);

		foreach (s; r.tails)
			traverse!f (s);
	}

void umain ()
	{/*...}*/
		auto list = List (5);
		list.next = new List (4);
		list.next.next = new List (3);

		import std.stdio;

		list.traverse!writeln;

		[1,2,3].traverse!writeln;
	}
