module models.aspect;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.algorithm;
import std.range;
import utils;
import units;
import math;


/* if aspect and resource capacities are not specified, default to this */
enum default_capacity = 2^^10;

// aspect - frontend (redirection), backup (default source), arbitrary functions. assume that internal data is hotter remotely sourced data
// performance - generated vs stored data
// @Direct, @Cached,

// TODO doc
enum Aspect; // applies to struct definitions. generate frontends, backends, directories, allocators, etc.
 // by default:
 // frontend data consists of Looks to properties and Views
 // backend data contains backing fields and Resources to match the frontend
 // initializing sets the backend data
 // sourcing sets the frontend source
 // this can only be done privately, by the owning model, or at the top level, using an As! builder
enum Direct; // no backend data generated. frontend contains actual value. can not coexist with Remote. sourcing a @Direct property from the As! builder is a compile-time error.
enum Remote; // no backend data generated, model must source this property from elsewhere. can't coexist with Direct. initializing a @Remote property from the As! builder is a compile-time error.
enum Cached; // TODO optional InvalidationPolicy, otherwise memoization cache clears itself after every model update

/* mixing this in produces iterable aspect_frontends and aspect_backends directories */
mixin template Model ()
	{/*...}*/
		private {/*imports}*/
			import std.conv;
			import std.typecons;
			import std.typetuple;
			import std.traits;
			import resource.allocator;
			import resource.directory;
			import resource.view;
			import utils;
		}
		public {/*assertions}*/
			static assert (is(typeof(this)), `Model requires host class`);
			static assert (is(typeof(this) == class), `Model requires host class`);

			// entity ctor/dtor functions
			static assert (__traits(compiles, This.model (Entity.Id.init)),
				`Model must define method model (Entity.Id)`
			);
			static assert (__traits(compiles, This.release (Entity.Id.init)),
				`Model must define method release (Entity.Id)`
			);

			static if (__ctfe)
				{/*...}*/
					static void processing_cycle_verification ()
						{/*...}*/
							static void assert_stage_defined (string stage)()
								{/*...}*/
									static const string error = `Model must define processing stage ` ~stage~ ` ()`;

									static assert (hasMember!(This, stage), error);
									static assert (isSomeFunction!(__traits(getMember, This, stage)), error);
									static assert (ParameterTypeTuple!(__traits(getMember, This, stage)).length == 0, error);
									static assert (is (ReturnType!(__traits(getMember, This, stage)) == void), error);
								}

							// preparation_stage 
							assert_stage_defined!q{initialize};
							assert_stage_defined!q{update};
						}
				}
		}
		alias This = typeof(this);

		mixin(generate_aspect_structure!This);
		mixin(generate_aspect_constructor!This);
		mixin PropertyAccessInterface!null;

		auto service_addresses ()
			{/*...}*/
				static auto class_level_services ()
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

				return mixin(class_level_services);
			}
		void source_from_backends (Aspect)(Entity.Id entity)
			if (is_aspect!Aspect)
			{/*...}*/
				immutable aspect = AspectDecl!Aspect.name;

				string code ()
					{/*...}*/
						string code;

						alias is_default = Not!(Or!(is_direct, is_remote));

						foreach (T; Filter!(is_default, get_variable_decls!Aspect))
							code ~= q{
								} ~aspect~ q{_frontends[entity].set_} ~T.name~ q{ (&} ~aspect~ q{_backends[entity].} ~T.name~ q{);
							};

						foreach (T; Filter!(is_default, get_resource_decls!Aspect))
							code ~= q{
								} ~aspect~ q{_frontends[entity].set_} ~T.name~ q{ (&view_} ~aspect~ q{_} ~T.name~ q{);
							};

						return code;
					}

				mixin(code);
			}
	}

static if (__ctfe) 
	{/*code generation}*/
		template generate_aspect_structure (T)
			{/*...}*/
				string generate_aspect_structure ()
					{/*...}*/
						string code;

						foreach (U; Aspects!T)
							code ~= q{
								}~AspectDecl!U.define_frontend~q{
								}~AspectDecl!U.define_backend~q{
								}~AspectDecl!U.declare_dataories~q{
								}~AspectDecl!U.declare_allocators~q{
								}~AspectDecl!U.define_viewing_functions;

						return code;
					}
			}
		template generate_aspect_constructor (T)
			{/*...}*/
				string generate_aspect_constructor ()
					{/*...}*/
						string code = q{this () } `{
						`;

						foreach (U; Aspects!T)
							code ~= q{
								}~AspectDecl!U.initialize_directories~q{
								}~AspectDecl!U.initialize_allocators;

						return code ~ `
						}`;
					}
			}

		template is_aspect (T...) // predicate over declarations
			if (T.length == 1)
			{/*...}*/
				enum is_aspect = staticIndexOf!(Aspect, __traits(getAttributes, T[0])) > -1;
			}
			
		template is_direct (T, string field) // internal predicate
			{/*...}*/
				enum is_direct = staticIndexOf!(Direct, __traits(getAttributes, __traits(getMember, T, field))) > -1;
			}
		template is_remote (T, string field) // internal predicate
			{/*...}*/
				enum is_remote = staticIndexOf!(Remote, __traits(getAttributes, __traits(getMember, T, field))) > -1;
			}
		template is_direct (T) // predicate over declarations
			if (__traits(compiles, T.is_direct))
			{/*...}*/
				enum is_direct = T.is_direct;
			}
		template is_remote (T) // predicate over declarations
			if (__traits(compiles, T.is_remote))
			{/*...}*/
				enum is_remote = T.is_remote;
			}

		template Aspects (T)
			{/*...}*/
				alias Aspects = Filter!(is_aspect, get_substructs!T);
			}

		template get_capacity (T...)
			if (T.length == 1)
			{/*...}*/
				static if (Filter!(is_numerical_param, __traits(getAttributes, T[0])).length == 1)
					{/*...}*/
						const uint get_capacity = Filter!(is_numerical_param, __traits(getAttributes, T[0]))[0];
					}
				else static if (Filter!(is_numerical_param, __traits(getAttributes, T[0])).length == 0)
					{/*...}*/
						const uint get_capacity = default_capacity;
					}
				else static assert (0);
			}

		struct AspectDecl (T)
			{/*...}*/
				static:
				static assert (is_aspect!T, T.stringof~ ` is not an aspect`);

				enum capacity = get_capacity!T;

				string model ()
					{/*...}*/
						import std.range;
						return fullyQualifiedName!T[0..$ - type.length - 1]
							.retro.findSplitBefore (`.`)[0].text.retro.text;
					}
				string type ()
					{/*...}*/
						return T.stringof;
					}
				string name ()
					{/*...}*/
						import std.string;
						return type.toLower;
					}

				string define_frontend ()
					{/*...}*/
						string code = q{struct } ~type~ q{Front }`{`q{
							alias Base = } ~type~ q{;

							Entity.Id id;
							mixin CompareBy!id;
						};

						foreach (U; Filter!(is_direct, get_resource_decls!T, get_variable_decls!T))
							code ~= q{
								} ~U.declare_data;				

						code ~= q{
							mixin Look!(id,};

						foreach (U; Filter!(Not!is_direct, get_resource_decls!T, get_variable_decls!T))
							code ~= q{
								} ~U.declare_look;				

						return code ~ q{
							);
						}`}`;
					}
				string define_backend ()
					{/*...}*/
						string code = q{struct } ~type~ q{Back }`{`q{
							alias Base = } ~type~ q{;
						};

						foreach (U; Filter!(Not!(Or!(is_direct, is_remote)), get_variable_decls!T))
							code ~= q{
								} ~U.declare_data;

						foreach (U; Filter!(Not!is_remote, get_resource_decls!T))
							code ~= q{
								} ~U.declare_resource;

						return code ~ q{
						}`}`;
					}
				string define_viewing_functions ()
					{/*...}*/
						string code;

						foreach (R; Filter!(Not!is_remote, get_resource_decls!T))
							code ~= q{
							} ~R.define_viewing_function;

						return code;
					}

				string declare_dataories ()
					{/*...}*/
						return q{
							Directory!(} ~type~ q{Front) } ~name~ q{_frontends;
							Directory!(} ~type~ q{Back, Entity.Id) } ~name~ q{_backends;
						};
					}
				string declare_allocators ()
					{/*...}*/
						string code;

						foreach (R; Filter!(Not!is_remote, get_resource_decls!T))
							code ~= q{
							} ~R.declare_allocator;

						return code;
					}

				string initialize_directories ()
					{/*...}*/
						return q{
							} ~name~ q{_frontends = Directory!} ~type~ q{Front (} ~capacity.text~ q{);
							} ~name~ q{_backends = Directory!(} ~type~ q{Back, Entity.Id) (} ~capacity.text~ q{);
						};
					}
				string initialize_allocators ()
					{/*...}*/
						string code;

						foreach (R; Filter!(Not!is_remote, get_resource_decls!T))
							code ~= q{
							} ~R.initialize_allocator;

						return code;
					}
			}
		template get_aspect_decl (T)
			{/*...}*/
				alias get_aspect_decl = AspectDecl!T;
			}
		template get_aspect_decls (T)
			{/*...}*/
				alias get_aspect_decls = staticMap!(get_aspect_decl, Aspects!T);
			}
		struct ResourceDecl (T, string field)
			{/*...}*/
				static assert (is (typeof(__traits(getMember, T, field)) == U[], U), T.stringof~ `.` ~field~ ` is not a resource`);
				static assert (not (is_direct && is_remote));
				// BUG these are being generated for position, velocity and mass as well... wtf?

				static:

				mixin(q{
					enum capacity = get_capacity!(T.} ~field ~q{);
				});

				string aspect ()
					{/*...}*/
						import std.string;
						return T.stringof.toLower;
					}
				string type ()
					{/*...}*/
						import std.range;
						mixin(q{
							return ElementType!(typeof(T.} ~field~ q{)).stringof;
						});
					}
				string name ()
					{/*...}*/
						return field;
					}

				string allocator ()
					{/*...}*/
						return aspect~ q{_} ~field~ q{_memory};
					}

				bool is_direct ()
					{/*...}*/
						return .is_direct!(T, field);
					}
				bool is_remote ()
					{/*...}*/
						return .is_remote!(T, field);
					}

				string viewing_function ()
					{/*...}*/
						return q{view_} ~aspect~ q{_} ~field;
					}
				string define_viewing_function ()
					{/*...}*/
						return q{
							auto } ~viewing_function~ q{ (Entity.Id entity)
							}`{`q{
								return view (} ~aspect~ q{_backends[entity].} ~field~ q{[]); // TODO this is where i left off
							}`}`q{
						};
					}
				string initialize_allocator ()
					{/*...}*/
						return q{
							} ~allocator~ q{ = Allocator!(} ~type~ q{)(} ~capacity.text~ q{);
						};
					}

				string declare_allocator ()
					{/*...}*/
						return q{
							Allocator!(} ~type~ q{) } ~allocator~ q{;
						};
					}
				string declare_resource ()
					{/*...}*/
						return q{Resource!(} ~type~ q{) } ~field~ q{;};
					}
				string declare_data ()
					{/*...}*/
						return q{View!(} ~type~ q{) } ~field~ q{;};
					}
				string declare_look ()
					{/*...}*/
						return q{View!(} ~type~ q{),} `"`~field~`"` q{,};
					}


				static void static_assertions ()
					{/*...}*/
						static assert (mixin(q{
							is (typeof(T.} ~field~ q{) == U[], U)
						}));
					}
			}
		template get_resource_decl (T)
			{/*...}*/
				template get_resource_decl (string member)
					{/*...}*/
						static if (mixin(q{is (typeof(T.} ~member~ q{) == U[], U)}))
							alias get_resource_decl = ResourceDecl!(T, member);
						else enum get_resource_decl = 0;
					}
			}
		template get_resource_decls (T)
			{/*...}*/
				alias get_resource_decls = Filter!(Not!is_numerical_param, 
					staticMap!(get_resource_decl!T, __traits(allMembers, T))
				);
			}
		struct VariableDecl (T, string field)
			{/*...}*/
				static:
				static assert (mixin(q{
					not (is (typeof(T.} ~field~ q{) == U[], U)
						|| is_member_function!(T.} ~field~ q{)
					)
				}), T.stringof~ `.` ~field~ ` is not a variable`);

				string aspect ()
					{/*...}*/
						import std.string;
						return T.stringof.toLower;
					}
				string type ()
					{/*...}*/
						import std.range;
						mixin(q{
							return typeof(T.} ~field~ q{).stringof;
						});
					}
				string name ()
					{/*...}*/
						return field;
					}
				bool is_direct ()
					{/*...}*/
						return .is_direct!(T, field);
					}
				bool is_remote ()
					{/*...}*/
						return .is_remote!(T, field);
					}
				static assert (not (is_direct && is_remote));

				string declare_data ()
					{/*...}*/
						return type~ q{ } ~field~ q{;};
					}
				string declare_look ()
					{/*...}*/
						return type~ q{,} `"`~field~`"` q{,};
					}
			}
		template get_variable_decl (T)
			{/*...}*/
				template get_variable_decl (string member)
					{/*...}*/
						static if (mixin(q{
							not (is (typeof(T.} ~member~ q{) == U[], U)
								|| is_member_function!(T.} ~member~ q{)
							)
						})) alias get_variable_decl = VariableDecl!(T, member);
						else enum get_variable_decl = 0;
					}
			}
		template get_variable_decls (T)
			{/*...}*/
				alias get_variable_decls = Filter!(Not!is_numerical_param, 
					staticMap!(get_variable_decl!T, __traits(allMembers, T))
				);
			}
	}

///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
///////////////////////////
struct Entity
	{/*...}*/
		struct Event
			{/*...}*/
				
			}
		struct EventList
			{/*...}*/
				
			}
		mixin TypeUniqueId;
		this (string name)
			{/*...}*/
				this.name = name;
				id = Id.create;
			}
		string name; // XXX this probably GCs
		Id id;
		mixin CompareBy!id;
	}
///////////////////////////
///////////////////////////
///////////////////////////
import resource.directory;
__gshared Directory!Entity entities;
shared static this ()
	{/*...}*/
		entities = Directory!Entity (128); // XXX
	}
auto model_entity (string name)
	{/*...}*/
		entities.append (Entity (name));
		return entities.back.id;
	}

mixin template PropertyAccessInterface (alias simulation)
	if (is_simulation!(typeof(simulation))		// external
	|| is (typeof(simulation) == typeof(null)))	// internal
	{/*...}*/
		public:
		public {/*primitives}*/
			template observe (Aspect, string property)
				{/*...}*/
					auto observe (Entity.Id entity)
						{/*...}*/
							return _execute_observe!property (_fetch!Aspect (entity));
						}
				}
			template source (Aspect, string property)
				{/*...}*/
					void source ()(Entity.Id entity)
						{/*...}*/
							static if (is_direct!(Aspect, property))
								static assert (0, `cannot remotely source Direct property`);

							else static if (is_remote!(Aspect, property))
								_execute_source!property (_fetch!Aspect (entity), null);
							
							else static if (__traits(compiles, ResourceDecl!(Aspect, property)))
								_execute_source!property (_fetch!Aspect (entity), 
									mixin(q{&} ~_resolve!Aspect~ResourceDecl!(Aspect, property).viewing_function)
								);

							else _execute_source!property (_fetch!Aspect (entity), 
								&_execute_observe!property (_fetch!(Aspect, `back`) (entity))
							);
						}
					void source (F)(Entity.Id entity, F signal)
						{/*...}*/
							static if (is_direct!(Aspect, property))
								static assert (0, `cannot remotely source Direct property`);

							else _execute_source!property (_fetch!Aspect (entity), signal);
						}
				}
			template write (Aspect, string property)
				{/*...}*/
					void write (Args...)(Entity.Id entity, Args args)
						{/*...}*/
							static if (is_direct!(Aspect, property))
								immutable side = `front`;

							else static if (not (is_remote!(Aspect, property)))
								immutable side = `back`;

							else static assert (0, `cannot directly write to Remote property`);

							_execute_write!property (_fetch!(Aspect, side)(entity), args);
						}
				}
		}
		public {/*acceleration}*/
			struct As (Aspect)
				if (is_aspect!Aspect)
				{/*...}*/
					Entity.Id entity;
					alias entity this;

					private mixin(q{
						} ~AspectDecl!Aspect.model~ q{.} ~AspectDecl!Aspect.type~ q{Front* frontend;
						} ~AspectDecl!Aspect.model~ q{.} ~AspectDecl!Aspect.type~ q{Back* backend;
					});

					@disable this ();
					this (Entity.Id entity)
						{/*...}*/
							this.entity = entity;

							if (not (_check!Aspect (entity)))
								_add!Aspect (entity);
						}

					mixin(property_access_interface);

					static {/*code generation}*/
						string property_access_interface ()
							{/*...}*/
								import std.typetuple;

								string code;

								foreach (U; TypeTuple!(get_resource_decls!Aspect, get_variable_decls!Aspect))
									code ~= define_observe!U
										~define_source!U
										~define_write!U;

								return code;
							}
						string define_observe (U)()
								{/*...}*/
									return q{
										auto } ~U.name~ q{ ()
											}`{`q{
												if (frontend is null)
													frontend = &_fetch!(Aspect, `front`)(entity);

												return _execute_observe!}`"`~U.name~`"`q{ (*frontend);
											}`}`q{
									};
								}
						string define_source (U)()
								{/*...}*/
									string signature = q{
										As } ~U.name~ q{ (F)(F signal)
										if (isSomeFunction!F)};

									static if (U.is_direct)
										return signature~ q{
											}`{`q{
												static assert (0, `cannot remotely source Direct property`);
											}`}`q{
										};
									else return signature~ q{
											}`{`q{
												if (frontend is null)
													frontend = &_fetch!(Aspect, `front`)(entity);

												_execute_source!}`"`~U.name~`"`q{ (*frontend, signal);

												return this;
											}`}`q{
									};
								}
						string define_write (U)()
								{/*...}*/
									static if (U.is_direct)
										string side = `front`;
									
									else string side = `back`;

									string signature = q{
										As } ~U.name~ q{ (Args...)(lazy scope Args args)
											if (not (anySatisfy!(isSomeFunction, Args)))};

									static if (U.is_remote)
										return signature~ q{
											}`{`q{
												static assert (0, `cannot directly write to Remote property`);
											}`}`q{
										};
									else return signature~ q{
											}`{`q{
												if (} ~side~ q{end is null)
													} ~side~ q{end = &_fetch!(Aspect, }`"`~side~`"`q{)(entity);

												_execute_write!}`"`~U.name~`"`q{ (*} ~side~ q{end, args);

												return this;
											}`}`q{
									};
								}
					}
				}
		}
		private:
		private {/*...}*/
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
			private {/*implementation}*/
				template _resolve (Aspect)
					{/*...}*/
						static if (interface_is_external)
							static string _resolve ()
								{/*...}*/
									 return q{simulation.get!(} ~AspectDecl!Aspect.model~ q{).};
								}
						else static string _resolve ()
							{/*...}*/
								 return q{};
							}
					}
				template _check (Aspect)
					if (is_aspect!Aspect)
					{/*...}*/
						auto _check (Entity.Id entity)
							{/*...}*/
								immutable resolve = _resolve!Aspect;

								mixin(q{
									return entity in } ~resolve~AspectDecl!Aspect.name~ q{_frontends;
								});
							}
					}
				template _fetch (Aspect, string side = `front`)
					if (is_aspect!Aspect)
					{/*...}*/
						auto ref _fetch (Entity.Id entity)
							in {/*...}*/
								assert (_check!Aspect(entity)); 
							}
							body {/*...}*/
								immutable resolve = _resolve!Aspect;

								mixin(q{
									return } ~resolve~AspectDecl!Aspect.name~ q{_} ~side~ q{ends[entity];
								});
							}
					}
				template _add (Aspect)
					if (is_aspect!Aspect)
					{/*...}*/
						void _add (Entity.Id entity)
							in {/*...}*/
								assert (not (_check!Aspect(entity)));
							}
							body {/*...}*/
								immutable resolve = _resolve!Aspect;
								immutable string aspect = AspectDecl!Aspect.name;
								immutable string Type = AspectDecl!Aspect.model~ q{.} ~AspectDecl!Aspect.type;

								mixin(q{
									} ~resolve~aspect~ q{_frontends.add (} ~Type~ q{Front (entity));
									} ~resolve~aspect~ q{_backends.add (entity, } ~Type~ q{Back.init);
									} ~resolve~ q{source_from_backends!(} ~Type~ q{)(entity);
								});
							}
					}
				template _execute_observe (string property)
					{/*...}*/
						auto ref _execute_observe (Aspect)(ref Aspect fetched)
							{/*...}*/
								mixin(q{
									return fetched.} ~property~ q{;
								});
							}
					}
				template _execute_source (string property)
					{/*...}*/
						void _execute_source (Aspect, U)(ref Aspect fetched, U signal)
							{/*...}*/
								mixin(q{
									fetched.set_} ~property ~ q{ (signal);
								});
							}
					}
				template _execute_write (string property)
					{/*...}*/
						void _execute_write (Aspect, Args...)(ref Aspect fetched, lazy scope Args args)
							if (Args.length > 0)
							{/*...}*/
								import resource.allocator;

								auto ref lhs ()
									{/*...}*/
										mixin(q{
											return fetched.} ~property~ q{;
										});
									}
								static string construction ()
									{/*...}*/
										return q{typeof(lhs ()) (args)};
									}
								static string assignment (string rhs)()
									{/*...}*/
										return `lhs = ` ~rhs;
									}

								static if (__traits(compiles, ResourceDecl!(Aspect.Base, property)))
									{/*...}*/
										immutable resolve = _resolve!(Aspect.Base);
										alias Resource = ResourceDecl!(Aspect.Base, property);

										static if (Resource.is_direct)
											mixin(q{
												lhs = } ~resolve~Resource.allocator~ q{.save (args);
											});
										else mixin(q{
											lhs = } ~resolve~Resource.allocator~ q{.save (args);
										});
									}
								else mixin(q{
									static if (__traits(compiles, } ~assignment!`args[0]`~ q{))
										} ~assignment!`args[0]`~ q{;

									else static if (__traits(compiles, } ~construction~ q{))
										} ~assignment!construction~ q{;

									else static assert (0, `couldn't construct or assign ` ~Args.stringof~ ` to ` ~typeof(lhs()).stringof~ ` ` ~property);
								});
							}
					}
			}
		}
	}

mixin template Simulation (Models...)
	{/*...}*/
		import utils;
		static assert (not(is(typeof(this))), `Simulation must be mixed in at global scope`);

		final class Simulation
			{/*...}*/
				import std.typetuple;
				import std.traits;
				import utils;

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

				alias Services = staticMap!(types_of, mixin(module_level_services));// BUG no services, no map?

				Models models;
				Services services;

				auto get (Model)()
					{/*...}*/
						return models[staticIndexOf!(Model, Models)];
					}

				this ()
					{/*...}*/
						foreach (ref service; mixin(module_level_services))
							{/*survey}*/
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
		mixin PropertyAccessInterface!simulation;
	}
bool is_simulation (T)()
	{/*...}*/
		return __traits(compiles, T.is_simulation);
	}

import services.physics;
import resource.view;
Physics physics;

static if (0)
	{/*...}*/
		mixin Simulation!(Physical);

		auto sq (size_t i)
			{/*...}*/
				return Physical.Position (square[i].x.meters, square[i].y.meters);
			}
		void main ()
			{/*...}*/
				physics = new Physics;
				physics.start; scope (exit) physics.stop;

				simulation = new typeof(simulation);

				auto fred = model_entity (`fred`)
					.As!(Physical.Body)
						.position (Physical.Position (0.meters)) // can assign values
						.velocity (0.meters/second) // can also forward ctor args to assign value
						.mass (10.kilograms)
						.geometry (square (0.5).map!(v => Physical.Position (v)))
						// TODO source it once its been allocated
						/* TODO 
							if this is data, allocate on the backend
							and point the frontend at it
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
