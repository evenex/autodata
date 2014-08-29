module evx.scheduling;

private {/*imports}*/
	private {/*std}*/
		import std.datetime;
		import std.concurrency;
		import std.conv;
		import std.traits;
	}
	private {/*evx}*/
		import evx.service;
		import evx.utils;
		import evx.meta;
		import evx.math;
		import evx.arrays;
	}

	alias seconds = evx.units.seconds;
}

class Scheduler: Service
	{/*...}*/
		public:
		public {/*services}*/
			void enqueue (T = long) (Seconds delay, T message = cast(T)0x0) 
				if (is (T: long))
				in {/*...}*/
					assert (this.is_running, "cannot enqueue event before Scheduler has started"); 
				}
				body {/*...}*/
					send (thisTid, delay, cast(long)message);
				}
			shared void enqueue (Args...) (Args args)
				{/*^}*/
					(cast(Scheduler)this).enqueue (args);
				}
		}
		public {/*notifications}*/
			struct Notification
				{/*...}*/
					alias message this;
					long message;
				}
		}

		protected:
		@Service shared override {/*interface}*/
			bool initialize ()
				{/*...}*/
					return true;
				}
			bool process ()
				{/*...}*/
					schedule.execute;
					return true;
				}
			bool listen ()
				{/*...}*/
					void new_event (Tid tid, Seconds delay, long message)
						{/*...}*/
							schedule.add (Schedule.Event (tid, delay, message));
						}

					if (schedule.empty)
						{/*wait for new event}*/
							receive (&new_event); 
							return true;
						}
					else {/*wait for new event until next event}*/
						if (received_before (schedule.lead_time, &new_event))
							return true;
						else return false;
					} 
				}
			bool terminate ()
				{/*...}*/
					return true;
				}
			const string name ()
				{/*...}*/
					return "scheduler";
				}
		}

		private:
		private {/*schedule}*/
			Schedule schedule;

			struct Schedule
				{/*...}*/
					private:
					private {/*events}*/
						Queue queue;

						alias Queue = Ordered!(Event[]);

						struct Event
							{/*...}*/
								public:
								int opCmp (const Event that) const nothrow pure
									{/*...}*/
										return compare (this.time, that.time);
									}
								bool opEquals (const Event that) const nothrow pure
									{/*...}*/
										return this.time == that.time;
									}

								private:
								private {/*data}*/
									Tid tid;
									SysTime time;
									long message;
								}
								private {/*ctor}*/
									this (Tid tid, Seconds delay, long message)
										{/*...}*/
											this.tid = tid;
											this.time = Clock.currTime + delay.to_duration;
											this.message = message;
										}
								}
							}
					}
					shared:
					shared {/*control}*/
						void add (Event event)
							{/*...}*/
								(cast()queue).insert (event);
							}
						void execute ()
							{/*...}*/
								if (empty)
									return;
								else {/*...}*/
									auto event = (cast()queue).front;
									(cast()queue).remove_at (0);

									event.tid.send (Notification (event.message));
								}
							}
					}
					shared {/*properties}*/
						@property Seconds lead_time () const
							{/*...}*/ 
								auto time = ((cast(Queue)queue).front.time - Clock.currTime).to_evx_time;

								debug if (time < 0.seconds) 
									{/*...}*/
										import std.stdio;

										stderr.writeln (`warning: an event was ` ~(-time).text~ ` late!`);

										stderr.flush;
									}
								return time < 0.seconds? 0.seconds: time;
							}

						pure @property bool empty () const
							{/*...}*/
								return (cast(Queue)queue).empty;
							}
					}
				}
		}
	}
	unittest {/*latency + order of arrival}*/
		import core.thread: Thread, sleep;

		alias Notification = Scheduler.Notification;

		{/*serial}*/
			foreach (i; 0..5)
				{/*...}*/
					scope S = new Scheduler;
					foreach (j; 0..5)
						{/*...}*/
							alias receive = std.concurrency.receive;
							int result;
							S.start ();
							S.enqueue (1.milliseconds, 0x1);
							S.enqueue (2.milliseconds, 0x2);
							receive ((Notification x) {assert (x == 0x1);});
							receive ((Notification x) {assert (x == 0x2);});
							S.enqueue (2.milliseconds, 0x2);
							S.enqueue (1.milliseconds, 0x1);
							receive ((Notification x) {assert (x == 0x1);});
							receive ((Notification x) {assert (x == 0x2);});
							S.stop ();
						}
				}
		}
		{/*parallel}*/
			auto all = new Scheduler [10];
			auto left  = all[0..$/2];
			auto right = all[$/2..$];

			foreach (i, ref s; all)   	s = new Scheduler;
			foreach (i, ref s; all)   	s.start ();
			foreach (i, ref s; all)   	s.enqueue (2*(1+i).milliseconds, i);
			foreach (i, ref s; all)  	receive ((Notification x) {assert (x == i);});
			foreach (i, ref s; right)	s.stop ();
			foreach (i, ref s; left)  	s.enqueue (2*(1+i).milliseconds, i);
			foreach (i, ref s; left)  	receive ((Notification x) {assert (x == i);});
			foreach (i, ref s; left)  	s.stop ();
			foreach (i, ref s; right) 	s.start ();
			foreach (i, ref s; right) 	s.enqueue (2*(1+i).milliseconds, i);
			foreach (i, ref s; right) 	receive ((Notification x) {assert (x == i);});
			foreach (i, ref s; all)   	s.start ();
			foreach (i, ref s; all) 	s.enqueue (2*(1+i).milliseconds, i);
			foreach (i, ref s; all)  	receive ((Notification x) {assert (x == i);});
			foreach (i, ref s; all)		s.stop ();
		}
	}

void sync_with (T) (T service, Scheduler scheduler, Hertz framerate) 
	if (is (T: Service))
	in {/*...}*/
		assert (service.is_running, "attempted to sync while "~T.stringof~" offline");
	}
	body {/*...}*/
		service.send (cast(shared)scheduler, framerate);

		if (not (received_before (500.milliseconds, (Synced confirmation){})))
			assert (null, "no reply from service thread. is it listening for auto_sync?");
	}
void sync_with (T) (T service, shared Scheduler scheduler, Hertz framerate)
	{/*^}*/
		sync_with (service, cast(Scheduler)scheduler, framerate);
	}

auto auto_sync (alias scheduler, alias action)()
	if (is (typeof(scheduler) == Scheduler)  && isSomeFunction!action)
	{/*...}*/
		void refresh_sync (Scheduler.Notification framerate)
			{/*...}*/
				(cast(Scheduler)scheduler).enqueue (1/framerate.hertz, framerate);

				action ();
			}

		void start_sync (shared Scheduler new_scheduler, Hertz framerate)
			in {/*...}*/
				assert (new_scheduler !is null, "attempted to sync with offline scheduler");
			}
			body {/*...}*/
				scheduler = cast(Scheduler)new_scheduler;

				scheduler.enqueue (1/framerate, framerate.to_scalar.to!long);

				Service.reply (Synced ());

				action ();
			}

		return τ(&start_sync, &refresh_sync);
	}

private {/*sync primitives}*/
	struct Synced {}
}
