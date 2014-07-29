module evx.utils;

// REVIEW & REFACTOR
import std.traits;
import std.typecons;
import std.typetuple;
import std.container;
import std.algorithm;
import std.math;
import std.range;
import std.datetime;
import std.string;
import std.ascii;
import std.concurrency;
import std.conv: to;
import resource.arrays: is_dynamic_array;

import evx.meta;

debug = profiler;

public {/*misc}*/
	alias τ = tuple;

	const bool not (T)(const T value)
		{/*...}*/
			return !value;
		}
	const bool not (alias predicate, T)(const T value)
		if (isSomeFunction!predicate)
		{/*...}*/
			return not (predicate (value));
		}

	alias And = templateAnd;
	alias Or  = templateOr;
	alias Not = templateNot;

	/* simulate opCmp */
	int compare (T,U)(T a, U b)
		{/*...}*/
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			else return 0;
		}
}
public {/*debug}*/
	/* warning exception */
	class Warning: Exception
		{/*...}*/
			this (string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
				{/*...}*/
					super (message, file, line, next);
				}
		}
	/* print detailed information about a caught exception */
	deprecated auto print_stack_trace (Ex, T...) (Ex exception, T message)
		if (is (Ex: Throwable))
		{/*...}*/
			import std.stdio;
			const string type = is (Ex == Warning)? `warning`: `error`;
			stderr.writeln ("tid("~tid_string~"): "~type~" ", message," @"~exception.file~"(", exception.line, "): "~exception.msg);
			if (!is (Ex == Warning))
				{/*...}*/
					stderr.writeln ("----------------");
					foreach (frame; exception.info)
						stderr.writeln (frame);
				}
			stderr.flush;
		}
	/* output the names and current values of the fields a given record or pointer target record */
	template examine_fields (alias record, bool show_types = false, T = typeof (record))
		{/*...}*/
			import std.stdio;
			void examine_fields ()
				{/*...}*/
					static if (isAggregateType!T)
						alias Record = T;
					else static if (isPointer!T)
						alias Record = PointerTarget!T;
					else static assert (0, "can't examine fields of "~T.stringof);

					string record_type = Record.stringof~' ';
					writeln (record_type~__traits (identifier, record)~`:`);

					foreach (field; __traits (allMembers, Record))
						{/*...}*/
							const bool is_field = field != `this` && __traits (compiles, typeof (__traits (getMember, record, field)));
							static if (not (is_field))
								continue;
							else
								{/*...}*/
									alias field_T = typeof (__traits (getMember, record, field));
									
									static if (isPointer!field_T)
										alias Field = PointerTarget!field_T;
									else alias Field = field_T;

									static if (show_types)
										string type = Field.stringof~' ';
									else 
										string type = "";

									alias member = Alias!(__traits (getMember, record, field));
									static if (__traits (getProtection, member) == `public`)
										{/*...}*/
											static if (isSomeFunction!member)
												{/*...}*/
													static if (functionAttributes!member & FunctionAttribute.property) 
														const bool okay_to_print = true;
													else const bool okay_to_print = false;
												}
											else const bool okay_to_print = true;
										}
									else const bool okay_to_print = false;

									static if (okay_to_print)
										writeln (` `~type~field~`: `, __traits (getMember, record, field));
								}
						}
					writeln (`---`);
				}
		}
	/* print a function call with arguments */
	const string function_call_to_string (string name, Args...) (Args args)
		{/*...}*/
			string call;
			foreach (arg; args)
				call ~= to!string (arg) ~ ", ";
			if (call.length == 0)
				return name~" ()";
			else return name~" ("~call[0..$-2]~")";
		}
	/* suppress stderr while in scope */
	template error_suppression ()
		{/*...}*/
			const string error_suppression ()
				{/*...}*/
					import std.string;
					const string S = __TIMESTAMP__.removechars (":").removechars (" ").succ.translate (['A':'q', 'o':'7', '1':'y', '4':'f', 'J':'4', 'T':'X', 'S':'5', 'e':'_']);
					const string ID = (S[2*$/3..$].succ~S[$/5..$/3].succ~S[$/2..3*$/4].succ~S[1..$/4].succ).succ;
					return `
						int errstream`~ID~`;
						{/*...}*/
							import std.c.stdio;
							import std.c.linux.linux;
							errstream`~ID~` = dup (stderr.fileno ());
							freopen ("/dev/null", "w", stderr);
						}
						scope (exit) {/*...}*/
							import std.c.stdio;
							import std.c.linux.linux;
							fflush (stderr);
							dup2 (errstream`~ID~`, stderr.fileno ());
						}`
					;
				}
		}
	/* report the status of a unit test */
	template report_test (string name)
		{/*...}*/
			const string report_test = `
				{
					import std.stdio;
					stderr.writeln ("initiating `~name~` test...");
					stderr.flush;
				}
				scope (success) {
					import std.stdio;
					stderr.writeln ("`~name~` test passed");
					stderr.flush;
				}
				scope (failure) {
					import std.stdio;
					stderr.writeln ("`~name~` test failed!");
					stderr.flush;
				}
			`;
		}
	/* write information about the thread environment to the output */
	/* and time program execution through checkpoints */
	struct Profiler
		{/*...}*/
			private import std.datetime;
			public:
				enum ExitStatus {success, failure}
			public {/*interface}*/
				static Profiler begin (string func_name = __PRETTY_FUNCTION__)
					{/*...}*/
						return Profiler (func_name);
					}
				void end (ExitStatus exit_status)
					{/*...}*/
						debug (profiler)
							{/*...}*/
								this.exit_time = Clock.currTime;
								this.exit_status = exit_status;
							}
					}
				void checkpoint (T...)(T marks)
					{/*...}*/
						debug (profiler)
							{/*...}*/
								import std.stdio;
								auto check = Clock.currTime - last_check;
								this.last_check = Clock.currTime;
								stderr.writeln (check, ` `, marks);
								stderr.flush;
							}
					}
			}
			public {/*~}*/
				~this ()
					{/*...}*/
						debug (profiler)
							{/*...}*/
								import std.stdio;
								stderr.writeln (profiler_exit_indent,
									exit_status == ExitStatus.failure? `FAILED!`:``, 
									`ex(`~tid_string~`): `, func_name, ` after `, exit_time-entry_time);
								stderr.flush;
							}
					}
			}
			private:
			private {/*data}*/
				string func_name;
				SysTime entry_time;
				SysTime exit_time;
				SysTime last_check;
				ExitStatus exit_status;
			}
			private {/*☀}*/
				this (string func_name)
					{/*...}*/
						debug (profiler)
							{/*...}*/
								import std.stdio;
								this.func_name = func_name;
								this.entry_time = Clock.currTime;
								this.last_check = entry_time;
								stderr.writeln (profiler_enter_indent, `in(`~tid_string~`): `, func_name, ` at `, entry_time.toISOExtString["2014-05-15".length..$]);
							}
					}
				@disable this ();
			}
		}
	const string profiler (string name = q{profiler})()
		{/*...}*/
			return q{
				auto }~name~q{ = Profiler.begin;
				scope (success) }~name~q{.end (Profiler.ExitStatus.success);
				scope (failure) }~name~q{.end (Profiler.ExitStatus.failure);
			};
		}
	public {/*formatting}*/
		string profiler_enter_indent ()
			{/*...}*/
				return '\t'.repeat (indent++).array;
			}
		string profiler_exit_indent ()
			{/*...}*/
				return '\t'.repeat (--indent).array;
			}
	}
	private {/*formatting}*/
		static uint indent = 0;
	}
}
pure nothrow {/*algorithm}*/
	/* move all elements in a range (starting at index) up by one position */
	/* leaving an empty space at the indexed position */
	void shift_up_from (R)(ref R range, size_t index)
		if (hasLength!R && is_indexable!R)
		{/*...}*/
			static if (is_dynamic_array!R)
				range.grow (1);
			else ++range.length;

			for (size_t i = range.length-1; i > index; --i)
				range[i] = range[i-1];
		}
	/* move all elements in a range (starting at index) down one position */
	/* overwriting the element at the indexed position */
	void shift_down_on (R)(ref R range, size_t index)
		if (hasLength!R && is_indexable!R)
		{/*...}*/
			for (auto i = index; i < range.length-1; ++i)
				range[i] = range[i+1];
				
			static if (is_dynamic_array!R)
				range.shrink (1);
			else --range.length;
		}

	/* nothrow replacement for std.algorithm.reduce */
	auto reduce (alias func, R)(auto ref R range)
		{/*...}*/
			Unqual!(ElementType!R) accumulator;

			static if (__traits(compiles, accumulator = 0))
				accumulator = 0;

			// FUTURE static if (isRandomAccess) try to block and parallelize... or foreach (x; parallel(r))?
			static if (isInputRange!R)
				{/*...}*/
					while (not (range.empty))
						{/*...}*/
							func (accumulator, range.front);
							range.popFront;
						}
				}
			else if (isIterable!R)
				{/*...}*/
					foreach (ref element; range)
						func (accumulator, element);
				}
			else static assert (0, `reduce cannot iterate or traverse ` ~R.stringof);

			return accumulator;
		}
}
public {/*containers}*/
	template PriorityQueue (T)
		{/*...}*/
			import std.container: BinaryHeap;
			alias PriorityQueue = BinaryHeap!(Array!(T), "a > b"); // REVIEW
		}
}
public {/*multithreading}*/
	/* get the thread id of the current thread as a string truncated to some digits */
	const string tid_string (bool owner = false, uint digits = 4) (Tid to_translate = Tid.init) // REVIEW
		{/*...}*/
			import std.conv;
			static if (owner)
				auto tid = ownerTid;
			else auto tid = thisTid;
			if (to_translate != Tid.init)
				tid = to_translate;
			return to!string (*cast(ulong*) &tid) [$-digits..$];
		}
	/* actively clear a threads messagebox for a set time, */
	/* in debug mode, also print the message */
	void flush_messages (Duration watch_time = 1.msecs)
		in {/*...}*/
			assert (watch_time >= 1.msecs);
		}
		body {/*...}*/
			import std.concurrency;
			import std.datetime;
			import std.stdio;
			auto clock = Clock.currTime;
			while (Clock.currTime < clock + watch_time)
				{/*...}*/
					receiveTimeout (clock + watch_time - Clock.currTime, (Variant _)
						{/*...}*/
							debug {/*}*/
								stderr.writeln ("tid("~tid_string~"): warning: cleared unread "~to!string(_.type)~" message"); 
								stderr.flush;
							}
						});
				}
		}
}
public {/*tuples}*/
	template λ (alias f) {alias λ = f;}
	template Aⁿ (T...) {alias Aⁿ = T;}
}
public {/*ranges}*/
	/* construct a ForwardRange out of a range of ranges such that the inner ranges appear concatenated */
	struct Contigious (R)
		if (allSatify!(And!(is_indexable, Not!isForwardRange), R, ElementType!R))
		{/*...}*/
			private size_t i, j;
			R ranges;

			this (R ranges)
				{/*...}*/
					this.ranges = ranges;
				}
			@property auto length ()
				{/*...}*/
					import math: sum;
					return ranges.map!(r => r.length).sum;
				}

			auto ref front ()
				{/*...}*/
					return ranges[j][i];
				}
			void popFront ()
				{/*...}*/
					if (++i == ranges[j].length)
						{/*...}*/
							++j;
							i = 0;
						}
				}
			bool empty ()
				{/*...}*/
					return j >= ranges.length;
				}
			auto save ()
				{/*...}*/
					return this;
				}
		}
	struct Contigious (R)
		if (allSatisfy!(isForwardRange, R, ElementType!R))
		{/*...}*/
			R ranges;

			this (R ranges)
				{/*...}*/
					this.ranges = ranges;
				}
			@property auto length ()
				{/*...}*/
					import math: sum;
					return ranges.map!(r => r.length).sum;
				}

			auto ref front ()
				{/*...}*/
					return ranges.front.front;
				}
			void popFront ()
				{/*...}*/
					ranges.front.popFront;

					if (ranges.front.empty)
						ranges.popFront;
				}
			bool empty ()
				{/*...}*/
					return ranges.empty;
				}
			auto save ()
				{/*...}*/
					return this;
				}
		}
	auto contigious (R)(R ranges)
		{/*...}*/
			return Contigious!R (ranges);
		}
	unittest {/*contigious}*/
		int[2] x = [1,2];
		int[2] y = [3,4];
		int[2] z = [5,6];

		int[2][] A = [x,y,z];

		assert (A.contigious.sum == 21);
	}

	/* traverse a range with elements rotated left by some number of positions */
	auto rotate_elements (R)(R range, long positions = 1)
		{/*...}*/
			auto n = range.length;
			auto i = (positions + n) % n;
			assert (i > 0);
			return range.cycle[i..n+i];
		}
	/* pair each element with its successor in the range, pairing the last element with the first */
	auto adjacent_pairs (R)(R range)
		{/*...}*/
			return range.zip (range.rotate_elements);
		}
}
public {/*indices}*/
	import evx.math: Interval;
	alias Index = size_t;
	alias Indices = Interval!Index;
}
