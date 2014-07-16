module models.test;
//version (unittest):
import models.aspect;
import services.service;

final class Server: Service
	{/*...}*/
		shared override:
		bool initialize ()
			{/*...}*/
				return true;
			}
		bool process ()
			{/*...}*/
				return true;
			}
		bool listen ()
			{/*...}*/
				return true;
			}
		bool terminate ()
			{/*...}*/
				return true;
			}
		const string name ()
			{/*...}*/
				return `test_server`;
			}
	}
final class Hidden: Service
	{/*...}*/
		shared override:
		bool initialize ()
			{/*...}*/
				return true;
			}
		bool process ()
			{/*...}*/
				return true;
			}
		bool listen ()
			{/*...}*/
				return true;
			}
		bool terminate ()
			{/*...}*/
				return true;
			}
		const string name ()
			{/*...}*/
				return `test_server`;
			}
	}

Server server;

final class Testing
	{mixin Model;/*}*/
		@Aspect struct Unit
			{/*...}*/
				/*
					declared variables compile to Looks on read and variables on write.
				*/
				int variable;
				/*
					declared arrays compile to Looks to Views on read and Resources on write.
				*/
				int[] array;

				/*
					@(n) where n ∈ ℕ specifies the capacity of the underlying Allocator.
				*/
				@(2^^4) int[] array_4;
				@(2^^8) int[] array_8;
			}

		/*
			public Services are automatically found and connected to a Model when the Simulation initializes.
			if the required service cannot be found at module scope, a compile-time error is thrown.
		*/
		public Server server; /// if no Server was declared at module scope, this would trigger a compiler-time error
		/*
			private Services are excluded from the search, and must be managed internally by the Model.
		*/
		private Hidden hidden; /// no Hidden Services are available at module scope, but this will compile because it is private

		void model (Entity.Id id){}
		void release (Entity.Id id){}

		void initialize (){}
		void update (){}
	}

mixin Simulation!Testing;

unittest
	{/*connect to services}*/
		mixin(report_test!`simulation services`);
		import std.exception;

		// all public Services must be started prior to initialization of Simulation
		assertThrown!Error (simulation = new typeof(simulation));

		server = new Server;
		assertThrown!Error (simulation = new typeof(simulation));

		server.start; scope (exit) server.stop;
		simulation = new typeof(simulation);

		// upon initialization, Simulation automatically connects all Models to required Services
		assert (simulation.get!Testing.server is server && server.is_running);
	}

void main ()
	{/*demo}*/
		mixin(report_test!`simulation demo`);
		import std.exception;
		import std.algorithm;
		import resource.view;

		/* initialize Service layer */
		server = new Server;
		server.start; scope (exit) server.stop;

		/* initialize Model layer */
		simulation = new typeof(simulation);

		/* initialize Entities */
		auto test_unit = model_entity (`test`).As!(Testing.Unit);

		{/*variables}*/
			/* write value */
			test_unit.variable (10);
			assert (test_unit.variable == 10);

			/* change source */
			static int eleven (Entity.Id id) {return 11;}
			test_unit.variable(& eleven);
			assert (test_unit.variable == 11);

			/* verify source */
			test_unit.variable (12);
			assert (test_unit.variable == 11);

			/* reset source */
			test_unit.reset!(Testing.Unit, `variable`);
			assert (test_unit.variable == 12);
		}
		{/*arrays}*/
			/* write value */
			test_unit.array ([10, 9, 8, 7, 6]);
			assert (test_unit.array.equal ([10, 9, 8, 7, 6]));

			/* change source */
			static int N (size_t i) {return cast(int)i + 1;}
			static View!int view_N (Entity.Id id) {return (&N).view (0,5);}
			test_unit.array (& view_N);
			assert (test_unit.array.equal ([1, 2, 3, 4, 5]));

			/* verify source */
			test_unit.array ([5, 4, 3, 2, 1]);
			assert (test_unit.array.equal ([1, 2, 3, 4, 5]));

			/* reset source */
			test_unit.reset!(Testing.Unit, `array`);
			assert (test_unit.array.equal ([5, 4, 3, 2, 1]));
		}
	}
