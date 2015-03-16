module spacecadet.operators.range;

/* generate random access range primitives

	This is an extension template meant to be used in a Sub structure.

	Note that, in Phobos, the resulting range will only qualify as bidirectional
	because std.range.isRandomAccessRange does not handle template or non-property range primitives,
	although the range does meet the definition of random access as given in D range references.
*/
template RangeOps ()
	{/*...}*/
		static if (Dimensions.length == 1)
			@property {/*...}*/
				auto ref front () {return this[~$];}
				auto ref back () {return this[$-1];}

				auto popFront () {++bounds[Dimensions[0]].left;}
				auto popBack () {--bounds[Dimensions[0]].right;}

				auto empty () {return length == 0;}
				auto length () const {return bounds[Dimensions[0]].width;}

				auto save () {return this;}

				auto opEquals (R)(R range)
					{/*...}*/
						import std.algorithm: equal;
						return equal (save, range);
					}
			}
	}
	unittest {/*...}*/
		import spacecadet.operators.slice;

		static struct Basic
			{/*...}*/
				int[] data = [1,2,3,4];

				auto access (size_t i) {return data[i];}
				auto length () const {return data.length;}

				mixin SliceOps!(access, length, RangeOps);
			}
		assert (Basic()[].length == 4);
		assert (Basic()[0..$/2].length == 2);
		foreach (_; Basic()[]){}
		foreach_reverse (_; Basic()[]){}

		static struct MultiDimensional
			{/*...}*/
				double[9] matrix = [
					1, 2, 3,
					4, 5, 6,
					7, 8, 9,
				];

				auto ref access (size_t i, size_t j)
					{/*...}*/
						return matrix[3*i + j];
					}

				enum size_t rows = 3, columns = 3;

				mixin SliceOps!(access, rows, columns, RangeOps);
			}
		assert (MultiDimensional()[0..$, 0].length == 3);
		assert (MultiDimensional()[0, 0..$].length == 3);
		foreach (_; MultiDimensional()[0..$, 0]){}
		foreach (_; MultiDimensional()[0, 0..$]){}
		foreach_reverse (_; MultiDimensional()[0..$, 0]){}
		foreach_reverse (_; MultiDimensional()[0, 0..$]){}
	}