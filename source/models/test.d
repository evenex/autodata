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

bool entity_simulated;

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
					@(N) specifies the capacity of the underlying Allocator.
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

		void simulate (Entity.Id id) 
			{entity_simulated = true;}
		void terminate (Entity.Id id) 
			{entity_simulated = false;}

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
		assert (simulation.model!Testing.server is server && server.is_running);
	}

unittest
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

		/* initialize test Entity */
		auto entity = simulate (`test`).As!(Testing.Unit);

		{/*variables}*/
			/* write value */
			entity.variable (10);
			assert (entity.variable == 10);

			/* change source */
			static int eleven (Entity.Id id) {return 11;}
			entity.variable(& eleven);
			assert (entity.variable == 11);

			/* verify source */
			entity.variable (12);
			assert (entity.variable == 11);

			/* reset source */
			simulation.model!Testing.reset_observation_sources (entity);
			assert (entity.variable == 12);
		}
		{/*arrays}*/
			/* write value */
			entity.array ([10, 9, 8, 7, 6]);
			assert (entity.array.equal ([10, 9, 8, 7, 6]));

			/* change source */
			static int N (size_t i) {return cast(int)i + 1;}
			static View!int view_N (Entity.Id id) {return (&N).view (0,5);}
			entity.array (& view_N);
			assert (entity.array.equal ([1, 2, 3, 4, 5]));

			/* verify source */
			entity.array ([5, 4, 3, 2, 1]);
			assert (entity.array.equal ([1, 2, 3, 4, 5]));

			/* reset source */
			simulation.model!Testing.reset_observation_sources (entity);
			assert (entity.array.equal ([5, 4, 3, 2, 1]));
		}
		{/*external observation}*/
			/* the observe template offers a convenient way to source properties across models */
			entity.array_4 ([9,9,9]);
			entity.array_8 (&observe!(Testing.Unit, `array_4`));

			assert (entity.array_4.equal (entity.array_8));

			/* note that it is only possible to source properties from different aspects of the same entity using the observe template */
			/* more complicated sourcing functions can of course be used, but will be defined on a per-case basis */

			/* independent verification */
			auto f1 = &observe!(Testing.Unit, `variable`);
			auto f2 = &observe!(Testing.Unit, `array`);
			assert (f1 (entity) == entity.variable);
			assert (f2 (entity).equal (entity.array));
		}

		/* entities are not made known to models until the next simulation update */
		/* this allows the entity to be fully initialized before being processed */
		assert (not (entity_simulated));
		simulation.update;
		assert (entity_simulated);

		/* terminating an entity can safely take place in a single step */
		terminate (entity);
		assert (not (entity_simulated));
	}
