module spacecadet.memory.reference;

private {/*import}*/
	import spacecadet.core;
	import spacecadet.meta;

	import spacecadet.memory.transfer;
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
template forward (Aliases...)
	{/*...}*/
		alias forward = Map!(forward, Aliases);
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
			in {/*...}*/
				assert (ptr);
			}
			body {/*...}*/
				return *ptr;
			}
		
		alias deref this;
	}
auto borrow (T)(ref T resource)
	{/*...}*/
		return Borrowed!T (resource);
	}

/* union of borrowed and owned resource, automatically aliases itself to given type irrespective of held type 
*/
struct MaybeBorrowed (T)
	{/*...}*/
		auto ref opAssign (U)(auto ref U value)
			if (Contains!(U, Types))
			{/*...}*/
				enum selected = IndexOf!(U, Types);

				is_borrowed = selected == is (U == Borrowed!T);

				indexed_cast!selected = value;

				return this;
			}

		this (U)(auto ref U value)
			{/*...}*/
				this = value;
			}

		ref deref ()
			{/*...}*/
				if (is_borrowed)
					return borrowed;
				else return owned;
			}

		alias deref this;

		private:

		alias Types = Cons!(T, Borrowed!T);

		byte[
			Reduce!(λ!q{(uint a, uint b) = a > b? a : b},
				Map!(λ!q{(T) = T.sizeof}, 
					Types
				)
			)
		] value;

		bool is_borrowed;

		ref owned ()
			{/*...}*/
				return indexed_cast!(IndexOf!(T, Types));
			}
		ref borrowed ()
			{/*...}*/
				return indexed_cast!(IndexOf!(Borrowed!T, Types)).deref;
			}

		ref indexed_cast (uint i)()
			in {/*...}*/
				static if (i == IndexOf!(T, Types))
					assert (not (is_borrowed));
				else static if (i == IndexOf!(Borrowed!T, Types))
					assert (is_borrowed);
				else static assert (0);
			}
			body {/*...}*/
				return *cast(Types[i]*) value.ptr;
			}
	}
