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

// TODO Aspects = Views + Extensions
debug = profiler;
// TODO DESIGN GOALS
/*
	DATA AND COMPUTATION
		DONE fixed buffers
			centrally managed static arrays
			fast allocation returns slices
			reserve in blocks for dynamic arrays
			RAII, managed at data source
		DONE range-based processing
			shallow containers over underlying static array slices
			actual data centrally managed, indexed by id types
			generally mutable ranges with immutable elements
			some mutation should be allowed to take place
				(must call specific method for mutable access?)
		DONE functional data paths
			no temp buffers, only source, swap and sink buffers
		DONE limited GC
			ok for semi-permanent or one-time stuff (services, filepaths, etc)
			don't use inside of functional pathways
	THREADS AND SHARING
		TODO service-based multithreading
			all non-main thread environments encapsulated in services
		TODO swap-based sharing
			per-thread swap buffers aka "client roster"
		TODO subscription-based queries
			eliminate message-passing overhead for regularly repeated queries 
			single queries can ask for single subscription
			message-based instantaneous option must be available for urgent queries
		TODO reserve messaging for control signals and urgent queries
			minimize urgent queries
	STRUCTS AND ALGORITHMS
		mixin-based structures
		traits-based dispatch & selection
		command-based construction
*/

public {/*misc}*/
	alias τ = tuple;

	const bool not (T)(const T value)
		{/*...}*/
			return !value;
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
	auto elaborate_exception (Ex, T...) (Ex exception, T message) if (is (Ex: Throwable))
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
public {/*search}*/
	/* specify how elements are compared for equality
	*/
	enum EqualityPolicy
		{/*...}*/
			/*
				use ==, if it is defined.
				otherwise, elements are tested for reflexive equality 
			*/  
			intrinsic, 
			/*
				ignore == and always test for reflexive equality.
			*/
			reflexive
		}

	/* result of a binary search over a sorted, indexable range.
		if the element was found, BinarySearchResult holds a pointer to the element and the element's position.
		otherwise, it holds a null pointer and the position that the element would occupy were it in the range.
	*/
	struct BinarySearchResult (T)
		{/*...}*/
			T* found;
			size_t position;
		}

	/* perform a binary search which assumes the range is ordered by the < operator
	*/
	auto binary_search (R, T = ElementType!R)(R range, T element)
		{/*...}*/
			return range.binary_search!(less_than!T)(element);
		}

	/* perform a customized policy-based binary search.
		by default, binary search compares elements with the < operator. 
		this can be overridden by supplying a comparison function as a template parameter. 
		the	range is assumed to be ordered according to the comparison function.
		
		equality checking is intrinsic by default, but can optionally be overridden as well.
	*/
	template binary_search (alias compare, EqualityPolicy equality = EqualityPolicy.intrinsic)
		if (is_comparison_function!compare)
		{/*...}*/
			auto binary_search (R, T = ElementType!R)(R range, T element)
				if (hasLength!R && is_indexable!R)
				{/*...}*/
					if (range.empty)
						return BinarySearchResult!T (null, 0L);

					long min = 0;
					long max = range.length;

					static if (hasMember!(T, `opEquals`) && equality != EqualityPolicy.reflexive)
						bool equal_to (ref const T that)
							{/*...}*/
								 return element == that;
							}
					else bool equal_to (ref const T that)
						{/*...}*/
							import math : reflexively_equal;
							return element.reflexively_equal!compare (that);
						}

					while (min < max)
						{/*...}*/
							alias sorted = compare;

							auto mid = (max + min)/2;

							if (equal_to (range[mid]))
								return BinarySearchResult!T (&range[mid], mid);
							else if (sorted (element, range[mid]))
								max = mid;
							else if (sorted (range[mid], element))
								min = mid + 1;
						}

					if (min < range.length && equal_to (range[min]))
						return BinarySearchResult!T (&range[min], min);
					else return BinarySearchResult!T (null, min);
				}
		}
}
public {/*move}*/
	/* move all elements in a range (starting at index) up by one position */
	/* leaving an empty space at the indexed position */
	void shift_up_from (R)(ref R range, size_t index)
		if (hasLength!R && is_indexable!R)
		{/*...}*/
			++range.length;

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
				
			--range.length;
		}
}
public {/*containers}*/
	template PriorityQueue (T)
		{/*...}*/
			import std.container: BinaryHeap;
			alias PriorityQueue = BinaryHeap!(Array!(T), "a > b");
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
public {/*metaprogramming}*/
	public {/*traits}*/
		/* test if type has a field */
		template has_field (T, field_T, string name)
			{/*...}*/
				const bool has_field ()
					{/*...}*/
						static if (hasMember!(T, name))
							{/*...}*/
								mixin(q{alias Field = typeof (T.}~name~q{);});
								return is (field_T : Field);
							}
						else return false;
					}
			}
		/* for each of reference_T's fields, test if Type has a compatible field */
		template has_fields (Type, reference_T)
			{/*...}*/
				const bool has_fields ()
					{/*...}*/
						foreach (member; __traits (allMembers, reference_T))
							{/*...}*/
								const bool is_function = isSomeFunction!(mixin(`reference_T.`~member));
								static if (is_function)
									continue;
								else {/*...}*/
									const bool has_no_type = !is (typeof (mixin(`reference_T.`~member)));
									static if (has_no_type)
										continue;
									else {/*...}*/
										alias Field = typeof (mixin(`reference_T.`~member));
										static if (has_field!(Type, Field, member))
											continue;
										else return false;
									}
								}

							}
						return true;
					}
			}
		/* test if a member has an attribute */
		template has_attribute (T, string member, alias attribute)
			{/*...}*/
				const bool has_attribute ()
					{/*...}*/
						foreach (type; mixin(q{__traits (getAttributes, T.}~member~q{)}))
							static if (is (type == attribute))
								return true;
						return false;
					}
			}
		/* test if function takes only pointer arguments */
		template takes_pointer (alias func)
			{/*...}*/
				const bool takes_pointer ()
					{/*...}*/
						return allSatisfy!(isPointer, ParameterTypeTuple!func);
					}
			}
		/* test if a template argument is a number  */
		template is_numerical_param (T...) if (T.length == 1)
			{/*...}*/
				const bool is_numerical_param = __traits(compiles, T[0] == 0);
			}
		/* test if a template argument is a string  */
		template is_string_param (T...) if (T.length == 1)
			{/*...}*/
				static if (__traits(compiles, typeof(T[0])))
						const bool is_string_param = isSomeString!(typeof(T[0]));
				else const bool is_string_param = false;
			}
		/* test if a template argument is a type  */
		template is_type (T...) if (T.length == 1)
			{/*...}*/
				const bool is_type = is (T[0]);
			}
		/* test if a template argument is an aliased symbol */
		template is_alias (T...) if (T.length == 1)
			{/*...}*/
				const bool is_alias = __traits(compiles, typeof (T[0])) 
					&& not (
						is_numerical_param!(T[0])
						|| is_string_param!(T[0])
					);
			}
		/* test if a function behaves syntactically as a comparison */
		template is_comparison_function (U...)
			if (U.length == 1)
			{/*...}*/
				static if (isSomeFunction!(U[0]))
					{/*...}*/
						alias Function = U[0];
						alias Params = ParameterTypeTuple!(U[0]);

						static if (Params.length == 2)
							{/*...}*/
								alias T = Params[0];
								static if (is (T == Params[1]))
									{/*...}*/
										alias Return = ReturnType!Function;
										static if (is (bool: Return) || is (Return: bool))
											enum is_comparison_function = true;
										else enum is_comparison_function = false;
									}
								else enum is_comparison_function = false;
							}
						else enum is_comparison_function = false;
					}
				else enum is_comparison_function = false;
			}
		/* test if a type is comparable using the < operator */
		template is_comparable (T...)
			if (T.length == 1)
			{/*...}*/
				static if (is (T[0]))
					{/*...}*/
						const T[0] a, b;
						enum is_comparable = __traits(compiles, a < b);
					}
				else enum is_comparable = false;
			}
		/* test if a range is indexable */
		template is_indexable (R)
			{/*...}*/
				enum is_indexable = __traits(compiles, R.init[0]);
			}
		/* test if T is a member function */
		template is_member_function (T...)
			if (T.length == 1)
			{/*...}*/
				enum is_member_function = isSomeFunction!(T[0])
					&& not (isFunctionPointer!(T[0])
						|| isDelegate!(T[0])
					);
			}
		/* test if a type can index D's built-in arrays and slices */
		template can_index_arrays (T)
			{/*...}*/
				enum can_index_arrays = __traits(compiles, T[].init[T.init]);
			}
		/* test if a member of T is publicly accessible */
		template is_accessible (T, string member)
			{/*...}*/
				enum is_accessible = mixin(q{__traits(compiles, T.} ~member~ q{)});
			}
	}
	public {/*mixins}*/
		/* a unique (up to the host type) identifier */
		mixin template TypeUniqueId (uint bit = 64)
			{/*...}*/
				static assert (is(typeof(this)), `mixin requires host struct`);

				struct Id
					{/*...}*/
						static auto create () nothrow
							{/*...}*/
								return typeof(this) (++generator);
							}
						private {/*data}*/
							static if (bit == 64)
								ulong id;
							else static if (bit == 32)
								uint id;
							else static if (bit == 16)
								ushort id;
							else static if (bit == 8)
								ubyte id;
							else static assert (0);
							__gshared typeof(id) generator;
						}
						mixin CompareBy!id;
					}
			}
		/* applies the command pattern to a struct */
		mixin template Command (Args...)
			{/*...}*/
				static assert (is(typeof(this)), `mixin requires host struct`);
				import std.typetuple;
				import std.typecons;

				alias Types = Filter!(is_type, Args);
				alias Names = Filter!(is_string_param, Args);

				static string command_property_declaration ()
					{/*...}*/
						static string command_getter_setter (string name)()
							{/*...}*/
								alias Type = Types[staticIndexOf!(name, Names)];
								return q{
									@property auto }~name~q{ (}~Type.stringof~q{ value)
										}`{`q{
											_}~name~q{ = value;
											return this;
										}`}`q{
									@property auto }~name~q{ ()
										}`{`q{
											return _}~name~q{;
										}`}`q{
								};
							}

						string code;
						foreach (name; Names)
							code ~= command_getter_setter!name;
						return code;
					}
				static string command_data_declaration ()
					{/*...}*/
						template prepend_underscore (string name)
							{enum prepend_underscore = `_`~name;}
						return alignForSize!Types ([staticMap!(prepend_underscore, Names)]);
					}

				mixin(command_property_declaration);
				mixin(command_data_declaration);
			}
		/* forward opApply (foreach) to a member */
		mixin template IterateOver (alias range)
			{/*...}*/
				static assert (is(typeof(this)), `mixin requires host struct`);
				alias Applied = typeof(range[0]);

				int opApply (scope int delegate(ref Applied) op)
					{/*...}*/
						int result;

						foreach (ref element; range)
							{/*...}*/
								result = op (element);

								if (result) 
									break;
							}

						return result;
					}
				int opApply (scope int delegate(size_t, ref Applied) op)
					{/*...}*/
						int result;

						foreach (i, ref element; range)
							{/*...}*/
								result = op (i, element);

								if (result) 
									break;
							}

						return result;
					}
				int opApply (scope int delegate(ref const Applied) op) const
					{/*...}*/
						return (cast()this).opApply (cast(int delegate(ref Applied)) op);
					}
				int opApply (scope int delegate(const size_t, ref const Applied) op) const
					{/*...}*/
						return (cast()this).opApply (cast(int delegate(size_t, ref Applied)) op);
					}
			}
		/* forward opCmp (<,>) to a member */
		mixin template CompareBy (alias member)
			{/*...}*/
				static assert (is(typeof(this)), `mixin requires host struct`);

				public {/*opCmp}*/
					int opCmp (ref const typeof(this) that) const
						{/*...}*/
							const string name = __traits(identifier, member);
							mixin(q{
								return compare (this.} ~name~ q{, that.} ~name~ q{);
							});
						}
					int opCmp (const typeof(this) that) const
						{/*...}*/
							const string name = __traits(identifier, member);
							mixin(q{
								return compare (this.} ~name~ q{, that.} ~name~ q{);
							});
						}
				}
			}
		/* enable mixin load_dynamic_library!"libname" */
		/* which attempts to link all member extern (C) function pointers with the specified lib */
		/* when mixed into a member function (typically the constructor) of a type */
		mixin template DynamicLibraryLoader ()
			{/*...}*/
				static const string load_dynamic_library (string library) ()
					{/*...}*/
						return `mixin(load_dynamic_symbols!(typeof (this), "`~library~`"));`;
					}
				static const string load_dynamic_symbols (caller_T, string library) () // TODO platform independence
					{/*...}*/
						string command = '{'~`
							import std.c.linux.linux;
							void* library = dlopen ("`~library~`", RTLD_NOW);
						`;
						foreach (symbol; __traits (allMembers, caller_T))
							{/*...}*/
								const string load_symbol = `mixin(load_dynamic_symbol!"`~symbol~`");`;
								const string enforce_symbol = `enforce (`~symbol~`, "couldn't load symbol `~symbol~` from library `~library~`");`;

								static if (isFunctionPointer!(__traits (getMember, caller_T, symbol)))
									static if (functionLinkage!(__traits (getMember, caller_T, symbol)) == "C")
										command ~= load_symbol ~ enforce_symbol;
							}
						return command ~ '}';
					}
				static const string load_dynamic_symbol (string symbol) ()
					{/*...}*/
						return symbol~` = cast (typeof (`~symbol~`)) dlsym (library, "`~symbol~`");`;
					}
			}
	}
	public {/*type processing}*/
		template pointer_to (T)
			{/*...}*/
				alias pointer_to = T*;
			}
		template array_of (T)
			{/*...}*/
				alias array_of = T[];
			}
		/* create a tuple of all members of a type that have a given alias attribute tag */
		template collect_members (T, alias attribute)
			{/*...}*/
				immutable string[] collect_members ()
					{/*...}*/
						immutable string[] collect (members...) ()
							{/*...}*/
								static if (members.length == 0)
									return [];
								else static if (members[0] == "this")
									return collect!(members[1..$]);
								else static if (has_attribute!(T, members[0], attribute))
									return members[0] ~ collect!(members[1..$]);
								else return collect!(members[1..$]);
							}
						return collect!(__traits (allMembers, T));
					}
			}
		/* convert any kind of tuple to its corresponding TypeTuple */
		template types_of (T...)
			{/*...}*/
				static if (__traits(compiles, typeof(T)))
					alias types_of = typeof(T);
				else alias types_of = T;
			}
		/* build a TypeTuple of all nested structs and classes defined within T */
		template get_substructs (T)
			{/*...}*/
				private template get_substruct (T)
					{/*...}*/
						template get_substruct (string member)
							{/*...}*/
								import std.range;
								static immutable name = q{T.} ~member;

								static if (member.empty)
									enum get_substruct = 0;
								
								else static if (mixin(q{is (}~name~q{)})
									&& is_accessible!(T, member)
									&& not (mixin(q{is (}~name~q{ == T)}))
								) mixin(q{
									alias get_substruct = T.} ~member~ q{;
								});
								else enum get_substruct = 0;
							}
					}

				alias get_substructs = Filter!(Not!is_numerical_param, 
					staticMap!(get_substruct!T, __traits(allMembers, T))
				);
			}
		/* build a string tuple of all assignable members of T */
		template assignable_members (T)
			{/*...}*/
				private template is_assignable (T)
					{/*...}*/
						template is_assignable (string member)
							{/*...}*/
								enum is_assignable = isAssignable!(typeof(__traits(getMember, T, member)));
							}
					}

				alias assignable_members = Filter!(is_assignable!T, __traits(allMembers, T));
			}
	}
	public {/*code generation}*/
		/* declare variables according to format (see unittest) */
		static string autodeclare (Params...)() 
			if (Params.length > 0)
			{/*...}*/
				alias Types = Filter!(is_type, Params);
				alias fixes = Filter!(is_string_param, Params);

				static if (fixes.length == 0)
					{/*...}*/
						const string prefix = ``;
						const string suffix = `; `;
					}
				else static if (fixes.length == 1)
					{/*...}*/
						template is_punctuation (c...) if (c.length == 1)
							{/*...}*/
								import std.ascii: isPunctuation;
								const bool is_punctuation = c[0][0].isPunctuation;
							}
						static if (anySatisfy!(is_punctuation, fixes[0].array))
							{/*suffix}*/
								const string prefix = ``;
								const string suffix = fixes[0];
							}
						else {/*prefix}*/
								const string prefix = fixes[0];
								const string suffix = `; `;
						}
					}
				else static if (fixes.length == 2)
					{/*...}*/
						const string prefix = fixes[0];
						const string suffix = fixes[1];
					}
				else static assert (0);

				string code;
				foreach (i, T; Types)
					code ~= T.stringof~` `~prefix~`_`~to!string(i)~suffix;
				return code;
			}
			unittest {/*autodeclare}*/
				static assert (autodeclare!(int, byte, `x`)			== q{int x_0; byte x_1; });
				static assert (autodeclare!(int, byte, `x`, `, `) 	== q{int x_0, byte x_1, });
				static assert (autodeclare!(int, byte, char, `:: `)	== q{int _0:: byte _1:: char _2:: });
			}
		/* apply a predicate to a series of rvalues */
		static string apply_to_each (string op, Names...)()
			if (allSatisfy!(is_string_param, Names))
			{/*...}*/
				string code;

				foreach (name; Names)
					code ~= q{
						} ~ name ~ q{.} ~ op ~ q{;
					};

				return code;
			}
	}
}
public {/*tags}*/
	struct Tag 
		{/*...}*/
			public:
			alias code this;
			public {/*toString}*/
				const @property string toString ()
					{/*...}*/
						return dictionary[this.code];
					}
			}
			private:
			private {/*data}*/
				ulong code;
			}
			private {/*☀}*/
				this (ulong code)
					{/*...}*/
						this.code = code;
					}
				@disable this ();
			}
			static:
			__gshared {/*data}*/
				string[ulong] dictionary;
			}
			static {/*hashing}*/
				immutable ulong generate (string str)()
					{/*...}*/
						static if (str.length == 0)
							return 5381;
						else {/*...}*/
							const auto tag = generate!(str[1..$]);
							return (tag << 6) ^ (tag << 16) ^ str[0];
						}
					}
			}
		}
	Tag tag (string label)()
		{/*...}*/
			auto code = Tag.generate!label;
			if (code !in Tag.dictionary)
				Tag.dictionary[code] = label;
			else assert (Tag.dictionary[code] == label);
			return Tag (code);
		}
	Tag tag (T)()
		{/*...}*/
			return tag!(T.stringof);
		}
}
public {/*tuples}*/
	template λ (alias f) {alias λ = f;}
	template Aⁿ (Tn...) {alias Aⁿ = Tn;}
}
