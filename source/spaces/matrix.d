module autodata.spaces.matrix;

private {/*imports}*/
	import autodata.operators;
	import autodata.core;
}

struct Matrix (T, uint n_rows, uint n_cols)
	{/*...}*/
		T[n_rows * n_cols] data;

		ref access (uint row, uint col)
			{/*...}*/
				return data[row*n_cols + col];
			}
		void pull (M)(M matrix, size_t row, Interval!size_t cols)
			{/*...}*/
				foreach (j; cols.left..cols.right)
					data[row*n_cols + j] = matrix[j - cols.left];
			}
		void pull (M)(M matrix, Interval!size_t rows, size_t col)
			{/*...}*/
				foreach (i; rows.left..rows.right)
					data[i*n_cols + col] = matrix[i - rows.left];
			}
		void pull (M)(M matrix, Interval!size_t rows, Interval!size_t cols)
			{/*...}*/
				foreach (i; rows.left..rows.right)
					pull (matrix[i - rows.left, ~$..$], i, cols);
			}

		auto ref opOpAssign (string op : `+`)(auto ref Matrix that)
			{/*...}*/
				foreach (i; 0..n_rows)
					foreach (j; 0..n_cols)
						this[i,j] += that[i,j];

				return this;
			}
		auto opBinary (string op : `+`)(auto ref Matrix that)
			{/*...}*/
				auto mat = this;

				mat += that;

				return mat;
			}
		// TODO matrix ops as necessary

		mixin TransferOps!(pull, access, n_rows, n_cols, RangeExt);
	}
	unittest {/*...}*/
		Matrix!(double, 2, 2) a, b;

		a.data = [
			1, 2,
			3, 4,
		];

		b.data = [
			4, 3,
			2, 1,
		];

		assert ((a+b).data == [
			5, 5,
			5, 5,
		]);
	}
