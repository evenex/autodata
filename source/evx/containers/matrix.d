module evx.containers.matrix;

private {/*imports}*/
	import evx.operators;
	import evx.math.intervals;
}

struct Matrix (T, uint n_rows, uint n_cols)
	{/*...}*/
		T[n_rows * n_cols] data;

		ref access (uint row, uint col)
			{/*...}*/
				return data[row*n_cols + col];
			}
		void pull (M)(M matrix, size_t row, size_t[2] cols)
			{/*...}*/
				foreach (j; cols.left..cols.right)
					data[row*n_cols + j] = matrix[j - cols.left];
			}
		void pull (M)(M matrix, size_t[2] rows, size_t col)
			{/*...}*/
				foreach (i; rows.left..rows.right)
					data[i*n_cols + col] = matrix[i - rows.left];
			}
		void pull (M)(M matrix, size_t[2] rows, size_t[2] cols)
			{/*...}*/
				foreach (i; rows.left..rows.right)
					pull (matrix[i - rows.left, ~$..$], i, cols);
			}

		mixin TransferOps!(pull, access, n_rows, n_cols, RangeOps);
	}
static assert (is (Matrix!(double, 3, 3)));
