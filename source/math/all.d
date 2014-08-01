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
	alias map = evx.functional.map; // BUG why the conflict? i'm not importing map from std.algorithm...
	alias reduce = evx.functional.reduce; // BUG why the conflict? i'm not importing reduce from std.algorithm...
}


/*
	REVIEW func ({do stuff; return that;}()); TOTALLY ENCAPSULATED!!!

*/
