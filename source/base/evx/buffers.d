module evx.buffers;

import std.range;
import std.traits;
import std.typetuple;
import std.conv: to, text;

import evx.utils;
import evx.meta;

import evx.allocators;
		import std.datetime: nsecs;
		import core.thread: Thread, sleep;


/* Buffers
Buffers are a mechanism for safely transferring large quantities
	of data over thread boundaries. They must be declared shared.

Buffers expose two Ranges, called the write and read buffers.
	The Buffer itself acts as an OutputRange with appending (which 
	writes to the write buffer). Buffers are backed by Resources, 
	so their length cannot exceed their declared capacity.

Because of the nondeterministic nature of the GC, Invalid Memory 
	errors can arise if Buffers persist on the heap at program 
	termination. Therefore it is highly recommended to declare 
	Buffers or their containing class as scoped, keep Buffers in 
	a stack-allocated struct, or otherwise employ the RAII idiom. 
*/

/*
	DoubleBuffers employ a one-step swap strategy.
	The data is transferred with a single call to swap ().
	It is recommended to employ a synchronization mechanism with
		a DoubleBuffer to prevent tearing.
*/
template DoubleBuffer (T, uint size)
	{/*...}*/
		final class DoubleBuffer // TODO struct
			{/*...}*/
				public: 
				shared {/*swap}*/
					void swap ()
						{/*...}*/
							(cast()this).buffer[++write_index %= 2].clear;
						}
				}
				shared {/*append}*/
					void put (U)(U data)
						{/*...}*/
							(cast()this).buffer[write_index] ~= data;
						}
					void opOpAssign (string op: `~`, U)(U that)
						{/*...}*/
							this.put (that);
						}
				}
				shared @property {/*buffers}*/
					auto write ()
						{/*...}*/
							return (cast()this).buffer[write_index][];
						}
					auto read ()
						{/*...}*/
							return (cast()this).buffer[(write_index+1)%2][];
						}
				}
				shared @property {/*size}*/
					auto length ()
						{/*...}*/
							return (cast()buffer[write_index]).length;
						}
					auto capacity ()
						{/*...}*/
							return (cast()buffer[write_index]).capacity;
						}
				}
				shared {/*ctor}*/
					this ()
						{/*...}*/
							auto memory = new Allocator!T (size*2);

							cast()buffer[0] = memory.allocate (size);
							cast()buffer[1] = memory.allocate (size);
						}
				}
				private:
				private {/*data}*/
					Resource!T buffer[2];
					uint write_index = 0;
				}
			}
		static assert (not (isOutputRange!(DoubleBuffer, T)));
		static assert (isOutputRange!(shared DoubleBuffer, T));
	}

/*
	TripleBuffers employ a lockless two-step swap strategy.
	In no particular order, the write thread must call writer_swap ()
		and the read thread must call reader_swap ().
	At the cost of 50% more memory usage over DoubleBuffers, TripleBuffers 
		can forego synchronization without the risk of tearing. As long as 
		the delay between paired swap calls does not exceed one processing 
		cycle, both threads can immediately continue working after calling 
		their respective swap functions.
*/
template TripleBuffer (T, uint size, uint poll_frequency = 4_000)
	{/*...}*/
		static immutable wait_period = (1_000_000_000/poll_frequency).nsecs;
		final class TripleBuffer
			{/*...}*/
				public:
				shared {/*swap}*/
					void writer_swap ()
						{/*...}*/
							while ((write_index + 2) % 3 != read_index)
								Thread.sleep (wait_period);
							(cast()buffer[++write_index %= 3]).clear; // REVIEW
						}
					void reader_swap ()
						{/*...}*/
							while ((write_index + 1) % 3 != read_index)
								Thread.sleep (wait_period);
							++read_index %= 3; // REVIEW Deprecation: Read-modify-write operations are not allowed for shared variables. Use core.atomic.atomicOp!"+="(this.read_index, 1) instead.
							//core.atomic.atomicOp!"+="(this.read_index, 1);
							//core.atomic.atomicOp!"%="(this.read_index, 3);
						}
				}
				shared {/*append}*/
					void put (U)(U data)
						{/*...}*/
							(cast()this).buffer[write_index] ~= data;
						}
					void opOpAssign (string op: `~`, U)(U that)
						{/*...}*/
							this.put (that);
						}
				}
				shared @property {/*buffers}*/
					auto write ()
						{/*...}*/
							return (cast()this).buffer[write_index][];
						}
					auto read ()
						{/*...}*/
							return (cast()this).buffer[read_index][];
						}
				}
				shared @property {/*size}*/
					auto length ()
						{/*...}*/
							return write.length;
						}
					auto capacity ()
						{/*...}*/
							return (cast()buffer[write_index]).capacity;
						}
				}
				shared {/*ctor}*/
					this ()
						{/*...}*/
							auto memory = new Allocator!T (size*3); // REVIEW allocator can't be manually deleted now... buffers will probably last all program, but still...

							cast()buffer[0] = memory.allocate (size);
							cast()buffer[1] = memory.allocate (size);
							cast()buffer[2] = memory.allocate (size);
						}
				}
				private:
				private {/*data}*/
					Resource!T buffer[3];
					uint write_index = 0;
					uint read_index  = 2;
				}
			}
		static assert (not (isOutputRange!(TripleBuffer, T)));
		static assert (isOutputRange!(shared TripleBuffer, T));
	}

/*
	BufferGroups group multiple Buffers using the same swap strategy.
	When a swap method is called on a BufferGroup, it is called on
	all Buffers contained within it. Individual Buffers may be
	accessed as data members of the BufferGroup.
*/
class BufferGroup (Declarations...)
	{/*...}*/
		mixin ParameterSplitter!(
			q{Names}, is_string_param,
			q{Types}, is_type,
			Declarations
		);

		public {/*assertions}*/
			static bool same_swap_strategy (T)()
				{/*...}*/
					return __traits(compiles, T.swap) && __traits(compiles, Types[0].swap)
						|| __traits(compiles, T.reader_swap) && __traits(compiles, Types[0].reader_swap);
				}
			static assert (allSatisfy!(same_swap_strategy, Types), 
				`all Buffers in a BufferGroup must use the same swap strategy`
			);
		}
		private {/*code generation}*/
			static string buffer_declarations ()
				{/*...}*/
					string code;

					foreach (i, T; Types)
						code ~= q{
							Types[} ~ i.text ~ q{] } ~ Names[i] ~ q{;
						};
					return code;
				}
		}

		alias BufferType = Types[0];
		shared {mixin(buffer_declarations);}

		static if (hasMember!(BufferType, `swap`))
			shared void swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.swap}, Names));
				}
		else {/*lockless swap}*/
			shared void reader_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.reader_swap}, Names));
				}
			shared void writer_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.writer_swap}, Names));
				}
		}

		shared this ()
			{/*...}*/
				foreach (i, T; Types)
					mixin(q{
						} ~ Names[i] ~ q{ = new shared T;
					});
			}
	}

unittest
	{/*...}*/
		static void test (string Buffer)()
			{/*...}*/
				mixin(q{
					scope b = new shared } ~Buffer~ q{!(int, 10);}
				);
				assert (b.capacity == 10);
				assert (b.length == 0);

				b.put ([9,8]);
				assert (b.length == 2);
				b.put (7);
				assert (b.length == 3);
				b ~= 6;
				assert (b.length == 4);
				b ~= [5,4];
				assert (b.length == 6);

				assert (b.write[].equal ([9,8,7,6,5,4]));
				assert (b.read[].equal ((int[]).init));

				static if (Buffer == q{TripleBuffer})
					b.writer_swap, b.reader_swap;
				else b.swap;

				assert (b.write[].equal ((int[]).init));
				assert (b.read[].equal ([9,8,7,6,5,4]));

				static if (Buffer == q{TripleBuffer})
					b.writer_swap, b.reader_swap;
				else b.swap;

				assert (b.write[].equal ((int[]).init));
				assert (b.read[].equal ((int[]).init));
			}

		test!q{DoubleBuffer};
		test!q{TripleBuffer};
	}

unittest
	{/*...}*/
		import evx.math;
		import std.concurrency;

		static void test (string Buffer)()
			{/*...}*/
				mixin(q{
					alias Buff = shared } ~ Buffer ~ q{!(int, 24);
				});

				scope A = new Buff;

				static void task (Buff A)
					{/*...}*/
						static if (Buffer == q{TripleBuffer})
							A.reader_swap;

						auto data = A.read[];
						ownerTid.send (data.sum);
					}

				A ~= [1, 2];
				A ~= [3, 4];
				static if (Buffer == q{DoubleBuffer})
					A.swap;
				else A.writer_swap;
				assert (A.length == 0);

				spawn (&task, A);
				receive ((int sum) {assert (sum == 10);});
			}

		test!q{DoubleBuffer};
		test!q{TripleBuffer};
	}
