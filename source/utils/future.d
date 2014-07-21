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
		bool is_fulfilled;

		T payload;

		void opAssign (U)(U that)
			if (__traits(compiles, payload = that))
			{/*...}*/
				payload = that;
				is_fulfilled = true;
			}
	}

unittest
	{/*demo}*/
		mixin(report_test!`future`);

		Promise!int promise;

		auto future = Future!int (promise);

		assert (not (promise.is_fulfilled));
		assert (not (future.is_ready));

		promise = 6;

		assert (promise.is_fulfilled);
		assert (future.is_ready);
		assert (future == 6);
	}
