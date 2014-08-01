module evx.math;

// REVIEW & REFACTOR
public: 
	import std.math;
	import std.algorithm: min, max;
	import evx.constants;
	import evx.units;
	import evx.functional;
	import evx.geometry; // unittest
	import evx.analysis; // unittest
	import evx.statistics; // unittest
	import evx.probability; // unittest
	import evx.combinatorics; // unittest
	import evx.arithmetic; // unittest
	import evx.ordering; // unittest

public {/*disambiguation}*/
	alias map = evx.functional.map;
	alias reduce = evx.functional.reduce;
	alias abs = evx.units.abs;
	alias approx = evx.units.approx;
}


/*
	REVIEW func ({do stuff; return that;}()); TOTALLY ENCAPSULATED!!!

*/
