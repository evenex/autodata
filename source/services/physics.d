module services.physics;

import std.algorithm;
// TODO more stable methods
import std.range;
import std.array;
import std.traits;
import std.math;

import utils;
import units;
import math;

import services.service;

import resource.buffer;
import resource.directory;
import resource.allocator;

import models.model;
// TODO full conversion to doubles. only openGL really needs 32-bit floats, and we can convert on-the-fly when we write to the output buffer
// TODO lazy parameters for all ops which move data (like add and append)

final class Physical
	{mixin Model;/*}*/
	//	alias Position = Vec2!Meters;
	//	alias Velocity = Vec2!(typeof(meters/second));

		@(2^^8)
		@Aspect struct Body
			{/*...}*/
				@(2^^16) double[] geometry;
				double position;
				double velocity;
				double mass;
				double damping;
				double elevation;
				double height;
			}

		// TODO aspect stuff
		auto model (Entity.Id entity)
			{/*...}*/
				
			}
		auto release (Entity.Id entity)
			{/*...}*/
				
			}
	}

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

final class Physics: Service
	{/*...}*/
		private {/*definitions}*/
			import dchip.all;
			alias Space 	= cpSpace*;
			alias ShapeId	= cpShape*;
			alias BodyId 	= cpBody*;
			struct UserId 
				{/*...}*/
					// REFACTOR
					size_t transfer; 
					void* storage ()
						{/*...}*/
							union Cast {size_t _; void* output;}
							return Cast(transfer).output;
						}

					static opCall (T)(T id)
						if (T.sizeof <= UserId.sizeof)
						{/*...}*/
							union Cast {T _; UserId output;}
							return Cast(id).output;
						}

					T opCast (T)()
						if (T.sizeof <= UserId.sizeof)
						{/*...}*/
							union Cast {UserId _; T output;}
							return Cast(this).output;
						}

					mixin CompareBy!transfer;

					static assert (size_t.sizeof == (void*).sizeof);
				}
		}
		public:
		public {/*queries}*/
			// REVIEW its uncertain which queries, if any, are safe to cast while the simulator is iterating.
			// this problem may require fibers and some kind of traffic control system
			// but how do i test?
			private struct Query
				{/*...}*/
					auto type = Type.none;
					UserId id;
					vec[2] args;
					enum Type {
						/*error*/ 		none, 
						/*intrinsic*/ 	mass, position, velocity, damping, applied_force, 
						///*historic*/	displacement, XXX
						/*collision*/	/*colliding,XXX*/ layer,
						/*spatial*/ 	box, ray, ray_exclusive
					}
					public {/*sort}*/
						mixin CompareBy!id;
					}
				}
			struct Incidence
				{/*...}*/
					UserId body_id;
					vec surface_normal;
					double ray_time;
				}
			@Query UserId[] box_query (vec[2] corners)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							type: Query.Type.box,
							args: corners
						};
					send (query);
					UserId[] result;
					receive ((immutable UserId[] reply)
						{result = reply.dup;});
					return result;
				}
			@Query Incidence ray_cast (vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.text~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							type: Query.Type.ray,
							args: ray
						};
					send (query);
					Incidence result;
					receive ((Incidence reply) 
						{result = reply;});
					return result;
				}
			@Query Incidence ray_query (T)(T id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							id: UserId (id),
							type: Query.Type.ray,
							args: ray
						};
					send (query);
					Incidence result;
					receive ((Incidence reply) 
						{result = reply;});
					return result;
				}
			@Query Incidence ray_cast_excluding (T)(T id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							id: UserId (id),
							type: Query.Type.ray_exclusive,
							args: ray
						};
					send (query);
					Incidence result;
					receive ((Incidence reply) 
						{result = reply;});
					return result;
				}
		}
		public {/*uploads}*/
			private struct Upload
				{/*...}*/
					UserId id; // wierd
					double mass;
					vec position;
					vec velocity;
					double damping;
					public {/*vertices}*/
						uint index;
						uint length;
					}
				}
			@Upload Body add (T) (Body seed, T geometry)
				if (is_geometric!T)
				{/*↓}*/
					add (seed, geometry);
					return seed;
				}
			@Upload void add (T) (ref Body seed, T geometry)
				if (is_geometric!T)
				in {/*...}*/
					assert (this.is_running, "attempted to add body before starting service");
				}
				body {/*...}*/
					if (seed.init_position != seed.init_position)
						seed.init_position = geometry.mean;
					import std.stdio;
					Upload upload =
						{/*...}*/
							id: seed.id,
							mass: seed.mass,
							position: seed.init_position,
							velocity: seed.init_velocity,
							damping: seed.init_damping,
							index: vertices.length.to!uint,
							length: geometry.length.to!uint
						};

					vertices ~= geometry;
					send (upload);
					receive ((bool acknowledge){});
					with (seed) seed = Body (this, id, mass, init_velocity, init_position, init_damping);
				}
		}
		public {/*update}*/
			void update ()
				in {/*...}*/
					assert (this.is_running, "attempted to update simulation before starting service");
				}
				body {/*...}*/
					send (true);
				}
		}
		static shared {/*time}*/
			immutable real Δt = 0.016667; // TODO set custom
			auto time ()
				{/*...}*/
					return t * Δt;
				}
			private ulong t = 0;
		}
		public {/*ctor}*/
			this ()
				{/*...}*/
					buffer.initialize;
					bodies = Directory!(Body, UserId) ();
					shape_id_memory = Allocator!ShapeId ();
					geometry_buffer = Allocator!vec ();
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
					{/*process uploads}*/
						buffer.swap;
						auto vertex_pool = buffer.vertices.rear[];
						foreach (upload; buffer.uploads.rear[])
							{/*...}*/
								auto i = upload.index;
								auto n = upload.length;
								auto temp = Body (
									space,
									upload.mass, 
									upload.position, 
									upload.velocity, 
									upload.damping, 
									upload.id,
									vertex_pool[i..i+n], 
								);
								bodies[upload.id] = temp;
								temp.body_id = BodyId.init; // REVIEW
							}
					}
					cp.SpaceStep (space, Δt);
					++t;
					{/*postprocess}*/
						foreach (ref dynamic_body; bodies)
							with (dynamic_body) if (damping > 0.0)
								velocity = velocity*(1.0 - damping);
					}
					return true;
				}
			bool listen ()
				{/*...}*/
					bool listening = true;

					auto proceed (bool _) 
						{/*...}*/
							listening = false;
						}
					auto upload (Upload upload)
						{/*...}*/
							buffer.uploads ~= upload; 
							reply (true);
						}
					auto remove (UserId id)
						{/*...}*/
							bodies.remove (id);
							reply (true);
						}
					auto query (Query query)
						{/*...}*/
							static auto get_id (cpShape* shape)
								{/*...}*/
									return UserId (cp.ShapeGetUserData (shape));
								}
							auto box_query (Query query)
								in {/*...}*/
									foreach (c; query.args)
										assert (c.x == c.x && c.y == c.y);
								}
								body {/*...}*/
									UserId[] bodies; // REFACTOR
									auto corners = query.args;

									auto a = corners[0];
									auto b = corners[1];

									auto box = cp.BB (min(a.x, b.x), min(a.y, b.y), max(a.x, b.x), max(a.y, b.y));
									auto layers = CP_ALL_LAYERS;
									auto group = CP_NO_GROUP;

									cp.SpaceBBQuery (space, box, layers, group, 
										(cpShape* shape, void* bodies) 
											{(*cast(UserId[]*) bodies) ~= get_id (shape);}, // REFACTOR gross
										&bodies
									);
									return bodies.map!(ptr => cast(immutable) ptr).array.idup; // REFACTOR super gross
								}
							auto ray_query (Query query)
								{/*...}*/
									auto id = query.id;
									auto ray = query.args;

									auto layers = CP_ALL_LAYERS;
									auto group = CP_NO_GROUP;

									cpSegmentQueryInfo info;

									if (id != UserId.init)
										foreach (shape; bodies[id].shape_ids)
											cp.ShapeSegmentQuery (shape, ray[0].to_cpv, ray[1].to_cpv, &info);
									else cp.SpaceSegmentQueryFirst (space, ray[0].to_cpv, ray[1].to_cpv, 
										layers, group, &info
									);

									if (info.shape)
										return Incidence (get_id (info.shape), info.n.vec, info.t);
									else return Incidence (UserId.init, 0.vec, 1.0);
								}
							auto ray_exclusive_query (Query query)
								{/*...}*/
									auto id = query.id;
									auto ray = query.args;

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
									else return Incidence (UserId.init, 0.vec, 1.0);
								}
							const string get (string prop)()
								{/*...}*/
									return q{case }~prop~q{: reply (bodies[query.id].}~prop~q{); return;};
								}
							const string ask (string prop)()
								{/*...}*/
									return q{case }~prop~q{: reply (}~prop~q{_query (query)); break;};
								}

							final switch (query.type)
								with (Query.Type) {/*...}*/
								/*intrinsic*/
								mixin (get!`mass`);
								mixin (get!`position`);
								mixin (get!`velocity`);
								mixin (get!`damping`);
								mixin (get!`applied_force`);
								/*historic*/
							//	mixin (get!`displacement`); XXX
								/*spatial*/
								mixin (ask!`box`);
								mixin (ask!`ray`);
								mixin (ask!`ray_exclusive`);
								/*misc*/
								//mixin (get!`colliding`); XXX
								mixin (get!`layer`);
								/*error*/
								case none: assert (null);
							}
						}
					static if (0) //XXX
					auto act (Id id, Body.Action action)
						{/*...}*/
							assert (id in body_ptr, "body "~to!string(id)~" does not exist");
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
					auto set (T)(T id, string property, vec value)
						{/*...}*/
							assert (id in bodies, "body "~id.text~" does not exist");
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
							reply (true);
						}
					auto debug_query (T)(T id, string query)
						{/*...}*/
							assert (id in bodies, "queried body "~to!string(id)~" not uploaded");
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

					receive (&proceed, &upload, &remove, &query /*, &act, &set, &debug_query XXX*/);

					return listening;
				}
			bool terminate ()
				{/*...}*/
					cp.SpaceFree (space);
					return true;
				}
			const string name ()
				{/*...}*/
					return "physics";
				}
		}
		private: 
		static {/*data}*/ // TODO maybe __gshared
			Space space;
			Directory!(Body, UserId) 
				bodies;
			Allocator!ShapeId 
				shape_id_memory;
			Allocator!vec 
				geometry_buffer;
			shared BufferGroup!(
				DoubleBuffer!(vec, 2^^12),
					`vertices`,
				DoubleBuffer!(Upload, 2^^10),
					`uploads`,
			) buffer;
		}
		struct Body
			{/*...}*/
				BodyId body_id;
				Resource!ShapeId shape_ids;

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
				private:
				@property {/*set}*/
					void position (vec new_position)
						{/*...}*/
							cp.BodySetPos (body_id, new_position.to_cpv);
							auto space = cp.BodyGetSpace (body_id);
							cp.SpaceReindexShapesForBody (space, body_id);
						}

					void velocity (vec new_velocity)
						in {/*...}*/
							assert (mass != double.infinity);
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
				private {/*☀/~}*/
					this (R...)(cpSpace* space, double mass, vec position, vec velocity, double damping, UserId user_id, R geometries)
						if (allSatisfy!(is_geometric, R))
						in {/*...}*/
							assert (mass == mass);
							assert (position == position);
							assert (velocity == velocity || mass == double.infinity);
							foreach (geometry; geometries)
								{/*...}*/
									assert (geometry.length > 2);
									auto bounds = geometry.reduce!(
										(u,v) => vec(max(u.x, v.x), max(u.y, v.y)),
										(u,v) => vec(min(u.x, v.x), min(u.y, v.y)),
									);
									assert ((bounds[1]-bounds[0]).norm > double.epsilon,
										"attempted to create physics body with zero volume");
								}
						}
						body {/*...}*/
							if (mass == double.infinity)
								this.body_id = cp.BodyNewStatic;
							else this.body_id = cp.BodyNew (mass, 0.0);

							cp.SpaceAddBody (space, body_id);
							this.position = position;
							this.velocity = velocity;
							this.damping  = damping;
							cp.BodySetUserData (body_id, user_id.storage);

							auto areas = only (geometries).map!area;
							auto Σ_areas = sum (areas);
							
							this.shape_ids = shape_id_memory.allocate (R.length);
							foreach (i, geometry; geometries)
								{/*...}*/
									ShapeId shape;
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
													auto poly = geometry_buffer.save (geometry);
													auto hull = geometry_buffer.allocate (len);

													cp.ConvexHull (len, cast(cpVect*)poly[].ptr, cast(cpVect*)hull[].ptr, null, 0.0);

													moment = cp.BodyGetMoment (body_id) + cp.MomentForPoly (component_mass, len, cast(cpVect*)hull[].ptr, cpvzero);
													this.shape_ids ~= cp.PolyShapeNew (body_id, len, cast(cpVect*)hull[].ptr, cpvzero);

													poly.free;
													hull.free;

													break;
												}
											case none: assert (null);
										}

									cp.BodySetMoment (body_id, moment);
									cp.SpaceAddShape (space, shape);
									cp.ShapeSetUserData (shape, user_id.storage);
								}
						}

					void free ()
						{/*...}*/
							auto space = cp.BodyGetSpace (body_id);

							foreach (shape; shape_ids[])
								{/*...}*/
									cp.SpaceRemoveShape (space, shape);
									cp.ShapeFree (shape);
								}
							shape_ids.free;

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
							auto dirs = geometry.zip (geometry.shift).map!(v => (v[1]-v[0]).unit);
							auto turn = dirs.zip (dirs.shift);

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
	}

auto area (R)(R polygon) // TODO unittest
	if (is_geometric!R)
	{/*...}*/
		return 0.5 * Σ (polygon.zip (polygon.shift).map!(v => v[0].det (v[1])));
	}
auto shift (R)(R range, long positions = 1) // TODO unittest
	{/*...}*/
		auto n = range.length;
		auto i = (positions + n) % n;
		assert (i > 0);
		return range.cycle[i..n+i];
	}

unittest
	{/*threads}*/
		import core.thread;
		import std.concurrency;

		mixin (report_test!`multithreaded physics`);
		static void test () {/*...}*/
			scope lP = new Physics;
			auto P = cast(shared)lP;
			P.initialize ();
			P.process ();
			P.terminate ();
			try ownerTid.send (true);
			catch (TidMissingException ex){}
		}
		test;
		std.concurrency.spawn (&test);
		std.concurrency.receive ((bool _){});
	}
unittest
	{/*shape deduction}*/
		alias Body = Physics.Body;
		alias TrueBody = Physics.TrueBody;
		import std.datetime;

		mixin (report_test!"shape deduction");

		scope p = new Physics;
		p.start; scope (exit) p.stop;

		auto a = p.add (Body (vec(0)), square (0.5));
		auto b = p.add (Body (vec(0)), square (0.5, vec(1000.0)));
		auto c = p.add (Body (vec(0)), circle (0.5));
		auto d = p.add (Body (vec(0)), circle (0.5, vec(1000.0)));
		p.update ();
		assert (a.type == TrueBody.Type.polygon);
		assert (b.type == TrueBody.Type.polygon);
		assert (c.type == TrueBody.Type.circle);
		assert (d.type == TrueBody.Type.circle);
		assert (a.initialized && a.position == vec(0));
		assert (b.initialized && b.position == vec(0));
		assert (c.initialized && c.position == vec(0));
		assert (d.initialized && d.position == vec(0));
		auto e = p.add (Body (vec(1000)), square (0.5));
		auto f = p.add (Body (vec(1000)), square (0.5, vec(1000.0)));
		p.update ();
		assert (e.type == TrueBody.Type.polygon);
		assert (f.type == TrueBody.Type.polygon);
		assert (e.initialized && e.position == vec(1000));
		assert (f.initialized && f.position == vec(1000));

		auto tri = p.add (Body (vec(0)), circle!3 (0.5, vec(1000.0)));
		auto pen = p.add (Body (vec(0)), circle!5 (0.5, vec(1000.0)));
		auto hex = p.add (Body (vec(0)), circle!6 (0.5, vec(1000.0)));
		p.update ();
		assert (tri.type == TrueBody.Type.polygon);
		assert (pen.type == TrueBody.Type.polygon);
		assert (hex.type == TrueBody.Type.circle);
	}
unittest
	{/*body positioning}*/
		alias Body = Physics.Body;

		mixin (report_test!`body positioning`);

		auto P = new Physics;
		P.start; scope (exit) P.stop;

		auto triangle = [vec(-1,-1), vec(-1,0), vec(0,-1)];
		auto a = P.add (Body (vec(1)), triangle);
		auto b = P.add (Body.immovable (vec(-1)), triangle);
		P.update;

		assert (a.position == vec(1));
		// static geometry is held at position (0,0) internally
		assert (b.position == vec(-1));
		// but should report its position correctly when queried

		assert (a.displacement == vec(1));
		// initial displacement for static bodies must be handled specially
		assert (b.displacement == vec(-1)); 
		// to allow client-side geometry to be correctly updated after initialization

		P.update;
		// the displacement goes to 0 after the next update
		assert (b.displacement == vec(0)); 
		// but the position is still reported correctly
		assert (b.position == vec(-1));
		// a remains unchanged as it has not been acted upon
		assert (a.position == vec(1));
	}
unittest
	{/*box_query}*/
		mixin (report_test!`box_query`);

		auto p = new Physics;
		p.start; scope (exit) p.stop;
		
		auto sq = [vec(0),vec(1,0),vec(1),vec(0,1)];
		auto μ = sq.mean;
		sq = sq.map!(v => v - μ).array;
		auto a = p.add (Physics.Body (vec(0)), sq);
		auto b = p.add (Physics.Body (vec(1.49)), sq);
		auto c = p.add (Physics.Body (vec(-1.51)), sq);
		auto d = p.add (Physics.Body (vec(1000)), sq);
		p.update;
		assert (p.box_query ([vec(-1),vec(1)])		.length == 2); // BUG probably disallow array literals cause they GC
		assert (p.box_query ([vec(-2),vec(0)])		.length == 2);
		assert (p.box_query ([vec(-3),vec(-2)])		.length == 1);
		assert (p.box_query ([vec(999),vec(1001)])	.length == 1);
		assert (p.box_query ([vec(300),vec(400)])	.length == 0);
		assert (p.box_query ([vec(-9999),vec(9999)]).length == 4);
	}
