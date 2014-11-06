module evx.adaptors.appendable;

private {/*imports}*/
	import evx.range;
	import evx.operators;
	import evx.math;
}

struct Appendable (R)
	if (is(R.TransferTraits))
	{/*...}*/
		private {/*base}*/
			struct Base
				{/*...}*/
					R base;
					private size_t _length;

					mixin BufferOps!base;

					auto length () const
						{/*...}*/
							return _length;
						}

					auto capacity ()
						{/*...}*/
							return base.length;
						}
					auto capacity ()(size_t n)
						if (BufferTraits.has_variable_length)
						{/*...}*/
							static if (BufferTraits.can_assign_length)
								{/*...}*/
									if (capacity < n)
										base.length = n;
								}
							else static if (BufferTraits.can_allocate)
								{/*...}*/
									if (length > 0)
										assert (0, `cannot reserve memory for ` ~R.stringof~ ` when it contains data`);
									else base.allocate (n);
								}
							else static assert (0);
						}
				}
		}
		Base buffer;

		/* push */
		auto opOpAssign (string op : `~`, S)(S range)
			in {/*...}*/
				assert (this.length + range.length <= this.capacity);
			}
			body {/*...}*/
				auto start = this.length;

				buffer._length = this.length + range.length;

				this[start..$] = range;
			}
		auto opOpAssign (string op : `~`)(ElementType!R element)
			{/*...}*/
				++buffer._length;

				this[$-1] = element;
			}

		/* pop */
		auto opOpAssign (string op : `-`)(size_t count)
			in {/*...}*/
				assert (count < length);
			}
			body {/*...}*/
				buffer._length = this.length - count;
			}
		auto opUnary (string op : `--`)()
			{/*...}*/
				this -= 1;
			}

		static if (is(R.BufferTraits))
			auto ref opAssign (R)(R that)
				{/*...}*/
					buffer.base = that;

					_length = min (length, buffer.capacity);

					return this;
				}

		mixin TransferOps!buffer;
	}
	unittest {/*...}*/
		import evx.containers;

		auto A = Appendable!(MArray!int)();

		A.capacity = 100;

		A ~= 1;
		A ~= 2;

		assert (A[] == [1,2]);

		A ~= [3,4];

		assert (A[] == [1,2,3,4]);

		A--;

		assert (A[] == [1,2,3]);

		A -= 2;

		assert (A[] == [1]);

		A = null;

		assert (A[].empty);
	}
