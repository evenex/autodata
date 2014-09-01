module services.collision;

import std.conv;
import std.algorithm;
import std.range;
import std.traits;
import std.math;

import evx.utils;
import evx.traits;
import evx.math;
import evx.meta;
import evx.service;
import evx.future;
import evx.arrays;
import evx.buffers;
import evx.allocators;
import evx.range;

alias map = evx.functional.map;

// TODO UNIT SAFE

private {/*library}*/
	struct cp
		{/*...}*/
			static auto opDispatch (string op, Args...) (Args args)
				{/*...}*/
					import core.thread;
					import dchip.all;
					mixin (`return cp`~op~` (args);`);
				}
		}
}

private struct RequestUpdate {};
private struct RequestUpload {};
private struct RequestQuery {};
private struct Confirmation {}

private enum MAX_SHAPES = 8;

final class CollisionDynamics (ClientId = size_t): Service
	if (ClientId.sizeof <= (void*).sizeof)
	{/*...}*/
		alias Id = ClientId;
		private {/*definitions}*/
			import dchip.all;
			alias Space 	= cpSpace*;
			alias ShapeId	= cpShape*;
			alias BodyId 	= cpBody*;
		}
		public:
		public {/*bodies}*/
			// REFACTOR
			struct Body
				{/*...}*/
					BodyId body_id;
					Appendable!(ShapeId[MAX_SHAPES]) shape_ids;
					CollisionDynamics world;

					double velocity_damping = 0.0;

					enum Type {none, circle, polygon}

					public:
					@property {/*get}*/
						double mass ()
							{/*...}*/
								return cp.BodyGetMass (body_id);
							}
						fvec position ()
							{/*...}*/
								return cp.BodyGetPos (body_id).vector;
							}
						fvec velocity ()
							{/*...}*/
								return cp.BodyGetVel (body_id).vector;
							}
						double damping ()
							{/*...}*/
								return velocity_damping;
							}
						uint layer ()
							{/*...}*/
								return cp.ShapeGetLayers (shape_ids[0]); // REVIEW
							}
						fvec applied_force ()
							{/*...}*/
								return cp.BodyGetForce (body_id).vector;
							}
					}
					@property {/*set}*/
						void position (fvec new_position)
							{/*...}*/
								cp.BodySetPos (body_id, new_position.to!cpVect);
								auto space = cp.BodyGetSpace (body_id);
								cp.SpaceReindexShapesForBody (space, body_id);
							}
						void velocity (fvec new_velocity)
							in {/*...}*/
								assert (mass.not!isInfinity);
							}
							body {/*...}*/
								cp.BodySetVel (body_id, new_velocity.to!cpVect);
							}
						void damping (double new_damping)
							in {/*...}*/
								assert (mass != double.infinity);
							}
							body {/*...}*/
								velocity_damping = new_damping;
							}
						void applied_force (fvec new_force)
							{/*...}*/
								cp.BodySetForce (body_id, new_force.to!cpVect);
							}
						void layer (uint new_layer)
							{/*...}*/
								foreach (shape; shape_ids)
									cp.ShapeSetLayers (shape, new_layer); // REVIEW
							}
					}
					private:
					private {/*☀/~}*/
						this (R)(cpSpace* space, double mass, fvec position, fvec velocity, double damping, ClientId client_id, R geometries)
							if (is_geometric!(ElementType!R))
							in {/*...}*/
								string not_specified (string property)
									{/*...}*/
										return property~ ` of body ` ~client_id.text~ ` not specified`;
									}

								assert (mass == mass, not_specified (`mass`));
								assert (position == position, not_specified (`position`));
								assert (velocity == velocity || mass.isInfinity, not_specified (`velocity`));
								foreach (geometry; geometries)
									{/*...}*/
										assert (geometry.length > 2);
										assert (geometry.area > double.epsilon,
											"attempted to create collision body with zero volume");
									}
							}
							body {/*...}*/
								if (mass.isInfinity)
									this.body_id = cp.BodyNewStatic;
								else this.body_id = cp.BodyNew (mass, 1.0);

								cp.SpaceAddBody (space, body_id);
								this.position = position;
								this.velocity = velocity;
								this.damping  = damping;
								cp.BodySetUserData (body_id, store (client_id));

								auto areas = geometries[].map!area;
								auto Σ_areas = sum (areas);
								
								foreach (i, geometry; geometries)
									{/*...}*/
										double moment;

										auto component_mass = mass * areas[i] / Σ_areas;

										with (Body.Type) final switch (deduce_shape (geometry))
											{/*create simulation data}*/
												case circle:
													{/*...}*/
														auto radius = geometry.radius;
														auto center = geometry.mean.to!cpVect;

														moment = cp.BodyGetMoment (body_id) + cp.MomentForCircle (component_mass, 0.0, radius, center);
														this.shape_ids ~= cp.CircleShapeNew (body_id, radius, center);

														break;
													}
												case polygon:
													{/*...}*/
														auto len = geometry.length.to!int;
														auto poly = geometry_memory.save (geometry);
														auto hull = geometry_memory.allocate (len);

														cp.ConvexHull (len, cast(cpVect*)poly[].ptr, cast(cpVect*)hull[].ptr, null, 0.0);

														moment = cp.BodyGetMoment (body_id) + cp.MomentForPoly (component_mass, len, cast(cpVect*)hull[].ptr, cpvzero);
														this.shape_ids ~= cp.PolyShapeNew (body_id, len, cast(cpVect*)hull[].ptr, cpvzero);

														break;
													}
												case none: assert (null);
											}
										auto shape_id = shape_ids.back;
							
										cp.BodySetMoment (body_id, moment);
										cp.SpaceAddShape (space, shape_id);
										cp.ShapeSetUserData (shape_id, store (client_id));
									}
							}

						void free () // TODO async
							{/*...}*/
								auto space = cp.BodyGetSpace (body_id);

								foreach (shape; shape_ids[])
									{/*...}*/
										cp.SpaceRemoveShape (space, shape);
										cp.ShapeFree (shape);
									}

								cp.SpaceRemoveBody (space, body_id);
								cp.BodyFree (body_id);
							}
					}
					static {/*shape deduction}*/
						auto deduce_shape (T)(T geometry)
							if (is_geometric!T)
							{/*...}*/
								auto center = geometry.mean;
								auto vs = geometry.map!(v => v - center);
								auto dirs = geometry.adjacent_pairs.map!(v => (v[1]-v[0]).unit);
								auto turn = dirs.adjacent_pairs;

								auto dot = turn.map!(v => v[0].dot(v[1]));
								auto μ_dot = dot.mean;
								auto σ_dot = dot.std_dev (μ_dot);

								auto det = turn.map!(v => v[0].det(v[1]));
								auto σ_det = det.std_dev;

								assert (σ_det.between ( 0.0, 1.0)
									 && σ_dot.between ( 0.0, 1.0)
									 && μ_dot.between (-1.0, 1.0)
								);

								if (// as we walk along the boundary of the polygon, we're ...
									σ_det <= 0.05 // turning in a consistent direction
								 && σ_dot <= 0.05 // turning at a consistent angle
								 && μ_dot >= 0.40 // turning at angles < 66° on average
								) return Type.circle;
								else return Type.polygon;
							}
					}
				}
			private struct Upload
				{/*...}*/
					public:
					mixin Builder!(
						double, 	`mass`,
						fvec, 		`position`,
						fvec, 		`velocity`,
						double, 	`damping`,
					);
					auto shape (R)(R geometry)
						if (is_geometric!R)
						{/*...}*/
							with (server.buffer)
								{/*...}*/
									auto start = vertices.length;

									vertices ~= geometry;

									this.shapes ~= vertices.write[start..vertices.length];
								}
							return this;
						}

					private:
					ClientId id;
					CollisionDynamics server;
					Appendable!(fvec[][MAX_SHAPES]) shapes;

					@property auto geometry ()
						{/*...}*/
							return contigious (shapes[]);
						}

					this (ClientId id, CollisionDynamics server)
						{/*...}*/
							this.id = id;
							this.server = server;
							this.velocity = 0;
						}
				}
			void expedite_uploads ()
				{/*...}*/
					send (RequestUpload ());
					receive ((Confirmation _){});
				}
			@Upload void add (Args...)(Args uploads)
				if (allSatisfy!(is_type_of!Upload, Args))
				in {/*...}*/
					assert (this.is_running, "attempted to add body before starting service");
					foreach (upload; uploads)
						assert (not (upload.id in bodies), `duplicate ids ` ~upload.id.text);
				}
				body {/*...}*/
					buffer.uploads ~= uploads.only;
				}
			auto new_body (ClientId)(ClientId id)
				{/*...}*/
					return Upload (id, this);
				}
		}
		public {/*actions}*/
			struct Action {}
		}
		public {/*queries}*/
			// REFACTOR
			struct BodyInterface
				{/*...}*/
					ClientId id;
					Body* body_option;
					Upload* upload_option;
					CollisionDynamics dynamics;

					this (ref Body physical_body)
						{/*...}*/
							body_option = &physical_body;
						}
					this (ref Upload upload, CollisionDynamics dynamics)
						{/*...}*/
							id = upload.id;
							upload_option = &upload;
							this.dynamics = dynamics;
						}

					private bool body_uploaded ()
						{/*...}*/
							body_option = dynamics.bodies.find (id);
							
							return body_option? true:false;
						}
					@property auto ref opDispatch (string op)()
						{/*...}*/
							if (body_option || body_uploaded) mixin(q{
								return body_option.} ~op~ q{;
							}); else mixin(q{
								return upload_option.} ~op~ q{;
							});
						}
					@property auto ref opDispatch (string op, Args...)(scope lazy Args args)
						{/*...}*/
							if (body_option || body_uploaded) mixin(q{
								return body_option.} ~op~ q{ (args);
							}); else mixin(q{
								return upload_option.} ~op~ q{;
							}); 
						}
				}
			auto get_body (ClientId id)
				{/*...}*/
					if (id in bodies)
						return BodyInterface (bodies[id]);
					else foreach (ref upload; buffer.uploads.write[])
						if (upload.id == id)
							return BodyInterface (upload, this);

					assert (0, `body ` ~id.text~ ` does not exist`);
				}

			void expedite_queries ()
				{/*...}*/
					send (RequestQuery ());
					receive ((Confirmation _){});
				}

			struct Query
				{/*...}*/
					struct Appender (T) 
						{/*...}*/
							void delegate(T) append;
							void delegate() finalize;
						}
					struct Box
						{/*...}*/
							fvec[2] corners;
							Appender!ClientId stream;

							@property void result (bool finished)
								{/*...}*/
									if (finished)
										stream.finalize ();
									else assert (0);
								}
						}
					struct Ray
						{/*...}*/
							ClientId id;
							RayCast ray_cast;

							alias ray_cast this;
						}
					struct RayCast
						{/*...}*/
							fvec[2] ray;
							Delivery!Incidence result;
						}
					struct RayCastExcluding
						{/*...}*/
							Ray ray_query;
							alias ray_query this;

							this (ClientId id, RayCast ray)
								{/*...}*/
									ray_query = Ray (id, ray);
								}
						}
				}
			struct Incidence
				{/*...}*/
					ClientId body_id;
					fvec surface_normal;
					double ray_time;
				}

			void box_query (Array)(fvec[2] corners, ref Future!Array result)
				in {/*...}*/
					static assert (isOutputRange!(Array, ClientId), Array.stringof~ `cant take `~ClientId.stringof);

					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.box ~= Query.Box (corners, Query.Appender!ClientId (x => result.stream.put (x), &result.finalize));
				}
			void ray_cast (fvec[2] ray, ref Future!Incidence result)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray_cast ~= Query.RayCast (ray, deliver (result));
				}
			void ray_query (T)(T id, fvec[2] ray, ref Future!Incidence result)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray ~= Query.Ray (id, Query.RayCast (ray, deliver (result)));
				}
			void ray_cast_excluding (T)(T id, fvec[2] ray, ref Future!Incidence result)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray_cast_excluding ~= Query.RayCastExcluding (id, Query.RayCast (ray, deliver (result)));
				}
		}
		public {/*update}*/
			void update ()
				in {/*...}*/
					assert (this.is_running, "attempted to update simulation before starting service");
				}
				body {/*...}*/
					send (RequestUpdate ());
				}
		}
		public {/*ctor}*/
			this () {auto_initialize;}
		}
		static shared {/*time}*/
			immutable real Δt = 0.016667; // TODO set custom
			private ulong t = 0;
			auto time ()
				{/*...}*/
					return t * Δt;
				}
		}
		protected:
		shared void answer_queries () // REFACTOR
			{/*...}*/
				static ClientId get_id (cpShape* shape)
					{/*...}*/
						return retrieve (cp.ShapeGetUserData (shape));
					}

				auto answer (T)(T query)
					in {/*...}*/
						static if (is (T == Query.Box))
							foreach (c; query.corners)
								assert (c.x == c.x && c.y == c.y);
					}
					body {/*...}*/
						static if (is (T == Query.Ray) || is (T == Query.RayCast))
							{/*...}*/
								static if (is (T == Query.Ray))
									auto id = query.id;
								else ClientId id;

								auto ray = query.ray;

								auto layers = CP_ALL_LAYERS;
								auto group = CP_NO_GROUP;

								cpSegmentQueryInfo info;

								if (id != ClientId.init)
									foreach (shape; bodies[id].shape_ids)
										cp.ShapeSegmentQuery (shape, ray[0].to!cpVect, ray[1].to!cpVect, &info);
								else cp.SpaceSegmentQueryFirst (space, ray[0].to!cpVect, ray[1].to!cpVect, 
									layers, group, &info
								);

								if (info.shape)
									return Incidence (get_id (info.shape), info.n.vector, info.t);
								else return Incidence (ClientId.init, 0.fvec, 1.0);
							}
						else static if (is (T == Query.RayCastExcluding))
							{/*...}*/
								auto id = query.id;
								auto ray = query.ray;

								auto layer = bodies[id].layer;
								bodies[id].layer = 0x0;

								auto layers = CP_ALL_LAYERS;
								auto group = CP_NO_GROUP;

								cpSegmentQueryInfo info;

								cp.SpaceSegmentQueryFirst (space, ray[0].to!cpVect, ray[1].to!cpVect, 
									layers, group, &info
								);

								bodies[id].layer = CP_ALL_LAYERS;

								if (info.shape)
									return Incidence (get_id (info.shape), info.n.vector, info.t);
								else return Incidence (ClientId.init, 0.fvec, 1.0);
							}
						else static if (is (T == Query.Box))
							{/*...}*/
								auto box = cp.BB (query.corners[].bounding_box.bounds_tuple.expand);
								auto layers = CP_ALL_LAYERS;
								auto group = CP_NO_GROUP;

								cp.SpaceBBQuery (space, box, layers, group, 
									(cpShape* shape, void* stream) 
										{(*cast(Query.Appender!ClientId*) stream).append (get_id (shape));}, // this is not ref, why does it route to ref?
									&query.stream
								);
								return true;
							}
					}

				void process_queries (string type)()
					{/*...}*/
						foreach (ref query; mixin(q{buffer.queries.} ~type~ q{.read[]}))
							query.result = answer (query);
					}

				process_queries!`box`;
				process_queries!`ray`;
				process_queries!`ray_cast`;
				process_queries!`ray_cast_excluding`;
			}
		shared void process_uploads () // REFACTOR
			{/*...}*/
				auto vertex_pool = buffer.vertices.read[];

				foreach (ref upload; buffer.uploads.read[])
					{/*...}*/
						with (upload) if (position != position)
							position = geometry.mean;

						bodies.insert (upload.id,
							Body (
								space,
								upload.mass, 
								upload.position, 
								upload.velocity, 
								upload.damping, 
								upload.id,
								upload.shapes
							)
						);
					}
			}

		@Service shared override {/*interface}*/
			import dchip.all;
			bool initialize ()
				{/*...}*/
					space = cp.SpaceNew ();
					cp.SpaceSetCollisionSlop (space, 0.01);
					return true;
				}
			bool process ()
				{/*...}*/
					buffer.swap;
					process_uploads;

					cp.SpaceStep (space, Δt);
					++t;

					{/*postprocess}*/
						foreach (ref dynamic_body; bodies)
							with (dynamic_body) if (damping > 0.0)
								velocity = velocity*(1.0 - damping).to!fvec;
					}

					answer_queries;

					return true;
				}
			bool listen ()
				{/*...}*/
					// REVIEW ALL
					bool listening = true;

					auto proceed (RequestUpdate) 
						{/*...}*/
							listening = false;
						}
					auto expedite_queries (RequestQuery) // maybe belongs with the next function
						{/*...}*/
							buffer.queries.swap;
							answer_queries;
							reply (Confirmation ());
						}
					auto expedite_uploads (RequestUpload)
						{/*...}*/
							buffer.vertices.swap;
							buffer.uploads.swap;
							process_uploads;
							reply (Confirmation ());
						}
					auto remove (ClientId id)
						{/*...}*/
							bodies.remove (id);
							reply (Confirmation ());
						}

					static if (0) //XXX
					auto act (Id id, Body.Action action)
						{/*...}*/
							assert (id in body_ptr, "body "~id.text~" does not exist");
							import std.string: cap = capitalize;
							const string apply (string op) ()
								{/*...}*/
									return q{case }~op~q{: cp.BodyApply}~cap(op)~q{(body_ptr[id], action.vector.to!cpVect, cpvzero); break;}; // arg[2] is how you get torque
								}
							with (Body.Action.Type) 
								final switch (action.type)
									{/*...}*/
										mixin (apply!`force`);
										mixin (apply!`impulse`);
										case none: assert (null);
									}
							reply (Confirmation ());
						}
					auto set (ClientId id, string property, fvec value)
						{/*...}*/
							assert (id in bodies, "body " ~id.text~ " does not exist");
							const string set (string prop) ()
								{/*...}*/
									return q{case }`"`~prop~`"`q{: bodies[id].}~prop~q{ = value; break;};
								}
							switch (property)
								{/*...}*/
									mixin (set!`position`);
									mixin (set!`velocity`);
									mixin (set!`applied_force`);
									default: assert (null);
								}
							reply (Confirmation ());
						}
					auto debug_query (T)(T id, string query)
						{/*...}*/
							assert (id in bodies, "queried body "~id.text~" not uploaded");
							debug const string get (string prop) ()
								{/*...}*/
									return q{case }`"`~prop~`"`q{: reply (bodies[id].}~prop~q{); return;};
								}
							debug switch (query)
								{/*...}*/
									mixin (get!`type`);
									default: assert (null);
								}
							else assert (null);
						}

					receive (&proceed, &expedite_queries, &expedite_uploads, &remove);

					return listening;
				}
			bool terminate ()
				{/*...}*/
					cp.SpaceFree (space);
					return true;
				}
			const string name ()
				{/*...}*/
					return "collision";
				}
		}
		private: 
		__gshared {/*data}*/
			Space space;

			mixin AutoInitialize;

			@Initialize!(2^^12) 
			Associative!(Array!Body, ClientId)  // REVIEW
				bodies;
				
			@Initialize!(2^^12) 
			Allocator!fvec geometry_memory;

			@Initialize!()
			shared BufferGroup!(
				DoubleBuffer!(fvec, 2^^12),
					`vertices`,
				DoubleBuffer!(Upload, 2^^10),
					`uploads`,
				DoubleBuffer!(Action, 2^^10),
					`actions`,
				BufferGroup!(
					DoubleBuffer!(Query.Box, 2^^4),
						`box`,
					DoubleBuffer!(Query.Ray, 2^^5),
						`ray`,
					DoubleBuffer!(Query.RayCast, 2^^5),
						`ray_cast`,
					DoubleBuffer!(Query.RayCastExcluding, 2^^5),
						`ray_cast_excluding`,
				), `queries`
			) buffer;
		}
		static {/*id conversion}*/
			struct StorageCast
				{/*...}*/
					union {/*...}*/
						 ClientId value;
						 void* pointer;
					}
					this (ClientId value)
						{/*...}*/
							this.value = value;
						}
					this (void* pointer)
						{/*...}*/
							this.pointer = pointer;
						}

				}
			void* store (ClientId id)
				{/*...}*/
					return StorageCast (id).pointer;
				}
			ClientId retrieve (void* id)
				{/*...}*/
					return StorageCast (id).value;
				}
		}
	}

unittest {/*threads}*/
	import core.thread;
	import std.concurrency;

	static void test () {/*...}*/
		scope lC = new CollisionDynamics!();
		auto C = cast(shared)lC;
		C.initialize ();
		C.process ();
		C.terminate ();
		try ownerTid.send (true);
		catch (TidMissingException ex){}
	}
	test;
	std.concurrency.spawn (&test);
	std.concurrency.receive ((bool _){});
}
unittest {/*shape deduction}*/
	alias Body = CollisionDynamics!().Body;
	import std.datetime;

	assert (Body.deduce_shape (circle) == Body.Type.circle);
	assert (Body.deduce_shape (square) == Body.Type.polygon);

	auto triangle = circle!3;
	auto pentagon = circle!5;
	auto hexagon = circle!6;

	assert (Body.deduce_shape (triangle) == Body.Type.polygon);
	assert (Body.deduce_shape (pentagon) == Body.Type.polygon);
	assert (Body.deduce_shape (hexagon) == Body.Type.circle);
}
unittest {/*body upload}*/
	import core.thread;
	import std.datetime;

	alias Body = CollisionDynamics!().Body;

	auto P = new CollisionDynamics!();
	P.start; scope (exit) P.stop;

	auto triangle = [fvec(-1,-1), fvec(-1,0), fvec(0,-1)];

	with (P) add (new_body (0)
		.mass (1)
		.position (fvec(1))
		.velocity (fvec(100))
		.shape (triangle)
	);

	with (P) add (new_body (1)
		.mass (1)
		.position (fvec(-1))
		.velocity (fvec(100))
		.shape (triangle)
	);

	auto a = P.get_body (0);
	auto b = P.get_body (1);

	assert (a.position == fvec(1));
	// static geometry is held at position (0,0) internally
	assert (b.position == fvec(-1));
	// but should report its position correctly when queried

	P.update;
	auto start = Clock.currTime;
	while (a.position == fvec(1))
		{/*...}*/
			assert (Clock.currTime - start < 2.seconds, `waited too long for body to update`);
			Thread.sleep (100.msecs);
		}
}
unittest {/*queries}*/
	import core.thread;
	import std.datetime;
	// TODO all other queries

	alias Id = CollisionDynamics!().Id;

	auto p = new CollisionDynamics!();
	p.start; scope (exit) p.stop;
	
	auto sq = [fvec(0),fvec(1,0),fvec(1),fvec(0,1)];
	auto μ = sq.mean;
	sq = sq.map!(v => v - μ).array;

	with (p) add (
		new_body (0)
		.mass (1)
		.position (0.fvec)
		.shape (sq),

		new_body (1)
		.mass (1)
		.position (fvec(1.49))
		.shape (sq),

		new_body (2)
		.mass (1)
		.position (fvec(-1.51))
		.shape (sq),

		new_body (3)
		.mass (1)
		.position (fvec(1000))
		.shape (sq)
	);

	Future!(Appendable!(Id[32]))[3] futures;

	p.box_query ([fvec(-1),fvec(1)], futures[0]);
	p.box_query ([fvec(-2),fvec(0)], futures[1]);
	p.box_query ([fvec(-3),fvec(-2)], futures[2]);
	// standard query
	p.update;

	futures.back.await;

	assert (futures[0].length == 2);
	assert (futures[1].length == 2);
	assert (futures[2].length == 1);

	futures.clear;

	p.box_query ([fvec(999),fvec(1001)], futures[0]);
	p.box_query ([fvec(300),fvec(400)], futures[1]);
	p.box_query ([fvec(-9999),fvec(9999)], futures[2]);

	p.expedite_queries;

	while (not (futures.back.is_realized))
		Thread.sleep (100.msecs);

	assert (futures[0].length == 1);
	assert (futures[1].length == 0);
	assert (futures[2].length == 4);
}
