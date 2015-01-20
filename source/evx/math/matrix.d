
struct Matrix (uint rows, uint cols, T)
	{/*...}*/
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

		auto opBinary (uint y, uint x, U)(Matrix!(y,x,U) matrix)
			in {/*...}*/
				static assert (
					cols == y,
					`dimensions incompatible for matrix multiplication `
					`(`
						~ rows.text ~ `×` ~ cols.text
						~ ` · `
						~ y.text ~ `×` ~ x.text ~
					`)`
				);
			}
			body {/*...}*/
				// TODO matrix multiplication
			}
	}
