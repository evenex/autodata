module evx.containers.adaptors.stack;

private {/*imports}*/
	import evx.range;
	import evx.operators;
	import evx.math;
	import evx.type;

	import evx.containers.adaptors.policy;
	import evx.containers.adaptors.capacity;
}

struct Stack (R, OnOverflow overflow_policy = OnOverflow.error)
	{/*...}*/
		R store;
		alias store this;

		mixin AdaptorCapacity;

		auto length () const
			{/*...}*/
				return _length;
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

				auto pulled ()() {store[i..j] = range;}
				auto iterated ()() {foreach (k; i..j) store[k] = range[k-i];}

				Match!(pulled, iterated);
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

				_length += range.length;

				this[$-range.length..$] = range;

				return this;
			}
		auto ref opOpAssign (string op : `~`, T)(T element)
			if (is (T : Element!R))
			{/*...}*/
				if (exit_on_overflow (1))
					return this;

				++_length;

				this[$-1] = element;

				return this;
			}

		/* pop */
		auto ref opOpAssign (string op : `-`)(size_t count)
			in {/*...}*/
				assert (count <= length,
					`attempted to pop ` ~ count.text ~ ` from ` ~ Stack.stringof ~ ` of length ` ~ length.text
				);
			}
			body {/*...}*/
				_length -= count;

				return this;
			}
		auto ref opUnary (string op : `--`)()
			{/*...}*/
				return this -= 1;
			}

		/* clear */
		auto clear ()
			{/*...}*/
				_length = 0;
			}

		mixin TransferOps!(pull, access, length, RangeOps);

		private mixin OverflowPolicy;
		private size_t _length;
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

		A ~= [1,2,3,4,5];
		A[1..4] = [4,3,2];

		assert (A[] == [1,4,3,2,5]);
	}