import std.traits;
import evx.math;
import std.conv;


struct BufferInfo (T)
	{/*...}*/
		enum has_element = is(T.ElementType);

		enum can_access = __traits(compiles, T.init.access (0) = T.ElementType.init);

		enum can_resize = __traits(compiles, T.init.resize (0) == true);
		enum can_nullify = __traits(compiles, T.init.nullify);

		enum can_passive_copy = __traits(compiles, T.init.copy_from (T.ElementType[].init, 0, 0));
		enum can_active_copy = __traits(compiles, T.init.copy_to (T.ElementType[].init, 0, 0));

		enum supports_buffer_interface = has_element && can_access && can_resize && can_nullify && can_passive_copy;

	}
string show_ct_info (T)()
	{/*...}*/
		string report = T.stringof~ `:`"\n";

		foreach (member; __traits(allMembers, T))
			static if (mixin(q{is(typeof(T.} ~member~ q{ == true))}))
			mixin(q{
				report ~= }`"` ~member~ `"`q{~ ` = ` ~(T.} ~member~ q{? "true":"false")~"\n";
			});

		return report;
	}

// we will use size_t for indexing... irregular indexing will have to be mixed in or wrapped, by supplying f: ℕ → ℝ
mixin template BufferInterface ()
	{/*...}*/
		static assert (BufferInfo!(typeof(this)).supports_buffer_interface,
			`does not support buffer interface: ` ~show_ct_info!(BufferInfo!(typeof(this)))
		);

		alias This = typeof(this);

		public:
		public {/*range}*/
			auto front ()
				{/*...}*/
					return this[0];
				}
			auto back ()
				{/*...}*/
					return this[$-1];
				}

			auto empty ()
				{/*...}*/
					return length == 0;
				}

			@property length () const
				{/*...}*/
					return _length;
				}
			alias opDollar = length;
		}
		public {/*assignment}*/
			auto opAssign (R)(R range)
				{/*...}*/
					this = null;

					if (this.resize (range.length))
						this._length = range.length;
					else assert (0, `failed to resize ` ~typeof(this).stringof~ ` to ` ~length.text);

					this[] = range;
				}

			auto opAssign (typeof(null))
				{/*...}*/
					this.nullify;

					_length = 0;
				}
		}
		public {/*opIndex*}*/
			auto ref opIndex (size_t i)
				{/*...}*/
					return access (i);
				}

			auto opIndex ()
				{/*...}*/
					return this[0..$];
				}
			auto opIndex (Slice slice)
				{/*...}*/
					return Sub (&sub_access, [slice[0], slice[1]]);
				}

			auto opIndexAssign (R)(R range)
				{/*...}*/
					this[0..$] = range;
				}
			auto opIndexAssign (R)(R range, Slice slice)
				{/*...}*/
					auto i = slice[0];
					auto j = slice[1];

					static if (BufferInfo!R.can_active_copy)
						range.copy_to (this, i, j);
					else this.copy_from (range, i, j);
				}

			auto opIndexAssign (ElementType element, size_t i)
				{/*...}*/
					this.access (i) = element;
				}
			auto opIndexAssign (ElementType element, Slice slice)
				{/*...}*/
					foreach (i; slice[0]..slice[1])
						this.access (i) = element;
				}
		}
		public {/*slicing}*/
			Slice opSlice (size_t dim: 0)(size_t i, size_t j)
				{/*...}*/
					return [i,j];
				}

			alias Slice = size_t[2];
		}
		public {/*sub buffers}*/
			struct Sub
				{/*...}*/
					public:
					public {/*range}*/
						auto ref front ()
							{/*...}*/
								return *access (bounds[0]);
							}
						auto ref back ()
							{/*...}*/
								return *access (bounds[1] - 1);
							}

						auto popFront ()
							{/*...}*/
								++bounds[0];
							}
						auto popBack ()
							{/*...}*/
								--bounds[1];
							}

						auto empty ()
							{/*...}*/
								return bounds[0] == bounds[1];
							}

						auto length ()
							{/*...}*/
								return bounds.interval.length;
							}
						alias opDollar = length;
					}
					public {/*equality}*/
						bool opEquals (R)(R range)
							{/*...}*/
								if (bounds.interval.size != range.length)
									return false;

								import std.range;

								return this.equal (range);
							}
					}
					public {/*opIndex*}*/
						auto ref opIndex (size_t i)
							{/*...}*/
								return *access (bounds[0] + i);
							}

						auto opIndex ()
							{/*...}*/
								return this;
							}
						auto opIndex (Slice slice)
							in {/*...}*/
								assert ((slice.vector + bounds[0]).array.interval.is_contained_in (this.bounds.interval));
							}
							body {/*...}*/
								return Sub (access, [bounds[0] + slice[0], bounds[0] + slice[1]]);
							}

						auto opIndexAssign (R)(R range)
							{/*...}*/
								this[0..$] = range;
							}
						auto opIndexAssign (R)(R range, Slice slice)
							{/*...}*/
								import evx.traits: is_indexable;

								auto subrange = opIndex (slice);

								foreach (i; subrange.bounds[0]..subrange.bounds[1])
									static if (is_indexable!R)
										*access (i) = range[i - subrange.bounds[0]];
									else {/*...}*/
										*access (i) = range.front;
										range.popFront;
									}
							}

						auto opIndexAssign (ElementType element, size_t i)
							{/*...}*/
								*access (bounds[0] + i) = element;
							}
						auto opIndexAssign (ElementType element, Slice slice)
							{/*...}*/
								auto subrange = opIndex (slice);

								foreach (i; subrange.bounds[0]..subrange.bounds[1])
									*access (i) = element;
									// sub can pack a ptr to buf and a set of functions that cast and call... saves space.
							}
					}
					public {/*slicing}*/
						Slice opSlice (size_t dim: 0)(size_t i, size_t j)
							{/*...}*/
								return [i,j];
							}
					}
					private:
					private {/*data}*/
						ElementType* delegate(size_t) access;
						size_t[2] bounds;
					}
				}
		}
		public {/*appending}*/
			auto opOpAssign (string op: `~`)(ElementType element)
				{/*...}*/
					if (not (this.resize (length + 1)))
						assert (0, `failed to resize ` ~This.stringof);

					++_length;

					this[$-1] = element;
				}
			auto opOpAssign (string op: `~`, R)(R range)
				{/*...}*/
					auto start = length;

					if (not (this.resize (length + range.length)))
						assert (0, `failed to resize ` ~This.stringof);

					_length = start + range.length;

					this[start..$] = range;
				}
		}
		public {/*popping}*/
			auto pop (size_t count = 1)
				{/*...}*/
					_length -= count;
				}
		}
		private:
		private {/*sub access}*/
			auto sub_access (size_t i)
				{/*...}*/
					return &access (i);
				}
		}
		private {/*data}*/
			size_t _length;
		}
	}

void main ()
	{/*...}*/
		struct Buffer
			{/*...}*/
				alias ElementType = int;

				int[666] array;

				public {/*array subinterface}*/
					ref access (size_t i)
						{/*...}*/
							return array[i];
						}
					auto resize (size_t i)
						{/*...}*/
							return i <= 666;
						}
					void nullify ()
						{/*...}*/
							
						}

					void copy_from (R)(R range, size_t i, size_t j)
						{/*...}*/
							import std.algorithm: copy;

							range.copy (array[i..j]);
						}
				}

				mixin BufferInterface;
			}

		Buffer test;

		test = [1,2,3];

		assert (test.length == 3);

		// static range primitives
		assert (test.front == 1);
		assert (test.back == 3);

		// element access
		assert (test[0] == 1);
		assert (test[1] == 2);
		assert (test[2] == 3);
		assert (test[$-1] == 3);

		// slice equality
		assert (test[0..1] == [1]);
		assert (test[1..3] == [2,3]);
		assert (test[0..$] == [1,2,3]);

		// slice equivalence
		assert (test[] == [1,2,3]);
		assert (test[].front == test.front);
		assert (test[].back == test.back);
		assert (test[][0] == test[0]);
		assert (test[][1] == test[1]);
		assert (test[][2] == test[2]);
		assert (test[][0..1] == test[0..1]);
		assert (test[][1..3] == test[1..3]);

		// element mutation
		test[0] = 4;
		assert (test[0] == 4);
		assert (test[] == [4,2,3]);

		// range mutation
		test[] = [4,5,6];
		assert (test[] == [4,5,6]);

		// subrange mutation
		test[0..2] = [7,8];
		assert (test[] == [7,8,6]);

		// slice mutation
		auto slice = test[1..3];
		assert (slice[] == [8,6]);
		slice[] = [9,9];
		assert (slice[] == [9,9]);
		slice[0] = 8;
		assert (test[] == [7,8,9]);
		slice[0..2] = 6;
		assert (test[] == [7,6,6]);

		// slice range traversal
		test[] = [1,1,1];
		foreach (x; test[])
			assert (x == 1);
		foreach (x; test[0..2])
			assert (x == 1);

		// reassignment
		test = [9,0];
		assert (test.length == 2);

		// element appending
		test ~= 1;
		assert (test.length == 3);
		assert (test[] == [9,0,1]);

		// range appending
		test ~= [2,3];
		assert (test.length == 5);
		assert (test[] == [9,0,1,2,3]);

		// popping
		test.pop;
		assert (test.length == 4);
		assert (test[] == [9,0,1,2]);
		test.pop (2);
		assert (test.length == 2);
		assert (test[] == [9,0]);

		// nullification
		test = null;
		assert (test.length == 0);
		assert (test[].empty);
		assert (test.empty);
	}
