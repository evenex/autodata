module evx.probability;

private {/*imports}*/
	private {/*std}*/
		import std.mathspecial;
		import std.random;
	}
}

/* sample a gaussian distribution */
auto gaussian ()()
	{/*...}*/
		return normalDistributionInverse (uniform (0.0, 1.0));
	}
