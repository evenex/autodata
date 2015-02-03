module evx.utils.lifetime;

private {/*import}*/
	import evx.patterns;
	import evx.operators;

	import evx.utils.memory;
}

struct Lifetime
	{/*...}*/
		// no assign, release on dtor
		struct Pinned (T)
			{/*...}*/
				mixin Forward;

				@disable auto ref opAssign (Args...)(auto ref Args);
				@disable this (this);

				~this ()
					{/*...}*/
						static if (is (T == class))
							destroy (data);
					}
			}
		// move on assign, release on dtor
		struct Unique (T)
			{/*...}*/
				mixin Forward;

				@disable this (this);

				auto ref opAssign ()(auto ref typeof(this) that)
					{/*...}*/
						if (&that != &this)
							that.move (this);

						return this;
					}

				~this ()
					{/*...}*/
						static if (is (T == class))
							destroy (data);
					}
			}
		// copy on assign, release on 0 linked references
		struct Linked (T)
			{/*...}*/
				mixin Forward;

				typeof(this)* prev;
				typeof(this)* here;
				typeof(this)* next;

				auto ref opAssign ()(auto ref typeof(this) that)
					{/*...}*/
						destroy (this);

						this.prev = &that;
						this.here = &this;
						this.next = that.next;

						that.next = &this;

						this.data = that.data;

						return this;
					}

				this (Args...)(Args args)
					{/*...}*/
						here = &this;

						data = typeof(data)(args);
					}

				this (this)
					{/*...}*/
						prev = here;
						here = &this;
						next = prev.next;

						prev.next = here;

						if (next)
							next.prev = here;
					}

				~this ()
					{/*...}*/
						if (prev)
							prev.next = next;

						if (next)
							next.prev = prev;

						if (next || prev)
							neutralize (data);
						else static if (is (T == class))
							destroy (data);
					}
			}
		// copy on assign, release on 0 global references
		struct Shared (T)
			{/*...}*/
				mixin Forward;
				mixin TypeUniqueId;

				__gshared size_t[Id] refcount;

				Id id;

				auto ref opAssign ()(auto ref typeof(this) that)
					{/*...}*/
						destroy (this);
						
						this.id = that.id;

						++refcount[id];

						this.data = that.data;

						return this;
					}

				this (Args...)(auto ref Args args)
					{/*...}*/
						id = Id ();

						++refcount[id];

						data = typeof(data)(args);
					}
				this (this)
					{/*...}*/
						++refcount[id];
					}
				~this ()
					{/*...}*/
						if (id != Id.init && --refcount[id] == 0)
							{/*...}*/
								refcount.remove (id);

								static if (is (T == class))
									destroy (data);
							}
						else neutralize (data);
					}
			}

		private {/*...}*/
			template Forward ()
				{/*...}*/
					private T data;

					mixin ForwardOps!data;

					this (Args...)(auto ref Args args)
						{/*...}*/
							data = T (args);
						}
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
			x0 = typeof(x0)(true);
		}
		assert (Test.killed);

		Test.reset;
		{/*Linked}*/
			auto x0 = Lifetime.Linked!Test (true);

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
