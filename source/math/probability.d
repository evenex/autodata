module evx.probability;

private {/*import std}*/
	import std.mathspecial:
		normalDistributionInverse;
	import std.random:
		uniform;
}

nothrow:

/* sample a gaussian distribution */
auto gaussian ()
	{/*...}*/
		try return normalDistributionInverse (uniform (0.0, 1.0));
		catch (Exception) assert (0);
	}
