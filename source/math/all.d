module evx.math;

private {/*import std}*/
	import std.algorithm: 
		map,
		copy,
		canFind,
		setIntersection;
	import std.traits: 
		isFloatingPoint, isIntegral, isUnsigned,
		Unqual, EnumMembers;
	import std.mathspecial:
		normalDistributionInverse;
	import std.random:
		uniform;
	import std.conv:
		to, text;
}
private {/*import evx}*/
	import evx.utils: 
		Aⁿ, τ, not,
		reduce;
	import evx.meta:
		ArrayInterface, IterateOver;
}

// REVIEW & REFACTOR
public: 
	import std.math;
	import evx.constants;
	import evx.units;
	import evx.geometry; // unittest
	import evx.analysis; // unittest
	import evx.statistics; // unittest
	import evx.probability; // unittest
	import evx.combinatorics; // unittest
	import evx.arithmetic; // unittest
	import evx.ordering; // unittest

void main (){}
