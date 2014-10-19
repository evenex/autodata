module evx.graphics.renderer;

private {/*imports}*/
	import evx.graphics.buffer;
}

enum GeometryEditing {disabled = false, enabled = true}

static if (0)
public {/*graph}*/
	class GraphRenderer (Policies...)
		{/*...}*/
			static {/*policies}*/
				mixin PolicyAssignment!(
					DefaultPolicies!(
						`graph_editable`, GeometryEditing.disabled,
					),
					Policies
				);
				static assert (not!graph_editable, `editable graph unimplemented`);
			}

			private struct Graph
				{/*...}*/
					mixin TypeUniqueId;

					vec[] vertices;
					GeometryBuffer buffer;
				}
			private VertexBuffer node;

			public:
			public {/*+/- graphs}*/
				auto add (R,S)(R vertices, S edge_indices)
					in {/*...}*/
						assert (edge_indices.length % 2 == 0);
					}
					body {/*...}*/
						auto id = Graph.Id.create;

						Graph graph = {vertices: vertices.map!(to!vec).array};
						graph.buffer = GeometryBuffer (graph.vertices, edge_indices);

						assets[id] = graph;

						return id;
					}
				auto remove (Graph.Id graph)
					{/*...}*/
						assets[graph].buffer = null;

						assets.remove (graph);
					}
			}
			public {/*rendering}*/
				auto draw (Graph.Id graph)
					{/*...}*/
						return Order (this).graph (assets[graph]);
					}

				void process ()
					{/*...}*/
						shader.activate;

						foreach (order; orders[])
							{/*...}*/
								void draw_nodes () // upload one circle at the beginning, then just apply scaling and shit to it
									{/*...}*/
										node.bind;

										foreach (v; order.graph.vertices[])
											{/*...}*/
												set_uniform (shader.translation, order.translate + v.to!fvec);
												set_uniform (shader.scale, order.scale * order.node_radius.to!float); // XXX we may have to public-access these or something...

												gl.DrawArrays (GL_TRIANGLE_FAN, 0, node.length);
											}
									}
								void draw_edges ()
									{/*...}*/
										order.graph.buffer.bind;

										with (order)
										gl.DrawElements (GL_LINES, graph.buffer.indices.length, GL_UNSIGNED_SHORT, null);
									}

								order.color = order.edge_color;
								shader.set_uniforms (order.to_shader);
								draw_edges;

								order.color = order.node_color;
								shader.set_uniforms (order.to_shader);
								draw_nodes;
							}
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
							Graph,  `graph`,
						);

						public:
						public {/*fulfillment}*/
							void enqueued ()
								{/*...}*/
									renderer.enqueue (this);
								}

							void immediately ()
								{/*...}*/
									assert (0, `immediate mode unimplemented`);
								}
						}
						public {/*ctor}*/
							this (GraphRenderer renderer)
								{/*...}*/
									this.renderer = renderer;

									node_color = yellow;
									edge_color = blue;
									node_radius = 0.02;
									rotate = 0;
									scale = 1;
									translate = 0.vec;
								}
						}
						private:
						private {/*conversion}*/
							BasicShader.Parameters to_shader ()
								{/*...}*/
									return BasicShader.Parameters ()
										.color (this.color.vector.to!Cvec)
										.translation (this.translate.to!fvec)
										.rotation (this.rotate)
										.scale (this.scale);
								}
						}
						private {/*data}*/
							GraphRenderer renderer;
						}
					}
			}
			private:
			private {/*data}*/
				BasicShader shader;
				Graph[Graph.Id] assets;
				Appendable!(Order[]) orders;
			}
			protected {/*ops}*/
				void enqueue (Order order)
					{/*...}*/
						orders ~= order;
					}

				void attach (BasicShader shader)
					{/*...}*/
						this.shader = shader;

						this.node = VertexBuffer (node_geometry);
					}
			}

			auto node_geometry ()
				{/*...}*/
					return circle!36;
				}
		}
}
static if (0)
public {/*mesh}*/
	class MeshRenderer (Policies...)
		{/*...}*/
			static {/*policies}*/
				mixin PolicyAssignment!(
					DefaultPolicies!(
						`mesh_editable`, GeometryEditing.disabled,
					),
					Policies
				);
				static assert (not!mesh_editable, `editable mesh unimplemented`);
			}

			private struct Mesh
				{/*...}*/
					mixin TypeUniqueId;

					GeometryBuffer buffer;
				}

			public:
			public {/*+/- meshes}*/
				auto add (R,S)(R vertices, S triangle_corner_indices)
					in {/*...}*/
						assert (triangle_corner_indices.length % 3 == 0);
					}
					body {/*...}*/
						auto id = Mesh.Id.create;

						assets[id] = Mesh (GeometryBuffer (vertices, triangle_corner_indices));

						return id;
					}
				auto remove (Mesh.Id mesh)
					{/*...}*/
						assets[mesh].buffer = null;

						assets.remove (mesh);
					}
			}
			public {/*rendering}*/
				auto draw (Mesh.Id mesh)
					{/*...}*/
						return Order (this).mesh (assets[mesh]);
					}

				void process ()
					{/*...}*/
						shader.activate;

						foreach (order; orders[])
							{/*...}*/
								order.mesh.buffer.bind;
								shader.set_uniforms (order.to_shader);

								void draw_solid ()
									{/*...}*/
										with (order)
										gl.DrawElements (GL_TRIANGLES, mesh.buffer.indices.length, GL_UNSIGNED_SHORT, null);
									}
								void draw_wireframe ()
									{/*...}*/
										with (order)
										foreach (i; 0..mesh.buffer.indices.length/3)
											gl.DrawElements (GL_LINE_LOOP, 3, GL_UNSIGNED_SHORT, (3*i*ushort.sizeof).to!size_t.voidptr);
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
			}
			public {/*order definition}*/
				enum Mode {solid, wireframe, overlay}

				struct Order
					{/*...}*/
						mixin Builder!(
							Color,  `color`,
							vec,    `translate`,
							double, `rotate`,
							double, `scale`,
							Mesh,   `mesh`,
							Mode,   `mode`,
						);

						public:
						public {/*fulfillment}*/
							void enqueued ()
								{/*...}*/
									renderer.enqueue (this);
								}
							void immediately ()
								{/*...}*/
									assert (0, `immediate mode unimplemented`);
								}
						}
						public {/*ctor}*/
							this (MeshRenderer renderer)
								{/*...}*/
									this.renderer = renderer;

									color = magenta (0.5);
									translate = 0.vec;
									rotate = 0;
									scale = 1;
								}
						}
						private:
						private {/*conversion}*/
							BasicShader.Parameters to_shader ()
								{/*...}*/
									return BasicShader.Parameters ()
										.color (this.color.vector.to!Cvec)
										.translation (this.translate.to!fvec)
										.rotation (this.rotate)
										.scale (this.scale);
								}
						}
						private {/*data}*/
							MeshRenderer renderer;
						}

					}
			}
			private:
			private {/*data}*/
				BasicShader shader;
				Mesh[Mesh.Id] assets;
				Appendable!(Order[]) orders;
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
}
