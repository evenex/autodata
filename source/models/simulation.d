module models.aspect;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.algorithm;
import std.range;

import utils;
import units;
import indirect;
import math;
import meta;

public import models.entity;

/* if aspect and resource capacities are not specified, default to this */
enum default_capacity = 2^^10;

// TODO doc
// XXX protip: if a Model is generating shit compiler errors, turn off the Model mixin to see whats really going on
struct Aspect (Description)
	{/*...}*/
		private {/*imports}*/
			import resource.directory;
			import resource.allocator;
		}
		public:
		public {/*definitions}*/
			alias Base = Description;
			enum capacity = get_capacity!Base;

			alias Resources = Filter!(isArray, FieldTypeTuple!Base);
			alias Allocators = staticMap!(Allocator, staticMap!(ElementType, Resources));
		}
		public {/*subaspects}*/
			struct Observable
				{/*...}*/
					Entity.Id id;
					mixin CompareBy!id;

					mixin Look!(id, 
						staticMap!(observable_type, FieldTypeTuple!Base), 
						assignable_members!Base
					);
				}
			struct Writeable
				{/*...}*/
					Entity.Id id; // XXX potential optimization - search directory by key only. maybe it'll be kept in a register, since we won't have to drag along the entire struct just to make comparisons
					mixin CompareBy!id;

					Tuple!(staticMap!(writeable_type, FieldTypeTuple!Base)) data;

					auto ref opDispatch (string property)()
						{/*...}*/
							static immutable i = staticIndexOf!(property, assignable_members!Base);

							static assert (i >= 0);
							static assert (is (writeable_type!(typeof(__traits(getMember, Base, property))) == data.Types[i]));

							return data[i];
						}
				}
		}
		public {/*data}*/
			Directory!Observable observable;
			Directory!Writeable  writeable;

			Allocators allocators;
		}
		public {/*views}*/
			mixin(view_functions);

			static string view_functions ()
				{/*...}*/
					string code;

					foreach (property; __traits(allMembers, Base))
						static if (is (typeof(__traits(getMember, Base, property)) == T[], T))
							code ~= q{
								auto view_} ~property~ q{ (Entity.Id entity)
									}`{`q{
										return view (writeable[entity].} ~property~ q{[]);
									}`}`q{
							};

					return code;
				}
		}
		public {/*interface}*/
			void initialize ()
				{/*...}*/
					{/*directories}*/
						void init_directory (T)(ref T directory)
							{directory = T (capacity);}

						init_directory (observable);
						init_directory (writeable);
					}
					{/*allocators}*/
						uint capacities[Resources.length];
						uint filled;

						foreach (property; __traits(allMembers, Base))
							static if (is (typeof(__traits(getMember, Base, property)) == T[], T))
								capacities[filled++] = get_capacity!(__traits(getMember, Base, property));

						assert (filled == Resources.length);

						foreach (i, ref allocator; allocators)
							allocator = typeof(allocator) (capacities[i]);
					}
				}
			void reset_observation_source (string property)(Entity.Id entity)
				{/*...}*/
					alias Property = typeof(__traits(getMember, Base, property));

					mixin(q{
						static if (isArray!Property)
							observable[entity].read_} ~property~ q{_from (&view_} ~property~ q{);
						else observable[entity].read_} ~property~ q{_from (&writeable[entity].} ~property~ q{());
					});
				}
			void reset_observation_sources (Entity.Id entity)
				{/*...}*/
					foreach (property; assignable_members!Base)
						reset_observation_source!property (entity);
				}
			void represent (Entity.Id entity)
				in {/*...}*/
					assert (this.is_representing (entity).not);
				}
				out {/*...}*/
					assert (this.is_representing (entity));
				}
				body {/*...}*/
					observable.add (Observable (entity));
					writeable.add (Writeable (entity));

					reset_observation_sources (entity);
				}
			bool is_representing (Entity.Id entity)
				{/*...}*/
					return entity in observable? true:false;
				}
			void release (Entity.Id entity)
				in {/*...}*/
					assert (this.is_representing (entity));
				}
				out {/*...}*/
					assert (this.is_representing (entity).not);
				}
				body {/*...}*/
					observable.remove (Observable (entity));
					writeable.remove (Writeable (entity));
				}
			bool opBinaryRight (string op: `in`)(Entity.Id entity)
				{/*...}*/
					return this.is_representing (entity);
				}
		}
		public {/*traits}*/
			template observable_type (T)
				{/*...}*/
					static if (is (T == U[], U))
						alias observable_type = View!U;
					else alias observable_type = T;
				}
			template writeable_type (T)
				{/*...}*/
					static if (is (T == U[], U))
						alias writeable_type = Resource!U;
					else alias writeable_type = T;
				}
		}
	}
mixin template Model ()
	{/*...}*/
		private {/*imports}*/
			import std.conv;
			import std.typecons;
			import std.typetuple;
			import std.traits;
			import std.string;
			import resource.allocator;
			import resource.directory;
			import resource.view;
			import utils;
		}
		public:
		public {/*assertions}*/
			static assert (is(typeof(this) == class), `Model requires host class`);

			static string assert_entity_method_defined (string method)()
				{/*...}*/
					return q{
						static assert (__traits(compiles, This.} ~method~ q{ (Entity.Id.init)),
							This.stringof ~ ` Model must define method: `} `"`~method~`"` q{
						);
					};
				}
			static string assert_processing_stage_defined (string stage)()
				{/*...}*/
					static immutable error_msg = `"Model must define processing stage: ` ~stage~ ` ()"`;

					return q{
						static assert (hasMember!(This, } `"`~stage~`"` q{), } ~error_msg~ q{);
						static assert (isSomeFunction!(__traits(getMember, This, } `"`~stage~`"` q{)), } ~error_msg~ q{);
						static assert (ParameterTypeTuple!(__traits(getMember, This, } `"`~stage~`"` q{)).length == 0, } ~error_msg~ q{);
						static assert (is (ReturnType!(__traits(getMember, This, } `"`~stage~`"` q{)) == void), } ~error_msg~ q{);
					};
				}

			mixin(``
				~assert_entity_method_defined!`simulate`
				~assert_entity_method_defined!`terminate`
				~assert_processing_stage_defined!`initialize`
				~assert_processing_stage_defined!`update`
			);
		}
		public {/*definitions}*/
			alias This = typeof(this);
		}
		public {/*model interface}*/
			mixin AccessLayer!null;
		}
		public {/*simulation interface}*/
			Aspects!This aspects;
			@property auto service_addresses ()
				{/*...}*/
					static string pointers_to_public_services ()
						{/*...}*/
							import std.range;
							import services.service;

							string names;

							foreach (thing; __traits(allMembers, typeof(this)))
								static if (thing.empty) 
									continue;
								else static if (mixin(q{is(typeof(} ~thing~ q{) : Service)}))
									static if (mixin(q{__traits(getProtection, } ~thing~ q{) == `public`}))
										names ~= q{&} ~thing~ q{, };

							if (names.empty)
								return q{τ()};
							else return q{τ(} ~names[0..$-2]~ q{)};
						}

					return mixin(pointers_to_public_services);
				}
			void reset_observation_sources (Entity.Id entity)
				{/*...}*/
					foreach (ref aspect; aspects)
						if (entity in aspect)
							aspect.reset_observation_sources (entity);
				}
			this ()
				{/*...}*/
					foreach (ref aspect; aspects)
						aspect.initialize;
				}
		}
	}
mixin template Simulation (Models...)
	{/*...}*/
		import resource.directory;
		import utils;
		static assert (not(is(typeof(this))), `Simulation must be mixed in at global scope`);

		final class Simulation
			{/*...}*/
				import std.typetuple;
				import std.traits;

				import meta;

				enum is_simulation = true;

				// code generation
				static auto module_level_services ()
					{/*...}*/
						import std.range;
						import services.service;
						mixin(q{
							alias this_module = .} ~moduleName!Simulation~ q{;
						});

						string names;

						foreach (thing; __traits(allMembers, this_module))
							static if (thing.empty) 
								continue;
							else static if (mixin(q{is(typeof(} ~thing~ q{) : Simulation)}))
								continue;
							else static if (mixin(q{is(typeof(} ~thing~ q{) : Service)}))
								names ~= thing~ q{, };

						if (names.empty)
							return q{TypeTuple!()};
						else return q{TypeTuple!(} ~names[0..$-2]~ q{)};
					}

				alias Services = staticMap!(types_of, mixin(module_level_services));

				Models models;
				Services services;

				auto ref model (Model)()
					if (not (is_aspect!Model))
					{/*...}*/
						return models[staticIndexOf!(Model, Models)];
					}
				auto ref aspect (Aspect)()
					if (is_aspect!Aspect)
					{/*...}*/
						.Aspect!Aspect* aspect;

						foreach (Model; Models)
							{/*...}*/
								immutable i = staticIndexOf!(.Aspect!Aspect, typeof(Model.aspects)); // REVIEW

								static if (i >= 0)
									{/*...}*/
										aspect = &model!Model.aspects[i];
									}
							}
						assert (aspect, `could not locate aspect ` ~Aspect.stringof);

						return *aspect;
					}
				void update ()
					{/*...}*/
						if (new_entities)
							foreach_reverse (entity; entities)
								{/*announce new entities}*/
									foreach (ref model; models)
										foreach (ref aspect; model.aspects)
											if (entity.id in aspect)
												{/*...}*/
													model.simulate (entity.id);
													break;
												}

									if (--new_entities == 0)
										break;
								}

						foreach (ref model; models)
							model.update;
					}

				this ()
					{/*...}*/
						foreach (ref service; mixin(module_level_services))
							{/*collect}*/
								assert (service.is_running, `attempted to start Simulation before starting ` ~typeof(service).stringof~ ` service`);
								this.services[staticIndexOf!(typeof(service), Services)] = service;
							}
						foreach (ref model; models)
							{/*initialize}*/
								{/*data layer}*/
									model = new typeof(model);
								}
								{/*service layer}*/
									foreach (service; model.service_addresses)
										{/*...}*/
											immutable i = staticIndexOf!(typeof(*service), Services);

											static assert (i >= 0, `could not locate required service: ` ~typeof(*service).stringof~ 
												` (simulation services must be declared at module scope)`);

											*service = this.services[i];
										}
								}
								{/*model layer}*/
									model.initialize;
								}
							}
					}
			}

		__gshared Simulation simulation;
		mixin AccessLayer!simulation;

		__gshared Directory!Entity entities;
		ulong new_entities;

		shared static this ()
			{/*...}*/
				entities = Directory!Entity (128); // XXX
			}

		auto simulate (string name)
			{/*...}*/
				entities.append (Entity (name));
				++new_entities;

				return entities.back.id;
			}
		void terminate (Entity.Id entity)
			{/*...}*/
				foreach (ref model; simulation.models)
					foreach (ref aspect; model.aspects)
						if (entity in aspect)
							{/*terminate entity}*/
								model.terminate (entity);
								break;
							}

				foreach (ref model; simulation.models)
					foreach (ref aspect; model.aspects)
						if (entity in aspect)
							aspect.release (entity);

				entities.remove (Entity (entity));
			}
	}

public {/*traits}*/
	template Aspects (Model)
		{/*...}*/
			alias Aspects = staticMap!(Aspect, Filter!(is_aspect, get_substructs!Model));
		}
	template is_aspect (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_aspect = staticIndexOf!(Aspect, __traits(getAttributes, T[0])) >= 0;
		}
	template is_simulation (T)
		{/*...}*/
			enum is_simulation = __traits(compiles, T.is_simulation);
		}
	template get_capacity (T...)
		if (T.length == 1)
		{/*...}*/
			alias Numbers = Filter!(is_numerical_param, __traits(getAttributes, T[0]));

			static if (Numbers.length == 1)
				{/*...}*/
					const uint get_capacity = Numbers[0];
				}
			else static if (Numbers.length == 0)
				{/*...}*/
					const uint get_capacity = default_capacity;
				}
			else static assert (0);
		}
}
public {/*access}*/
	mixin template AccessLayer (alias simulation)
		if (is_simulation!(typeof(simulation))		// external
		|| is (typeof(simulation) == typeof(null)))	// internal
		{/*...}*/
			public:
			public {/*aspect cast}*/
				struct As (Aspect)
					if (is_aspect!Aspect)
					{/*...}*/
						import std.traits;
						import std.typetuple;

						public:
						Entity.Id entity;
						alias entity this;

						@disable this ();
						this (Entity.Id entity)
							{/*...}*/
								this.entity = entity;

								if (not (entity in aspect!Aspect))
									aspect!Aspect.represent (entity);
							}

						auto opDispatch (string property, Args...)(Args args)
							{/*...}*/
								static if (Args.length == 0)
									enum action = `observe`;
								else static if (allSatisfy!(Or!(isSomeFunction, isPointer), Args[0]))
									enum action = `source`;
								else enum action = `write`;

								static if (action is `observe` || action is `source`)
									{/*...}*/
										if (observable is null)
											observable = &aspect!Aspect.observable[entity];
									}
								else {/*...}*/
									if (writeable is null)
										writeable = &aspect!Aspect.writeable[entity];
								}

								static if (action is `observe`)
									{/*...}*/
										mixin(q{
											return observable.} ~property~ q{;
										});
									}
								else static if (action is `source`)
									{/*...}*/
										mixin(q{
											observable.read_} ~property~ q{_from (args);
										});
										return this;
									}
								else static if (action is `write`)
									{/*...}*/
										auto ref lhs ()
											{/*...}*/
												mixin(q{
													return writeable.} ~property~ q{;
												});
											}

										static if (is (typeof(__traits(getMember, Aspect, property)) == T[], T))
											{/*write to resource}*/
												immutable i = staticIndexOf!(T[], .Aspect!Aspect.Resources);

												lhs = aspect!Aspect.allocators[i].save (args);
											}
										else {/*write to variable}*/
											static string assign_to (string rhs)()
												{/*...}*/
													return `lhs =` ~rhs;
												}
											static string constructor ()
												{/*...}*/
													return q{typeof(lhs) (args)};
												}

											mixin(q{
												static if (__traits(compiles, } ~assign_to!`args[0]`~ q{))
													} ~assign_to!`args[0]`~ q{;

												else static if (__traits(compiles, } ~constructor~ q{))
													} ~assign_to!constructor~ q{;

												else static assert (0, 
													`couldn't construct or assign ` ~Args.stringof~ ` to ` ~typeof(lhs()).stringof~ ` ` ~property
												);
											});
										}

										return this;
									}
								else static assert (0);
							}

						private:
						.Aspect!Aspect.Observable* observable;
						.Aspect!Aspect.Writeable*  writeable;
					}
			}
			private:
			private {/*policy}*/
				static bool interface_is_external ()
					{/*...}*/
						/* REVIEW
							models are prohibited from directly accessing properties of other models,
							and have no knowledge of the simulation. (this also prevents a circular
							dependency of the models on the currently active simulation type).
							as such models can only access their own aspects.
							properties can be sourced from "phenomenon" functions which are defined
							at the top level and have access to the active simulation.
							thus models can indirectly access other models' properties, but the knowledge
							of this is contained at the top "phenomenon" level
						*/
						return is_simulation!(typeof(simulation));
					}
				static assert (interface_is_external != is(typeof(this)));
			}
			private {/*routing}*/
				auto ref aspect (Aspect)()
					if (is_aspect!Aspect)
					{/*...}*/
						static if (interface_is_external)
							return simulation.aspect!Aspect;
						else return this;
					}
				auto observe (Aspect, string property)(Entity.Id entity)
					if (is_aspect!Aspect)
					{/*...}*/
						mixin(q{
							return aspect!Aspect.observable[entity].} ~property ~q{;
						});
					}
			}
		}
}

///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
import services.collision;
import resource.view;

static if (0)
	{/*...}*/
		CollisionDynamics!(Entity.Id) collision;
		mixin Simulation!(Physical);

		auto sq (size_t i)
			{/*...}*/
				return Physical.Position (square[i].x.meters, square[i].y.meters);
			}
		unittest
			{/*...}*/
				collision = new CollisionDynamics!(Entity.Id);
				collision.start; scope (exit) collision.stop;

				simulation = new typeof(simulation);

				auto fred = model (`fred`)
					.As!(Physical.Body)
						.position (Physical.Position (0.meters)) // can assign values
						.velocity (0.meters/second) // can also forward ctor args to assign value
						.mass (10.kilograms)
						.geometry (square (0.5).map!(v => Physical.Position (v)))
						// TODO source it once its been allocated
						/* TODO 
							if this is data, allocate on the writeable
							and point the observable at it
							if this is a function returning a view, source it
							if this is a view... then this property needs to be direct
							TODO LATER if this thing needs to be allocated with room to grow...
							 then shit. declaration-level allocation strategy?
							 uint Capacity (how much is available, total?)
							 double Reserve (what percentage extra to allocate?)
						*/
				;


				std.stdio.stderr.writeln (observe!(Physical.Body, `position`)(fred));
				std.stdio.stderr.writeln (fred.position);
				std.stdio.stderr.writeln (observe!(Physical.Body, `velocity`)(fred));
				std.stdio.stderr.writeln (fred.velocity);
				std.stdio.stderr.writeln (fred.geometry);
			//			.damping (& ground_contact_friction) // this sets the source. we've customized the behavior without resorting to a new type. Aspect/Model > OOP ... but something makes me feel like biomechanics should determine this somehow? or rather the function does something conditional on if the things got biomechanics or what... so the models dont know about each other unless they're prereqs, but can otherwise communicate through events and share data through routing defined at the top level. but the model functions, entity function whatever, they can know about all kinds of models. they are like general units of like knowledge and observation and pattern recognition or whatever.... i dunno, like slivers of interpretation basically. what the fuck do you call that?? but anyway the point is, these functions are what operate at the highest level of abstraction. they are just my thoughts and observations on the world.
			//			.elevation (& fall_to_ground) // this should post a message, `fred fell x meters` so Medical can react
			//			.height (1.7.meters)
			//			.geometry (& human_geometry) // this function draws from height and mass to make a circle of some plausible diameter
			//	();
			static if (0)
				{/*...}*/
					.As!(Visual.Object)
						.geometry (& observe!(Physical.Body, `geometry`)) // observe is probably okay syntax
						.texture (`art/fred.tga`) // @Direct
					.As!(Container.Inventory)
						.capacity (1)
						.items (`ak47`) // JK THIS TOTALLY SETS A PROPERTY NOW // this doesnt set a property, but rather affects some initial state
					.As!(Behavioral.Agent)
						.priorities (`run around`, `shoot randomly`) // ditto ^
						.resources (& skills) // since skills requires behavior model, it should know how to phrase skills as a resource
					.As!(Skill.Practitioner) // requires behavioral model
						.basic (`firearms`)
						.advanced (`sprinting`) // how do i get this to affect biomechanics? define (autodocumenting, somehow) functions that look at the skills and determine bonuses. these functions can be thought of as... i dunno, skill effects? abilities? things that tend to happen when you're good at something?
						.expert (`bullshit`)
						.elite (`fredness`, `potty training`)
						.master (`disguise`)
					.As!(Medical.Subject) // average starting values and sources automatically preloaded
					.As!(Biomechanical.Biped) // requires physical body and medical subject
						.top_speed (& ability!`top_speed`) // ability!prop is in the Skills model and computes the value of the attribute given some skills
						// now what if fred puts on a powered exoskeleton? that's something he's piloting
						// it is a Piloting.Vehicle or something and a Biomechanical.Biped to boot
						// and it can partially source its top speed from the driver or whatever
				(); // verification step. set dtor to assert verification.. bc this is not an entity, its is a command
				}
			}
	}
