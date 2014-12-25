module evx.misc.patch;

template Patch (Base, uint bug_id : 13860) // BUG https://issues.dlang.org/show_bug.cgi?id=13860
	{/*...}*/
		Base base;
		alias base this;

		this (T...)(T args) {base = Base (args);}

		auto limit (uint d)() const
			{/*...}*/
				return base.limit!d;
			}
		auto ref access (Coords!Base point)
			{/*...}*/
				return base.access (point);
			}

		mixin SliceOps!(access, Map!(limit, Iota!(dimensionality!Base)), RangeOps);
	}
// HACK if the contents were out in the Product definition, the following error would arise from attempting to get the returntypes of limit or access (especially puzzling since i'm pretty sure access isn't a template): 
	//source/experimental.d(2403): Error: struct experimental.Product!(int[], int[]).Product no size yet for forward reference
	//ulong[2]
	//source/experimental.d(2452): Error: template instance experimental.Product!(int[], int[]) error instantiating
	//source/experimental.d(2460):        instantiated from here: by!(int[], int[])
// that is, it prints pragma(msg, ReturnType!(limit!0)); but then crashes on error.
