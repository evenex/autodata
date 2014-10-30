module evx.operators.comparison;

private {/*imports}*/
	import evx.math.logic;
}

/* forward opCmp (<,>,<=,>=) 
*/

mixin template ComparisonOps (alias member)
	{/*...}*/
		static assert (is(typeof(this)), `mixin requires host struct`);

		auto opCmp ()(auto ref const typeof(this) that) const
			{/*...}*/
				import evx.math.ordinal: compare;

				enum name = __traits(identifier, member);

				mixin(q{
					return compare (this.} ~name~ q{, that.} ~name~ q{);
				});
			}
	}
	unittest {/*...}*/
		debug struct Test {int x; mixin ComparisonOps!x;}

		assert (Test(1) < Test(2));
		assert (Test(1) <= Test(2));
		assert (not (Test(1) > Test(2)));
		assert (not (Test(1) >= Test(2)));

		assert (not (Test(1) < Test(1)));
		assert (not (Test(1) > Test(1)));
		assert (Test(1) <= Test(1));
		assert (Test(1) >= Test(1));
	}