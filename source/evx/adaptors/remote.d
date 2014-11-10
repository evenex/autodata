module evx.adaptors.remote;

private {/*import}*/
	import evx.operators;
}

/* for data that is expensive to modify but must be modified frequently 
	post () propagates changes 
*/
struct Remote (LocalBuffer, RemoteBuffer)
	{/*...}*/
		static assert (is(LocalBuffer.BufferTraits) && is(RemoteBuffer.BufferTraits));

		struct Buffers
			{/*...}*/
				LocalBuffer local;
				RemoteBuffer remote;
				bool dirty;

				//static assert (is(ElementType!LocalBuffer : ElementType!RemoteBuffer)); TODO

				alias remote this;

				void pull (R)(R range, size_t i, size_t j)
					{/*...}*/
						local[i..j] = range;
								std.stdio.writeln (`pull `, RemoteBuffer.stringof);

						dirty = true;
					}
				auto access (size_t i)
					{/*...}*/
						return local[i];
					}
				auto length () const
					{/*...}*/
						return local.length;
					}

				void allocate (size_t n)
					{/*...}*/
						local.allocate (n);
						remote.allocate (n);

						dirty = true;
					}
				void free ()
					{/*...}*/
						local.free;
						remote.free;
					}

				void post ()
					{/*...}*/
						if (dirty)
							remote[] = local[];

						dirty = false;
					}
			}

		Buffers data;
		mixin BufferOps!data;
	}
	unittest {/*...}*/
		import evx.containers;

		Remote!(MArray!int, MArray!int) me;

		me.allocate (5);

		assert (me.length == 5);
		assert (me.local.length == me.remote.length);

		me.post;
		assert (me[] == me.remote[]);

		me[0] = 9;
		assert (me[] != me.remote[]);
		assert (me[0] == 9);

		me.post;
		assert (me[] == me.remote[]);
	}
