module evx.patterns.id;

/* generate Id, a unique (up to host type) identifier type 
*/
mixin template TypeUniqueId (uint bit = 0)
	{/*...}*/
		import evx.operators;//		import evx.operators.comparison;

		static assert (is(typeof(this)), `mixin requires host struct`);

		struct Id
			{/*...}*/
				static auto create ()
					{/*...}*/
						return typeof(this) (++generator);
					}

				private {/*data}*/
					static if (bit == 64)
						ulong id;
					else static if (bit == 32)
						uint id;
					else static if (bit == 16)
						ushort id;
					else static if (bit == 8)
						ubyte id;
					else static if (bit == 0)
						size_t id;
					else static assert (0);
					__gshared typeof(id) generator;
				}

				pure mixin ComparisonOps!id;
			}
	}
	unittest {
		debug {/*TypeUniqueId.create cannot be made pure}*/
			struct Test { mixin TypeUniqueId; }

			auto x = Test.Id.create;

			assert (x == x);
			assert (x != Test.Id.create);
			assert (Test.Id.create != Test.Id.create);
		}
	}
