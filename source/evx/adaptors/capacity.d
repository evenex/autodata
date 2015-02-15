module evx.adaptors.capacity;

package template AdaptorCapacity ()
	{/*...}*/
		auto capacity () const
			{/*...}*/
				return store.length;
			}
		auto capacity ()(size_t n)
			{/*...}*/
				void move_and_allocate ()()
					{/*...}*/
						if (length > 0)
							{/*...}*/
								auto temp = R (this[]);
								store.allocate (n);
								store[0..temp[].length] = temp[];
							}
						else store.allocate (n);
					}
				void allocate ()()
					{/*...}*/
						if (length > 0)
							assert (0, `cannot reserve memory for ` ~ R.stringof ~ ` when it contains data`);

						store.allocate (n);
					}
				void set_length ()() {store.length = n;}

				if (capacity >= n)
					return;

				else Match!(set_length, move_and_allocate, allocate);
			}
	}
