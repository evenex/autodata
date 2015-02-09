module evx.adaptors.common;

private {/*import}*/
	import std.conv: text;

	import evx.type;
	import evx.range;
}

struct CommonInterface (Types...)
	if (Types.length > 1)
	{/*...}*/
		byte[
			Reduce!(λ!q{(uint a, uint b) = a > b? a : b},
				Map!(λ!q{(T) = T.sizeof}, 
					Types
				)
			)
		] value;

		ref opCast (T)()
			{/*...}*/
				return indexed_cast!(IndexOf!(T, Types));
			}

		auto ref opDispatch (string op, Args...)(Args args)
			{/*...}*/
				enum visit (uint i) = q{
					case } ~ i.text ~ q{:
						return indexed_cast!} ~ i.text ~ q{.} ~ op ~ q{ (args);
				};

				switch (current)
					{/*...}*/
						mixin([Map!(visit, Count!Types)].join.text);
						default: assert (0);
					}
			}

		auto ref opAssign (T)(auto ref T value)
			{/*...}*/
				import evx.memory;

				current = IndexOf!(T, Types);

				this.value[0..T.sizeof] = value.bytes;

				return this;
			}

		private:

		int current;

		ref indexed_cast (uint i)()
			in {/*...}*/
				assert (i == current);
			}
			body {/*...}*/
				return *cast(Types[i]*) value.ptr;
			}
	}
