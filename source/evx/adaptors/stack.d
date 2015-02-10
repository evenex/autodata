module evx.adaptors.stack;

private {/*imports}*/
	import evx.range;
	import evx.operators;
	import evx.math;
	import evx.type;
}

struct Stack (R)
	{/*...}*/
		R store;
		private size_t _length;

		alias store this;

		auto length () const
			{/*...}*/
				return _length;
			}

		auto capacity ()
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
					assert (0, `cannot reserve memory for ` ~R.stringof~ ` when it contains data`);
				else Match!(allocate, set_length);
			}

		auto ref access (size_t i)
			{/*...}*/
				return store[i];
			}

		void pull (R)(R range, size_t i)
			{/*...}*/
				pull (range, i, i+1);
			}
		void pull (R)(R range, size_t[2] interval)
			{/*...}*/
				auto i = interval.left, j = interval.right;

				auto pulled ()() {store[interval.left..interval.right] = range;}
				auto iterated ()() {foreach (k; i..j) store[k] = range[k-i];}

				Match!(pulled, iterated);
			}

		/* push */
		auto opOpAssign (string op : `~`, S)(S range)
			if (not (is (S : Element!R)))
			in {/*...}*/
				assert (this.length + range.length <= this.capacity);
			}
			body {/*...}*/
				auto start = length;

				_length += range.length;

				store[start.._length] = range;
			}
		auto opOpAssign (string op : `~`, T)(T element)
			if (is (T : Element!R))
			{/*...}*/
				++_length;

				this[$-1] = element;
			}

		/* pop */
		auto opOpAssign (string op : `-`)(size_t count)
			in {/*...}*/
				assert (count < length);
			}
			body {/*...}*/
				_length -= count;
			}
		auto opUnary (string op : `--`)()
			{/*...}*/
				this -= 1;
			}

		/* clear */
		auto clear ()
			{/*...}*/
				_length = 0;
			}

		mixin TransferOps!(pull, access, length, RangeOps);
	}
	unittest {/*...}*/
		auto A = Stack!(int[])();

		A.capacity = 100;

		A ~= 1;
		A ~= 2;

		assert (A[].length == 2);
		assert (A[] == [1,2]);

		A ~= [3,4];

		assert (A[] == [1,2,3,4]);

		A--;

		assert (A[] == [1,2,3]);

		A -= 2;

		assert (A[] == [1]);

		A.clear;

		assert (A[].empty);
	}
