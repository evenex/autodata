module evx.operators.transfer;

private {/*imports}*/
	import evx.traits.concepts;
	import evx.range.traits;
}

struct TransferTraits (Buffer)
	{/*...}*/
		static {/*alias}*/
			private Buffer buffer = Buffer.init;

			static if (is(typeof(buffer.access (0))))
				alias Element = typeof(buffer.access (0));
			else static if (is(typeof(buffer.ptr[0])))
				alias Element = typeof(buffer.ptr[0]);
			else alias Element = void;
		}

		mixin Traits!(
			`has_pointer`, q{*(buffer.ptr + 1) = Element.init;},
			`has_length`,  q{size_t x = buffer.length;},

			`can_access`, q{Element x = buffer.access (size_t.min);},
			`can_pull`,   q{buffer.pull (NullInputRange!Element.init, size_t.min, size_t.max);},
			`can_push`,   q{buffer.push ((Element*).init, size_t.min, size_t.max);},

			`access_by_ref`, q{buffer.access (size_t.min) = Element.init;},

			`access_primitive`,   q{static assert (can_access || has_pointer);},
			`transfer_primitive`, q{static assert (can_pull || has_pointer);},
		);
	}

// this is the data movement interface
/* define standardized, higher-order-compatible, auto-optimizing opSlice/opIndex operators over a member with data transfer primitives 
	required primitives:
		ACCESS PRIMITIVE: returns the i'th data element of the buffer, used for reading the contents of the buffer. preserves ref storage class.
			Element x = member.access (size_t.min);
			|| Element x = member.ptr[size_t.min];

		TRANSFER PRIMITIVE: copies the entire contents of range into the region bounded by indices i and j.
			member.pull (Element[].init, size_t.min, size_t.max);
			|| *member.ptr = Element.init;

		LENGTH PRIMITIVE: the upper bound of indexable data, used for controlling access and slicing limits.
			size_t x = member.length;

	optional primitives:
		push (Element[] target): if target has ptr, copies the entire contents of the buffer into target. used for inverted-control data transfer.
		ptr: enables optimized data transfer when target and source both have ptr.
*/
mixin template TransferOps (alias buffer)
	{/*...}*/
		static {/*analysis}*/
			alias TransferTraits = evx.operators.transfer.TransferTraits!(typeof(buffer));

			mixin template require (string trait)
				{/*...}*/
					alias requirement = TransferTraits.require!(typeof(this), trait, TransferOps);
				}

			mixin require!`access_primitive`;
			mixin require!`transfer_primitive`;
			mixin require!`has_length`;
		}

		mixin(q{
			alias } ~__traits(identifier, buffer)~ q{ this;
		});

		public:
		public {/*element}*/
			auto ref front ()
				{/*...}*/
					return this[0];
				}
		}
		public {/*pointer}*/
			static if (TransferTraits.has_pointer)
				auto ptr ()
					{/*...}*/
						return buffer.ptr;
					}
		}
		public {/*length}*/
			@property length () const
				{/*...}*/
					return buffer.length;
				}
			alias opDollar = length;
		}
		public {/*access}*/
			auto ref opIndex (size_t i)
				in {/*...}*/
					assert (i < length);
				}
				body {/*...}*/
					return access (&buffer, i);
				}
		}
		public {/*slicing}*/
			auto opIndex ()
				{/*...}*/
					return this[0..$];
				}
			auto opIndex (size_t[2] slice)
				{/*...}*/
					return Sub (&buffer, slice);
				}
			size_t[2] opSlice (size_t dim: 0)(size_t i, size_t j)
				in {/*...}*/
					assert (i <= j && j <= length);
				}
				body {/*...}*/
					return [i,j];
				}
		}
		public {/*range assignment}*/
			auto opIndexAssign (R)(R range)
				{/*...}*/
					this[0..$] = range;
				}
			auto opIndexAssign (R)(R range, size_t[2] slice)
				{/*...}*/
					range_assign (&buffer, range, slice);
				}
		}
		public {/*element assignment}*/
			auto ref opIndexAssign (TransferTraits.Element element, size_t i)
				in {/*...}*/
					assert (i < length);
				}
				body {/*...}*/
					return element_assign (&buffer, element, i);
				}
			auto opIndexAssign (TransferTraits.Element element, size_t[2] slice)
				{/*...}*/
					multi_element_assign (&buffer, element, slice);
				}
		}
		private:
		private {/*sub_buffer}*/
			struct Sub
				{/*...}*/
					alias Source = typeof(buffer);

					public:
					public {/*pointer/offset}*/
						static if (TransferTraits.has_pointer)
							auto ptr ()
								{/*...}*/
									return main_buffer.ptr + bounds[0];
								}
						else auto offset ()
							{/*...}*/
								return bounds[0];
							}
					}
					public {/*length}*/
						@property length () const
							{/*...}*/
								return bounds[1] - bounds[0];
							}
						alias opDollar = length;
					}
					public {/*access}*/
						auto ref opIndex (size_t i)
							{/*...}*/
								return access (main_buffer, bounds[0] + i);
							}
					}
					public {/*slicing}*/
						auto opIndex ()
							{/*...}*/
								return this[0..$];
							}
						auto opIndex (size_t[2] slice)
							{/*...}*/
								slice[] += bounds[0];

								return Sub (main_buffer, slice);
							}
						size_t[2] opSlice (size_t dim: 0)(size_t i, size_t j)
							in {/*...}*/
								assert (i <= j && j <= length);
							}
							body {/*...}*/
								return [i,j];
							}
					}
					public {/*iteration}*/
						auto ref front ()
							{/*...}*/
								return this[0];
							}
						void popFront ()
							{/*...}*/
								++bounds[0];
							}

						auto ref back ()
							{/*...}*/
								return this[$-1];
							}
						void popBack ()
							{/*...}*/
								--bounds[1];
							}

						bool empty ()
							{/*...}*/
								return length == 0;
							}

						@property save ()
							{/*...}*/
								return this;
							}
					}
					public {/*range assignment}*/
						auto opIndexAssign (R)(R range)
							{/*...}*/
								this[0..$] = range;
							}
						auto opIndexAssign (R)(R range, size_t[2] slice)
							{/*...}*/
								slice[] += bounds[0];

								range_assign (main_buffer, range, slice);
							}
					}
					public {/*element assignment}*/
						auto ref opIndexAssign (TransferTraits.Element element, size_t i)
							{/*...}*/
								return element_assign (main_buffer, element, i + bounds[0]);
							}
						auto opIndexAssign (TransferTraits.Element element, size_t[2] slice)
							{/*...}*/
								slice[] += bounds[0];

								multi_element_assign (main_buffer, element, slice);
							}
					}
					public {/*equality comparison}*/
						bool opEquals (R)(R range)
							{/*...}*/
								import std.range: equal;

								static if (is(R == void[]))
									return this.empty;
								else return this.equal (range); // TODO this is costly for gpu buffers, maybe "has_equality" or something for custom overrides?
							}
					}
					private:
					private {/*data}*/
						typeof(buffer)* main_buffer;
						size_t[2] bounds;
					}
				}
		}
		static {/*access/transfer}*/
			auto ref access (typeof(buffer)* buffer, size_t i)
				{/*...}*/
					static if (TransferTraits.can_access)
						return buffer.access (i);
					else static if (TransferTraits.has_pointer)
						return buffer.ptr[i];
					else static assert (0);
				}

			auto range_assign (R)(typeof(buffer)* buffer, R range, size_t[2] slice)
				in {/*...}*/
					static if (evx.operators.transfer.TransferTraits!R.has_length)
						assert (range.length == slice[1] - slice[0]);
					else static assert (range[].count == slice[1] - slice[0]);
				}
				body {/*...}*/
					static if (TransferTraits.has_pointer && evx.operators.transfer.TransferTraits!R.has_pointer)
						{/*...}*/
							auto this_ptr = buffer.ptr + slice[0]; // TODO vector blit optimization
							auto that_ptr = range.ptr;

							foreach (_; slice[0]..slice[1])
								*(this_ptr++) = *(that_ptr++);
						}
					else static if (TransferTraits.has_pointer && evx.operators.transfer.TransferTraits!R.can_push)
						{/*...}*/
							auto ptr = buffer.ptr + slice[0];

							static if (is(R == Sub))
								range.push (ptr, range.bounds[0], range.bounds[1]);
							else range.push (ptr, 0, range.length);
						}
					else static if (TransferTraits.can_pull)
						{/*...}*/
							buffer.pull (range, slice[0], slice[1]);
						}
					else static if (TransferTraits.has_pointer)
						{/*...}*/
							auto ptr = buffer.ptr + slice [0];

							foreach (item; range)
								*(ptr++) = item;
						}
					else static assert (0);
				}

			auto ref element_assign (typeof(buffer)* buffer, TransferTraits.Element element, size_t i)
				{/*...}*/
					static if (TransferTraits.access_by_ref)
						return buffer.access (i) = element;
					else static if (TransferTraits.can_pull)
						return buffer.pull ((&element)[0..1], i, i+1);
					else static if (TransferTraits.has_pointer)
						return buffer.ptr[i] = element;
					else static assert (0);
				}

			auto multi_element_assign (typeof(buffer)* buffer, TransferTraits.Element element, size_t[2] slice)
				{/*...}*/
					static if (TransferTraits.can_pull)
						{/*...}*/
							import std.range: repeat;

							buffer.pull (element.repeat (slice[1] - slice[0]), slice[0], slice[1]);
						}
					else static if (TransferTraits.has_pointer)
						{/*...}*/
							foreach (i; slice[0]..slice[1])
								buffer.ptr[i] = element;
						}
					else static assert (0);
				}
		}
	}
	unittest {/*...}*/
		{/*basic functionality test}*/
			struct Test_StaticArray
				{/*...}*/
					int[3] buffer;

					mixin TransferOps!buffer;
				}
			struct Test_DynamicArray
				{/*...}*/
					int[] buffer;

					mixin TransferOps!buffer;
				}

			void basic_transfer_test (T)()
				{/*...}*/
					T test = {buffer: [1,2,3]};

					assert (test.length == 3);

					// element access
					assert (test[0] == 1);
					assert (test[1] == 2);
					assert (test[2] == 3);
					assert (test[$-1] == 3);

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

					// slice equality
					assert (test[0..1] == [7]);
					assert (test[1..3] == [8,6]);
					assert (test[0..$] == [7,8,6]);

					// slice equivalence
					assert (test[][] == test[]);
					assert (test[][0] == test[0]);
					assert (test[][1] == test[1]);
					assert (test[][2] == test[2]);
					assert (test[][0..1] == test[0..1]);
					assert (test[][1..3] == test[1..3]);

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
				}

			basic_transfer_test!Test_StaticArray;
			basic_transfer_test!Test_DynamicArray;
		}
		{/*active/passive copying}*/
			// TODO test active/passive copying
		}
	}
