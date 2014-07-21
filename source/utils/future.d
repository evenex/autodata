module future;

import utils;

struct Future (T)
	{/*...}*/
		public:
		public {/*interface}*/
			@property bool is_ready () const
				{/*...}*/
					return promise.is_fulfilled;
				}
			auto ref opCall ()
				in {/*...}*/
					assert (this.is_ready);
				}
				body {/*...}*/
					return promise.payload;
				}
			alias opCall this;
		}
		public {/*ctor}*/
			this (ref Promise!T promise)
				{/*...}*/
					this.promise = &promise;
				}
		}
		private:
		private {/*data}*/
			Promise!T* promise;
		}
	}
struct Promise (T)
	{/*...}*/
		T payload;
		bool is_fulfilled;

		void opAssign (U)(U that)
			if (__traits(compiles, payload = that))
			in {/*...}*/
				assert (not (is_fulfilled));
			}
			body {/*...}*/
				payload = that;
				is_fulfilled = true;
			}
	}

auto promise (T)(ref Promise!T result)
	{/*...}*/
		return Future!T (result);
	}

unittest
	{/*demo}*/
		mixin(report_test!`future`);
		import std.exception;

		Promise!int promise;

		auto future = .promise (promise);

		assert (not (promise.is_fulfilled));
		assert (not (future.is_ready));
		/* cannot read future before promise fulfillment */
		assertThrown!Error (future ());

		promise = 6;

		assert (promise.is_fulfilled);
		assert (future.is_ready);
		assert (future == 6);
		/* cannot fulfill promise twice */
		assertThrown!Error (promise = 1);
	}
