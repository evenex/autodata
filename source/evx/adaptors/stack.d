module evx.adaptors.stack;

private {/*imports}*/
	import evx.range;
	import evx.operators;
	import evx.math;
}

struct Stack (R)
	{/*...}*/
		R base;
		private size_t _length;

		alias base this;

		auto length () const
			{/*...}*/
				return _length;
			}

		auto capacity ()
			{/*...}*/
				return base.length;
			}
		auto capacity ()(size_t n)
			{/*...}*/
				if (capacity >= n)
					return;

				if (length > 0)
					assert (0, `cannot reserve memory for ` ~R.stringof~ ` when it contains data`);
				else base.length = n;
			}

		auto ref access (size_t i)
			{/*...}*/
				return base[i];
			}

		void pull (R)(R range, size_t i, size_t j)
			{/*...}*/
				foreach (k; i..j)
					base[k] = range[k-i];
			}

		/* push */
		auto opOpAssign (string op : `~`, S)(S range)
			in {/*...}*/
				assert (this.length + range.length <= this.capacity);
			}
			body {/*...}*/
				auto start = length;

				_length += range.length;

				base[start.._length] = range;
			}
		auto opOpAssign (string op : `~`)(ElementType!R element)
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
