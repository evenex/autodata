module models.model;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import utils;
import math;


/* if aspect and resource capacities are not specified, default to this */
enum default_capacity = 2^^10;

enum Aspect;
enum Direct;

struct Entity
	{/*...}*/
		struct Event
			{/*...}*/
				
			}
		struct EventList
			{/*...}*/
				
			}
		mixin TypeUniqueId;
	}

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

			static assert (__traits(compiles, This.model (Entity.Id.init)),
				`Model must define method model (Entity.Id)`
			);
			static assert (__traits(compiles, This.release (Entity.Id.init)),
				`Model must define method release (Entity.Id)`
			);
		}
		alias This = typeof(this);

		mixin(generate_aspect_structure!This);
		mixin(generate_aspect_constructor!This);
	}

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
	template is_aspect (T)
		{/*...}*/
			enum is_aspect = staticIndexOf!(Aspect, __traits(getAttributes, T)) > -1;
		}
	template is_direct (T, string field)
		{/*...}*/
			enum is_direct = staticIndexOf!(Direct, __traits(getAttributes, __traits(getMember, T, field))) > -1;
		}
	template is_direct (T)
		if (__traits(compiles, T.is_direct))
		{/*...}*/
			enum is_direct = T.is_direct;
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
						auto opCmp (ref const } ~type~ q{Front that) const }`{`q{
							return compare (this.id, that.id);
						}`}`q{
					};

					foreach (U; Filter!(is_direct, get_resource_decls!T, get_variable_decls!T))
						code ~= q{
							} ~U.declare_direct;				

					code ~= q{
						mixin Look!(id,};

					foreach (U; Filter!(templateNot!is_direct, get_resource_decls!T, get_variable_decls!T))
						code ~= q{
							} ~U.declare_indirect;				

					return code ~ q{
						);
					}`}`;
				}
			static string define_backend ()
				{/*...}*/
					string code = q{struct } ~type~ q{Back }`{`;

					foreach (U; Filter!(templateNot!is_direct, get_variable_decls!T))
						code ~= q{
							} ~U.declare_direct;

					foreach (U; get_resource_decls!T)
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
			alias get_resource_decls = Filter!(templateNot!is_numerical_param, 
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
			alias get_variable_decls = Filter!(templateNot!is_numerical_param, 
				staticMap!(get_variable_decl!T, __traits(allMembers, T))
			);
		}
}

///////////////////////////
void main ()
	{/*...}*/
		import services.physics;
		Physical.BodyFront P;
		vec x = 0.vec;
		P.set_velocity (&x);

		import std.stdio;
		writeln (P.velocity);
	}
