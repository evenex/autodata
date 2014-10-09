module evx.math;

public: 
	import std.math;
	import std.algorithm: min, max;
	import evx.logic;
	import evx.functional;
	import evx.constants;
	import evx.units;
	import evx.vectors;
	import evx.geometry;
	import evx.analysis;
	import evx.statistics;
	import evx.probability;
	import evx.combinatorics;
	import evx.arithmetic;
	import evx.ordinal;
	import evx.algebra;

template MathToolkit ()
	{/*...}*/
		enum MathToolkit = q{
			mixin(FunctionalToolkit!());
			mixin(AnalysisToolkit!());
			mixin(ArithmeticToolkit!());
		};
	}
