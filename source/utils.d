module evx.utils;

// REVIEW & REFACTOR
private {/*import std}*/
	//import std.traits;

	import std.typecons:
		Tuple, tuple;

	import std.typetuple:
		templateAnd, templateOr, templateNot;

	//import std.container;
	//import std.algorithm;
	//import std.math;
	import std.range:
		repeat;

	import std.datetime:
		Clock, SysTime;

	import std.stdio:
		stderr, writeln;

	//import std.string;
	//import std.ascii;
	import std.concurrency:
		Tid, thisTid;

	import std.conv:
		text;
}

pure nothrow:

//import resource.arrays: is_dynamic_array;

import evx.math:
	Interval;
//import evx.meta;
//import evx.functional: zip, map;

debug = profiler;

public {/*misc}*/
	alias τ = tuple;

	const bool not (T)(const T value)
		{/*...}*/
			return !value;
		}
		
	const bool not (alias predicate, Args...)(const Args args)
		if (isSomeFunction!predicate)
		{/*...}*/
			return not (predicate (args));
		}

	alias And = templateAnd;
	alias Or  = templateOr;
	alias Not = templateNot;

	/* simulate opCmp 
	*/
	int compare (T,U)(T a, U b) pure nothrow
		{/*...}*/
			static if (__traits(compiles, a.opCmp (b)))
				return a.opCmp (b);
			else static if (allSatisfy!(isNumeric, T, U))
				return cast(int)(a - b);
			else static assert (0, `can't compare ` ~T.stringof~ ` with ` ~U.stringof);
		}

	/* readability-enhancing tag for non-const sections or members in a series of consts. 
		will not override const label (const:)
	*/
	enum vary;

	/* readability-enhancing tag for non-pure sections or functions in a series of pures. 
		will not override pure label (pure:)
	*/
	enum imp;
}
debug {/*}*/
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
			const string type = is (Ex == Warning)? `warning`: `error`;

			stderr.writeln (`tid(` ~tid_string~ `): ` ~type~ ` `, message, ` @` ~exception.file~ `(`, exception.line, `): ` ~exception.msg);

			if (not (is (Ex == Warning)))
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
			void examine_fields ()
				{/*...}*/
					static if (isAggregateType!T)
						alias Record = T;
					else static if (isPointer!T)
						alias Record = PointerTarget!T;
					else static assert (0, `can't examine fields of ` ~T.stringof);

					string record_type = Record.stringof~ ' ';
					writeln (record_type ~__traits (identifier, record)~ `:`);

					foreach (field; __traits (allMembers, Record))
						{/*...}*/
							const bool is_field = field != `this` && __traits (compiles, typeof (__traits (getMember, record, field)));
							
							static if (not (is_field))
								continue;
							else {/*...}*/
								alias field_T = typeof (__traits (getMember, record, field));
								
								static if (isPointer!field_T)
									alias Field = PointerTarget!field_T;
								else alias Field = field_T;

								static if (show_types)
									string type = Field.stringof~' '; // TODO tilde formatting
								else 
									string type = "";

								alias member = Alias!(__traits (getMember, record, field));
								static if (__traits (getProtection, member) == `public`) // TODO is_accesible
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
									writeln (` ` ~type~field~ `: `, __traits (getMember, record, field));
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
				call ~= arg.text~ `, `;
				
			if (call.length == 0)
				return name;
			else return name~ ` (` ~call[0..$-2]~ `)`;
		}
		
	/* suppress stderr while in scope */
	template error_suppression (int line = __LINE__)
		{/*...}*/
			debug auto error_suppression ()
				{/*...}*/
					const string ID = __LINE__.text;
		
					return q{
						int errstream} ~ID~ q{;
						}`{`q{
							import std.c.stdio;
							import std.c.linux.linux;
							
							errstream} ~ID~ q{ = dup (stderr.fileno);
							freopen ("/dev/null", "w", stderr);
						}`}`q{
						scope (exit) }`{`q{
							import std.c.stdio;
							import std.c.linux.linux;
							
							fflush (stderr);
							dup2 (errstream} ~ID~ q{, stderr.fileno);
						}`}`q{
					};
				}
			else enum error_suppression = ``;
		}
		
	/* write information about the thread environment to the output */
	/* and time program execution through checkpoints */
	struct Profiler
		{/*...}*/
			enum ExitStatus {success, failure}

			pure nothrow:
			
			public:
			public {/*interface}*/
				static Profiler begin (string func_name = __PRETTY_FUNCTION__)
					{/*...}*/
						return Profiler (func_name);
					}
					
				void end (ExitStatus exit_status)
					{/*...}*/
						debug (profiler) try
							{/*...}*/
								this.exit_time = Clock.currTime;
								this.exit_status = exit_status;
							}
						catch (Exception) assert (0);
					}
					
				void checkpoint (T...)(T marks)
					{/*...}*/
						debug (profiler)
							{/*...}*/
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
						debug (profiler) try
							{/*...}*/
								stderr.writeln (profiler_exit_indent,
									exit_status == ExitStatus.failure? `FAILED!`:``, 
									`ex(` ~tid_string~`): `, func_name, ` after `, exit_time-entry_time);

								stderr.flush;
							}
						catch (Exception) assert (0);
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
						debug (profiler) try
							{/*...}*/
								import std.stdio;
								this.func_name = func_name;
								this.entry_time = Clock.currTime;
								this.last_check = entry_time;
								stderr.writeln (profiler_enter_indent, `in(` ~tid_string~ `): `, func_name, ` at `, entry_time.toISOExtString["2014-05-15".length..$]);
							}
						catch (Exception) assert (0);
					}
				@disable this ();
			}
		}
	const string profiler (string name = q{profiler})()
		{/*...}*/
			return q{
				auto } ~name~ q{ = Profiler.begin;
				scope (success) } ~name~ q{.end (Profiler.ExitStatus.success);
				scope (failure) } ~name~ q{.end (Profiler.ExitStatus.failure);
			};
		}
	public {/*formatting}*/
		auto profiler_enter_indent ()
			{/*...}*/
				debug return '\t'.repeat (indent++);
			}
		auto profiler_exit_indent ()
			{/*...}*/
				debug return '\t'.repeat (--indent);
			}
	}
	private {/*formatting}*/
		static uint indent = 0;
	}
}
public {/*move}*/
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
}
public {/*containers}*/
	template PriorityQueue (T)
		{/*...}*/
			alias PriorityQueue = BinaryHeap!(Array!(T), "a > b"); // REVIEW
		}
}
public {/*multithreading}*/
	/* get the thread id of the current thread as a string truncated to some digits */
	auto tid_string (bool owner = false, uint digits = 4)(Tid to_translate = Tid.init) // REVIEW
		{/*...}*/
			debug try {/*...}*/
				static if (owner)
					auto tid = ownerTid;
				else auto tid = thisTid;
				
				if (to_translate != Tid.init)
					tid = to_translate;
					
				return (*cast(ulong*) &tid).text [$-digits..$];
			}
			catch (Exception) assert (0);
		}
}
public {/*tuple}*/
	template Aⁿ (T...) {alias Aⁿ = T;}
}
public {/*ranges}*/
	/* construct a ForwardRange out of a range of ranges such that the inner ranges appear concatenated 
	*/
	struct Contigious (R)
		if (allSatify!(And!(is_indexable, Not!isForwardRange), R, ElementType!R))
		{/*...}*/
			// TODO pure nothrow
			private size_t i, j; // TODO private
			R ranges;

			this (R ranges)
				{/*...}*/
					this.ranges = ranges;
				}
			@property auto length ()
				{/*...}*/
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
			// TODO pure nothrow
			R ranges; // TODO private

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
		import std.range: equal;
	
		int[2] x = [1,2];
		int[2] y = [3,4];
		int[2] z = [5,6];

		int[2][] A = [x,y,z];

		assert (A.contigious.equal ([1,2,3,4,5,6]));
	}

	/* traverse a range with elements rotated left by some number of positions 
	*/
	auto rotate_elements (R)(R range, long positions = 1)
		in {/*...}*/
			auto n = range.length;
			assert ((positions + n) % n > 0);
		}
		body {/*...}*/
			auto n = range.length;
			auto i = (positions + n) % n;
			
			return range.cycle[i..n+i];
		}

	/* pair each element with its successor in the range, pairing the last element with the first 
	*/
	auto adjacent_pairs (R)(R range)
		{/*...}*/
			return range.zip (range.rotate_elements);
		}

	/* test if an attempted slice will be within some bounds 
	*/
	bool slice_within_bounds (size_t i, size_t j, size_t length)
		{/*...}*/
			return i <= j && j <= length && i < length;
		}
}
public {/*indices}*/
// TODO	import evx.math: Interval;
	alias Index = size_t;
	alias Indices = Interval!Index;
}
