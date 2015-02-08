module evx.memory.reference;

private {/*import}*/
	import evx.type;

	import evx.memory.transfer;
}

/* forward an argument, as lvalue reference or rvalue move 
*/
template forward (alias symbol)
	{/*...}*/
		static if (__traits(isRef, symbol))
			alias forward = symbol;
		else auto forward ()
			{/*...}*/
				typeof(symbol) value;
				move (symbol, value);
				
				return value;
			}
	}

// TODO coalesce forward methods when this bug is squashed
template forward2 (Aliases...) // BUG https://issues.dlang.org/show_bug.cgi?id=14096
	{/*...}*/
		auto ref f (uint i)()
			{/*...}*/
				return forward!(Aliases[i]);
			}

		alias forward2 = Map!(f, Count!Aliases);
	}

/* a borrowed resource bypasses RAII and move semantics 
*/
struct Borrowed (T)
	{/*...}*/
		T* ptr;

		this (ref T resource)
			{/*...}*/
				this = resource;
			}

		auto ref opAssign (ref T resource)
			{/*...}*/
				ptr = &resource;

				return this;
			}

		ref deref ()
			{/*...}*/
				return *ptr;
			}

		alias deref this;
	}
auto borrow (T)(ref T resource)
	{/*...}*/
		return Borrowed!T (resource);
	}
