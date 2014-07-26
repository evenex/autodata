module services.collision;

import std.algorithm;
import std.range;
import std.traits;
import std.math;

import utils;
import units;
import math;
import meta;
import future;

import services.service;

import resource.array;
import resource.buffer;
import resource.directory;
import resource.allocator;
import resource.view;

// TODO full conversion to doubles. only openGL really needs 32-bit floats, and we can convert on-the-fly when we write to the output buffer
// TODO lazy parameters for all ops which move data (like add and append)


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
private {/*conversions}*/
	import dchip.all : cpVect;
	cpVect to_cpv(vec v)
		{/*...}*/
			return cpVect (v.x, v.y);
		}
}

private struct UpdateSignal {};

private immutable MAX_SHAPES = 8;

final class CollisionDynamics (ClientId = size_t): Service
	if (ClientId.sizeof <= (void*).sizeof)
	{/*...}*/
		private {/*definitions}*/
			import dchip.all;
			alias Space 	= cpSpace*;
			alias ShapeId	= cpShape*;
			alias BodyId 	= cpBody*;
		}
		public:
		public {/*bodies}*/
			struct Body
				{/*...}*/
					BodyId body_id;
					Dynamic!(ShapeId[MAX_SHAPES]) shape_ids;
					CollisionDynamics world;

					double velocity_damping = 0.0;

					enum Type {none, circle, polygon}

					public:
					@property {/*get}*/
						double mass ()
							{/*...}*/
								return cp.BodyGetMass (body_id);
							}
						vec position ()
							{/*...}*/
								return vec(cp.BodyGetPos (body_id));
							}
						vec velocity ()
							{/*...}*/
								return vec(cp.BodyGetVel (body_id));
							}
						double damping ()
							{/*...}*/
								return velocity_damping;
							}
						uint layer ()
							{/*...}*/
								return cp.ShapeGetLayers (shape_ids[0]); // REVIEW
							}
						vec applied_force ()
							{/*...}*/
								return vec(cp.BodyGetForce (body_id));
							}
					}
					@property {/*set}*/
						void position (vec new_position)
							{/*...}*/
								cp.BodySetPos (body_id, new_position.to_cpv);
								auto space = cp.BodyGetSpace (body_id);
								cp.SpaceReindexShapesForBody (space, body_id);
							}
						void velocity (vec new_velocity)
							in {/*...}*/
								assert (mass.not!isInfinity);
							}
							body {/*...}*/
								cp.BodySetVel (body_id, new_velocity.to_cpv);
							}
						void damping (double new_damping)
							in {/*...}*/
								assert (mass != double.infinity);
							}
							body {/*...}*/
								velocity_damping = new_damping;
							}
						void applied_force (vec new_force)
							{/*...}*/
								cp.BodySetForce (body_id, new_force.to_cpv);
							}
						void layer (uint new_layer)
							{/*...}*/
								foreach (shape; shape_ids)
									cp.ShapeSetLayers (shape, new_layer); // REVIEW
							}
					}
					private:
					private {/*☀/~}*/
						this (R)(cpSpace* space, double mass, vec position, vec velocity, double damping, ClientId client_id, R geometries)
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
														auto center = geometry.mean.to_cpv;

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
						vec, 		`position`,
						vec, 		`velocity`,
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
					Dynamic!(vec[][MAX_SHAPES]) shapes;
					Promise!(Body*) promise;

					@property auto geometry ()
						{/*...}*/
							return contigious (shapes[]);
						}

					this (ClientId id, CollisionDynamics server)
						{/*...}*/
							this.id = id;
							this.server = server;
						}
				}
			@Upload void add (Upload upload)
				in {/*...}*/
					assert (this.is_running, "attempted to add body before starting service");
					assert (not (upload.id in bodies), `duplicate ids`);
				}
				body {/*...}*/
					buffer.uploads ~= upload;
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
			auto body_ (ClientId id)
				{/*...}*/
					auto result = bodies.index_of (id);

					if (result > -1)
						return BodyInterface (bodies[id]);
					else foreach (ref upload; buffer.uploads.write[])
						if (upload.id == id)
							return BodyInterface (upload, this);

					assert (0, `body ` ~id.text~ ` does not exist`);
				}

			struct Query
				{/*...}*/
					struct Box
						{/*...}*/
							vec[2] corners;
							Promise!(View!ClientId) result;
						}
					struct Ray
						{/*...}*/
							ClientId id;
							RayCast ray_cast;

							alias ray_cast this;
						}
					struct RayCast
						{/*...}*/
							vec[2] ray;
							Promise!Incidence result;
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
					vec surface_normal;
					double ray_time;
				}

			Future!(View!ClientId) box_query (vec[2] corners)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.box ~= Query.Box (corners);
					return promise (buffer.queries.box.write.back.result);
				}
			Future!Incidence ray_cast (vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray_cast ~= Query.RayCast (ray);
					return promise (buffer.queries.ray_cast.write.back.result);
				}
			Future!Incidence ray_query (T)(T id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray ~= Query.Ray (id, Query.RayCast (ray));
					return promise (buffer.queries.ray.write.back.result);
				}
			Future!Incidence ray_cast_excluding (T)(T id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					buffer.queries.ray_cast_excluding ~= Query.RayCastExcluding (id, Query.RayCast (ray));
					return promise (buffer.queries.ray_cast_excluding.write.back.result);
				}
		}
		public {/*update}*/
			void update ()
				in {/*...}*/
					assert (this.is_running, "attempted to update simulation before starting service");
				}
				body {/*...}*/
					send (UpdateSignal ());
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
					mixin(profiler);
					(profiler).checkpoint (&bodies);
					{/*process uploads}*/
						buffer.swap;
						auto vertex_pool = buffer.vertices.read[];
						foreach (ref upload; buffer.uploads.read[])
							{/*...}*/
								with (upload) if (position != position)
									position = geometry.mean;

								upload.promise = &bodies.add (upload.id, // TODO promise xor interface?
									Body (
										space,
										upload.mass, 
										upload.position, 
										upload.velocity, 
										upload.damping, 
										upload.id,
										upload.shapes
									)
								)[1];
							}
					}
					cp.SpaceStep (space, Δt);
					++t;
					{/*postprocess}*/
						foreach (ref dynamic_body; bodies)
							with (dynamic_body) if (damping > 0.0)
								velocity = velocity*(1.0 - damping);
					}
					{/*reply to queries}*/
						static auto get_id (cpShape* shape)
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
												cp.ShapeSegmentQuery (shape, ray[0].to_cpv, ray[1].to_cpv, &info);
										else cp.SpaceSegmentQueryFirst (space, ray[0].to_cpv, ray[1].to_cpv, 
											layers, group, &info
										);

										if (info.shape)
											return Incidence (get_id (info.shape), info.n.vec, info.t);
										else return Incidence (ClientId.init, 0.vec, 1.0);
									}
								else static if (is (T == Query.Box))
									{/*...}*/
										auto i = query_results.length;

										auto box = cp.BB (query.corners.bounding_box.bounds_tuple.expand);
										auto layers = CP_ALL_LAYERS;
										auto group = CP_NO_GROUP;

										cp.SpaceBBQuery (space, box, layers, group, 
											(cpShape* shape, void* results) 
												{(*cast(Dynamic!(Array!ClientId)*) results) ~= get_id (shape);},
											&query_results
										);
										return view (query_results[i..$]);
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

										cp.SpaceSegmentQueryFirst (space, ray[0].to_cpv, ray[1].to_cpv, 
											layers, group, &info
										);

										bodies[id].layer = CP_ALL_LAYERS;

										if (info.shape)
											return Incidence (get_id (info.shape), info.n.vec, info.t);
										else return Incidence (ClientId.init, 0.vec, 1.0);
									}
							}

						query_results.clear;
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
					return true;
				}
			bool listen ()
				{/*...}*/
					// REVIEW ALL
					bool listening = true;

					auto proceed (UpdateSignal _) 
						{/*...}*/
							listening = false;
						}
					auto remove (ClientId id)
						{/*...}*/
							bodies.remove (id);
							reply (true); /// REVIEW
						}
					static if (0) //XXX
					auto act (Id id, Body.Action action)
						{/*...}*/
							assert (id in body_ptr, "body "~id.text~" does not exist");
							import std.string: cap = capitalize;
							const string apply (string op) ()
								{/*...}*/
									return q{case }~op~q{: cp.BodyApply}~cap(op)~q{(body_ptr[id], action.vector.to_cpv, cpvzero); break;}; // arg[2] is how you get torque
								}
							with (Body.Action.Type) 
								final switch (action.type)
									{/*...}*/
										mixin (apply!`force`);
										mixin (apply!`impulse`);
										case none: assert (null);
									}
							reply (true);
						}
					auto set (ClientId id, string property, vec value)
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
							reply (true); // REVIEW
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

					receive (&proceed, &remove);

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
			Directory!(Body, ClientId) 
				bodies;

			@Initialize!(2^^10) 
			Dynamic!(Array!ClientId) 
				query_results;
				
			@Initialize!(2^^12) 
			Allocator!vec geometry_memory;

			@Initialize!()
			shared BufferGroup!(
				DoubleBuffer!(vec, 2^^12),
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

unittest
	{/*threads}*/
		import core.thread;
		import std.concurrency;

		mixin (report_test!`multithreaded collision`);
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
unittest
	{/*shape deduction}*/
		alias Body = CollisionDynamics!().Body;
		import std.datetime;

		mixin(report_test!"shape deduction");

		assert (Body.deduce_shape (circle) == Body.Type.circle);
		assert (Body.deduce_shape (square) == Body.Type.polygon);

		auto triangle = circle!3;
		auto pentagon = circle!5;
		auto hexagon = circle!6;

		assert (Body.deduce_shape (triangle) == Body.Type.polygon);
		assert (Body.deduce_shape (pentagon) == Body.Type.polygon);
		assert (Body.deduce_shape (hexagon) == Body.Type.circle);
	}
void main()
	{/*body upload}*/
		import core.thread;
		import std.datetime;

		alias Body = CollisionDynamics!().Body;

		mixin (report_test!`body upload`);

		auto P = new CollisionDynamics!();
		P.start; scope (exit) P.stop;

		auto triangle = [vec(-1,-1), vec(-1,0), vec(0,-1)];

		with (P) add (new_body (0)
			.mass (1)
			.position (vec(1))
			.velocity (vec(100))
			.shape (triangle)
		);

		with (P) add (new_body (1)
			.mass (1)
			.position (vec(-1))
			.velocity (vec(100))
			.shape (triangle)
		);

		auto a = P.body_(0);
		auto b = P.body_(1);


		assert (a.position == vec(1));
		// static geometry is held at position (0,0) internally
		assert (b.position == vec(-1));
		// but should report its position correctly when queried

		P.update;
					Thread.sleep (1.seconds); //  TODO

		assert (b.position.x > -1);
		assert (a.position.x > -1);

		//assert (a.displacement == vec(1));
		// initial displacement for static bodies must be handled specially TODO i think this is no longer true
		//assert (b.displacement == vec(-1)); 
		// to allow client-side geometry to be correctly updated after initialization

		P.update;
		// the displacement goes to 0 after the next update XXX
		//assert (b.displacement == vec(0));  XXX
		// but the position is still reported correctly
		assert (b.position.x > -1);
		assert (a.position.x > -1);
	}
unittest
	{/*queries}*/
		mixin (report_test!`queries`);
		// TODO all other queries

		auto p = new CollisionDynamics;
		p.start; scope (exit) p.stop;
		
		auto sq = [vec(0),vec(1,0),vec(1),vec(0,1)];
		auto μ = sq.mean;
		sq = sq.map!(v => v - μ).array;
		auto a = p.add_body (CollisionDynamics.Body (vec(0)), sq);
		auto b = p.add_body (CollisionDynamics.Body (vec(1.49)), sq);
		auto c = p.add_body (CollisionDynamics.Body (vec(-1.51)), sq);
		auto d = p.add_body (CollisionDynamics.Body (vec(1000)), sq);
		p.update;
		assert (p.box_query ([vec(-1),vec(1)])		.length == 2); // BUG probably disallow array literals cause they GC
		assert (p.box_query ([vec(-2),vec(0)])		.length == 2);
		assert (p.box_query ([vec(-3),vec(-2)])		.length == 1);
		assert (p.box_query ([vec(999),vec(1001)])	.length == 1);
		assert (p.box_query ([vec(300),vec(400)])	.length == 0);
		assert (p.box_query ([vec(-9999),vec(9999)]).length == 4);
	}
