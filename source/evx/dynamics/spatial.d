module evx.dynamics.spatial;
version(none):

private {/*imports}*/
	import dchip.all;

	import std.conv;

	import evx.math;
	import evx.range;
	import evx.memory;
	import evx.containers;
	import evx.misc.utils;
}
private {/*definitions}*/
	alias SimulationSpace = cpSpace*;
	alias ShapeId = cpShape*;
	alias BodyId = cpBody*;
	alias Collision = cpArbiter*;
}

package {/*library}*/
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

alias Acceleration = typeof(meters/second.squared);
alias Speed = typeof(meters/second);
alias Position = Vector!(2, Meters);
alias Displacement = Position;
alias Velocity = Vector!(2, Speed);
alias Force = Vector!(2, Newtons);
alias Scalar = float;

private enum MAX_N_SHAPES = 4;

struct SpatialId
	{/*...}*/
		void* data;
		alias data this;

		auto as (T)()
			{/*...}*/
				return data.unvoid!T;
			}
		this (T)(T data)
			{/*...}*/
				static if (is (T == int))
					this.data = size_t(data).voidptr;
				else this.data = data.voidptr; // REVIEW what module this belongs in
			}
	}
struct Body
	{/*...}*/
		enum Type {none, circle, polygon}

		public:
		@property {/*get}*/
			Kilograms mass ()
				{/*...}*/
					return cp.BodyGetMass (body_id).kilograms;
				}
			Position position ()
				{/*...}*/
					return cp.BodyGetPos (body_id).vector.each!(p => p.meters).Position;
				}
			Velocity velocity ()
				{/*...}*/
					return cp.BodyGetVel (body_id).vector.each!(v => v.meters/second).Velocity;
				}
			Scalar damping ()
				{/*...}*/
					return world.bodies[SpatialDynamics.get_id (body_id)].velocity_damping;
				}
			Force applied_force ()
				{/*...}*/
					return cp.BodyGetForce (body_id).vector.each!(f => f.newtons).Force;
				}
			Scalar orientation ()
				{/*...}*/
					return cp.BodyGetAngle (body_id);
				}
			auto layer ()
				{/*...}*/
					return shape_ids[].map!(shape => cp.ShapeGetLayers (shape)); // BUG lazy evaluation across coroutine boundaries could prove disasterous but voldemort types discourage storage so it may not be an issue... as long as coroutine savable context is limited to a well-defined state struct then it should be ok
				}
			auto id ()
				{/*...}*/
					return SpatialId (cp.BodyGetUserData (body_id));
				}
		}
		@property {/*set}*/
			auto position (Position new_position)
				{/*...}*/
					cp.BodySetPos (body_id, new_position.each!(to!Scalar).to!cpVect);

					reindex_shapes;

					return this;
				}
			auto orientation (Scalar new_orientation)
				{/*...}*/
					cp.BodySetAngle (body_id, new_orientation);

					reindex_shapes;

					return this;
				}
			auto velocity (Velocity new_velocity)
				in {/*...}*/
					assert (mass.is_finite);
				}
				body {/*...}*/
					cp.BodySetVel (body_id, new_velocity.each!(to!Scalar).to!cpVect);

					return this;
				}
			auto damping (Scalar new_damping)
				in {/*...}*/
					assert (world);
					assert (mass.is_finite);
				}
				body {/*...}*/
					world.bodies[SpatialDynamics.get_id (body_id)].velocity_damping = new_damping;

					return this;
				}
			auto applied_force (Force new_force)
				{/*...}*/
					cp.BodySetForce (body_id, new_force.each!(to!Scalar).to!cpVect);

					return this;
				}
			auto layer (uint new_layer)
				{/*...}*/
					foreach (shape; shape_ids[])
						cp.ShapeSetLayers (shape, new_layer); // REVIEW

					return this;
				}
		}
		public {/*actions}*/
			void apply_force (Force force, Position contact = zero!Position)
				{/*...}*/
					cp.BodyApplyForce (body_id, force.each!(to!Scalar).to!cpVect, contact.each!(to!Scalar).to!cpVect);
				}
		}
		private:
		private {/*data}*/
			BodyId body_id;
			Stack!(ShapeId[MAX_N_SHAPES]) shape_ids;
			SpatialDynamics world;

			Scalar velocity_damping = 0.0;
		}
		private {/*ctor/free}*/
			this (R...)(SpatialDynamics world, SpatialId spatial_id, Kilograms mass, R geometries)
				in {/*...}*/
					foreach (Range; R)
						static assert (is_geometric!Range, 
							Range.stringof ~ ` is not geometric [` ~ ElementType!R.stringof ~ `]`
						);

					assert (mass == mass, `mass of body ` ~spatial_id.text~ ` not specified`);

					foreach (geometry; geometries)
						{/*...}*/
							enum zero_volume_error = "attempted to create collision body with zero volume";

							assert (geometry.length > 2, zero_volume_error);
							assert (geometry.area.to!Scalar > Scalar.epsilon, zero_volume_error);
						}
				}
				body {/*...}*/
					this.world = world;

					auto space = world.space;

					if (mass.is_infinite)
						{/*...}*/
							this.body_id = cp.BodyNewStatic; 
							assert (cp.BodyIsStatic (this.body_id));
						}
					else this.body_id = cp.BodyNew (mass.to!Scalar, 1.0);

					if (not (cp.BodyIsStatic (body_id)))
						cp.SpaceAddBody (space, body_id);

					cp.BodySetUserData (body_id, spatial_id);

					static if (R.length > 1)
						auto areas = geometries[].map!area;
					else auto areas = [geometries.area];

					auto Σ_areas = sum (areas);
					
					foreach (i, geometry; geometries)
						{/*...}*/
							Scalar moment;

							auto component_mass = (mass * areas[i] / Σ_areas).to!Scalar;

							with (Body.Type) final switch (deduce_shape (geometry))
								{/*create simulation data}*/
									case circle:
										{/*...}*/
											auto radius = geometry.radius.to!Scalar;
											auto center = geometry.mean.each!(to!Scalar).to!cpVect;

											moment = cp.MomentForCircle (component_mass, 0.0, radius, center);
											this.shape_ids ~= cp.CircleShapeNew (body_id, radius, center);

											break;
										}
									case polygon:
										{/*...}*/
											auto len = geometry.length.to!int;
											auto poly = Array!cpVect (geometry[].map!(v => v.each!(to!Scalar)).map!(to!cpVect));
											auto hull = Array!cpVect (len);

											cp.ConvexHull (len, poly.ptr, hull.ptr, null, 0.0);

											moment = cp.MomentForPoly (component_mass, len, hull.ptr, cpvzero);
											this.shape_ids ~= cp.PolyShapeNew (body_id, len, hull.ptr, cpvzero);

											break;
										}
									case none: assert (null);
								}
							auto shape_id = shape_ids[$-1];
				
							if (not (cp.BodyIsStatic (body_id)))
								cp.BodySetMoment (body_id, cp.BodyGetMoment (body_id) + moment);

							cp.SpaceAddShape (space, shape_id);

							cp.ShapeSetUserData (shape_id, spatial_id);
						}
				}

			void free ()
				{/*...}*/
					if (not (cp.BodyIsRogue (body_id)))
						{/*...}*/
							auto space = world.space;

							foreach (shape; shape_ids[])
								{/*...}*/
									cp.SpaceRemoveShape (space, shape);
									cp.ShapeFree (shape);
								}

							cp.SpaceRemoveBody (space, body_id);
						}

					cp.BodyFree (body_id);
				}
		}
		private {/*upkeep}*/
			void reindex_shapes ()
				{/*...}*/
					if (cp.BodyIsStatic (body_id))
						cp.SpaceReindexStatic (world.space);
					else cp.SpaceReindexShapesForBody (world.space, body_id);
				}
		}
		static {/*shape deduction}*/
			auto deduce_shape (T)(T geometry)
				if (is_geometric!T)
				{/*...}*/
					auto center = geometry.mean;
					auto vs = geometry.map!(v => v - center);
					auto dirs = geometry.adjacent_pairs.map!((u,v) => (u-v).unit);
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
struct Incidence
	{/*...}*/
		SpatialId body_id;
		fvec surface_normal;
		Scalar ray_time;

		bool occurred ()
			{/*...}*/
				return surface_normal != zero!fvec;
			}
	}

struct Region
	{/*...}*/
		private Borrowed!SpatialDynamics world;
		Position[2] bounds;
	}

template AppendOps (alias append, alias length, alias capacity)
	{/*...}*/
		
	}
/*
	tgt = physics[a..b] but can't find length for allocation
		→ stack (), 
			query_call (a,b, ∀{stack ~= entry})
			tgt = stack[]

	auto x = physics[a..b]
		→ stack, etc
			x = stack
			typeof(x) == Stack
			
	tgt ~= physics[a..b] and use a push detection system
		→ query.push (tgt, [a,b])
		→ query_call (
			a,b,
			∀{tgt ~= entry}
		)
*/

final class SpatialDynamics
	{/*...}*/
		public:
		public {/*bodies}*/
			auto new_body (T, R...)(T spatial_id, Kilograms mass, R geometries)
				if (R.length > 0)
				in {/*...}*/
					assert (SpatialId (spatial_id) !in bodies, spatial_id.text~ ` already exists`);
				}
				out {/*...}*/
					assert (SpatialId (spatial_id) in bodies, `failed to add ` ~spatial_id.text);
				}
				body {/*...}*/
					auto id = SpatialId (spatial_id);

					this.bodies[id] = Body (
						this,
						id,
						mass, 
						geometries
					);

					return bodies[id];
				}
			auto get_body (T)(T spatial_id)
				{/*...}*/
					auto id = SpatialId (spatial_id);

					if (auto result = id in bodies)
						return result;
					else assert (0, `body ` ~id.text~ ` not uploaded, cannot access`);
				}
			auto delete_body (T)(T spatial_id)
				{/*...}*/
					auto id = SpatialId (spatial_id);

					bodies[id].free;
					bodies.remove (id);
				}

			auto n_bodies ()
				{/*...}*/
					return bodies.length;
				}
		}
		public {/*time}*/
			auto Δt = 0.016667.seconds;

			auto time ()
				{/*...}*/
					return elapsed_ticks * Δt;
				}
		}
		public {/*gravity}*/
			auto gravity (Vector!(2, Acceleration) gravity)
				{/*...}*/
					cp.SpaceSetGravity (space, gravity.each!(to!Scalar).to!cpVect);
				}
			Vector!(2, Acceleration) gravity ()
				{/*...}*/
					return cp.SpaceGetGravity (space).vector * meters/second/second;
				}
		}
		public {/*update}*/
			void update ()
				{/*...}*/
					cp.SpaceStep (space, Δt.to!Scalar);
					elapsed_ticks += 1;

					{/*postprocess}*/
						foreach (ref dynamic_body; bodies)
							with (dynamic_body) {/*...}*/
								if (mass.is_infinite)
									continue;

								if (damping > zero!Scalar)
									velocity = velocity * (unity!Scalar - damping);
							}
					}
				}
		}
		public {/*queries}*/
			private //TODO
			static managed_result_query (string type)()
				{/*...}*/
					return q{
						auto } ~type~ q{_query (Args...)(Args args)
							if (not (is (typeof(args[$-1] ~= SpatialId.init))))
							}`{`q{
								Stack!(SpatialId[]) result;

								} ~type~ q{_query (args, result);

								return result;
							}`}`q{
					};
				}

			// TODO make lazy query structures
			void box_query (Output)(Position[2] corners, ref Output result) // slice[left..right, up..down] → box_query (left-down, right-up)
				{/*...}*/
					alias Id = Element!Output;

					auto box = cp.BB (corners[].map!(v => v.each!(to!Scalar)).bounding_box.extents.expand);
					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;

					cp.SpaceBBQuery (space, box, layers, group, 
						(ShapeId shape, void* data) 
							{(*cast(Output*)data) ~= get_id (shape).as!Id;},
						&result
					);
				}

			void polygon_query (Output, R)(R polygon, ref Output result) // slice[polygon] → polygon_query(polygon)
				{/*...}*/
					alias Id = Element!Output;

					auto len = polygon.length.to!int;
					auto poly = Array!cpVect (polygon[].map!(v => v.each!(to!Scalar)).map!(to!cpVect));
					auto hull = Array!cpVect (len);

					cp.ConvexHull (len, poly.ptr, hull.ptr, null, 0.0);

					auto temp_body = cp.BodyNew (1,1);
					auto shape = cp.PolyShapeNew (temp_body, len, hull.ptr, cpvzero);
					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;
					cp.ShapeSetLayers (shape, layers);
					cp.ShapeSetGroup (shape, group);

					cp.SpaceShapeQuery (space, shape,
						(ShapeId shape, cpContactPointSet* points, void* data)
							{(*cast(Output*)data) ~= get_id (shape).as!Id;},
						&result
					);

					cp.BodyFree (temp_body);
					cp.ShapeFree (shape);
				}

			void circle_query (Output)(Position center, Meters radius, ref Output result) // slice[vec(m,m), m]
				{/*...}*/
					alias Id = Element!Output;

					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;

					static put_id ()(ShapeId shape, Scalar distance, cpVect point, void* data)
						{/*...}*/
							(*cast(Output*)data) ~= get_id (shape).as!Id;
						}
					static put_id_and_location ()(ShapeId shape, Scalar distance, cpVect point, void* data)
						{/*...}*/
							(*cast(Output*)data) ~= (τ(get_id (shape).as!(Id.Types[0]), point.vector * meters));
						}

					cp.SpaceNearestPointQuery (space,
						center.each!(to!Scalar).to!cpVect, radius.to!Scalar,
						layers, group,
						&Match!(put_id, put_id_and_location), &result
					);
				}

			mixin(managed_result_query!`box`);
			mixin(managed_result_query!`polygon`);
			mixin(managed_result_query!`circle`);

			struct Intersection
				{/*...}*/
					SpatialId id;
					Position location;
				}

			Incidence ray_cast (Position[2] ray)
				{/*...}*/
					return ray_query (SpatialId.init, ray);
				}

			Incidence ray_cast_excluding (T)(T spatial_id, Position[2] ray)
				{/*...}*/
					auto id = SpatialId (spatial_id);
					auto saved_layer = bodies[id].layer;

					bodies[id].layer = 0x0;

					auto result = ray_cast (ray);

					bodies[id].layer = saved_layer;

					return result;
				}

			Incidence ray_query (T)(T spatial_id, Position[2] ray)
				{/*...}*/
					auto id = SpatialId (spatial_id);
					auto seg = ray[].map!(v => v.each!(to!Scalar)).map!(to!cpVect);

					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;

					cpSegmentQueryInfo info;

					if (id == SpatialId.init)
						cp.SpaceSegmentQueryFirst (space, seg[0], seg[1], 
							layers, group, &info
						);
					else foreach (shape; bodies[id].shape_ids[])
							cp.ShapeSegmentQuery (shape, seg[0], seg[1], &info);

					if (info.shape)
						return Incidence (get_id (info.shape), info.n.vector, info.t);
					else return Incidence (SpatialId.init, 0.fvec, 1.0);
				}
		}
		public {/*ctor/dtor}*/
			this ()
				{/*...}*/
					space = cp.SpaceNew ();
					cp.SpaceSetCollisionSlop (space, 0.01);
					cp.SpaceSetDefaultCollisionHandler (
						space,
						&collision_callback,
						null, null, null,
						cast(void*)this
					);
				}
			~this ()
				{/*...}*/
					foreach (sim_body; bodies)
						sim_body.free;

					cp.SpaceFree (space);
				}
		}
		public {/*callbacks}*/
			@property on_collision (void delegate(SpatialId,SpatialId) on_collide)
				{/*...}*/
					this.on_collide = on_collide;
				}
		}
		private: 
		private {/*callbacks}*/
			static collision_callback (Collision collision, SimulationSpace space, void* data)
				{/*...}*/
					BodyId a, b;
					SpatialDynamics phy = cast(SpatialDynamics)data;

					if (phy.on_collide !is null)
						foreach (_; 0..cp.ArbiterGetCount (collision))
							{/*...}*/
								cp.ArbiterGetBodies (collision, &a, &b);

								phy.on_collide (get_id (a), get_id (b));
							}

					return true;
				}
		}
		private {/*get_id}*/
			static get_id (ShapeId shape)
				{/*...}*/
					return SpatialId (cp.ShapeGetUserData (shape));
				}
			static get_id (BodyId body_id)
				{/*...}*/
					return SpatialId (cp.BodyGetUserData (body_id));
				}
		}
		private {/*data}*/
			SimulationSpace space;

			void delegate(SpatialId,SpatialId) on_collide;

			Body[SpatialId] bodies;
				
			ulong elapsed_ticks = 0;
		}
		invariant (){/*}*/
			assert (space);
		}
	}

unittest {/*demo}*/
	scope phy = new SpatialDynamics;

	auto b1 = phy.new_body (1, 1.kilogram, square (meters))
		.velocity (fvec(0, 10)*meters/second);

	assert (b1.position == zero!Position);
	phy.update;
	assert (b1.position != zero!Position);

	Stack!(SpatialId[3]) hits;
	phy.box_query ([zero!Position, 10 * unity!Position], hits);
	assert (hits[].equal ([SpatialId (1)]));

	auto b2 = phy.new_body (2, 1.kilogram, square (meters))
		.position (fvec(0,1)*meters);

	bool collided;
	phy.on_collide = (SpatialId a, SpatialId b) {collided = true;};

	int iter_count = 0;
	while (not (collided || iter_count > 1_000))
		phy.update;

	assert (collided);
}
unittest {/*shape deduction}*/
	assert (Body.deduce_shape (circle) == Body.Type.circle);
	assert (Body.deduce_shape (square) == Body.Type.polygon);

	auto triangle = circle!3;
	auto pentagon = circle!5;
	auto hexagon = circle!6;

	assert (Body.deduce_shape (triangle) == Body.Type.polygon);
	assert (Body.deduce_shape (pentagon) == Body.Type.polygon);
	assert (Body.deduce_shape (hexagon) == Body.Type.circle);
}
unittest {/*polygon query}*/
	scope phy = new SpatialDynamics;

	auto my_location = zero!Position;

	phy.new_body (1L, 1.kilogram, square (meters));

	auto things_i_see = Stack!(Array!SpatialId) (10);
	phy.polygon_query (
		[my_location, my_location + fvec(1,1)*meters, my_location + fvec(1,-1)*meters],
		things_i_see
	);

	assert (things_i_see[].equal (SpatialId(1L).only));
}

// REFACTOR
auto collision_group (R...)(R bodies)
	{/*...}*/
		static size_t id_generator;

		auto group_id = ++id_generator;

		foreach (item; bodies)
			{/*...}*/
				static if (isInputRange!(typeof(item)))
					foreach (dynamic_body; item)
						foreach (shape; dynamic_body.shape_ids[])
						cp.ShapeSetGroup (shape, group_id);
				else foreach (shape; item.shape_ids[])
					cp.ShapeSetGroup (shape, group_id);
			}
	}
