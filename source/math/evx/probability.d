module evx.probability;

private {/*imports}*/
	private {/*std}*/
		import std.mathspecial;
		import std.random;
	}
}

nothrow:

/* sample a gaussian distribution */
auto gaussian ()
	{/*...}*/
		try return normalDistributionInverse (uniform (0.0, 1.0));
		catch (Exception) assert (0);
	}
