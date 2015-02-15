module evx.adaptors.queue;

private {/*imports}*/
	import evx.range;
	import evx.operators;
	import evx.math;
	import evx.type;

	import evx.adaptors.policy;
}

struct Queue (R, OnOverflow overflow_policy = OnOverflow.error) // TODO implement overflow
	{/*...}*/
		R store;
		private size_t[2] limit;

		alias store this;

		auto length () const
			{/*...}*/
				auto i = limit.left, j = limit.right;

				if (i <= j)
					return j - i;
				else return (capacity - i) + j + 1;
			}

		auto capacity () const
			{/*...}*/
				return store.length;
			}
		auto capacity ()(size_t n)
			{/*...}*/
				void allocate ()() {store.allocate (n);}
				void set_length ()() {store.length = n;}

				if (capacity >= n)
					return;

				if (length > 0)
					assert (0, `cannot reserve memory for ` ~ R.stringof ~ ` when it contains data`);
				else Match!(allocate, set_length);
			}

		auto ref access (size_t i)
			{/*...}*/
				return store[(limit.left + i) % capacity];
			}

		void pull (R)(R range, size_t i)
			{/*...}*/
				pull (range, i, i+1);
			}
		void pull (R)(R range, size_t[2] interval)
			{/*...}*/
				auto i = (limit.left + interval.left) % capacity,
					j = (limit.left + interval.right) % capacity;

				if (i <= j)
					{/*...}*/
						auto pulled ()() {store[i..j] = range;}
						auto iterated ()() {foreach (k; i..j) store[k] = range[k-i];}

						Match!(pulled, iterated);
					}
				else {/*...}*/
					immutable C = capacity;

					auto wrapped_pulled ()() 
						{/*...}*/
							store[i..C] = range[0..C-i];
							store[0..j] = range[C-i..$];
						}
					auto wrapped_iterated ()()
						{/*...}*/
							foreach (k; i..C) store[k] = range[k-i];
							foreach (k; 0..j) store[k] = range[k-(C-i)];
						}

					Match!(wrapped_pulled, wrapped_iterated);
				}
			}

		/* push */
		auto ref opOpAssign (string op : `~`, S)(S range)
			if (not (is (S : Element!R)))
			in {/*...}*/
				assert (this.length + range.length <= this.capacity);
			}
			body {/*...}*/
				if (exit_on_overflow (range.length))
					return this;

				auto start = limit.right;

				limit.right += range.length;
				limit.right %= (capacity + 1);

				this[$-range.length..$] = range;

				return this;
			}
		auto ref opOpAssign (string op : `~`, T)(T element)
			if (is (T : Element!R))
			{/*...}*/
				if (exit_on_overflow (1))
					return this;

				++limit.right;
				limit.right %= (capacity + 1);

				this[$-1] = element;

				return this;
			}

		/* pop */
		auto ref opOpAssign (string op : `-`)(size_t count)
			in {/*...}*/
				assert (count < length);
			}
			body {/*...}*/
				limit.left += count + capacity;
				limit.left %= capacity;

				return this;
			}
		auto ref opUnary (string op : `--`)()
			{/*...}*/
				return this -= 1;
			}

		/* clear */
		auto clear ()
			{/*...}*/
				limit.left = limit.right = 0;
			}

		mixin TransferOps!(pull, access, length, RangeOps);

		private mixin OverflowPolicy;
	}
	unittest {/*...}*/
		auto A = Queue!(int[])();

		A.capacity = 5;

		A ~= 1;
		A ~= 2;

		assert (A[].length == 2);
		assert (A[] == [1,2]);

		A ~= [3,4];

		assert (A[] == [1,2,3,4]);

		A--;

		assert (A[] == [2,3,4]);

		A ~= 5;

		assert (A[] == [2,3,4,5]);

		A -= 2;

		assert (A[] == [4,5]);

		A ~= [6,7,8];

		assert (A[] == [4,5,6,7,8]);

		A[1..4] = [7,6,5];

		assert (A[] == [4,7,6,5,8]);

		A.clear;

		assert (A[].empty);

		A ~= 1;
		A ~= 2;
		A ~= [3,4,5];
		A -= 2;
		A ~= [6,7];

		assert (A[] == [3,4,5,6,7]);
	}
