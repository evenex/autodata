import std.traits;
import std.algorithm;
import std.array;
import std.range;
import std.math;
import utils; // TODO make views and looks and math public imports?
import views;
import math;
import physics_service;
import modeling;

class Ballistic
	{/*...}*/
		private alias Body = Physics.Body.Id;

		static immutable critical_speed = 100.0; // m/s
		static immutable max_flight_time = 1.2; // s
		static immutable impact_time = 1.0e-05; // s (1cm/1000m/s)

		this (Physics world, Material delegate (Projectile*, Body) on_impact)
			{/*...}*/
				this.world = world;
				callback.on_impact = on_impact;
			}
		auto launch (Body source, Projectile projectile)
			{/*...}*/
				projectile.source = source;
				in_flight ~= projectile;

				debug if (tracer !is null)
					tracer.on_launch (&in_flight.back);
			}
		auto update ()
			{/*...}*/
				foreach (ref projectile; in_flight)
					{/*...}*/
						float step_time_remaining = world.Δt;

						while (projectile.velocity.norm > critical_speed 
							&& step_time_remaining > 0.0)
							{/*...}*/
								auto flight = Flight (this, projectile, step_time_remaining);

								handle!q{on_flight}(&projectile, flight.final_position);

								projectile.position = flight.final_position;
								projectile.velocity = flight.final_velocity;

								if (flight.resulted_in_impact)
									{/*...}*/
										step_time_remaining -= flight.duration;

										auto material = handle!q{on_impact}(&projectile, flight.impact_body);

										auto impact = Impact (this, flight, material);

										projectile.velocity = impact.final_velocity;
										projectile.radius = impact.final_radius;
										projectile.source = impact.target;

										if (impact.resulted_in_entry)
											{/*...}*/
												handle!q{on_entry}(&projectile);

												auto penetration = Penetration (this, impact, step_time_remaining);

												projectile.position = penetration.final_position;
												projectile.velocity = penetration.final_velocity;
												projectile.radius = penetration.final_radius;

												if (penetration.resulted_in_exit)
													{/*...}*/
														step_time_remaining -= penetration.duration;

														handle!q{on_exit}(&projectile);
													}
												else handle!q{on_stop}(&projectile);
											}
									}
								else step_time_remaining = 0.0;
							}

						projectile.flight_time += world.Δt;
					}
				for (int i = 0; i < in_flight.length; i++)
					if (in_flight[i].velocity.norm < critical_speed 
						|| in_flight[i].flight_time > max_flight_time)
						{/*...}*/
							handle!q{on_fade}(&in_flight[i]);
							in_flight = in_flight.remove (i--);
						}
				debug if (tracer !is null)
					tracer.update;
			}

		Physics world;
		Projectile[] in_flight;

		struct Callback
			{/*...}*/
				Material delegate(Projectile*, Body) on_impact;
				void delegate(Projectile*, vec new_position) on_flight;
				void delegate(Projectile*) on_entry;
				void delegate(Projectile*) on_exit;
				void delegate(Projectile*) on_stop;
				void delegate(Projectile*) on_fade;
			}
		Callback callback;

		public:
		public {/*objects}*/
			struct Projectile
				{/*...}*/
					mixin Command!(
						float, 	`mass`,
						float, 	`radius`,
						float, 	`hardness`,
						vec, 	`position`,
						vec, 	`velocity`,
					);
					//Tag tag; // BUG tags are useless if they disable default initialization
					private {/*data}*/
						float flight_time = 0.0;
						Body source;

						debug {/*...}*/
							mixin Type_Unique_Id;
							Id id; // TODO remove the check from the tracer and turn it into an assertion
						}
					}
				}
			struct Material
				{/*...}*/
					float density;
					float strength;
				}
			enum: Material {air = Material (1.225, 0.0)}
		}
		debug {/*trace}*/
			void trace (Args...)(Args args)
				if (__traits(compiles, this.new Tracer (args)))
				in {/*...}*/
					assert (tracer is null);
				}
				body {/*...}*/
					tracer = this.new Tracer (args);
				}
		}
		private:
		private {/*events}*/
			auto handle (string event, Args...)(Args args)
				{/*...}*/
					mixin(q{alias Return = ReturnType!(callback.}~event~q{);});
					debug if (tracer !is null)
						{/*...}*/
							static if (is (Return == void))
								mixin(q{
									tracer.}~event~q{ (args);
								});
							else static if (is (Return == Material))
								mixin(q{
									auto material = callback.}~event~q{ (args);
									tracer.}~event~q{ (args[0], material);
									return material;
								});
							else static assert (0);
						}
					if (mixin(q{callback.}~event~q{ !is null}))
						mixin(q{return callback.}~event~q{ (args);});
					else static if (is (Return == void))
						return;
					else assert (0);
				}

			struct Flight
				{/*...}*/
					Projectile* projectile;

					vec final_position;
					vec final_velocity;
					float duration;

					bool resulted_in_impact;
					Body impact_body;
					vec impact_normal;
					
					this (Ballistic model, ref Projectile projectile, double max_duration)
						in {/*...}*/
							assert (model !is null);
							assert (model.world !is null);
							assert (projectile.mass.isnan.not);
							assert (projectile.radius.isnan.not);
							assert (projectile.hardness.isnan.not);
						}
						out {/*...}*/
							assert (final_position != vec.init);
							assert (final_velocity != vec.init);
							assert (duration.isnan.not);
							assert (impact_body != projectile.source, `self-collision`);
						}
						body {/*...}*/
							this.projectile = &projectile;

							auto x = projectile.position;
							auto Δx = projectile.velocity * max_duration;
							auto trace = model.world.ray_cast_excluding (projectile.source, [x, x+Δx]); // BUG turns out, array literals will trigger a heap allocation
							auto distance_to_impact = Δx.norm * trace.ray_time;
							this.impact_body = trace.body_id;
							this.impact_normal = trace.surface_normal;

							auto m = projectile.mass;
							auto r = projectile.radius;

							auto system = Integrator!(Method.average,
								(float x, float v, float t) {/*...}*/
									auto dx = v;
									auto dv = -0.5 * air.density * v^^2 * π*r^^2 / m;
									auto dt = 1.0;
									return τ(dx, dv, dt);
								},
							)(	0.0f,
								projectile.velocity.norm,
								0.0f
							); debug if (model.tracer !is null)
								system.on_step ((float x, float v, float t)
									{model.tracer.on_flight_step (&projectile, x, v, t);}
								);

							auto flight = system.solve_for ((double x, double v, double t) =>
								t >= max_duration || v <= critical_speed || x >= distance_to_impact,
								0.0001
							);

							auto x_1 = flight[0];
							auto v_1 = flight[1];
							auto t_1 = flight[2];
							auto u = projectile.velocity.unit;

							if (x_1 >= distance_to_impact 
								&& v_1 > critical_speed 
								&& t_1 < max_duration)
								this.resulted_in_impact = true;

							this.final_position = projectile.position + u * x_1;
							this.final_velocity = u * v_1;
							this.duration = t_1;
						}
				}
			struct Impact
				{/*...}*/
					Projectile* projectile;
					Material material;
					Body target;

					vec final_velocity;
					float final_radius;
					bool resulted_in_entry;

					this (Ballistic model, Flight flight, Material material)
						in {/*...}*/
							assert (model !is null);
							assert (model.world !is null);
							assert (flight.projectile.mass.isnan.not);
							assert (flight.projectile.radius.isnan.not);
							assert (flight.projectile.hardness.isnan.not);
							assert (flight.impact_body != Body.init, `flight registered impact with nonexistent body: `~flight.to!string);
							assert (flight.impact_body != flight.projectile.source);
							assert (abs(flight.impact_normal.norm - 1.0) < 0.001);
							assert (model.callback.on_impact !is null);
						}
						out {/*...}*/
							assert (target != Body.init);
							assert (final_velocity != vec.init);
							assert (final_radius.isnan.not);
						}
						body {/*...}*/
							this.projectile = flight.projectile;
							this.target = flight.impact_body;
							this.material = material;
							auto m = projectile.mass;
							auto v = projectile.velocity;
							auto h = projectile.hardness;
							auto r = projectile.radius;
							auto n = flight.impact_normal;
							auto s = material.strength;
							auto ρ = material.density;

							auto total_stress = (v*m) / (impact_time * π*r^^2);
							auto normal_stress = total_stress.proj (n).norm;
							auto shear_stress = total_stress.rej (n).norm;

							if (normal_stress >= s * sqrt(ρ)) // XXX
								resulted_in_entry = true;
							else resulted_in_entry = false;

							if (this.resulted_in_entry)
								{/*...}*/
									this.final_radius = r + (1.0-h) * shear_stress * impact_time;
									auto θ = asin (v.unit.det (n)); // TODO refraction equation
									this.final_velocity = v.rotate (θ);
								}
							else {/*...}*/
								this.final_radius = r + (1.0-h) * normal_stress * impact_time;
								// TEMP
								float loss_rate = 0.3;
								auto u = (1.0 - loss_rate)*v;
								this.final_velocity = u - 2 * u.proj (n); //TODO separate reflection equation
							}
						}
				}
			struct Penetration
				{/*...}*/
					vec final_position;
					vec final_velocity;
					float final_radius;
					float duration;

					bool resulted_in_exit;

					this (Ballistic model, Impact impact, double max_duration)
						in {/*...}*/
							assert (model !is null);
							assert (model.world !is null);
							assert (impact.projectile.mass.isnan.not);
							assert (impact.projectile.radius.isnan.not);
							assert (impact.projectile.hardness.isnan.not);
						}
						out {/*...}*/
							assert (final_position != vec.init);
							assert (final_velocity != vec.init);
							assert (final_radius.isnan.not);
							assert (duration.isnan.not);
							assert (this.resulted_in_exit || this.final_velocity.norm < critical_speed);
						}
						body {/*...}*/
							auto material = impact.material;
							auto projectile = impact.projectile;

							auto x = projectile.position;
							auto Δx = projectile.velocity * max_duration;
							auto trace = model.world.ray_query (impact.target, [x+Δx, x]);
							auto distance_to_exit = Δx.norm * (1.0 - trace.ray_time);

							auto ρ = material.density;
							auto s = material.strength;
							auto m = projectile.mass;
							auto h = projectile.hardness;
							auto n = trace.surface_normal;
								
							auto system = Integrator!(Method.average,
								(float x, float v, float r, float t) {/*...}*/
									auto dx = v;
									auto dv = -0.5 * ρ*(log(log(s))) * v^^2 * π*r^^2 / m;
									auto dr = 0.5 * (1.0-h) * ρ * v^^2 / m;
									auto dt = 1.0;
									return τ(dx, dv, dr, dt);
								}
							)( 	0.0f,
								projectile.velocity.norm,
								projectile.radius,
								0.0f
							); debug if (model.tracer !is null) 
								system.on_step ((float x, float v, float r, float t)
									{model.tracer.on_penetration_step (projectile, x, v, r, t);}
								);

							auto penetration = system.solve_for ((double x, double v, double r, double t) =>
								t >= max_duration || v <= critical_speed || x >= distance_to_exit,
								0.0001
							);

							if (penetration[0] >= distance_to_exit)
								this.resulted_in_exit = true;

							auto x_1 = penetration[0];
							auto v_1 = penetration[1];
							auto r_1 = penetration[2];
							auto t_1 = penetration[3];
							auto u = projectile.velocity.unit;
							
							if (this.resulted_in_exit)
								this.final_velocity = v_1 * u;//.rotate (asin (u.det (n))/ρ);
							else this.final_velocity = 0.vec; // BUG we might have just ended the timestep while inside the material...

							this.final_position = projectile.position + x_1 * u;
							this.final_radius = r_1;
							this.duration = t_1;
						}
				}
		}
		debug {/*trace}*/
			Tracer tracer;
			class Tracer
				{/*...}*/
					private alias Id = Physics.Body.Id;

					import display_service;
					import camera_tool;
					import scribe_tool;
					import plotting_tool;
					import info_box;

					Projectile.Id traced;

					Event 	launch;
					Event[] impacts;
					Event[] penetrations;
					Event 	termination;
					vec[]	trajectory;
					struct Event
						{/*...}*/
							Info_Box info;
							vec location;
						}

					Data data;
					struct Data
						{/*...}*/
							double[] xs;
							double[] vs;
							double[] rs;
							double[] ts;
						}

					Display gfx;
					Scribe txt;
					Camera cam;

					this (Display gfx, Camera cam, Scribe txt)
						{/*...}*/
							this.gfx = gfx;
							this.txt = txt;
							this.cam = cam;
						}
					void update ()
						{/*...}*/
							if (traced == Projectile.Id.init)
								return;

							launch.info.bounds.move_to (launch.location.to_view_space (cam).from_draw_space.to_extended_space (gfx));
							launch.info.draw;

							foreach (impact; impacts)
								{/*...}*/
									impact.info.bounds.move_to (impact.location.to_view_space (cam).from_draw_space.to_extended_space (gfx));
									impact.info.draw;
								}

							foreach (penetration; penetrations)
								{/*...}*/
									penetration.info.bounds.move_to (penetration.location.to_view_space (cam).from_draw_space.to_extended_space (gfx));
									penetration.info.draw;
								}

							termination.info.bounds.move_to (termination.location.to_view_space (cam).from_draw_space.to_extended_space (gfx));
							termination.info.draw;

							gfx.draw (white.alpha (0.2), trajectory.to_view_space (cam), Geometry_Mode.l_strip);
						}

					public {/*event}*/
						void on_launch (Projectile* projectile)
							{/*...}*/
								if (projectile.id == Projectile.Id.init)
									projectile.id = Projectile.Id.create;

								traced = projectile.id;
								auto color = velocity_hue (projectile);

								launch.info = Info_Box (square (0.1).scale (vec(1.25, 1)));
								launch.info.add (txt
									.write (`launch speed `~projectile.velocity.norm.to!string[0..min(3,$)]~` m/s`)
									.color (white).size (10), square
								).decorate ((Bounding_Box box)
									{gfx.draw (color.alpha (0.4), box.scale (1.05).from_extended_space.to_draw_space (gfx));}
								);
								launch.location = projectile.position - projectile.velocity.unit;

								impacts.clear;
								impacts.reserve (16);

								penetrations.clear;
								penetrations.reserve (16);

								termination = Event.init;

								trajectory = [projectile.position];
								trajectory.reserve (16);

								with (data)
									xs.clear, vs.clear, ts.clear, rs.clear;
								with (data)
									xs.reserve (2^^12), vs.reserve (2^^12), ts.reserve (2^^12), rs.reserve (2^^12);
							}
						void on_flight (Projectile* projectile, vec new_position)
							{/*...}*/
								gfx.draw (velocity_hue (projectile), [projectile.position, new_position].to_view_space (cam));

								if (projectile.id != traced) return;

								trajectory ~= projectile.position;
							}
						void on_impact (Projectile* projectile, Material material)
							{/*...}*/
								if (projectile.id != traced) return;

								auto color = velocity_hue (projectile);

								impacts ~= Event (Info_Box (square (0.1).scale (vec(1.25,1))), projectile.position - projectile.velocity.unit);
								impacts.back.info.add (txt
									.write (`impact speed `~projectile.velocity.norm.to!string[0..min(3,$)]~` m/s`)
									.color (white).size (10)
									.align_to (Alignment.center),
									square
								).decorate ((Bounding_Box box)
									{gfx.draw (color.alpha (0.4), box.scale (1.05).from_extended_space.to_draw_space (gfx));} // TODO at least get rid of to_draw_space by having Display handle coords
								);

								trajectory ~= projectile.position;
							}
						void on_entry (Projectile* projectile)
							{/*...}*/
							}
						void on_exit (Projectile* projectile)
							{/*...}*/
								if (projectile.id != traced) return;

								auto color = velocity_hue (projectile);

								impacts ~= Event (Info_Box (square (0.1).scale (vec(1.25,1))), projectile.position + projectile.velocity.unit);
								impacts.back.info.add (txt
									.write (`exit speed `~projectile.velocity.norm.to!string[0..min(3,$)]~` m/s`)
									.color (white).size (10)
									.align_to (Alignment.center),
									square
								).decorate ((Bounding_Box box)
									{gfx.draw (color.alpha (0.4), box.scale (1.05).from_extended_space.to_draw_space (gfx));} // TODO at least get rid of to_draw_space by having Display handle coords
								);

								trajectory ~= projectile.position;
							}
						void on_stop (Projectile* projectile)
							{/*...}*/
								if (projectile.id != traced) return;

								terminate_trace (projectile);
							}
						void on_fade (Projectile* projectile)
							{/*...}*/
								if (projectile.id != traced) return;

								terminate_trace (projectile);
							}
					}
					public {/*integration}*/
						void on_flight_step (Projectile* projectile, float x, float v, float t)
							{/*...}*/
								static int i = -1;
								if (++i % 50 != 0) return;

								if (projectile.id is traced) with (data)
									xs ~= x, vs ~= v, rs ~= projectile.radius, ts ~= t;
							}
						void on_penetration_step (Projectile* projectile, float x, float v, float r, float t)
							{/*...}*/
								static int i = -1;
								if (++i % 50 != 0) return;

								if (projectile.id is traced) with (data)
									xs ~= x, vs ~= v, rs ~= r, ts ~= t;
							}
					}

					private:
						void terminate_trace (Projectile* projectile)
							{/*...}*/
								if (data.ts.length < 2) return;

								auto Δt = data.ts[1] - data.ts[0];
								foreach (i, ref t; data.ts)
									t = i*Δt;

								auto v_0 = data.vs[0];
								auto color = Color.from_hsv (360 * data.vs.mean / data.vs[0]);

								auto plot = Plot (data.ts, data.vs)
									.color (color*white)
									.title (`speed`)
									.y_axis (``, Plot.Range (0, Plot.automatic))
									.x_axis (`seconds`)
									.text_size (10)
									.using (gfx, txt);

								termination.info = Info_Box (square (0.2).scale (vec(1.5,1)));
								termination.info.add (plot, square)
									.align_to (Alignment.top_center)
									.decorate ((Bounding_Box box) 
										{gfx.draw (color, box.scale (1.01).from_extended_space.to_draw_space (gfx));}
									);

								termination.location = projectile.position + projectile.velocity.unit;
							}
						auto velocity_hue (Projectile* projectile)
							{/*...}*/
								if (projectile.id != traced)
									return gray;
								auto v_0 = data.vs.length? data.vs[0] : projectile.velocity.norm;
								return Color.from_hsv (360 * (v_0 - projectile.velocity.norm) / v_0);
							}
					this () {assert (0);} // OUTSIDE BUG linker error on @disable this ()
				}
		}
	}
