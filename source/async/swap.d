module autodata.async.swap;

version (none):

private {/*imports}*/
	private {/*core}*/
		import core.atomic;
		import core.thread;
	}
	private {/*std}*/
		import std.datetime;
		import std.range;
		import std.traits;
		import std.typetuple;
		import std.conv;
	}

	import autodata.meta;
}

/* Buffers
Buffers are a mechanism for safely transferring large quantities
	of data over thread boundaries. They must be declared .

Buffers expose two Ranges, called the write and read buffers.
	The Buffer itself acts as an OutputRange with appending (which 
	writes to the write buffer). Buffers are backed by DynamicArrays, 
	they will reallocate if their length exceeds their declared capacity. REVIEW no longer true

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
struct DoubleBuffered (R) // TODO REVIEW synchronized final class
	{/*...}*/
		public: 
		public {/*swap}*/
			void swap ()
				{/*...}*/
					atomicStore (write_index, (write_index+1)%2);

					if (write_index == 0) // REVIEW
						(cast()this).buffer[0].clear;
					else (cast()this).buffer[1].clear;
				}
		}
		@property {/*buffers}*/
			ref write ()
				{/*...}*/
					if (write_index == 0) //REVIEW
						return (cast()this).buffer[0];
					else return (cast()this).buffer[1];
				}
			ref read ()
				{/*...}*/
					if (write_index == 0) //REVIEW
						return (cast()this).buffer[1];
					else return (cast()this).buffer[0];
				}
		}
		@property {/*size}*/
			auto length ()
				{/*...}*/
					if (write_index == 0) //REVIEW
						return (cast()buffer[0]).length;
					else return (cast()buffer[1]).length;
				}
		}
		public {/*ctor}*/
			this (size_t size)
				{/*...}*/
					with (cast()this) 
					foreach (ref array; buffer)
						array = typeof(array)(size);
				}
		}
		private:
		private {/*data}*/
			Cons!(R,R) buffer; // BUG was R[2], causes bad attribute inference https://issues.dlang.org/show_bug.cgi?id=14239
			shared uint write_index = 0; // REVIEW shared at what level?
		}
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
template TripleBuffered (R, uint poll_frequency = 4_000)
	{/*...}*/
		static immutable wait_period = (1_000_000_000/poll_frequency).nsecs;

		struct TripleBuffered // REVIEW synchronization
			{/*...}*/
				public:
				public {/*swap}*/
					void writer_swap ()
						{/*...}*/
							while (not (cas (&write_index, (read_index+1)%3, (write_index+1)%3)))
								Thread.sleep (wait_period);

							(cast()buffer[write_index]).clear;
						}
					void reader_swap ()
						{/*...}*/
							while (not (cas (&read_index, (write_index+1)%3, (read_index+1)%3)))
								Thread.sleep (wait_period);
						}
				}
				@property {/*buffers}*/
					ref write ()
						{/*...}*/
							return (cast()this).buffer[write_index];
						}
					ref read ()
						{/*...}*/
							return (cast()this).buffer[read_index];
						}
				}
				@property {/*size}*/
					auto length ()
						{/*...}*/
							return write.length;
						}
				}
				public {/*ctor}*/
					this (size_t size)
						{/*...}*/
							with (cast()this) 
							foreach (ref array; buffer)
								array = typeof(array)(size);
						}
				}
				private:
				private {/*data}*/
					R[3] buffer;
					uint write_index = 0;
					uint read_index  = 2;
				}
			}
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
		public {mixin(buffer_declarations);}

		static if (hasMember!(BufferType, `swap`))
			void swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.swap}, Names));
				}
		else {/*lockless swap}*/
			void reader_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.reader_swap}, Names));
				}
			void writer_swap ()
				{/*...}*/
					mixin(apply_to_each!(q{.writer_swap}, Names));
				}
		}

		this ()
			{/*...}*/
				foreach (i, T; Types)
					mixin(q{
						} ~ Names[i] ~ q{ = new  T;
					});
			}
	}

void main () {/*...}*/
	static void test (string Buffer)()
		{/*...}*/
			mixin(q{
				scope b = new  } ~Buffer~ q{!(int[]);}
			);
			assert (b.length == 0);

			b.write.put ([9,8]);
			assert (b.length == 2);
			b.write.put (7);
			assert (b.length == 3);
			b ~= 6;
			assert (b.length == 4);
			b ~= [5,4];
			assert (b.length == 6);

			assert (b.write[].equal ([9,8,7,6,5,4]));
			assert (b.read[].equal ((int[]).init));

			static if (Buffer == q{TripleBuffered})
				b.writer_swap, b.reader_swap;
			else b.swap;

			assert (b.write[].equal ((int[]).init));
			assert (b.read[].equal ([9,8,7,6,5,4]));

			static if (Buffer == q{TripleBuffered})
				b.writer_swap, b.reader_swap;
			else b.swap;

			assert (b.write[].equal ((int[]).init));
			assert (b.read[].equal ((int[]).init));
		}

	test!q{DoubleBuffered};
	test!q{TripleBuffered};
}
unittest {/*...}*/
	import std.concurrency;

	static void test (string Buffer)()
		{/*...}*/
			mixin(q{
				alias Buff =  } ~ Buffer ~ q{!(int, 24);
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
