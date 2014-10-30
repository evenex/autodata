module evx.graphics.renderer;

private {/*imports}*/
	import std.conv;

	import evx.graphics.opengl;
	import evx.graphics.buffer;
	import evx.graphics.color;
	import evx.graphics.shader.repo;

	import evx.patterns.builder;
}

struct Geometry
	{/*...}*/
		VertexBuffer vertices;
		IndexBuffer indices;

		void bind ()
			{/*...}*/
				vertices.buffer.bind;
				indices.buffer.bind;
			}
	}

class MeshRenderer
	{/*...}*/
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
					order.mesh.bind;

					with (order)
					shader.position (mesh.vertices)
						.color (color.vector.each!(to!float))
						.translation (translate)
						.rotation (rotate)
						.scale (scale);

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
		public {/*order definition}*/
			enum Mode {solid, wireframe, overlay}

			struct Order
				{/*...}*/
					mixin Builder!(
						Color,   `color`,
						vec,     `translate`,
						double,  `rotate`,
						double,  `scale`,
						Mode,    `mode`,
					);

					public:
					public {/*fulfillment}*/
						void enqueued ()
							{/*...}*/
								renderer.enqueue (this);
							}
						void immediately ()
							{/*...}*/
								renderer.process (this);
							}
					}
					public {/*ctor}*/
						this (MeshRenderer renderer, Geometry mesh)
							{/*...}*/
								this.renderer = renderer;
								this.mesh = mesh;

								color = magenta (0.5);
								translate = 0.vec;
								rotate = 0;
								scale = 1;
							}
					}
					private:
					private {/*data}*/
						Geometry mesh;
						MeshRenderer renderer;
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
					import evx.graphics.shader.program; // TODO all this just to get Cvec... belongs elsewhere

					void draw_nodes ()
						{/*...}*/
							node.bind;
							shader.position (node)
								.color (order.node_color.vector.to!Cvec)
								.scale (order.scale * order.node_radius.to!float);

							foreach (v; order.graph.vertices[])
								{/*...}*/
									shader.translation (order.translate + v);

									gl.DrawArrays (GL_TRIANGLE_FAN, 0, node.length.to!int); // BUG what to do about setting slices as draw arguments??? what happens when i want set slices of gl arrays as shader parameters?
								}
						}
					void draw_edges ()
						{/*...}*/
							order.graph.bind;

							with (order)
							shader.position (graph.vertices)
								.color (order.edge_color.vector.to!Cvec)
								.translation (translate)
								.rotation (rotate)
								.scale (scale);

							with (order)
							gl.DrawElements (GL_LINES, graph.indices.length.to!int, GL_UNSIGNED_SHORT, null);
						}

					draw_edges;
					draw_nodes;
				}
		}
		public {/*order definition}*/
			struct Order
				{/*...}*/
					mixin Builder!(
						Color,  `node_color`,
						Color,  `edge_color`,
						Color,  `color`,
						vec,    `translate`,
						double, `rotate`,
						double, `scale`,
						double, `node_radius`,
					);

					public:
					public {/*fulfillment}*/
						void enqueued ()
							{/*...}*/
								renderer.enqueue (this);
							}

						void immediately ()
							{/*...}*/
								renderer.process (this);
							}
					}
					public {/*ctor}*/
						this (GraphRenderer renderer, Geometry graph)
							{/*...}*/
								this.renderer = renderer;
								this.graph = graph;

								node_color = yellow;
								edge_color = blue;
								node_radius = 0.02;
								rotate = 0;
								scale = 1;
								translate = 0.vec;
							}
					}
					private:
					private {/*data}*/
						GraphRenderer renderer;
						Geometry graph;
					}
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

import evx.math;
mixin(MathToolkit!());
static if (0) void main ()
	{/*...}*/
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

				geometry.indices[] = ℕ[0..geometry.indices.length].map!(i => (24 * gaussian).abs.round.clamp (0,23));

				// STICKING POINT: getting all the order variables loaded into the shader... sometimes they get missed, and the shader doesn't draw
				// STICKING POINT: remembering to bind buffers
				// STICKING POINT: attaching shit to other shit
				// other than that, pretty confortable...

				display.render;

//				import core.thread;
				Thread.sleep (20.msecs);
			}
	}
