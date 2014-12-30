module evx.operators.search;

/* generate an `in` operator from a search function

	Requires:
		a search function returning a value which is either an lvalue or dereferencable type
*/
template SearchOps (alias search)
	{/*...}*/
		private {/*import}*/
			import std.traits;
		}

		auto opBinaryRight (string op: `in`)(ParameterTypeTuple!search query)
			in {/*...}*/
				void dereference (T)(T q){auto p = *q;}
				void address (T)(ref T q){auto p = &q;}

				enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

				static assert (query.length == 1,
					error_header
					~ `search function can have only one argument`
				);

				static assert (
					is (typeof(dereference!(ReturnType!search))) 
					|| is (typeof(address!(ReturnType!search))),
					error_header
					~ `search return value must be pointer or reference`
				);
			}
			body {/*...}*/
				return search (query);
			}
	}
	unittest {/*...}*/
		import std.algorithm: find;
		import evx.range;

		static struct ByPtr
			{/*...}*/
				int[] data = [1,2,4,6,9];

				auto search (int x)
					{/*...}*/
						auto result = data.find (x);

						if (result.empty)
							return null;
						else return result.ptr;
					}

				mixin SearchOps!search;
			}
		static struct ByRef
			{/*...}*/
				string[] data = [`one`, `two`, `four`, `seven`];

				const string not_found;

				ref search (string i)
					{/*...}*/
						if (data.find (i).empty)
							return not_found;
						else return data.find (i).front;
					}

				mixin SearchOps!search;
			}

		if (auto x = 4 in ByPtr())
			assert (*x == 4);

		if (auto x = 3 in ByPtr())
			assert (0);

		if (auto x = `four` in ByRef())
			assert (x == `four`);

		if (auto x = `five` in ByRef())
			assert (0);

		assert ((3 in ByPtr()) == null);
		assert ((`three` in ByRef()) == null);
	}
