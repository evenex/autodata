private {/*imports}*/
	import std.datetime;
	import std.concurrency;
	import std.traits;
	import service;
	import utils;
	import math;
}

class Scheduler: Service
	{/*...}*/
		public:
		public {/*services}*/
			void enqueue (T = long) (Duration delay, T message = cast(T)0x0) if (is (T: long))
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
					schedule.execute ();
					return true;
				}
			bool listen ()
				{/*...}*/
					void new_event (Tid tid, Duration delay, long message)
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
						alias Queue = Priority_Queue!Event;
						struct Event
							{/*...}*/
								public:
								public {/*sort}*/
									int opCmp (ref const Event that) const
										{return this.time.opCmp (that.time);}
								}
								private:
								private {/*data}*/
									Tid tid;
									SysTime time;
									long message;
								}
								private {/*☀}*/
									this (Tid tid, Duration delay, long message)
										{/*...}*/
											this.tid = tid;
											this.time = Clock.currTime + delay;
											this.message = message;
										}
								}
							}
					}
					shared:
					shared {/*control}*/
						void add (Event event)
							{/*...}*/
								(cast(Queue)queue).insert (event);
							}
						void execute ()
							{/*...}*/
								if (empty)
									return;
								else {/*...}*/
									auto event = (cast(Queue)queue).removeAny;
									event.tid.send (Notification (event.message));
								}
							}
					}
					shared {/*properties}*/
						@property Duration lead_time () const
							{/*...}*/
								auto time = (cast(Queue)queue).front.time - Clock.currTime;
								debug if (time < 0.seconds) 
									{/*...}*/
										import std.stdio;
										stderr.writeln (`warning: an event was `~to!string(-time)~` late!`);
										stderr.flush;
									}
								return time < 0.msecs? 0.msecs: time;
							}
						pure @property bool empty () const
							{/*...}*/
								return (cast(Queue)queue).empty;
							}
					}
				}
		}
		version (rigorous) unittest 
			{/*latency + order of arrival}*/
				mixin (report_test!"Scheduler");
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
									S.enqueue (1.msecs, 0x1);
									S.enqueue (2.msecs, 0x2);
									receive ((Notification x) {assert (x == 0x1);});
									receive ((Notification x) {assert (x == 0x2);});
									S.enqueue (2.msecs, 0x2);
									S.enqueue (1.msecs, 0x1);
									receive ((Notification x) {assert (x == 0x1);});
									receive ((Notification x) {assert (x == 0x2);});
									S.stop ();
								}
						}
				}
				{/*parallel}*/
					auto ALL = new Scheduler [10];
					auto LEFT  = ALL[0..$/2];
					auto RIGHT = ALL[$/2..$];

					foreach (i, ref s; ALL)   	s = new Scheduler;
					foreach (i, ref s; ALL)   	s.start ();
					foreach (i, ref s; ALL)   	s.enqueue (2*(1+i).msecs, i);
					foreach (i, ref s; ALL)  	receive ((Notification x) {assert (x == i);});
					foreach (i, ref s; RIGHT)	s.stop ();
					foreach (i, ref s; LEFT)  	s.enqueue (2*(1+i).msecs, i);
					foreach (i, ref s; LEFT)  	receive ((Notification x) {assert (x == i);});
					foreach (i, ref s; LEFT)  	s.stop ();
					foreach (i, ref s; RIGHT) 	s.start ();
					foreach (i, ref s; RIGHT) 	s.enqueue (2*(1+i).msecs, i);
					foreach (i, ref s; RIGHT) 	receive ((Notification x) {assert (x == i);});
					foreach (i, ref s; ALL)   	s.start ();
					foreach (i, ref s; ALL) 	s.enqueue (2*(1+i).msecs, i);
					foreach (i, ref s; ALL)  	receive ((Notification x) {assert (x == i);});
					foreach (i, ref s; ALL)		s.stop ();
				}
			}
	}

void sync_with (T) (T service, Scheduler scheduler, uint framerate = 30) if (is (T: Service))
	in {/*...}*/
		assert (service.is_running, "attempted to sync while "~T.stringof~" offline");
	}
	body {/*...}*/
		service.send (cast(shared)scheduler, framerate);
		if (not (receiveTimeout (500.msecs, (bool confirmation){})))
			assert (null, "no reply from service thread. is it listening for (shared Scheduler, uint)?");
	}
void sync_with (T) (T service, shared Scheduler scheduler, uint framerate = 30)
	{/*^}*/
		sync_with (service, cast(Scheduler)scheduler, framerate);
	}

auto auto_sync (alias scheduler, alias action)()
	if (is (typeof(scheduler) == Scheduler)  && isSomeFunction!action)
	{/*...}*/
		void refresh_sync (Scheduler.Notification framerate)
			{/*...}*/
				(cast(Scheduler)scheduler).enqueue ((1000/framerate).msecs, framerate);
				action ();
			}
		void start_sync (shared Scheduler new_scheduler, uint framerate)
			in {/*...}*/
				assert (new_scheduler !is null, "attempted to sync with offline scheduler");
			}
			body {/*...}*/
				scheduler = cast(Scheduler)new_scheduler;
				scheduler.enqueue ((1000/framerate).msecs, framerate);
				Service.reply (true);
				action ();
			}
		return tuple (&start_sync, &refresh_sync);
	}
