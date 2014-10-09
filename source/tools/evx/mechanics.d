module mechanics;

import evx.spatial;
import evx.math;
import evx.utils;
import std.conv;
import dchip.all;

static if (0)
{/*...}*/
	alias SpringId = cpConstraint*;
	alias PinId = cpConstraint*;

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
					{return x + radius * î!vec.rotate (θ) * sgn;}

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
							.position (i * (-ĵ!vec) * segment_length);
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

static if (0)
void main ()
	{/*...}*/
		import evx.display;
		import evx.colors;
		alias map = evx.functional.map;

		auto phy = new SpatialDynamics;
		phy.Δt = 1/240.hertz;
		phy.gravity = vec(0, -9.8)*meters/second/second;
		
		auto gfx = new Display (1920, 1280); // TODO get monitor info, resolution, fullscreen, etc
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

		version (recording)
			{/*...}*/
				import opencv;
				auto video = new Video.Output (`out.avi`, gfx.dimensions[].map!(to!int).ivec.to!CvSize);
			}

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

				version (recording) {/*}*/
					auto image = Image (gfx.dimensions[].map!(to!int).ivec.tuple.expand);
					void[] image_data = new void[gfx.dimensions[].product.to!size_t * 3];

					gfx.screenshot (image_data);
					cv.SetData (image, image_data.ptr, gfx.dimensions.x.to!int * 3); // dst, src, row_size (bytes)
					image.flip;
					video.put (image);
				}
			}
	}
}
