module evx.operators.error;

package template StandardErrorMessages ()
	{/*...}*/
		alias Element (T) = ElementType!(Select!(is (T == U[2], U), T, T[2]));

		static if (__traits(compiles, fullyQualifiedName!(typeof(this))))
			enum error_header = fullyQualifiedName!(typeof(this)) ~ `: `;

		else enum error_header = typeof(this).stringof ~ `: `;

		enum type_mismatch_error = error_header
			~ Map!(Element, Selected).stringof ~ ` does not convert to ` ~ Map!(Element, Map!(ExprType, limits)).stringof;

		auto out_of_bounds_error (T, U)(T arg, U limit) 
			{return error_header ~ `bounds exceeded! ` ~ arg.text ~ ` not in ` ~ limit.text;}
	}
