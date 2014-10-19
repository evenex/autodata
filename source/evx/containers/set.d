module evx.containers.set;

private {/*imports}*/
	import evx.operators.iteration;
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

		this (Items...)(Items items)
			{/*...}*/
				insert (items);
			}

		auto elements () const
			{/*...}*/
				return store.keys;
			}
		mixin IterationOps!elements;
	}
