module evx.graphics.renderer.core;

private {/*imports}*/
	import std.conv;
	import std.array;
	import std.typetuple;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.shader;

	import evx.traits;
	import evx.math;
}

mixin template RenderOrder (Renderer)
	{/*...}*/
		import evx.math;

		enum render_order;

		Renderer renderer;

		this (Renderer renderer)
			{/*...}*/
				this.renderer = renderer;

				static if (__traits(compiles, defaults ()))
					defaults;
			}
		
		void immediately ()
			{/*...}*/
				renderer.process (this);

				auto index = (&this - renderer.orders.ptr).to!size_t / this.sizeof;

				renderer.orders[index..$-1] = renderer.orders[index+1..$];
				renderer.orders.length = renderer.orders.length - 1;
			}
		
		mixin AffineTransform;

		GLuint render_target;
	}

template GraphicsServices (Renderer)
	{/*...}*/
		string code ()
			{/*...}*/
				string[] shaders;
				string[] renderers;

				foreach (member; __traits (allMembers, Renderer))
					static if (__traits(getProtection, __traits(getMember, Renderer, member)) == `public`)
						{/*...}*/
							enum type = q{typeof(Renderer.} ~member~ q{)};

							mixin(q{
								static if (__traits(compiles, mixin(type)))
									alias T = } ~type~ q{;
								else alias T = void;
							});

							static if (is(T: ShaderProgram!(V,F), V,F))
								shaders ~= `"` ~member~ `"`;
							else static if (is(T.RenderTraits))
								renderers ~= `"` ~member~ `"`;
						}

				return q{
					alias Shaders = TypeTuple!(} ~shaders.join (`, `)~ q{);
					alias Renderers = TypeTuple!(} ~renderers.join (`, `)~ q{);
					alias All = TypeTuple!(Shaders, Renderers);
				};
			}
			
		mixin(code);
	}

struct RenderTraits (Renderer)
	{/*...}*/
		private __gshared Renderer renderer;

		static if (is(Renderer.Order))
			alias OrderType = Renderer.Order;
		else alias OrderType = void;

		//alias ShaderList = ShaderType, 'identifier'
		mixin Traits!(
			`has_order`, q{static assert (is(Renderer.Order.render_order));},
			`can_render`, q{renderer.render (Renderer.Order.init);},
			`has_shader`, q{static assert (GraphicsServices!Renderer.Shaders.length == 1);},
			`has_renderers`, q{static assert (GraphicsServices!Renderer.Renderers.length > 0);},
		);
	}

mixin template RenderOps (alias renderer)
	{/*...}*/
		static {/*analysis}*/
			alias RenderTraits = .RenderTraits!(typeof(renderer));
			alias GraphicsServices = .GraphicsServices!(typeof(renderer));
			alias Order = RenderTraits.OrderType;

			mixin template require (string trait)
				{/*...}*/
					alias require = RenderTraits.require!(typeof(this), trait, RenderOps);
				}

			mixin require!`has_order`;
			mixin require!`can_render`;

			static assert (GraphicsServices.Shaders.length < 2, `only one shader per renderer currently supported`);
		}
		static {/*dependencies}*/
			import evx.misc.services;
		}

		mixin AliasThis!renderer;

		Order[] orders;

		Order* draw ()
			{/*...}*/
				orders ~= Order (this);

				return &orders[$-1];
			}
		Order* draw (Args...)(Args args)
			in {/*...}*/
				static assert (is (typeof(renderer.draw (args)) == Order),
					typeof(this).stringof~ `: `
					~typeof(renderer).stringof~ `.draw (` ~Args.stringof~ `) must return Order, not ` 
					~typeof(renderer.draw (args)).stringof
				);
			}
			body {/*...}*/
				orders ~= renderer.draw (args);

				orders[$-1].renderer = this;

				return &orders[$-1];
			}

		void process ()
			{/*...}*/
				static if (RenderTraits.has_shader)
					shader.activate;

				foreach (ref order; orders[])
					process (order);

				orders = null;
			}
		void process (ref Order order)
			in {/*...}*/
				static if (RenderTraits.has_shader)
					assert (this.shader !is null, `shader not connected`);

				assert (&order >= orders.ptr && &order < orders.ptr + orders.length,
					`Order at ` ~(&order).to!string~ ` is outside of order queue (`
					~orders.ptr.to!string~ `, ` ~(orders.ptr + orders.length).to!string~ `)`
					` it is an error to store render orders as values, they must be accessed`
					` through references or pointers`
				);
			}
			body {/*...}*/
				// TODO assert shader activated?
				static if (RenderTraits.has_shader)
					{/*...}*/
						shader.activate;// TEMP
						shader.transform (order);
					}
				
				renderer.render (order);
			}

		mixin(attachments);

		private static attachments ()
			{/*...}*/
				string code;

				foreach (service; GraphicsServices.All)
					code ~= q{
						void attach (typeof(this.} ~service~ q{) s)
							}`{`q{
								this.} ~service~ q{ = s;
							}`}`q{
					};


				return code;
			}
	}
