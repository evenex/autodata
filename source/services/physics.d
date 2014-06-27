module services.physics;

import std.algorithm;
// TODO more stable methods
import std.range;
import std.array;
import std.traits;
import std.math;

import utils;
import math;

import services.service;

import memory.buffer;

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
		public struct Body
			{/*...}*/
				public:
				@Query {/*intrinsic}*/
					@property {/*mass}*/
						float mass () const
							{/*...}*/
								if (initialized && init_mass != float.infinity)
									{/*...}*/
										float mass;
										Query query =
											{/*...}*/
												type: Query.Type.mass,
												id: this.id
											};
										world.send (query);
										receive ((float reply){mass = reply;});
										return mass;
									}
								else return init_mass;
							}
						void mass (float new_mass)
							in {/*...}*/
								assert (uninitialized, "attempted to set mass after initialization");
							}
							body {/*...}*/
								init_mass = new_mass;
							}
					}
					@property {/*position}*/
						vec position () const
							{/*...}*/
								if (uninitialized || mass == float.infinity)
									return init_position;
								else {/*...}*/
									vec position;
									Query query = 
										{/*...}*/
											type: Query.Type.position,
											id: this.id
										};
									world.send (query);
									receive ((vec reply){position = reply;});
									return position;
								}
							}
						void position (vec new_position)
							{/*...}*/
								if (uninitialized)
									init_position = new_position;
								else {/*...}*/
									world.send (id, "position", new_position);
									receive ((bool acknowledgement){});
								}
							}
					}
					@property {/*velocity}*/
						vec velocity () const
							{/*...}*/
								if (uninitialized)
									return init_velocity;
								else {/*...}*/
									vec velocity;
									Query query =
										{/*...}*/
											type: Query.Type.velocity,
											id: this.id
										};
									world.send (query);
									receive ((vec reply){velocity = reply;});
									return velocity;
								}
							}
						void velocity (vec new_velocity)
							in {/*...}*/
								assert (mass != float.infinity);
							}
							body {/*...}*/
								if (uninitialized)
									init_velocity = new_velocity;
								else {/*...}*/
									world.send (id, "velocity", new_velocity);
									receive ((bool acknowledgement){});
								}
							}
					}
					@property {/*damping}*/
						float damping () const
							{/*...}*/
								if (uninitialized)
									return init_damping;
								else {/*...}*/
									float damping;
									Query query =
										{/*...}*/
											type: Query.Type.damping,
											id: this.id
										};
									world.send (query);
									receive ((float reply){damping = reply;});
									return damping;
								}
							}
						void damping (float new_damping)
							in {/*...}*/
								assert (mass != float.infinity);
							}
							body {/*...}*/
								if (uninitialized)
									init_damping = new_damping;
								else {/*...}*/
									world.send (id, "damping", new_damping);
									receive ((bool acknowledgement){});
								}
							}
					}
					@property {/*applied force}*/
						vec applied_force () const
							in {/*...}*/
								assert (initialized);
							}
							body {/*...}*/
								vec applied_force;
								Query query =
									{/*...}*/
										type: Query.Type.applied_force,
										id: this.id
									};
								world.send (query);
								receive ((vec reply){applied_force = reply;});
								return applied_force;
							}
						void applied_force (vec new_force)
							in {/*...}*/
								assert (initialized);
								assert (mass != float.infinity);
							}
							body {/*...}*/
								world.send (id, "applied_force", new_force);
								receive ((bool acknowledgement){});
							}
					}
				}
				@Query {/*historic}*/
					@property vec displacement () const
						in {/*...}*/
							assert (initialized);
						}
						body {/*...}*/
							vec displacement;
							Query query = 
								{/*...}*/
									type: Query.Type.displacement,
									id: this.id
								};
							world.send (query);
							receive ((vec reply){displacement = reply;});
							return displacement;
						}
				}
				@Query {/*collision}*/
					@property {/*layer}*/
						uint layer ()
							in {/*...}*/
								assert (initialized);
							}
							body {/*...}*/
								uint layer;
								Query query = 
									{/*...}*/
										type: Query.Type.layer,
										id: this.id
									};
								world.send (query);
								receive ((uint reply){layer = reply;});
								return layer;
							}
						void layer (uint new_layer)
							in {/*...}*/
								assert (initialized);
							}
							body {/*...}*/
								world.send (id, "layer", new_layer);
								receive ((bool acknowledgement){});
							}
					}
					@property bool colliding () const
						in {/*...}*/
							assert (initialized);
						}
						body {/*...}*/
							bool colliding;
							Query query =
								{/*...}*/
									type: Query.Type.colliding,
									id: this.id
								};
							world.send (query);
							receive ((bool reply){colliding = reply;});
							return colliding;
						}
				}
				@property {/*existence}*/
					bool initialized () const
						{/*...}*/
							if (world is null)
								return false;
							else return true;
						}
					bool uninitialized () const
						{/*...}*/
							return not (initialized);
						}
				}
				public:
				@Action {/*actions}*/
					private struct Action
						{/*...}*/
							auto type = Type.none;
							vec vector;
							enum Type {none, force, impulse}
						}
					void apply_force (vec force)
						{/*...}*/
							Action action = 
								{/*...}*/
									type: Action.Type.force,
									vector: force
								};
							world.send (id, action);
							receive ((bool acknowledge){});
						}
					void apply_impulse (vec impulse)
						{/*...}*/
							Action action = 
								{/*...}*/
									type: Action.Type.impulse,
									vector: impulse
								};
							world.send (id, action);
							receive ((bool acknowledge){});
						}
				}
				public:
				public {/*id}*/
					mixin TypeUniqueId;
					pure @property Body.Id id () const
						{/*...}*/
							return body_id;
						}
				}
				public {/*user data}*/
					void* user_data;
				}
				@Upload {/*☀}*/
					@() static Body immovable (vec position = vec(0))
						{/*...}*/
							return Body (float.infinity, position);
						}
					@() this (vec position, vec velocity = vec(0), float damping = 0.0)
						{/*...}*/
							this (1.0, position, velocity, damping);
						}
					@Id this (float mass, vec position, vec velocity = vec(0), float damping = 0.0)
						{/*...}*/
							this.world = null;
							this.body_id = Body.Id.create;
							this.init_mass = mass;
							this.init_position = position;
							this.init_velocity = velocity;
							this.init_damping = damping;
						}
				}
				public {/*~}*/
					~this ()
						{/*...}*/
							if (initialized && id != Body.Id.init)
								{/*...}*/
									//world.send (id); TODO deletion
									//receive ((bool goodbye){});
								}
						}
				}
				private:
				private {/*data}*/
					Physics world;
					Body.Id body_id;
					float init_mass;
					vec init_position;
					vec init_velocity;
					float init_damping;
				}
				private {/*☀}*/
					@Upload this (Physics world, Body.Id id, float mass, vec velocity, vec position, float damping)
						in {/*...}*/
							assert (world !is null, "world doesn't exist");
						}
						body {/*...}*/
							this.world = world;
							this.body_id = id;
							this.init_mass = mass;
							this.init_position = position;
							this.init_velocity = velocity;
							this.init_damping = damping;
						}
				}
				debug {/*...}*/
					TrueBody.Type type ()
						{/*...}*/
							world.send (id, "type");
							TrueBody.Type type;
							receive ((TrueBody.Type reply) {type = reply;});
							return type;
						}
				}
			}
		private struct TrueBody
			{/*...}*/
				private {/*imports}*/
					import dchip.all;
				}
				public:
				public {/*~}*/
					~this ()
						{/*...}*/
							if (id in bodies)
								{/*...}*/
									assert (id in body_ptr);
									assert (id in shape_ptr);
									auto space = cp.ShapeGetSpace (shape_ptr[id]);
									assert (cp.SpaceContainsShape (space, shape_ptr[id]));
									assert (cp.SpaceContainsBody (space, body_ptr[id]));
									cp.SpaceRemoveBody (space, body_ptr[id]);
									cp.ShapeFree (shape_ptr[id]);
									cp.BodyFree (body_ptr[id]);
									bodies.remove (id);
									body_ptr.remove (id);
									shape_ptr.remove (id);
								}
						}
				}
				private:
				@property {/*intrinsic}*/
					@property {/*mass}*/
						float mass ()
							{/*...}*/
								return cp.BodyGetMass (body_ptr[id]);
							}
					}
					@property {/*position}*/
						vec position ()
							{/*...}*/
								return cast(vec)cp.BodyGetPos (body_ptr[id]);
							}
						void position (vec new_position)
							{/*...}*/
								cp.BodySetPos (body_ptr[id], new_position.to_cpv);
								auto space = cp.ShapeGetSpace (shape_ptr[id]);
								cp.SpaceReindexShapesForBody (space, body_ptr[id]);
							}
					}
					@property {/*velocity}*/
						vec velocity ()
							{/*...}*/
								return cast(vec)cp.BodyGetVel (body_ptr[id]);
							}
						void velocity (vec new_velocity)
							in {/*...}*/
								assert (mass != float.infinity);
							}
							body {/*...}*/
								cp.BodySetVel (body_ptr[id], new_velocity.to_cpv);
							}
					}
					@property {/*damping}*/
						float damping ()
							{/*...}*/
								return velocity_damping;
							}
						void damping (float new_damping)
							in {/*...}*/
								assert (mass != float.infinity);
							}
							body {/*...}*/
								velocity_damping = new_damping;
							}
					}
					@property {/*applied_force}*/
						vec applied_force ()
							{/*...}*/
								return cast(vec)cp.BodyGetForce (body_ptr[id]);
							}
						void applied_force (vec new_force)
							{/*...}*/
								cp.BodySetForce (body_ptr[id], new_force.to_cpv);
							}
					}
				}
				@property {/*historic}*/
					@property {/*displacement}*/
						vec displacement ()
							{/*...}*/
								return position - last_position;
							}
						void displacement (vec new_displacement)
							{/*...}*/
								assert (null);
							}
					}
				}
				@property {/*collision}*/
					@property {/*layer}*/
						uint layer ()
							{/*...}*/
								return cp.ShapeGetLayers (shape_ptr[id]);
							}
						void layer (uint new_layer)
							{/*...}*/
								cp.ShapeSetLayers (shape_ptr[id], new_layer);
							}
					}
					@property bool colliding ()
						{/*...}*/
							static void collide (cpBody* impl, cpArbiter* arbiter, void* data)
								{/*...}*/
									*cast(bool*)data = true;
								}
							static void colliding (cpBody* impl, void* data)
								{/*...}*/
									cpBodyEachArbiter (impl, &collide, data);
								}
							////////////
							bool is_colliding;
							colliding (body_ptr[id], &is_colliding);
							return is_colliding;
						}
				}
				private {/*data}*/
					Body.Id id;
					vec last_position = vec(0);
					float velocity_damping = 0.0;
					Type type = Type.none;
					enum Type {none, circle, polygon};
				}
				private {/*☀}*/
					this (T) (cpSpace* space, T geometry, float mass, vec position, vec velocity, float damping, Body.Id id)
						in {/*...}*/
							assert (mass == mass);
							assert (position == position);
							assert (velocity == velocity || mass == float.infinity);
							assert (geometry.length > 2);
							auto bounds = geometry.reduce!(
								(u,v) => vec(max(u.x, v.x), max(u.y, v.y)),
								(u,v) => vec(min(u.x, v.x), min(u.y, v.y)),
							);
							assert ((bounds[1]-bounds[0]).norm > float.epsilon,
								"attempted to create physics body with zero volume");
						}
						body {/*...}*/
							this.id = id;
							with (TrueBody.Type) {/*deduce shape}*/
								import std.math;

								auto center = geometry.mean;
								auto V = geometry.map!(v => v - center).array;
								auto segs = V.zip (V[1..$]~V[0..1]).map!(v => (v[1]-v[0]).unit).array;
								auto diff = segs.zip (segs[1..$]~segs[0..1]);

								auto dot = diff.map!(v => v[0].dot(v[1]));
								auto μ_dot = dot.mean;
								auto σ_dot = dot.std_dev (μ_dot);

								auto det = diff.map!(v => v[0].det(v[1]));
								auto σ_det = det.std_dev;

								{/*assign shape type}*/
									assert (σ_det.between ( 0.0, 1.0)
										 && σ_dot.between ( 0.0, 1.0)
										 && μ_dot.between (-1.0, 1.0)
									);

									if (// as we walk along the boundary of the polygon, we're ...
										σ_det <= 0.05 // turning in a consistent direction
									 && σ_dot <= 0.05 // turning at a consistent angle
									 && μ_dot >= 0.40 // turning at angles < 66° on average
									) this.type = circle;
									else this.type = polygon;
								}
								vec offset = mass == float.infinity? center: vec(0);
								final switch (type)
									{/*create simulation data}*/
										case circle:
											{/*...}*/
												auto radius = V.radius;
												if (mass != float.infinity)
													body_ptr[id] = cp.BodyNew (mass, cp.MomentForCircle (mass, 0.0, radius, cpvzero));
												else body_ptr[id] = cp.SpaceGetStaticBody (space);
												shape_ptr[id] = cp.CircleShapeNew (body_ptr[id], radius, offset.to_cpv);
												break;
											}
										case polygon:
											{/*...}*/
												auto len = cast(int) V.length;
												auto poly = cast(cpVect*) V.ptr;
												auto hull = new cpVect[len];
												len = cp.ConvexHull (len, poly, hull.ptr, null, 0.0);
												if (mass != float.infinity)
													body_ptr[id] = cp.BodyNew (mass, cp.MomentForPoly (mass, len, hull.ptr, cpvzero));
												else body_ptr[id] = cp.SpaceGetStaticBody (space);
												shape_ptr[id] = cp.PolyShapeNew (body_ptr[id], len, hull.ptr, offset.to_cpv);
												break;
											}
										case none: assert (null);
									}
							}
							{/*add to space}*/
								if (mass != float.infinity)
									cp.SpaceAddBody (space, body_ptr[id]);
								cp.SpaceAddShape (space, shape_ptr[id]);
							}
							{/*set properties}*/
								cp.BodySetUserData (body_ptr[id], cast(void*)id);
								cp.ShapeSetUserData (shape_ptr[id], cast(void*)id);
								if (mass != float.infinity)
									{/*...}*/
										this.position = position;
										this.velocity = velocity;
										this.damping = damping;
									}
								else {/*static body initial displacement correction}*/
									assert (cp.BodyIsStatic (body_ptr[id]));
									assert (this.position == vec(0));
									this.last_position = -position;
								}
							}
						}
				}
			}
		public:
		public {/*queries}*/
			private struct Query
				{/*...}*/
					auto type = Type.none;
					Body.Id id;
					vec[2] args;
					enum Type {
						/*error*/ 		none, 
						/*intrinsic*/ 	mass, position, velocity, damping, applied_force, 
						/*historic*/	displacement, 
						/*collision*/	colliding, layer,
						/*spatial*/ 	box, ray, ray_exclusive
					}
					public {/*sort}*/
						int opCmp (ref Query Q) const
							{/*...}*/
								return this.id < Q.id;
							}
					}
				}
			struct Incidence
				{/*...}*/
					Body.Id body_id;
					vec surface_normal;
					float ray_time;
				}
			@Query Body.Id[] box_query (vec[2] corners)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							type: Query.Type.box,
							args: corners
						};
					send (query);
					Body.Id[] result;
					receive ((immutable Body.Id[] reply) 
						{result = reply.dup;});
					return result;
				}
			@Query Incidence ray_cast (vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
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
			@Query Incidence ray_query (Body.Id id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							id: id,
							type: Query.Type.ray,
							args: ray
						};
					send (query);
					Incidence result;
					receive ((Incidence reply) 
						{result = reply;});
					return result;
				}
			@Query Incidence ray_cast_excluding (Body.Id id, vec[2] ray)
				in {/*...}*/
					assert (this.is_running, "attempted query before starting service (currently "~this.status.to!string~")");
				}
				body {/*...}*/
					Query query =
						{/*...}*/
							id: id,
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
					Body.Id id;
					float mass;
					vec position;
					vec velocity;
					float damping;
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
					vertices = new shared DoubleBuffer!(vec, 2^^12);
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
					mixin (profiler);
					{/*record histories}*/
						foreach (ref rigid_body; bodies.byValue)
							rigid_body.last_position = rigid_body.position;
					}
					{/*process uploads}*/
						vertices.swap;
						auto vertex_pool = vertices.rear[];
						foreach (upload; uploads)
							{/*...}*/
								auto i = upload.index;
								auto n = upload.length;
								auto temp = TrueBody (
									space,
									vertex_pool[i..i+n], 
									upload.mass, 
									upload.position, 
									upload.velocity, 
									upload.damping, 
									upload.id
								);
								bodies[upload.id] = temp;
								temp.id = Body.Id.init;
							}
						uploads.clear ();
					}
					cp.SpaceStep (space, Δt);
					t++;
					{/*postprocess}*/
						foreach (ref dynamic_body; bodies.byValue)
							with (dynamic_body) if (damping > 0.0)
								velocity = velocity*(1.0 - damping);
					}
					return true;
				}
			bool listen ()
				{/*...}*/
					bool listening = true;
					mixin(profiler!`prof1`);

					auto proceed (bool _) 
						{/*...}*/
					mixin (profiler);
							listening = false;
						}
					auto upload (Upload upload)
						{/*...}*/
					mixin (profiler);
							uploads ~= upload; 
							reply (true);
						}
					auto remove (Body.Id id)
						{/*...}*/
					mixin (profiler);
							bodies.remove (id);
							reply (true);
						}
					auto query (Query query)
						{/*...}*/
					mixin (profiler!`prof3`);
							static Body.Id get_id (cpShape* shape)
								{/*...}*/
					mixin(profiler!`prof2`);
									return cast(Body.Id)cast(long)(cp.ShapeGetUserData (shape));
								}
							auto box_query (Query query)
								in {/*...}*/
									foreach (c; query.args)
										assert (c.x == c.x && c.y == c.y);
								}
								body {/*...}*/
					mixin(profiler!`prof2`);
									Body.Id[] bodies;
									auto corners = query.args;

									auto a = corners[0];
									auto b = corners[1];

									auto box = cp.BB (min(a.x, b.x), min(a.y, b.y), max(a.x, b.x), max(a.y, b.y));
									auto layers = CP_ALL_LAYERS;
									auto group = CP_NO_GROUP;

									cp.SpaceBBQuery (space, box, layers, group, 
										(cpShape* shape, void* bodies) 
											{(*cast(Body.Id[]*) bodies) ~= get_id (shape);},
										&bodies
									);
									return bodies.map!(ptr => cast(immutable) ptr).array.idup;
								}
							auto ray_query (Query query)
								{/*...}*/
					mixin(profiler!`prof2`);
									auto id = query.id;
									auto ray = query.args;

									auto layers = CP_ALL_LAYERS;
									auto group = CP_NO_GROUP;

									cpSegmentQueryInfo info;

									if (id != Body.Id.init)
										cp.ShapeSegmentQuery (shape_ptr[id], ray[0].to_cpv, ray[1].to_cpv, &info);
									else cp.SpaceSegmentQueryFirst (space, ray[0].to_cpv, ray[1].to_cpv, 
										layers, group, &info
									);

									if (info.shape)
										return Incidence (get_id (info.shape), info.n.vec, info.t);
									else return Incidence (Body.Id.init, 0.vec, 1.0);
								}
							auto ray_exclusive_query (Query query)
								{/*...}*/
					mixin(profiler!`prof2`);
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
									else return Incidence (Body.Id.init, 0.vec, 1.0);
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
								mixin (get!`displacement`);
								/*spatial*/
								mixin (ask!`box`);
								mixin (ask!`ray`);
								mixin (ask!`ray_exclusive`);
								/*misc*/
								mixin (get!`colliding`);
								mixin (get!`layer`);
								/*error*/
								case none: assert (null);
							}
						}
					auto act (Body.Id id, Body.Action action)
						{/*...}*/
					mixin (profiler);
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
					auto set (Body.Id id, string property, vec value)
						{/*...}*/
					mixin (profiler);
							assert (id in body_ptr, "body "~to!string(id)~" does not exist");
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
					auto debug_query (Body.Id id, string query)
						{/*...}*/
					mixin (profiler);
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

					receive (&proceed, &upload, &remove, &query, &act, &set, &debug_query);

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
		private {/*data}*/
			shared DoubleBuffer!(vec, 2^^12) vertices;
		}
		static:
		static {/*context}*/
			import dchip.all;
			cpSpace* space;
			TrueBody[Body.Id] bodies;
			cpBody*[Body.Id]   body_ptr;
			cpShape*[Body.Id]  shape_ptr;
			Upload[] uploads;
		}
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
