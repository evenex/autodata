module evx.graphics.renderer.graph;

private {/*import}*/
	import std.conv;

	import evx.graphics.renderer.core;

	import evx.graphics.opengl;
	import evx.graphics.color;
	import evx.graphics.shader;
	import evx.graphics.buffer;

	import evx.patterns;
	import evx.math;
}

class GraphRenderer
	{/*...}*/
		mixin Wrapped!Implementation;
		mixin RenderOps!wrapped;

		this ()
			{/*...}*/
				this.node = this.node_geometry;
			}

		struct Implementation
			{/*...}*/
				BasicShader shader;
				VertexBuffer node;

				struct Order
					{/*...}*/
						mixin Builder!(ChainBy.address,
							Color,  `node_color`,
							Color,  `edge_color`,
							Color,  `color`,
							double, `node_radius`,
							Geometry, `geometry`,
						);

						void defaults ()
							{/*...}*/
								node_color = yellow;
								edge_color = blue;
								node_radius = 0.02;
							}

						mixin RenderOrder!GraphRenderer;
					}

				auto ref draw (Geometry geometry)
					{/*...}*/
						Order order;

						order.geometry = geometry;

						return order;
					}

				void render (Order order)
					{/*...}*/
						void draw_nodes ()
							{/*...}*/
								node.bind;
								shader.position (node)
									.color (order.node_color.vector)
									.scale (order.scale * order.node_radius.to!float);

								foreach (v; order.geometry.vertices[])
									{/*...}*/
										shader.translation (order.translation + v);

										gl.DrawArrays (GL_TRIANGLE_FAN, 0, node.length.to!int); // BUG what to do about setting slices as draw arguments??? what happens when i want set slices of gl arrays as shader parameters?
									}
							}
						void draw_edges ()
							{/*...}*/
								order.geometry.bind;

								with (order)
								shader.position (geometry.vertices)
									.color (order.edge_color.vector);

								with (order)
								gl.DrawElements (GL_LINES, geometry.indices.length.to!int, GL_UNSIGNED_SHORT, null);
							}

						draw_edges;
						draw_nodes;
					}

				auto node_geometry ()
					{/*...}*/
						return circle!36;
					}
			}
	}
