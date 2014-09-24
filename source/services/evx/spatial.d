module evx.spatial;

private {/*imports}*/
	private {/*core}*/
		import core.atomic;
	}
	private {/*std}*/
		import std.conv;
		import std.algorithm;
		import std.range;
		import std.traits;
		import std.math;
		import std.string;
		import std.functional;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.traits;
		import evx.math;
		import evx.meta;
		import evx.service;
		import evx.future;
		import evx.arrays;
		import evx.buffers;
		import evx.range;
	}
	private {/*dchip}*/
		import dchip.all;
	}


	alias map = evx.functional.map;
	alias sum = evx.arithmetic.sum;
}
private {/*definitions}*/
	alias SimulationSpace = cpSpace*;
	alias ShapeId = cpShape*;
	alias BodyId = cpBody*;
	alias Collision = cpArbiter*;
	alias SpringId = cpConstraint*;
	alias PinId = cpConstraint*;
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

alias Acceleration = typeof(meters/second.squared);
alias Speed = typeof(meters/second);
alias Position = Vector!(2, Meters);
alias Displacement = Position;
alias Velocity = Vector!(2, Speed);
alias Force = Vector!(2, Newtons);

private enum MAX_N_SHAPES = 4;
private enum MAX_N_FORCES = 4;

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
				this.data = data.voidptr;
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
					return cp.BodyGetPos (body_id).vector[].map!(p => p.meters).Position;
				}
			Velocity velocity ()
				{/*...}*/
					return cp.BodyGetVel (body_id).vector[].map!(v => v.meters/second).Velocity;
				}
			Scalar damping ()
				{/*...}*/
					return world.bodies[SpatialDynamics.get_id (body_id)].velocity_damping;
				}
			Force applied_force ()
				{/*...}*/
					return cp.BodyGetForce (body_id).vector[].map!(f => f.newtons).Force;
				}
			Scalar angle ()
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
					cp.BodySetPos (body_id, new_position.dimensionless.to!cpVect);

					reindex_shapes;

					return this;
				}
			auto angle (Scalar new_angle)
				{/*...}*/
					cp.BodySetAngle (body_id, new_angle);

					reindex_shapes;

					return this;
				}
			auto velocity (Velocity new_velocity)
				in {/*...}*/
					assert (mass.is_finite);
				}
				body {/*...}*/
					cp.BodySetVel (body_id, new_velocity.dimensionless.to!cpVect);

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
					cp.BodySetForce (body_id, new_force.dimensionless.to!cpVect);

					return this;
				}
			auto layer (uint new_layer)
				{/*...}*/
					foreach (shape; shape_ids)
						cp.ShapeSetLayers (shape, new_layer); // REVIEW

					return this;
				}
		}
		public {/*actions}*/
			void apply_force (Force force, Position contact = zero!Position)
				{/*...}*/
					cp.BodyApplyForce (body_id, force.dimensionless.to!cpVect, contact.dimensionless.to!cpVect);
				}
		}
		private:
		private {/*data}*/
			BodyId body_id;
			Appendable!(ShapeId[MAX_N_SHAPES]) shape_ids;
			SpatialDynamics world;

			Scalar velocity_damping = 0.0;
		}
		private {/*ctor/free}*/
			this (R...)(SpatialDynamics world, SpatialId spatial_id, Kilograms mass, R geometries)
				if (allSatisfy!(is_geometric, R))
				in {/*...}*/
					assert (mass == mass, `mass of body ` ~spatial_id.text~ ` not specified`);

					foreach (geometry; geometries)
						{/*...}*/
							enum zero_volume_error = "attempted to create collision body with zero volume";

							assert (geometry.length > 2, zero_volume_error);
							assert (geometry.area.dimensionless > Scalar.epsilon, zero_volume_error);
						}
				}
				body {/*...}*/
					this.world = world;

					auto space = world.space;

					if (mass.is_infinite)
						{/*...}*/
							this.body_id = cp.BodyNewStatic; 
							assert (cp.BodyIsStatic (this.body_id));
							assert (cp.BodyIsStatic (this.body_id));
						}
					else this.body_id = cp.BodyNew (mass.to!double, 1.0);

					if (not (cp.BodyIsStatic (body_id)))
						cp.SpaceAddBody (space, body_id);

					cp.BodySetUserData (body_id, spatial_id);

					static if (R.length > 1)
						auto areas = geometries[].map!area;
					else auto areas = [geometries.area];

					auto Σ_areas = sum (areas);
					
					foreach (i, geometry; geometries)
						{/*...}*/
							double moment;

							auto component_mass = (mass * areas[i] / Σ_areas).dimensionless;

							with (Body.Type) final switch (deduce_shape (geometry))
								{/*create simulation data}*/
									case circle:
										{/*...}*/
											auto radius = geometry.radius.dimensionless;
											auto center = geometry.mean.dimensionless.to!cpVect;

											moment = cp.MomentForCircle (component_mass, 0.0, radius, center);
											this.shape_ids ~= cp.CircleShapeNew (body_id, radius, center);

											break;
										}
									case polygon:
										{/*...}*/
											auto len = geometry.length.to!int;
											auto poly = Array!vec (geometry[].map!dimensionless);
											auto hull = Array!vec (len);

											cp.ConvexHull (len, cast(cpVect*)poly[].ptr, cast(cpVect*)hull[].ptr, null, 0.0);

											moment = cp.MomentForPoly (component_mass, len, cast(cpVect*)hull[].ptr, cpvzero);
											this.shape_ids ~= cp.PolyShapeNew (body_id, len, cast(cpVect*)hull[].ptr, cpvzero);

											break;
										}
									case none: assert (null);
								}
							auto shape_id = shape_ids.back;
				
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
struct Incidence
	{/*...}*/
		SpatialId body_id;
		vec surface_normal;
		double ray_time;
	}

auto phy_id () // TEMP
	{/*...}*/
		static size_t id;

		return ++id;
	}

struct Spring // REVIEW does this belong separate from SD?
	{/*...}*/
		alias Stiffness = typeof(newtons/meter);
		alias Damping = typeof(newtons/(meters/second));

		public:
		@property {/*get}*/
			Position[2] anchors ()
				{/*...}*/
					return [cp.DampedSpringGetAnchr1 (id).vector * meters, cp.DampedSpringGetAnchr2 (id).vector * meters];
				}

			Meters resting_length ()
				{/*...}*/
					return cp.DampedSpringGetRestLength (id).meters;
				}
			
			Stiffness stiffness ()
				{/*...}*/
					return cp.DampedSpringGetStiffness (id).newtons/meter;
				}

			Damping damping ()
				{/*...}*/
					return cp.DampedSpringGetDamping (id).kilograms/second;
				}

			Meters length ()
				{/*...}*/
					auto endpoints = (anchors.vector + 
						anchor_site[].map!(b => τ(b.position, b.angle))
							.map!((x,θ) => x.rotate (θ))
					);

					return distance (endpoints.tuple.expand);
				}
		}
		@property {/*set}*/
			auto damping (Damping c)
				{/*...}*/
					cp.DampedSpringSetDamping (id, c.dimensionless);

					return this;
				}
			auto stiffness (Stiffness k)
				{/*...}*/
					cp.DampedSpringSetStiffness (id, k.dimensionless);

					return this;
				}
			auto resting_length (Meters length)
				{/*...}*/
					cp.DampedSpringSetRestLength (id, length.dimensionless);

					return this;
				}
			auto anchors (Position[2] anchors)
				{/*...}*/
					cp.DampedSpringSetAnchr1 (id, anchors[0].dimensionless.to!cpVect);
					cp.DampedSpringSetAnchr2 (id, anchors[1].dimensionless.to!cpVect);

					return this;
				}
		}
		public {/*ctor}*/
			this (Body a, Body b)
				in {/*...}*/
					assert (a.world is b.world);
				}
				body {/*...}*/
					this.id = cp.DampedSpringNew (
						a.body_id, b.body_id, zero!cpVect, zero!cpVect,
						0, 0, 0
					);

					anchor_site[0] = a;
					anchor_site[1] = b;

					cp.SpaceAddConstraint (a.world.space, id);
				}
		}
		private:
		private {/*data}*/
			SpringId id;
			Body[2] anchor_site;
		}
	}
struct RotarySpring
	{/*...}*/
		alias Stiffness = typeof(newtons/meter);
		alias Damping = typeof(newtons/(meters/second));

		public:
		@property {/*get}*/
			Scalar resting_angle ()
				{/*...}*/
					return cp.DampedRotarySpringGetRestAngle (id);
				}
			
			Stiffness stiffness ()
				{/*...}*/
					return cp.DampedRotarySpringGetStiffness (id).newtons/meter;
				}

			Damping damping ()
				{/*...}*/
					return cp.DampedRotarySpringGetDamping (id).kilograms/second;
				}

			Scalar angle ()
				{/*...}*/
					auto endpoints = anchor_site[].map!(b => b.position);

					return angle_between (endpoints.vector!2.tuple.expand);
				}
		}
		@property {/*set}*/
			auto damping (Damping c)
				{/*...}*/
					cp.DampedRotarySpringSetDamping (id, c.dimensionless);

					return this;
				}
			auto stiffness (Stiffness k)
				{/*...}*/
					cp.DampedRotarySpringSetStiffness (id, k.dimensionless);

					return this;
				}
			auto resting_angle (Scalar angle)
				{/*...}*/
					cp.DampedRotarySpringSetRestAngle (id, angle);

					return this;
				}
		}
		public {/*ctor}*/
			this (Body a, Body b)
				in {/*...}*/
					assert (a.world is b.world);
				}
				body {/*...}*/
					this.id = cp.DampedRotarySpringNew (
						a.body_id, b.body_id, 0, 0, 0
					);

					anchor_site[0] = a;
					anchor_site[1] = b;

					cp.SpaceAddConstraint (a.world.space, id);
				}
		}
		private:
		private {/*data}*/
			SpringId id;
			Body[2] anchor_site;
		}
	}
struct Rope (size_t n_segments)
	{/*...}*/
		Kilograms mass ()
			{/*...}*/
				return _mass;
			}
		Meters length ()
			{/*...}*/
				return _length;
			}
		Meters radius ()
			{/*...}*/
				return _radius;
			}

		Meters diameter ()
			{/*...}*/
				return radius * 2;
			}

		auto geometry ()
			{/*...}*/
				auto test (Position x, Scalar θ, int sgn = 1) 
					{return x + radius * î.vec.rotate (θ) * sgn;}

				return chain (
					segment_geometry.translate (segments[0].position).rotate (segments[0].angle)[0..2],
					roundRobin (
						segments[].map!(b => τ(b.position, b.angle, +1)).map!(τ => test (τ.expand)),
						segments[].map!(b => τ(b.position, b.angle, -1)).map!(τ => test (τ.expand)),
					), 
					segment_geometry.translate (segments[$-1].position).rotate (segments[$-1].angle).retro[0..2],
				);
			}

		auto segment_mass ()
			{/*...}*/
				return mass/n_segments;
			}
		auto segment_length ()
			{/*...}*/
				return length/n_segments;
			}
		auto segment_geometry ()
			{/*...}*/
				return square.map!(v => v * vector (diameter, segment_length * 1.5)); // HACK to avoid passthru, we must overlap segments. TODO this more methodically
			}

		auto stiffness (Spring.Stiffness k)
			{/*...}*/
				foreach (spring; springs)
					spring.stiffness = k;

				foreach (spring; rotary_springs)
					spring.stiffness = k;

				return this;
			}
		auto stiffness ()
			{/*...}*/
				return springs[0].stiffness;
			}

		auto damping (Spring.Damping c)
			{/*...}*/
				foreach (spring; springs)
					spring.damping = c;

				foreach (spring; rotary_springs)
					spring.damping = c;

				return this;
			}
		auto damping ()
			{/*...}*/
				return springs[0].damping;
			}

		auto position (Position x)
			{/*...}*/
				auto Δx = x - segments[0].position;

				foreach (seg; segments[])
					with (seg) position = position + Δx;

				return this;
			}
		auto rotate (Scalar θ)
			{/*...}*/
				
			}

		this (SpatialDynamics phy, Kilograms mass, Meters length, Meters radius)
			{/*...}*/
				this._mass = mass;
				this._length = length;
				this._radius = radius;

				foreach (i; 0..n_segments)
					{/*build segments}*/
						segments ~= phy.new_body (phy_id, segment_mass, segment_geometry)
							.position (i * (-ĵ.vec) * segment_length);
					}

				foreach (i; 0..n_segments-1)
					{/*add springs}*/
						auto anchor = vector (radius, 0.meters);

						springs ~= Spring (segments[i], segments[i+1])
							.resting_length (segments[i].position.distance_to (segments[i+1].position))
							.anchors ([anchor, anchor]);

						springs ~= Spring (segments[i], segments[i+1])
							.resting_length (segments[i].position.distance_to (segments[i+1].position))
							.anchors ([-anchor, -anchor]);

						rotary_springs ~= RotarySpring (segments[i], segments[i+1]);
					}

				foreach (seg; segments[])
					{/*disable self-collision}*/
						foreach (shape; seg.shape_ids[])
							cp.ShapeSetGroup (shape, segments[].front.id.as!size_t);
					}
			}


		private:

		Appendable!(Body[n_segments]) segments;
		Appendable!(Spring[2*(n_segments-1)]) springs;
		Appendable!(RotarySpring[n_segments-1]) rotary_springs;

		Kilograms _mass;
		Meters _length;
		Meters _radius;
	}
struct Pin
	{/*...}*/
		PinId id;

		this (Body a, Body b)
			{/*...}*/
				this.id = cp.PinJointNew (a.body_id, b.body_id, zero!cpVect, zero!cpVect);

				cp.SpaceAddConstraint (a.world.space, id);
			}
	}

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

					this.bodies.insert (
						id, Body (
							this,
							id,
							mass, 
							geometries
						)
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
					return bodies.size;
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
					cp.SpaceSetGravity (space, gravity.dimensionless.to!cpVect);
				}
			Vector!(2, Acceleration) gravity ()
				{/*...}*/
					return cp.SpaceGetGravity (space).vector * meters/second/second;
				}
		}
		public {/*update}*/
			void update ()
				{/*...}*/
					cp.SpaceStep (space, Δt.dimensionless);
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
			void box_query (Array)(Position[2] corners, ref Array result)
				in {/*...}*/
					alias Id = ElementType!Array;

					static assert (is(typeof(SpatialId(Id.init))));
					static assert (isOutputRange!(Array, Id), Array.stringof~ ` cant put `~Id.stringof);
				}
				body {/*...}*/
					alias Id = ElementType!Array;

					auto box = cp.BB (corners[].map!dimensionless.bounding_box.extents.expand);
					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;

					cp.SpaceBBQuery (space, box, layers, group, 
						(cpShape* shape, void* stream) 
							{(cast(Array*)stream).put (get_id (shape).as!Id);},
						&result
					);
				}

			Incidence ray_cast (Position[2] ray)
				{/*...}*/
					return ray_query (SpatialId.init, ray);
				}

			Incidence ray_cast_excluding (T)(T spatial_id, Position[2] ray)
				{/*...}*/
					auto id = SpatialId (id);
					auto layer = bodies[id].layer;

					bodies[id].layer = 0x0;

					auto result = ray_cast (ray);

					bodies[id].layer = CP_ALL_LAYERS;

					return result;
				}

			Incidence ray_query (T)(T spatial_id, Position[2] ray)
				{/*...}*/
					auto id = SpatialId (spatial_id);
					auto seg = ray[].map!dimensionless.map!(to!cpVect);

					auto layers = CP_ALL_LAYERS;
					auto group = CP_NO_GROUP;

					cpSegmentQueryInfo info;

					if (id != SpatialId.init)
						foreach (shape; bodies[id].shape_ids)
							cp.ShapeSegmentQuery (shape, seg[0], seg[1], &info);
					else cp.SpaceSegmentQueryFirst (space, seg[0], seg[1], 
						layers, group, &info
					);

					if (info.shape)
						return Incidence (get_id (info.shape), info.n.vector, info.t);
					else return Incidence (SpatialId.init, 0.vec, 1.0);
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

					auto_initialize;
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

			mixin AutoInitialize;

			@Initialize!(2^^12) 
			Associative!(Array!Body, SpatialId) bodies;
				
			@Initialize!()
			Appendable!(Position, 2^^12) vertices;

			ulong elapsed_ticks = 0;
		}
	}

unittest {/*demo}*/
	scope phy = new SpatialDynamics;

	auto b1 = phy.new_body (1, 1.kilogram, square (meters))
		.velocity (vec(0, 10)*meters/second);

	assert (b1.position == zero!Position);
	phy.update;
	assert (b1.position != zero!Position);

	Appendable!(SpatialId[3]) hits;
	phy.box_query (([zero!Position, unity!Position].vector!2 * 10).array, hits);
	assert (hits[].equal ([SpatialId (1)]));

	auto b2 = phy.new_body (2, 1.kilogram, square (meters))
		.position (vec(0,1)*meters);

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
void main ()
	{/*...}*/
		import evx.display;
		import evx.colors;
		alias map = evx.functional.map;

		auto phy = new SpatialDynamics;
		phy.Δt = 1/240.hertz;
		phy.gravity = vec(0, -9.8)*meters/second/second;
		
		auto gfx = new Display (1000, 1000);
		gfx.start; scope (exit) gfx.stop;
		gfx.background (white);

		import evx.input;
		bool simulation_terminated;
		auto usr = new Input (gfx, (bool){simulation_terminated = true;});

		auto mount_geometry = circle!3 (0.1.meters);
		auto mount = phy.new_body (phy_id, infinity.kilograms, mount_geometry)
			.position (vec(0, 1.5) * meters);

		auto chain = Rope!10 (phy, 10.kilograms, 1.meter, 0.01.meters)
			.stiffness (20_000.newtons/meter)
			.damping (1_000_000.newtons/(meters/second))
			.position (mount.position);

		cp.SpaceAddConstraint (phy.space, cp.SlideJointNew (
			chain.segments[0].body_id, chain.segments[$-1].body_id,
			zero!cpVect, zero!cpVect,
			0.0, chain.length.to!double * 1
		));

		auto bag = Rope!10 (phy, 90.kilograms, 1.5.meters, 0.2.meters)
			.stiffness (60_000.newtons/meter)
			.damping (1_000_000.newtons/(meters/second))
			.position (chain.segments[$-1].position);

		collision_group (mount, chain.segments[], bag.segments[]);

		Pin (bag.segments.front, chain.segments.back);
		Pin (chain.segments.front, mount);
		RotarySpring (bag.segments.front, chain.segments.back)
			.stiffness (100_000.newtons/meter)
			.damping (100_000.newtons/(meter/second))
			.resting_angle (0);

		// REVIEW do we absolutely need to manually track IDs? maybe should be opt-in

		auto ball_geometry = circle (0.05.meters);
		auto ball = phy.new_body (phy_id, 1.kilogram, ball_geometry)
			.position (vec(-50, -0.5) * meters)
			.velocity (25 * î.meters/second);

		ball.velocity = ball.velocity.rotate (π/6.8);

		import evx.camera;
		auto cam = new Camera (phy, gfx); {/*...}*/
			cam.zoom (400);
			cam.set_program = (Camera.Capture id)
				{/*draw}*/
					{/*mount}*/
						gfx.draw (yellow * black (0.95), mount_geometry.translate (mount.position).to_view_space (cam), GeometryMode.t_strip);
					}
					{/*chain}*/
						gfx.draw (grey (0.95), chain.geometry.to_view_space (cam), GeometryMode.t_strip);

						if (0)
						foreach (seg; chain.segments[])
							gfx.draw (cyan, chain.segment_geometry.rotate (seg.angle).translate (seg.position).to_view_space (cam));
					}
					{/*bag}*/
						gfx.draw (black (0.95), bag.geometry.to_view_space (cam), GeometryMode.t_strip);

						if (0)
						foreach (seg; bag.segments[])
							gfx.draw (cyan, bag.segment_geometry.rotate (seg.angle).translate (seg.position).to_view_space (cam));
					}
					{/*ball}*/
						gfx.draw (green*black (0.8), ball_geometry[].translate (ball.position).to_view_space (cam), GeometryMode.t_fan);
					}
				};
		}

		cp.SpaceSetIterations (phy.space, 100);

		import opencv;
		auto video = new Video.Output (`out.avi`, gfx.dimensions[].map!(to!int).ivec.to!CvSize);

		while (not (simulation_terminated))
			{/*...}*/
				import std.datetime;
				auto t = Clock.currTime;

				phy.update;
				phy.update;
				phy.update;
				phy.update;
				usr.process;
				cam.capture;
				gfx.render;

				foreach (seg; chain.segments)
					with (seg) velocity = velocity * 0.1;

				auto image = Image (gfx.dimensions[].map!(to!int).ivec.tuple.expand);
				void[] image_data = new void[gfx.dimensions[].product.to!size_t * 3];

				gfx.screenshot (image_data);
				cv.SetData (image, image_data.ptr, gfx.dimensions.x.to!int * 3); // dst, src, row_size (bytes)
				image.flip;
				video.put (image);
			}
	}
