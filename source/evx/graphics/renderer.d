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
				{/*...}*/
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

			void attach (BasicShader shader)
				{/*...}*/
					this.shader = shader;
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

			void attach (BasicShader shader)
				{/*...}*/
					this.shader = shader;
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

				VertexBuffer cards;
				VertexBuffer tex_coords;
				ColorBuffer colors;
			}

		void process (Order order)
			{/*...}*/
				
			}
		void enqueue (Order order)
			{/*...}*/
				
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
	mesh.attach (shader);
	graph.attach (shader);

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
