module spacecadet.memory.lifetime;

private {/*import}*/
	import spacecadet.meta;
	import spacecadet.patterns;
	import spacecadet.math;
	import spacecadet.memory.transfer;
}

/* resource lifetime management wrappers
	control assignment, copy, and destruction behavior for the wrapped type

	wrapped instances can acquire a value by forwarding constructor arguments,
		or by calling the member function "own" on an unwrapped type

	unwrapped values cannot be assigned to wrapped values via operator
		but if the wrapped type defines a cross-type assignment operator, it is preserved
*/
struct Lifetime
	{/*...}*/
		// no assign, no copy, release on dtor
		struct Pinned (T)
			{/*...}*/
				mixin CommonOps;

				@disable this (this);

				void initialize (){}

				mixin(opAssign_complement);

				~this ()
					{/*...}*/
						static if (is (T == class))
							destroy (data);
					}
			}
		// move on assign, no copy, release on dtor
		struct Unique (T)
			{/*...}*/
				mixin CommonOps;

				@disable this (this);

				auto ref opAssign ()(auto ref this that)
					{/*...}*/
						if (&that != &this)
							that.move (this);

						return this;
					}

				void initialize (){}

				mixin(opAssign_complement);

				~this ()
					{/*...}*/
						static if (is (T == class))
							destroy (data);
					}
			}
		// copy on assign, release on 0 references
		struct Shared (T)
			{/*...}*/
				mixin CommonOps;
				mixin TypeUniqueId;

				__gshared size_t[Id] refcount;

				Id id;

				auto ref opAssign ()(auto ref this that)
					{/*...}*/
						destroy (this);
						
						this.id = that.id;

						++refcount[id];

						this.data = that.data;

						return this;
					}

				void initialize ()
					{/*...}*/
						id = Id ();

						++refcount[id];
					}

				mixin(opAssign_complement);

				this (this)
					{/*...}*/
						if (id != Id.init)
							++refcount[id];
					}
				~this ()
					{/*...}*/
						if (id != Id.init)
							{/*...}*/
								if (--refcount[id] == 0)
									{/*...}*/
										refcount.remove (id);

										static if (is (T == class))
											destroy (data);
									}
								else neutralize (data);
							}
					}
			}

		private {/*...}*/
			template CommonOps ()
				{/*...}*/
					private T data;

					mixin ForwardOps!data;

					this (Args...)(auto ref Args args)
						{/*...}*/
							destroy (this);

							initialize;

							data = T (args);
						}

					auto ref own ()(auto ref T that)
						{/*...}*/
							destroy (this);

							initialize;

							that.move (data);

							return this;
						}
				}

			static opAssign_complement ()
				{/*...}*/
					return q{
						auto ref opAssign (U)(auto ref U that)
							if (not (Contains!(U, typeof(this), T)))
							{/*...}*/
								destroy (this);

								initialize;

								data = that;

								return this;
							}
					};
				}
		}
	}
	unittest {/*...}*/
		static struct Test
			{/*...}*/
				static bool killed;
				static reset () {killed = false;}
				bool neutral = true;

				this (bool live)
					{/*...}*/
						this.neutral = not!live;
					}
				~this ()
					{/*...}*/
						if (not!neutral)
							{/*...}*/
								assert (not!killed);
								killed = true;
							}
					}
			}

		void rvalue (T)(T){}
		void lvalue (T)(ref T){}
		void black_hole (T)(ref T x)
			{/*...}*/
				T x1;

				x1 = x;
			}

		Test.reset;
		{/*Pinned}*/
			auto x0 = Lifetime.Pinned!Test (true);

			static assert (not (__traits(compiles, (){auto x1 = x0;})));
			static assert (not (__traits(compiles, (){auto x1 = typeof(x0)(false); x1 = x0;})));
			static assert (not (__traits(compiles, (){auto x1 = Test(false); x0 = x1;})));

			static assert (not (__traits(compiles, rvalue (x0))));
			static assert (__traits(compiles, lvalue (x0)));
		}
		assert (Test.killed);

		Test.reset;
		{/*Unique}*/
			auto x0 = Lifetime.Unique!Test (true);

			static assert (not (__traits(compiles, (){auto x1 = x0;})));
			static assert (__traits(compiles, (){auto x1 = typeof(x0)(false); x1 = x0;}));
			static assert (not (__traits(compiles, (){auto x1 = Test(false); x0 = x1;})));

			static assert (not (__traits(compiles, rvalue (x0))));
			static assert (__traits(compiles, lvalue (x0)));

			assert (not (Test.killed || x0.neutral));
			black_hole (x0);
			assert (Test.killed && x0.neutral);

			Test.reset;
			
			auto x1 = Test (true);
			assert (x0.neutral && not (x1.neutral));
			x0.own (x1);
			assert (not (x0.neutral) && x1.neutral);
		}
		assert (Test.killed);

		Test.reset;
		{/*Shared}*/
			auto x0 = Lifetime.Shared!Test (true);

			static assert (__traits(compiles, (){auto x1 = x0;}));
			static assert (__traits(compiles, (){auto x1 = typeof(x0)(false); x1 = x0;}));
			static assert (not (__traits(compiles, (){auto x1 = Test(false); x0 = x1;})));

			static assert (__traits(compiles, rvalue (x0)));
			static assert (__traits(compiles, lvalue (x0)));

			black_hole (x0);
			assert (not (Test.killed));

			auto x1 = x0;
			auto x2 = x0;
			auto x3 = x0;

			destroy (x0);
			assert (not (Test.killed));
			destroy (x2);
			assert (not (Test.killed));
			destroy (x1);
			assert (not (Test.killed));
		}
		assert (Test.killed);
	}
