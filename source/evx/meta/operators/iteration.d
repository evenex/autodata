module evx.operators.iteration;

private {/*imports}*/
	import std.traits;
	import std.range;

	import evx.math.logic;
	import evx.traits.concepts;
	import evx.operators.transfer;
}

struct IterationTraits (R)
	{/*...}*/
		mixin Traits!(
			`is_input_range`, q{static assert (isInputRange!R);},
			`is_iterable`, q{static assert (is_input_range || TransferTraits!R.has_pointer);},
		);
	}

enum Iteration {constant, mutable}

/* forward opApply (foreach) 
*/
mixin template IterationOps (alias container, Iteration iteration = Iteration.mutable)
	{/*...}*/
		import std.traits;

		static assert (is(typeof(this)), `mixin requires host struct`);

		static if (iteration is Iteration.mutable)
			{/*...}*/
				int opApply (scope int delegate(ref typeof(container[0])) op)
					{/*...}*/
						int result;

						foreach (ref element; container)
							{/*...}*/
								result = op (element);

								if (result) 
									break;
							}

						return result;
					}
				int opApply (scope int delegate(size_t, ref typeof(container[0])) op)
					{/*...}*/
						int result;

						foreach (i, ref element; container)
							{/*...}*/
								result = op (i, element);

								if (result) 
									break;
							}

						return result;
					}
			}
		else static if (iteration is Iteration.constant)
			{/*...}*/
				int opApply (scope int delegate(const ref typeof(container[0])) op) const
					{/*...}*/
						return (cast()this).opApply (cast(int delegate(ref typeof(container[0]))) op);
					}
				int opApply (scope int delegate(const size_t, const ref Unqual!(typeof(container[0]))) op) const
					{/*...}*/
						return (cast()this).opApply (cast(int delegate(size_t, ref Unqual!(typeof(container[0])))) op);
					}
			}
		else static assert (0);
	}
	unittest {/*...}*/
		import std.conv: to;

		debug struct Test {int[4] x; pure : mixin IterationOps!x;}

		static assert (isIterable!Test);

		auto t = Test ([1,2,3,4]);

		foreach (i; t)
			i = 0;

		assert (not (t == Test ([0,0,0,0])));

		auto sum = 0;
		foreach (i; t)
			sum += i;

		assert (sum == 10);

		foreach (ref i; t)
			i = sum;

		assert (t == Test ([10, 10, 10, 10]));

		foreach (i, ref j; t)
			j = i.to!int + 1;

		assert (t == Test([1,2,3,4]));
	}
