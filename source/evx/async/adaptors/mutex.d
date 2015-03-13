module evx.async.adaptors.mutex;
version(none):

private {/*import}*/
	import core.atomic;
	import core.thread;

	import evx.math;
}

struct Mutexed (T, Duration check_interval = 100.nsecs)
{/*...}*/
	private {/*...}*/
		T store;
		shared bool locked;
	}

	auto acquire ()
		{/*...}*/
			return Lock (this);
		}
	alias acquire this;

	struct Lock
		{/*...}*/
			this (ref Mutexed source)
				{/*...}*/
					this.source = &source;

					while (not (cas (&source.locked, false, true)))
						Thread.sleep (check_interval);
				}
			~this ()
				{/*...}*/
					atomicStore (source.locked, false);
				}

			ref get ()
				{/*...}*/
					return source.store;
				}
			alias get this;

			private Mutexed* source;
		}
}
void xmain ()
	{/*...}*/
		//Mutexed!(int[]) x; BUG https://issues.dlang.org/show_bug.cgi?id=14185
	}
