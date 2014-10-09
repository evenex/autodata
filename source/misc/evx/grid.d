module evx.grid;

private {/*import}*/
	private {/*std}*/
		import std.algorithm;
		import std.typecons;
		import std.range;
	}
	private {/*evx}*/
		import evx.meta;
		import evx.traits;
		import evx.arrays;
		import evx.spatial;
		import evx.range;
		import evx.math;
		import evx.utils;
		import evx.display;
		import evx.colors;
		import evx.camera;
		import evx.input;
		import evx.scribe;
	}

	mixin(FunctionalToolkit!());
	alias m = meters;
	alias sum = evx.arithmetic.sum;
}

struct Grid (T)
	{/*...}*/
		alias Vec = Vector!(2,T);

		size_t columns, rows;
		T width = zero!T, height = zero!T;

		auto resolution (size_t columns, size_t rows)
			{/*...}*/
				this.columns = columns;
				this.rows = rows;

				return this;
			}
		auto measure (T width, T height)
			in {/*...}*/
				assert (width > zero!T);
				assert (height > zero!T);
			}
			body {/*...}*/
				this.width = width;
				this.height = height;

				return this;
			}

		auto Δx ()
			out (Δx) {/*...}*/
				assert (Δx > zero!T);
			}
			body {/*...}*/
				return width/(columns-1);
			}
		auto Δy ()
			out (Δy) {/*...}*/
				assert (Δy > zero!T);
			}
			body {/*...}*/
				return height/(rows-1);
			}

		bool is_valid ()
			{/*...}*/
				return columns * rows > 0 && width > zero!T && height > zero!T;
			}

		auto opDollar (size_t dim)() const
			{/*...}*/
				static if (dim == 0)
					return columns;
				else static if (dim == 1)
					return rows;
				else static assert (0);
			}
		auto opSlice (size_t dim)(size_t start, size_t end) // TODO
			{/*...}*/
				
			}
		auto opSlice ()()
			{/*...}*/
				return flat_traversal;
			}

		auto translate (Vec Δp)
			{/*...}*/
				
			}

		auto flat_traversal ()
			{/*...}*/
				return Vec(-width/2, -height/2).sequence!((v,i) => v + Vec(Δx*(i % columns), Δy*(i / rows)))[0..columns*rows];
			}

		auto strip_traversal ()
			{/*...}*/
				return flat_traversal.enumerate.map!((i,v) => v * vec((i/rows)%2? -1:1, 1) + Vec(zero!T, i%2 && i/rows > 0? -Δy:zero!T));
			}

		auto hex_traversal ()
			{/*...}*/
				return flat_traversal.enumerate.map!((i,v) => v * vec((i/rows)%2? -1:1, 1) + Vec(zero!T, (i%4 < 2) && (i/rows > 0)? -Δy:zero!T));
			}

		auto neighborhood (size_t flat_index)
			{/*...}*/
				auto i = flat_index;

				auto n = i - columns;
				auto s = i + columns;

				auto col = i % columns;
				auto row = i / rows;

				auto stencil = Stencil ([
					n-1, n, n+1,
					i-1, i, i+1,
					s-1, s, s+1
				]);

				if (col == columns - 1)
					{/*...}*/
						stencil[][2] = i;
						stencil[][5] = i;
						stencil[][8] = i;
					}
				else if (col == 0)
					{/*...}*/
						stencil[][0] = i;
						stencil[][3] = i;
						stencil[][6] = i;
					}

				if (row == rows - 1)
					{/*...}*/
						stencil[][6] = i;
						stencil[][7] = i;
						stencil[][8] = i;
					}
				else if (row == 0)
					{/*...}*/
						stencil[][0] = i;
						stencil[][1] = i;
						stencil[][2] = i;
					}
					
				return stencil;
			}
	}

struct Stencil
	{/*...}*/
		size_t[9] indices;

		auto opSlice ()
			{/*...}*/
				return indices[];
			}
	}

unittest {/*visualize traversals}*/
	scope gfx = new Display;
	gfx.start; scope (exit) gfx.stop;

	bool end;
	scope usr = new Input (gfx, (bool){end = true;});

	auto grid = Grid!double ()
		.measure (2,2)
		.resolution (20,20);
		
	auto noisy (T)(T grid)
		{/*...}*/
			return grid[].map!(v => v + 0.0015 * vec(gaussian.clamp (-1,1), gaussian.clamp (-1,1)));
		}

	while (not(end))
		{/*...}*/
			gfx.draw (blue (0.05), noisy (grid.strip_traversal), GeometryMode.t_strip); 

			foreach (i, v; enumerate (noisy (grid.hex_traversal).adjacent_pairs[0..$-1]))
				gfx.draw (green (i*1.0/grid[].length), [v[0],v[1]], GeometryMode.lines, 1);

			gfx.render;
			usr.process;

			import core.thread;
			Thread.sleep (20.msecs);
		}
}
