module future;

import utils;

unittest
	{/*demo}*/
		mixin(report_test!`promise`);
		import std.exception;

		{/*future}*/
			Future!int future;

			assert (not (future.is_realized));

			future = 6;

			assert (future.is_realized);
			assert (future == 6);
			/* cannot realize future twice */
			assertThrown!Error (future = 1);
		}
		{/*promise}*/
			Future!int future;

			auto promise = .promise (future);
			assert (not (promise.is_fulfilled));
			/* cannot read promise before future realization */
			assertThrown!Error (promise ());

			future = 6;

			assert (promise.is_fulfilled);
			assert (promise == 6);
		}
		{/*delivery}*/
			Future!int future;

			auto delivery = deliver (future);
			assert (not (delivery.was_delivered));

			delivery = 6;

			assert (delivery.was_delivered);
			assert (future.is_realized);
			assert (future == 6);

			/* cannot realize future twice */
			assertThrown!Error (future = 1);
			/* cannot make delivery twice */
			assertThrown!Error (delivery = 1);
		}
	}

struct Future (T)
	{/*...}*/
		public:
		const @property {/*status}*/
			bool is_realized ()
				{/*...}*/
					return realized;
				}
		}
		public {/*interface}*/
			void assign (U)(U that)
				if (__traits(compiles, payload = that))
				in {/*...}*/
					assert (this.is_realized.not, `Future!(` ~T.stringof~ `) has already been realized`);
				}
				body {/*...}*/
					payload = that;
					finalize;
				}
			auto ref stream ()
				{/*...}*/
					return payload;
				}
			void finalize ()
				{/*...}*/
					realized = true;
				}
			void await (uint poll_frequency = 1000)
				{/*...}*/
					import core.thread;
					import std.datetime;

					immutable wait_period = (1_000_000_000/poll_frequency).nsecs;

					while (not (realized))
						Thread.sleep (wait_period);
				}
			auto get () const
				in {/*...}*/
					assert (this.is_realized, `attempted to access Future!(` ~T.stringof~ ` before it was realized`);
				}
				body {/*...}*/
					return payload;
				}
			alias get this;
		}
		public {/*operators}*/
			alias opCall = get;
			alias opAssign = assign;
		}
		private:
		private {/*data}*/
			T payload;
			bool realized;
		}
	}
struct Promise (T)
	{/*...}*/
		public:
		const @property {/*status}*/
			@property bool is_fulfilled () const
				{/*...}*/
					return future.is_realized;
				}
		}
		public {/*interface}*/
			auto await (uint poll_frequency = 1000)
				{/*...}*/
					future.await (poll_frequency);
				}
			auto get ()
				in {/*...}*/
					assert (this.is_ready, `attempted to access Promise!(` ~T.stringof~ `) before it was fulfilled`);
				}
				body {/*...}*/
					return future.payload;
				}
			alias get this;
		}
		public {/*operators}*/
			alias opCall = get;
		}
		public {/*ctor}*/
			this (ref Future!T future)
				{/*...}*/
					this.future = &future;
				}
		}
		private:
		private {/*data}*/
			Future!T* future;
		}
	}
struct Delivery (T)
	{/*...}*/
		public:
		const @property {/*status}*/
			@property bool was_delivered ()
				{/*...}*/
					return future.is_realized;
				}
		}
		public {/*interface}*/
			void assign (U)(U that)
				if (not (is (U == typeof(this))))
				{/*...}*/
					*future = that;
				}
			auto ref stream ()
				{/*...}*/
					return future.stream;
				}
			void finalize ()
				{/*...}*/
					future.finalize;
				}
		}
		public {/*operators}*/
			alias opAssign = assign;
		}
		public {/*ctor}*/
			this (ref Future!T future)
				{/*...}*/
					this.future = &future;
				}
		}
		private:
		private {/*data}*/
			Future!T* future;
		}
	}

auto promise (T)(ref Future!T future)
	{/*...}*/
		return Promise!T (future);
	}
auto deliver (T)(ref Future!T future)
	{/*...}*/
		return Delivery!T (future);
	}
