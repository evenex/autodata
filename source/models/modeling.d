module models.model; // TODO change this stupid name

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
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
			static assert (is(typeof(this)), `mixin requires host struct`);

			// entity ctor/dtor functions
			static assert (__traits(compiles, This.model (Entity.Id.init)),
				`Model must define method model (Entity.Id)`
			);
			static assert (__traits(compiles, This.release (Entity.Id.init)),
				`Model must define method release (Entity.Id)`
			);

			static if (0)
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
							assert_stage_defined!q{read_events};
							assert_stage_defined!q{send_queries};
							// communication_stage 
							assert_stage_defined!q{receive_queries};
							assert_stage_defined!q{send_replies};
							// update_stage 
							assert_stage_defined!q{receive_replies};
							assert_stage_defined!q{update};
							// broadcast_stage 
							assert_stage_defined!q{post_events};
						}
				}
		}
		alias This = typeof(this);

		mixin(generate_aspect_structure!This);
		mixin(generate_aspect_constructor!This);

		void preparation_stage ()
			{/*...}*/
				read_events;
				send_queries;
			}
		void communication_stage ()
			{/*...}*/
				receive_queries;
				send_replies;
			}
		void update_stage ()
			{/*...}*/
				receive_replies;
				update;
			}
		void broadcast_stage ()
			{/*...}*/
				post_events;
			}
	}
import services.physics;
pragma (msg, `! `, Aspects!Physical);
pragma (msg, `! `, generate_aspect_constructor!(Physical.Body));

public {/*code generation}*/
	template generate_aspect_structure (T)
		{/*...}*/
			string generate_aspect_structure ()
				{/*...}*/
					string code;

					foreach (U; Aspects!T)
						code ~= q{
							}~AspectDecl!U.define_frontend~q{
							}~AspectDecl!U.define_backend~q{
							}~AspectDecl!U.declare_directories~q{
							}~AspectDecl!U.declare_allocators;

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
}
private {/*code generation}*/
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
			enum capacity = get_capacity!T;

			static string type ()
				{/*...}*/
					return T.stringof;
				}
			static string name ()
				{/*...}*/
					import std.string;
					return type.toLower;
				}

			static string define_frontend ()
				{/*...}*/
					string code = q{struct } ~type~ q{Front }`{`q{
						Entity.Id id;
						mixin CompareBy!id;
					};

					foreach (U; Filter!(is_direct, get_resource_decls!T, get_variable_decls!T))
						code ~= q{
							} ~U.declare_direct;				

					code ~= q{
						mixin Look!(id,};

					foreach (U; Filter!(Not!is_direct, get_resource_decls!T, get_variable_decls!T))
						code ~= q{
							} ~U.declare_indirect;				

					return code ~ q{
						);
					}`}`;
				}
			static string define_backend ()
				{/*...}*/
					string code = q{struct } ~type~ q{Back }`{`;

					foreach (U; Filter!(Not!(Or!(is_direct, is_remote)), get_variable_decls!T))
						code ~= q{
							} ~U.declare_direct;

					foreach (U; Filter!(Not!is_remote, get_resource_decls!T))
						code ~= q{
							} ~U.declare_resource;

					return code ~ q{
					}`}`;
				}

			static string declare_directories ()
				{/*...}*/
					return q{
						Directory!} ~type~ q{Front } ~name~ q{_frontends;
						Directory!(} ~type~ q{Back, Entity.Id) } ~name~ q{_backends;
					};
				}
			static string declare_allocators ()
				{/*...}*/
					string code;

					foreach (R; get_resource_decls!T)
						code ~= q{
						} ~R.declare_allocator;

					return code;
				}

			static string initialize_directories ()
				{/*...}*/
					return q{
						} ~name~ q{_frontends = Directory!} ~type~ q{Front (} ~capacity.text~ q{);
						} ~name~ q{_backends = Directory!(} ~type~ q{Back, Entity.Id) (} ~capacity.text~ q{);
					};
				}
			static string initialize_allocators ()
				{/*...}*/
					string code;

					foreach (R; get_resource_decls!T)
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
			mixin(q{
				enum capacity = get_capacity!(T.} ~field ~q{);
			});

			static string aspect ()
				{/*...}*/
					import std.string;
					return T.stringof.toLower;
				}
			static string type ()
				{/*...}*/
					import std.range;
					mixin(q{
						return ElementType!(typeof(T.} ~field~ q{)).stringof;
					});
				}
			static string allocator ()
				{/*...}*/
					return aspect~ q{_} ~field~ q{_memory};
				}
			static bool is_direct ()
				{/*...}*/
					return .is_direct!(T, field);
				}
			static bool is_remote ()
				{/*...}*/
					return .is_remote!(T, field);
				}
			static assert (not (is_direct && is_remote));

			static string initialize_allocator ()
				{/*...}*/
					return q{
						} ~allocator~ q{ = Allocator!(} ~type~ q{)(} ~capacity.text~ q{);
					};
				}

			static string declare_allocator ()
				{/*...}*/
					return q{
						Allocator!(} ~type~ q{) } ~allocator~ q{;
					};
				}
			static string declare_resource ()
				{/*...}*/
					return q{Resource!(} ~type~ q{) } ~field~ q{;};
				}
			static string declare_direct ()
				{/*...}*/
					return q{View!(} ~type~ q{) } ~field~ q{;};
				}
			static string declare_indirect ()
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
			static string type ()
				{/*...}*/
					import std.range;
					mixin(q{
						return typeof(T.} ~field~ q{).stringof;
					});
				}
			static bool is_direct ()
				{/*...}*/
					return .is_direct!(T, field);
				}
			static bool is_remote ()
				{/*...}*/
					return .is_remote!(T, field);
				}
			static assert (not (is_direct && is_remote));

			static string declare_direct ()
				{/*...}*/
					return type~ q{ } ~field~ q{;};
				}
			static string declare_indirect ()
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
// the As builder basically is a wrapper for a T that exposes only the setters (for source and value)
// and respects the @Remote, @Direct rules
// it can take an Entity.Id or another As builder
struct As (T)
	{/*...}*/
		// generate source setters and initializers from properties
		// how do models provide initializers for @Remote?
		// what about shit like Container.add?
		// mixin shit from T
		Entity.Id entity;
		// for each property in T
		// route a call on that property:
			// default:
				// (& ...) set frontend source
				// (...) set backend value (try implicit conversion, then ctor, then equals)
			// @Direct:
				// (& ...) ERROR
				// (...) set frontend value (^ditto)
			// @Remote:
				// (& ...) set frontend source
				// (...) ERROR
	}
auto as (T)(Entity.Id id)
	{/*...}*/
		return As!(T).init;
	}
auto as (T)(As!T id)
	{/*...}*/
		return As!(T).init;
	}


void main ()
	{/*...}*/
		import services.physics;
		model_entity (`fred`)
			.as!(Physical.Body)
	//			.position (Physical.Position (0.meters)) // start here, use default source
		;
	//			.velocity (0.meters/second) // should be able to just forward ctor args. also special syntax for vectorizing units would be nice
	//			.mass (10.kilograms)
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
