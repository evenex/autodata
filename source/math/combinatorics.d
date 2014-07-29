module evx.combinatorics;

private {/*import std}*/
	import std.traits: 
		isIntegral;
}

pure nothrow:

auto factorial (T)(T n)
	if (isIntegral!T)
	{/*...}*/
		pure static real fac (real n) // REVIEW this should be T unless we ask for extended range
			{/*...}*/
				if (n <= 1) return 1;
				else return n*fac (n-1);
			}

		static if (__ctfe)
			return fac (n);
		else return std.functional.memoize!fac (n);
	}
auto binomial (T1, T2)(T1 n, T2 k)
	if (allSatisfy!(isIntegral, T1, T2))
	{/*...}*/
		return n.factorial / (k.factorial * (n-k).factorial);
	}
alias choose = binomial;
