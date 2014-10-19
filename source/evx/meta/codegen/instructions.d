module evx.codegen.instructions;

private {/*imports}*/
	import std.typetuple;

	import evx.traits;
}

/* apply a suffix operation to a series of identifiers 
*/
string apply_to_each (string op, Names...)()
	if (allSatisfy!(is_string_param, Names))
	{/*...}*/
		string code;

		foreach (name; Names)
			code ~= q{
				} ~name~ op ~ q{;
			};

		return code;
	}
	unittest {/*...}*/
		int a = 0, b = 1, c = 2, d = 3;

		mixin(apply_to_each!(`++`, `a`, `b`, `c`, `d`));

		assert (a == 1);
		assert (b == 2);
		assert (c == 3);
		assert (d == 4);

		mixin(apply_to_each!(`*= -1`, `a`, `b`, `c`, `d`));

		assert (a == -1);
		assert (b == -2);
		assert (c == -3);
		assert (d == -4);
	}
