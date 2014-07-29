module evx.arithmetic;

private {/*import evx}*/
	import evx.utils: reduce;
}

pure nothrow:

/* ctfe-able arithmetic predicates
*/
auto add (T)(T a, T b) 
	{return a + b;}
auto subtract (T)(T a, T b) 
	{return a - b;}

/* get an array of natural numbers from 0 to max-1 */
auto ℕ (size_t max)()
	{/*↓}*/
		return ℕ (max);
	}
auto ℕ (T)(T count)
	if (isIntegral!T)
	{/*...}*/
		return sequence!((i,n) => i[0]+n)(0)
			.map!(n => cast(T)n)
			.take (count.to!size_t);
	}
/* compute the product of a sequence */
auto Π (T)(auto ref T sequence)
	{/*...}*/
		return sequence.reduce!((Π,x) => Π*x);
	}
/* compute the sum of a sequence */
auto Σ (T)(auto ref T sequence)
	{/*...}*/
		return sequence.sum;
	}
auto sum (T)(auto ref T sequence)
	{/*...}*/
		return sequence.reduce!((Σ,x) => Σ+x);
	}
