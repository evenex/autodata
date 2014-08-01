module evx.math;

public: 
	import std.math;
	import std.algorithm: min, max;
	import evx.constants;
	import evx.units;
	import evx.functional;
	import evx.geometry;
	import evx.analysis;
	import evx.statistics;
	import evx.probability;
	import evx.combinatorics;
	import evx.arithmetic;
	import evx.ordering;

public {/*disambiguation}*/
	alias map = evx.functional.map;
	alias reduce = evx.functional.reduce;
	alias abs = evx.units.abs;
	alias approx = evx.units.approx;
}
