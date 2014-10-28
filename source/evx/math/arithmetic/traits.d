module evx.math.arithmetic.traits;

import std.traits;
import evx.math.algebra;

/* test whether a type is capable of addition, subtraction, multiplication and division 
*/
template supports_arithmetic (T)
	{/*...}*/
		enum one = unity!(const(Unqual!T));

		enum supports_arithmetic = __traits(compiles,
			{auto x = one, y = one; static assert (__traits(compiles, x+y, x-y, x*y, x/y));}
		);
	}

/* test whether a number is odd or even at compile-time 
*/
template is_even (size_t n)
	{/*...}*/
		enum is_even = n % 2 == 0;
	}
template is_odd (size_t n)
	{/*...}*/
		enum is_odd = not (is_even);
	}
template is_multiple_of (size_t m)
	{/*...}*/
		template is_multiple_of (size_t n)
			{/*...}*/
				enum is_multiple_of = n % m == 0;
			}
	}
