module evx.graphics.renderer.core;

private {/*imports}*/
	import std.conv;
	import std.array;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.shader;

	import evx.patterns;
	import evx.math;
	import evx.misc.services;
}

struct Geometry // REFACTOR
	{/*...}*/
		VertexBuffer vertices;
		IndexBuffer indices;

		void bind ()
			{/*...}*/
				vertices.buffer.bind;
				indices.buffer.bind;
			}
	}


import evx.traits;
import evx.patterns;
mixin template RenderOrder (Renderer)
	{/*...}*/
		import evx.math;

		enum render_order;

		Renderer renderer;
		
		void enqueued ()
			{/*...}*/
				renderer.enqueue (this);
			}
		void immediately ()
			{/*...}*/
				renderer.process (this);
			}

		mixin AffineTransform;
	}

struct RenderTraits (T)
	{/*...}*/
		private __gshared T renderer;

		static if (is(T.Order))
			alias OrderType = T.Order;
		else alias OrderType = void;

		mixin Traits!(
			`has_order`, q{static assert (is(T.Order.render_order));},
			`has_shader`, q{static assert (is(typeof(renderer.shader): ShaderProgram!(V,F), V,F));},
			`can_process`, q{renderer.process (T.Order.init);}
		);
	}

mixin template RenderOps (alias renderer)
	{/*...}*/
		alias RenderTraits = .RenderTraits!(typeof(renderer));
		alias Order = RenderTraits.OrderType;

		mixin AliasThis!renderer;

		Order[] orders;

		auto draw (Args...)(Args object)
			{/*...}*/
				return Order (this, object);
			}
		void process ()
			{/*...}*/
				static if (RenderTraits.has_shader)
					shader.activate;

				foreach (order; orders[])
					process (order);

				orders = null;
			}
		void process (Order order)
			{/*...}*/
				renderer.process (order);
			}
		void enqueue (Order order)
			{/*...}*/
				orders ~= order;
			}
	}
