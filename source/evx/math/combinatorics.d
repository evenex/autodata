module evx.math.combinatorics;

private {/*imports}*/
	private {/*std}*/
		import std.typetuple; 
		import std.traits; 
		import std.functional;
	}
}

pure nothrow:

auto factorial (T)(T n)
	if (isIntegral!T)
	{/*...}*/
		pure static size_t fac (size_t n) nothrow
			{/*...}*/
				if (n <= 1) return 1;
				else return n*fac (n-1);
			}

		return fac (n);
	}
auto binomial (T1, T2)(T1 n, T2 k)
	if (allSatisfy!(isIntegral, T1, T2))
	{/*...}*/
		return n.factorial / (k.factorial * (n-k).factorial);
	}
alias choose = binomial;

unittest {/*...}*/
	{/*ctfe-factorials}*/
		assert (0.factorial == 1);  
		assert (1.factorial == 1);
		assert (2.factorial == 2);
		assert (3.factorial == 6);
		assert (4.factorial == 24);
		assert (5.factorial == 120);
		assert (6.factorial == 720);
		assert (7.factorial == 5040);
		assert (8.factorial == 40320);
		assert (9.factorial == 362880);
		assert (10.factorial == 3628800);
		assert (11.factorial == 39916800);
		assert (12.factorial == 479001600);

		version(X86_64)
			{/*...}*/
				assert (13.factorial == 6227020800);
				assert (14.factorial == 87178291200);
				assert (15.factorial == 1307674368000);
				assert (16.factorial == 20922789888000);
				assert (17.factorial == 355687428096000);
				assert (18.factorial == 6402373705728000);
				assert (19.factorial == 121645100408832000);
				assert (20.factorial == 2432902008176640000);
			}
	}
	{/*pascal's triangle}*/
		assert (0.choose (0) == 1);

		assert (1.choose (0) == 1);
		assert (1.choose (1) == 1);

		assert (2.choose (0) == 1);
		assert (2.choose (1) == 2);
		assert (2.choose (2) == 1);

		assert (3.choose (0) == 1);
		assert (3.choose (1) == 3);
		assert (3.choose (2) == 3);
		assert (3.choose (3) == 1);

		assert (4.choose (0) == 1);
		assert (4.choose (1) == 4);
		assert (4.choose (2) == 6);
		assert (4.choose (3) == 4);
		assert (4.choose (4) == 1);

		assert (5.choose (0) == 1);
		assert (5.choose (1) == 5);
		assert (5.choose (2) == 10);
		assert (5.choose (3) == 10);
		assert (5.choose (4) == 5);
		assert (5.choose (5) == 1);
	}
}
