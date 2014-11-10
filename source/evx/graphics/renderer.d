module evx.graphics.renderer;

private {/*imports}*/
	import std.conv;
	import std.array;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.shader;

	import evx.patterns;
	import evx.math;
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

mixin template RenderOrder (Renderer)
	{/*...}*/
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

class MeshRenderer
	{/*...}*/
		enum Mode {solid, wireframe, overlay}

		struct Order
			{/*...}*/
				mixin Builder!(
					Color,   `color`,
					Mode,    `mode`,
				);

				public:
				mixin RenderOrder!MeshRenderer;
				public {/*ctor}*/
					this (MeshRenderer renderer, Geometry mesh)
						{/*...}*/
							this.renderer = renderer;
							this.mesh = mesh;

							color = magenta (0.5);
						}
				}
				private:
				private {/*data}*/
					Geometry mesh;
				}
			}

		public:
		public {/*rendering}*/
			auto draw (Geometry mesh)
				in {/*...}*/
					assert (shader);
				}
				body {/*...}*/
					return Order (this, mesh);
				}

			void process ()
				{/*...}*/
					shader.activate;

					foreach (order; orders[])
						process (order);

					orders = null;
				}

			void process (Order order)
				{/*...}*/
					order.mesh.bind; // REFACTOR

					with (order)
					shader.position (mesh.vertices) // REFACTOR
						.color (color) // REFACTOR
						.translation (translation) // REFACTOR
						.rotation (rotation) // REFACTOR
						.scale (order.scale);  // BUG why do i need to specify order here?

					void draw_solid ()
						{/*...}*/
							with (order)
							gl.DrawElements (GL_TRIANGLES, mesh.indices.length.to!int, GL_UNSIGNED_SHORT, null);
						}
					void draw_wireframe ()
						{/*...}*/
							with (order)
							foreach (i; 0..mesh.indices.length/3)
								gl.DrawElements (GL_LINE_LOOP, 3, GL_UNSIGNED_SHORT, cast(void*)(3*i*ushort.sizeof));
						}

					with (Mode) final switch (order.mode)
						{/*...}*/
							case solid:
								draw_solid;
								break;
							case wireframe:
								draw_wireframe;
								break;
							case overlay:
								draw_solid;
								draw_wireframe;
								break;
						}
				}
		}

		private:
		private {/*data}*/
			BasicShader shader;
			Order[] orders;
		}
		package {/*ops}*/
			void enqueue (Order order)
				{/*...}*/
					orders ~= order;
				}
		}
	}

class GraphRenderer
	{/*...}*/
		struct Order
			{/*...}*/
				mixin Builder!(
					Color,  `node_color`,
					Color,  `edge_color`,
					Color,  `color`,
					double, `node_radius`,
				);

				mixin RenderOrder!GraphRenderer;

				public:
				public {/*ctor}*/
					this (GraphRenderer renderer, Geometry graph)
						{/*...}*/
							this.renderer = renderer;
							this.graph = graph;

							node_color = yellow;
							edge_color = blue;
							node_radius = 0.02;
						}
				}
				private:
				private {/*data}*/
					Geometry graph;
				}
			}

		public:
		public {/*rendering}*/
			auto draw (Geometry graph)
				{/*...}*/
					return Order (this, graph);
				}

			void process ()
				{/*...}*/
					shader.activate;

					foreach (order; orders[])
						process (order);

					orders = null;
				}

			void process (Order order)
				{/*...}*/
					void draw_nodes ()
						{/*...}*/
							node.bind;
							shader.position (node)
								.color (order.node_color.vector)
								.scale (order.scale * order.node_radius.to!float);

							foreach (v; order.graph.vertices[])
								{/*...}*/
									shader.translation (order.translation + v);

									gl.DrawArrays (GL_TRIANGLE_FAN, 0, node.length.to!int); // BUG what to do about setting slices as draw arguments??? what happens when i want set slices of gl arrays as shader parameters?
								}
						}
					void draw_edges ()
						{/*...}*/
							order.graph.bind;

							with (order)
							shader.position (graph.vertices)
								.color (order.edge_color.vector)
								.translation (translation)
								.rotation (rotation)
								.scale (order.scale); // BUG why do i need to specify order here?

							with (order)
							gl.DrawElements (GL_LINES, graph.indices.length.to!int, GL_UNSIGNED_SHORT, null);
						}

					draw_edges;
					draw_nodes;
				}
		}
		public {/*ctor}*/
			this ()
				{/*...}*/
					this.node = node_geometry;
				}
		}
		private:
		private {/*data}*/
			BasicShader shader;
			Order[] orders;
			VertexBuffer node;

			auto node_geometry ()
				{/*...}*/
					return circle!36;
				}
		}
		protected {/*ops}*/
			void enqueue (Order order)
				{/*...}*/
					orders ~= order;
				}
		}
	}

import evx.graphics.text;

class TextRenderer
	{/*...}*/
		struct Order
			{/*...}*/
				Text text;

				mixin RenderOrder!TextRenderer;

				this (TextRenderer renderer, Text text)
					{/*...}*/
						this.renderer = renderer;
						this.text = text;
					}
			}

		auto draw (Text text) // REFACTOR
			{/*...}*/
				return Order (this, text);
			}

		void process ()
			{/*...}*/
				//shader.activate;
			}
		void process (Order order)
			{/*...}*/
				
			}
		void enqueue (Order order)
			{/*...}*/
				
			}

		TextShader shader;
	}

alias TextShader = ShaderProgram!(
	VertexShader!(
		Input!(
			fvec[], `position`,		Init!(0,0),
			fvec[], `texture_coords`,
			Color[], `glyph_color`, Init!(1,1,0,1),
		), 
		Output!(
			Color[], `color`,
			fvec[], `tex_coords`,
		), q{
			gl_Position.xy = position;
			color = glyph_color;
			tex_coords = texture_coords;
		}
	),
	FragmentShader!(
		Input!(
			Color[], `color`,
			fvec[], `tex_coords`,
			Texture, `tex`,
		), 
		Output!(
			Color[], `frag_color`,
		), q{
			frag_color = vec4 (color.rgb, color.a * texture (tex, tex_coords).r);
		}
	)
);

pragma(msg, TextShader.code);

void maain ()
	{/*...}*/
		import evx.graphics.display;
		scope gfx = new Display;

		auto f = Font (200);
		scope t = new Text (f, gfx, `hello`);

		scope s = new TextShader;

		auto triangle = [fvec (1), fvec(0), fvec(1,0)];

		gfx.attach (s);

								std.stdio.writeln (0);
		t.bind;
								std.stdio.writeln (1);
		auto c = t.cards[].mean;
								std.stdio.writeln (2);
		t.cards[] = t.cards[].map!(v => v - c);
								std.stdio.writeln (3);
		t[0..$/3].color = red;
								std.stdio.writeln (4);
		t[$/3..2*$/3].color = white;
								std.stdio.writeln (5);
		t[2*$/3..$].color = blue;
								std.stdio.writeln (6);
		//t.bind;
								std.stdio.writeln (7);

								std.stdio.writeln (8);
								std.stdio.writeln (9);
								std.stdio.writeln (10);
		t.tex_coords.dirty = true;
								std.stdio.writeln (11);

		s.position (t.cards)
			.glyph_color (t.colors)
			.texture_coords (t.tex_coords)
			.rotation (float(π/4))
			.translation (0.25.vec)
			.scale (float (0.5));
								std.stdio.writeln (12);

		foreach (i; 0..t.length.to!int)
			gl.DrawArrays (GL_TRIANGLE_FAN, 4*i, 4); 
		
		gfx.render;

		import core.thread;
		Thread.sleep (3000.msecs);
	}

auto connect_services (T...)(T services)
	{/*...}*/
		return Services!T (services);
	}
import std.typetuple;
struct Services (T...)
	{/*...}*/
		T services;

		auto to_clients (U...)(U clients)
			{/*...}*/
				foreach (ref client; clients)
					{/*...}*/
						alias Client = typeof(client);
						
						foreach (member; __traits(allMembers, Client))
							static if (__traits(compiles, typeof(__traits(getMember, Client, member))))
								{/*...}*/
									enum i = staticIndexOf!(typeof(__traits(getMember, Client, member)), T);

									static if (i >= 0)
										__traits(getMember, client, member) = services[i];
								}
					}
			}
	}

unittest {/*...}*/
	import evx.graphics;//	import evx.graphics.display;
	import evx.math;//	import evx.math.overloads;
	import core.thread;

	alias map = evx.math.functional.map;

	scope display = new Display;
	scope shader = new BasicShader;
	scope mesh = new MeshRenderer;
	scope graph = new GraphRenderer;

	display.attach (shader);
	connect_services (shader).to_clients (graph, mesh);

	auto geometry = Geometry (
		VertexBuffer (circle),
		IndexBuffer ([0,1,2, 2,1,4, 6,7,5, 9,5,3, 2,9,12])
	);

	foreach (i; 0..80)
		{/*...}*/
			mesh.draw (geometry)
				.color (grey (0.1))
				.rotate (i*π/24)
				.enqueued;

			mesh.draw (geometry)
				.color (white (0.1))
				.rotate (-i*π/24)
				.enqueued;

			mesh.process;

			mesh.draw (geometry)
				.color (blue (0.1))
				.rotate ((12+i)*π/24)
				.immediately;

			graph.draw (geometry)
				.node_color (white (gaussian) * cyan (gaussian))
				.immediately;

			geometry.indices[] = ℕ[0..geometry.indices.length].map!(i => (24 * gaussian).abs.round.clamp (interval (0, 23)));

			// STICKING POINT: getting all the order variables loaded into the shader... sometimes they get missed, and the shader doesn't draw
			// STICKING POINT: remembering to bind buffers
			// STICKING POINT: attaching shit to other shit
			// other than that, pretty confortable...

			display.render;

			Thread.sleep (20.msecs);
		}
}
