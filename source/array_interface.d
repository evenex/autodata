import std.traits;
import evx.analysis;
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

		size_t _length;

		@property length () const
			{/*...}*/
				return _length;
			}

		auto opAssign (R)(R range)
			{/*...}*/
				this.nullify;

				if (this.resize (range.length))
					this._length = range.length;
				else assert (0, `failed to resize ` ~typeof(this).stringof~ ` to ` ~length.text);

				static if (BufferInfo!R.can_active_copy)
					range.copy_to (this, 0, range.length);
				else this.copy_from (range, 0, range.length);
			}

		auto front ()
			{/*...}*/
				return this[0];
			}
		auto back ()
			{/*...}*/
				return this[$-1];
			}

		auto ref opIndex (size_t i)
			{/*...}*/
				return access (i);
			}

		auto opDollar () const
			{/*...}*/
				return length;
			}

		struct Slice
			{/*...}*/
				
			}

		auto opIndex ()
			{/*...}*/
				
			}
		auto opIndex (size_t[2] bounds)
			{/*...}*/
				
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
		assert (test[] == [7,9,9]);
		slice[0] = 8;
		assert (test[] == [8,9,9]);

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
		assert (test[] == []);
	}
