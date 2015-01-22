module evx.math.matrix;

private {/*imports}*/
	import std.conv;

	import evx.operators;
	import evx.math.geometry; // REFACTOR dot product will be refactored
}

struct Matrix (uint n_rows, uint n_cols, T)
	{/*...}*/
		enum rows = n_rows;
		enum cols = n_cols;

		T[rows*cols] data;

		auto ref access (size_t i, size_t j)
			in {/*...}*/
				assert (i < rows,
					i.text ~ ` exceeds `
					~ rows.text ~ ` rows`
				);
				assert (j < cols,
					j.text ~ ` exceeds `
					~ cols.text ~ ` columns`
				);
			}
			body {/*...}*/
				return matrix[rows*i + j];
			}

		void pull (R)(R r, size_t[2] y, size_t x)
			{/*...}*/
				foreach (i; y.left..y.right)
					access (i,x) = r[i - y.left];
			}
		void pull (R)(R r, size_t y, size_t[2] x)
			{/*...}*/
				foreach (j; x.left..x.right)
					access (y,j) = r[j - x.left];
			}
		void pull (R)(R r, size_t[2] y, size_t[2] x)
			{/*...}*/
				foreach (i; y.left..y.right)
					pull (r[i - y.left, 0..$], i, x);
			}

		mixin TransferOps!(pull, access, rows, cols);

		auto opBinary (uint y, uint x, U)(Matrix!(y,x,U) B)
			in {/*...}*/
				static assert (
					cols == y,
					`dimensions incompatible for matrix multiplication `
					`(`
						~ rows.text ~ `×` ~ cols.text
						~ ` · `
						~ B.rows.text ~ `×` ~ B.cols.text ~
					`)`
				);
			}
			body {/*...}*/
				alias A = this;

				Matrix!(A.rows, B.cols, typeof(A[0,0] * B[0,0]))
					C;

				foreach (row; 0..C.rows)
					foreach (col; 0..C.cols)
						C[row,col] = A[row, 0..$].dot (B[0..$, col]);

				return C;
			}
	}

	// TODO submatrix, determinant, linear equations, cast, etc etc
