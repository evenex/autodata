module evx.set;

import evx.meta;

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

		this (Items...)(Items items)
			{/*...}*/
				insert (items);
			}

		auto keys () const
			{/*...}*/
				return store.keys;
			}
		mixin IterateOver!keys;
	}
