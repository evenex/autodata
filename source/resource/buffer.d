module resource.buffer;

import std.range;
import std.traits;
import std.typetuple;
import std.conv: to, text;

import utils;

import resource.allocator;

/* Buffers
Buffers are a mechanism for safely transferring large quantities
	of data over thread boundaries. They must be declared shared.

Buffers expose two Ranges, called the fore and rear buffers,
	and themselves act as an OutputRange with appending (which 
	writes to the fore buffer). Buffers are backed by Resources, 
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
							(cast()this).buffer[++write %= 2].clear;
						}
				}
				shared {/*append}*/
					void put (U)(U data)
						{/*...}*/
							(cast()this).buffer[write] ~= data;
						}
					void opOpAssign (string op: `~`, U)(U that)
						{/*...}*/
							this.put (that);
						}
				}
				shared @property {/*buffers}*/
					auto fore ()
						{/*...}*/
							return (cast()this).buffer[write][];
						}
					auto rear ()
						{/*...}*/
							return (cast()this).buffer[(write+1)%2][];
						}
				}
				shared @property {/*size}*/
					auto length ()
						{/*...}*/
							return (cast()buffer[write]).length;
						}
					auto capacity ()
						{/*...}*/
							return (cast()buffer[write]).capacity;
						}
				}
				shared {/*ctor}*/
					this ()
						{/*...}*/
							auto memory = new Allocator!T (size*2);

							buffer[0] = cast(shared)memory.allocate (size);
							buffer[1] = cast(shared)memory.allocate (size);
						}
				}
				private:
				private {/*data}*/
					Resource!T buffer[2];
					uint write = 0;
				}
				enum BufferTrait;
			}
		static assert (not (isOutputRange!(DoubleBuffer, T)));
		static assert (isOutputRange!(shared DoubleBuffer, T));
	}

/*
	TripleBuffers employ a lockless two-step swap strategy.
	In no particular order, the writing thread must call writer_swap ()
		and the reading thread must call reader_swap ().
	At the cost of 50% more memory usage over DoubleBuffers, TripleBuffers 
		can forego synchronization without the risk of tearing. As long as 
		the delay between paired swap calls does not exceed one processing 
		cycle, both threads can immediately continue working after calling 
		their respective swap functions.
*/
template TripleBuffer (T, uint size, uint sync_frequency = 4_000)
	{/*...}*/
		import std.datetime: nsecs;
		import core.thread: Thread, sleep;

		static immutable sync_cycle = (1_000_000_000/sync_frequency).nsecs;
		final class TripleBuffer
			{/*...}*/
				public:
				shared {/*swap}*/
					void writer_swap ()
						{/*...}*/
							while ((write + 2) % 3 != read)
								Thread.sleep (sync_cycle);
							(cast()buffer[++write %= 3]).clear;
						}
					void reader_swap ()
						{/*...}*/
							while ((write + 1) % 3 != read)
								Thread.sleep (sync_cycle);
							++read %= 3;
						}
				}
				shared {/*append}*/
					void put (U)(U data)
						{/*...}*/
							(cast()this).buffer[write] ~= data;
						}
					void opOpAssign (string op: `~`, U)(U that)
						{/*...}*/
							this.put (that);
						}
				}
				shared @property {/*buffers}*/
					auto fore ()
						{/*...}*/
							return (cast()this).buffer[write][];
						}
					auto rear ()
						{/*...}*/
							return (cast()this).buffer[read][];
						}
				}
				shared @property {/*size}*/
					auto length ()
						{/*...}*/
							return fore.length;
						}
					auto capacity ()
						{/*...}*/
							return (cast()buffer[write]).capacity;
						}
				}
				shared {/*ctor}*/
					this ()
						{/*...}*/
							auto memory = new Allocator!T (size*3); // REVIEW allocator can't be manually deleted now... buffers will probably last all program, but still...

							buffer[0] = cast(shared)memory.allocate (size);
							buffer[1] = cast(shared)memory.allocate (size);
							buffer[2] = cast(shared)memory.allocate (size);
						}
				}
				private:
				private {/*data}*/
					Resource!T buffer[3];
					uint write = 0;
					uint read  = 2;
				}
				enum BufferTrait;
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
struct BufferGroup (Types_and_Names...)
	{/*...}*/
		alias Types = Filter!(is_type, Types_and_Names);
		alias Names = Filter!(is_string_param, Types_and_Names);

		public {/*assertions}*/
			static assert (Types.length == Names.length, 
				`types and identifiers must be paired in BufferGroup declaration`
			);
			static assert (Types.length + Names.length == Types_and_Names.length, 
				`BufferGroup declaration must consist only of types and identifier strings`
			);
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
					mixin(apply_to_each!(q{swap}, Names));
				}
		else {/*lockless swap}*/
			shared void reader_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{reader_swap}, Names));
				}
			shared void writer_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{writer_swap}, Names));
				}
		}

		shared void initialize ()
			{/*...}*/
				foreach (i, T; Types)
					mixin(q{
						} ~ Names[i] ~ q{ = new shared T;
					});
			}
	}

private template is_Buffer (T...)
	if (T.length == 1)
	{/*...}*/
		enum is_Buffer = __traits(compiles, typeof(T[0]).BufferTrait);
	}

unittest
	{/*...}*/
		static void test (string Buffer)()
			{/*...}*/
				mixin(report_test!(Buffer ~ ` swap`));

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

				assert (b.fore[].equal ([9,8,7,6,5,4]));
				assert (b.rear[].equal ((int[]).init));

				static if (Buffer == q{TripleBuffer})
					b.writer_swap, b.reader_swap;
				else b.swap;

				assert (b.fore[].equal ((int[]).init));
				assert (b.rear[].equal ([9,8,7,6,5,4]));

				static if (Buffer == q{TripleBuffer})
					b.writer_swap, b.reader_swap;
				else b.swap;

				assert (b.fore[].equal ((int[]).init));
				assert (b.rear[].equal ((int[]).init));
			}

		test!q{DoubleBuffer};
		test!q{TripleBuffer};
	}

unittest
	{/*...}*/
		import math;
		import std.concurrency;

		static void test (string Buffer)()
			{/*...}*/
				mixin(report_test!(`threaded ` ~ Buffer ~ ` swap`));

				mixin(q{
					alias Buff = shared } ~ Buffer ~ q{!(int, 24);
				});

				scope A = new Buff;

				static void task (Buff A)
					{/*...}*/
						static if (Buffer == q{TripleBuffer})
							A.reader_swap;

						auto data = A.rear[];
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
