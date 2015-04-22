autodata
======
####a system for working with n-dimensional data types
  * automatically generate checked, consistent interfaces
  * operate on them with a rich set of functional primitives

---
##overview
a __space__ is a data set with an n-dimensional index: `I₀ × I₁ × ⋯ × Iₙ → T`,
> where `T` is any data type,  
> and each `Iᵢ` is an additive group. <!-- REVIEW: with manual origin, maybe only a monoid is required --> 

---
     
__autodata__ generates spatial interfaces through \*Ops mixin templates:

	struct Space
	{
		auto access (size_t i)
		{
			return i;
		}

		size_t length = 100;

		mixin IndexOps!(access, length);
	}

`IndexOps` is passed the indexing function (`access`) and the boundaries of the space (`length`).  
These names can be anything you want, (as long as its not a reserved D operator overloading keyword)  
so this code is equivalent to the previous listing:

	struct Space
	{
		auto zxcvbn (size_t i)
		{
			return i;
		}

		size_t qwerty = 100;

		mixin IndexOps!(zxcvbn, qwerty);
	}

Both will enable bounds-checked indexing operations:

	writeln (Space()[40]); // output: 40
	writeln (Space()[$-1]); // output: 99
	writeln (Space()[101]); // error! out of bounds
	writeln (Space()[$]); // error! out of bounds

---

The above could be accomplished by renaming `access` to `opIndex` and writing a bounds-checking contract, but adding slicing support to a type is a more involved undertaking.  
You'll have to, at the very least, overload `opSlice` (using D's old overloading syntax, which precludes multidimensional support).  
More likely, you will need to define multiple overloads for `opIndex`, an `opSlice` template for returning some interval type, a sliced subspace type, and bounds checking logic for everything.  
<br>
With __autodata__, we can extend `Space` to support slicing by changing `IndexOps` to `SliceOps`:

	struct Space
	{
		auto access (size_t i)
		{
			return i;
		}

		size_t length = 100;

		mixin SliceOps!(access, length);
	}
