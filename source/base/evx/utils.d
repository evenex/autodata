module evx.utils;

private {/*import std}*/
	import std.typecons:
		Tuple, tuple;

	import std.typetuple:
		ReplaceAll;

	import std.string:
		toStringz;

	import std.traits:
		isSomeString;

	import std.range:
		repeat;

	import std.datetime:
		Clock, SysTime;

	import std.stdio:
		stderr;

	import std.concurrency:
		Tid, thisTid;

	import std.conv:
		text;
}
private {/*import evx}*/
	import evx.meta:
		CompareBy;

	import evx.math:
		zero, Interval;
}

pure nothrow:

debug = profiler;
public {/*c-compatibility}*/
	/* forward a set of arguments, converting strings into null-terminated c-strings
	*/
	static to_c (Args...)(Args args)
		{/*...}*/
			alias CArgs = ReplaceAll!(string, const(char)*, Args);
			CArgs c_args;

			foreach (i, arg; args)
			static if (isSomeString!(typeof(arg)))
			c_args[i] = args[i].toStringz;
			else c_args[i] = args[i];

			return τ(c_args);
		}
}
public debug {/*}*/
	/* pure nothrow writeln 
	*/
	auto writeln (Args...)(Args args)
		{/*...}*/
			debug try {/*...}*/
				foreach (arg; args)
					stderr.write (arg, ` `);
				stderr.writeln;
			}
			catch (Exception) assert (0);
		}
		
	/* print a function call with arguments 
	*/
	string function_call_to_string (string name, Args...) (Args args)
		{/*...}*/
			string call;
			
			debug try foreach (arg; args)
				call ~= arg.text~ `, `;
			catch (Exception) assert (0); // UPLOAD
				
			if (call.length == 0)
				return name;
			else return name~ ` (` ~call[0..$-2]~ `)`;
		}
		
	/* suppress stderr while in scope 
	*/
	template error_suppression (int line = __LINE__)
		{/*...}*/
			debug string error_suppression ()
				{/*...}*/
					enum ID = __LINE__.text;
		
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
			else string error_suppression = ``;
		}

	/* get the thread id of the current thread as a string truncated to some digits 
	*/
	auto tid_string (uint digits = 4)()
		{/*...}*/
			debug try {/*...}*/
				auto tid = thisTid;
				
				return (*cast(ulong*) &tid).text[$-digits..$];
			}
			catch (Exception) assert (0);
		}
}
debug (profiler) {/*...}*/
	/* write information about the thread environment to the output 
		and time program execution through checkpoints */
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
						debug (profiler) try
							{/*...}*/
								auto check = Clock.currTime - last_check;
								
								this.last_check = Clock.currTime;
								
								stderr.writeln (check, ` `, marks);
								stderr.flush;
							}
						catch (Exception) assert (0);
					}
			}
			public {/*~}*/
				~this ()
					{/*...}*/
						writeln (profiler_exit_indent,
							exit_status == ExitStatus.failure? `FAILED!`:``, 
							`ex(` ~tid_string~`): `, func_name, ` after `, exit_time - entry_time);
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
						debug try {/*...}*/
							this.func_name = func_name;
							this.entry_time = Clock.currTime;
							this.last_check = entry_time;

							writeln (profiler_enter_indent, `in(` ~tid_string~ `):`, func_name, `at`, entry_time.toISOExtString["2014-05-15".length..$]);
						}
						catch (Exception) assert (0);
					}
				@disable this ();
			}
		}

	/* convenience function for constructing a named profiler 
	*/
	string profiler (string name = q{profiler})()
		{/*...}*/
			return q{
				import evx.utils: Profiler;

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
		debug static uint indent = 0;
	}
}
public {/*UDA tags}*/
	/* for non-const sections or members in a series of consts 
		will not override const label (const:)
	*/
	enum vary;

	/* for non-pure sections or functions in a series of pures 
		will not override pure label (pure:)
	*/
	enum imp;
}
public {/*tuples}*/
	alias τ = tuple;
	template Aⁿ (T...) {alias Aⁿ = T;}
}
public {/*indices}*/
	alias Index = size_t;
	alias Indices = Interval!Index;
}
