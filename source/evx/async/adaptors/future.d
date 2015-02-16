module evx.async.adaptors.future;

private {/*imports}*/
	import core.thread;
	import evx.math;
}

unittest {/*demo}*/
	{/*future}*/
		Future!int future;

		assert (not (future.is_realized));

		future = 6;

		assert (future.is_realized);
		assert (future == 6);
		/* cannot realize future twice */
		version (releasemode_conditional_compilation) // TODO
		assertThrown!Error (future = 1);
	}
	{/*promise}*/
		Future!int future;

		auto promise = .promise (future);
		assert (not (promise.is_fulfilled));
		/* cannot read promise before future realization */
		version (releasemode_conditional_compilation) // TODO
		assertThrown!Error (promise ());

		future = 6;

		assert (promise.is_fulfilled);
		assert (promise == 6);
	}
	{/*delivery}*/
		Future!int future;

		auto order = deliver (future);
		assert (not (order.was_delivered));

		order.send (6);

		assert (order.was_delivered);
		assert (future.is_realized);
		assert (future == 6);

		/* cannot realize future twice */
		version (releasemode_conditional_compilation) // TODO
		assertThrown!Error (future = 1);
		/* cannot make order twice */
		version (releasemode_conditional_compilation) // TODO
		assertThrown!Error (order.send (1));
	}
	{/*promise/delivery}*/
		Future!int future;

		auto promise = .promise (future);
		auto order = deliver (future);

		assert (not (order.was_delivered));
		assert (not (promise.is_fulfilled));
		assert (not (future.is_realized));

		order.send (6);

		assert (order.was_delivered);
		assert (promise.is_fulfilled);
		assert (future.is_realized);

		assert (promise == 6);
		assert (future == 6);
	}
}

struct Future (T)
	{/*...}*/
		public:
		public {/*client interface}*/
			void await (size_t poll_frequency = 1000)
				{/*...}*/
					immutable wait_period = (1_000_000_000/poll_frequency).nsecs;

					while (not (realized))
						Thread.sleep (wait_period);
				}

			auto get () const
				in {/*...}*/
					assert (this.is_realized, `attempted to access ` ~Future.stringof~ ` before it was realized`);
				}
				body {/*...}*/
					return payload;
				}
			alias get this;

		}
		public {/*server interface}*/
			void assign (U)(U that)
				if (__traits(compiles, payload = that))
				in {/*...}*/
					assert (this.is_realized.not, Future.stringof~ ` has already been realized`);
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
		}
		const @property {/*status}*/
			bool is_realized ()
				{/*...}*/
					return realized;
				}
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
		public {/*client interface}*/
			auto await (uint poll_frequency = 1000)
				{/*...}*/
					future.await (poll_frequency);
				}

			auto get ()
				in {/*...}*/
					assert (this.is_fulfilled, `attempted to access ` ~Promise.stringof~ ` before it was fulfilled`);
				}
				body {/*...}*/
					return future.payload;
				}
			alias get this;
		}
		const @property {/*status}*/
			@property bool is_fulfilled () const
				{/*...}*/
					return future.is_realized;
				}
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
		public {/*server interface}*/
			void send (U)(U that)
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
		const @property {/*status}*/
			@property bool was_delivered ()
				{/*...}*/
					return future.is_realized;
				}
		}
		public {/*operators}*/
			alias opAssign = send;
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
		private {/*}*/
			void finalize ()
				{/*...}*/
					future.finalize;
				}
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
