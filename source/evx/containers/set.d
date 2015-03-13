module evx.containers.set;
version(none):

private {/*imports}*/
	import evx.operators;
}

struct Set (T)
	{/*...}*/
		private byte[0][T] store;

		auto insert (Items...)(Items items)
			{/*...}*/
				foreach (item; items)
					store[item] = [];
			}
		auto remove (Items...)(Items items)
			{/*...}*/
				foreach (item; items)
					store.remove (item);
			}
		auto contains (T item)
			{/*...}*/
				return item in store;
			}

		this (Items...)(Items items)
			{/*...}*/
				insert (items);
			}

		auto elements () const
			{/*...}*/
				return store.keys;
			}
		mixin IterationOps!elements;
		mixin SearchOps!contains;
	}
	unittest {/*...}*/
		import evx.math.logic;

		Set!int A;

		A.insert (1);
		A.insert (3);

		assert (A.contains (1));
		assert (1 in A);
		assert (3 in A);

		assert (4 !in A);

		A.remove (1);
		assert (not (A.contains (1)));

		A.remove (3);
		assert (3 !in A);
	}
