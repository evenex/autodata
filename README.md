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
     
__autodata__ generates spatial interfaces through `*Ops` mixin templates:

```d
struct Space
{
	auto access (size_t i)
	{
		return i;
	}

	size_t length = 100;

	mixin IndexOps!(access, length);
}
```

`IndexOps` is passed the indexing function (`access`) and the boundaries of the space (`length`).  
These names can be anything you want, (as long as its not a reserved D operator overloading keyword)  
so this code is equivalent to the previous listing:

```d
struct Space
{
	auto zxcvbn (size_t i)
	{
		return i;
	}

	size_t qwerty = 100;

	mixin IndexOps!(zxcvbn, qwerty);
}
```

Both will enable bounds-checked indexing operations:

```d
writeln (Space()[40]); // output: 40
writeln (Space()[$-1]); // output: 99
writeln (Space()[101]); // error! out of bounds
writeln (Space()[$]); // error! out of bounds
```

---

The above could be accomplished by renaming `access` to `opIndex` and writing a bounds-checking contract, but adding slicing support to a type is a more involved undertaking.  
You'll have to, at the very least, overload `opSlice` (using D's old overloading syntax, which precludes multidimensional support).  
More likely, you will need to define multiple overloads for `opIndex`, an `opSlice` template for returning some interval type, a sliced subspace type, and bounds checking logic for everything.  
<br>
With __autodata__, we can extend `Space` to support slicing by changing `IndexOps` to `SliceOps`:

```d
struct Space
{
	auto access (size_t i)
	{
		return i;
	}

	size_t length = 100;

	mixin SliceOps!(access, length);
}
```

Now, we can slice `Space`:

```d
writeln (Space()[0..100][0]); // output: 0
writeln (Space()[50..100][0]); // output: 50
writeln (Space()[75..101]); // error! out of bounds
```

Boundaries need not start at 0, either:
```d
struct Space
{
	auto access (size_t i)
	{
		return i;
	}

	size_t[2] span = [100, 200];

	mixin SliceOps!(access, span);
}

writeln (Space()[0]); // error! out of bounds
writeln (Space()[100]); // output: 100
```

Though, without further modification (see: extensions), slices will start at 0. <!--REVIEW mention extensions and special symbols like "origin"-->

```d
writeln (Space()[][0]); // output: 100
```

---

Extending Space to multiple dimensions is trivial:

```d
struct Space
{
	auto access (size_t i, size_t j)
	{
		return i + j;
	}

	size_t x_length = 10;
	size_t y_length = 10;

	mixin SliceOps!(access, x_length, y_length);
}
```

```d
writeln (Space()[0, 0]); // output: 0
writeln (Space()[5, 7]); // output: 12
writeln (Space()[5, 10]); // error! out of bounds

writeln (Space()[5..7, 7..10][0, 0]); // output: 12
writeln (Space()[5..$, 7][0]); // output: 12
writeln (Space()[$-1, $-1]); // output: 18
```

---

__autodata__ also supports negative and non-integer indices:

```d
struct ISpace
{
	auto access (int i)
	{
		return i;
	}

	auto axis = [-10, 10];

	mixin SliceOps!(access, axis);
}

writeln (ISpace()[-5]); // output: -5
writeln (ISpace()[-7..7][0]); // output: -7

struct RSpace
{
	auto access (double i)
	{
		return i;
	}

	auto length = 100.0;

	mixin SliceOps!(access, axis);
}

writeln (RSpace()[33.3]); // output: 33.3
writeln (RSpace()[0..51][$/2]); // output: 25.5
```

The length operator `$` normally denotes the right-side boundary of a range.  
In __autodata__, `$` can be inverted with `~` to get the left-side boundary:

```d
writeln (ISpace()[~$..0][0]); // output: -5
writeln (RSpace()[~$]); // output: 0.0
```

---

__autodata__ provides a mechanism for injecting custom behavior into subspaces.  
We can use this to extend the `Sub!Space` object to support `RandomAccessRange` operations:

```d
struct Space
{
	auto access (size_t i)
	{
		return i;
	}

	size_t length = 100;

	mixin SliceOps!(access, length, RangeExt);
}
```

The extension template `RangeExt` enables:

```d
static assert (isRandomAccesRange!(typeof(Space()[])));

foreach (i; Space()[71..75])
	write (i, `, `); // output: 71, 72, 73, 74,

foreach_reverse (i; Space()[97..100])
	write (i, `, `); // output: 99, 98, 97

writeln (Space()[55..60] == [55,56,57,58,59]); // output: true
```

`RangeExt` will also turn any 1-dimensional slice of an n-dimensional space into a `RandomAccessRange`:

```d
struct Space
{
	auto access (size_t i, size_t j)
	{
		return i + j;
	}

	size_t x_length = 10;
	size_t y_length = 10;

	mixin SliceOps!(access, x_length, y_length, RangeExt);
}

```
```d
foreach (i; Space()[2, 3..7])
	writeln (i, `, `); // output: 5, 6, 7, 8
```

---

Any zero-parameter template (ordinary mixins or enum strings) can be used to extend a subspace. <!-- REVIEW there's a lot more to say, and even this probably belongs in its own section. maybe just put "for more on subspace extensions" as a link to a separate man page -->

```d
template MaxExt ()
{
	typeof(this[0]) cached_max;
	bool max_is_cached;

	auto max ()
	{
		if (!max_is_cached)
		{
			foreach (i; this[])
				if (i > cached_max)
					cached_max = i;

			max_is_cached = true;
		}
		return cached_max;
	}
}

struct Space
{
	auto access (size_t i)
	{
		return i;
	}

	size_t length = 100;

	mixin SliceOps!(access, length, RangeExt, MaxExt);

	mixin MaxExt;
}

writeln (Space().max); // output: 99
writeln (Space()[].max); // output: 99
writeln (Space()[20..40].max); // output: 39
```

---
