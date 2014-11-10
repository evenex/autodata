module evx.graphics.renderer.mesh;

private {/*import}*/
	import std.conv;

	import evx.graphics.renderer.core;

	import evx.graphics.color;
	import evx.graphics.shader;
	import evx.graphics.opengl;

	import evx.patterns;
}

class MeshRenderer
	{/*...}*/
		enum Mode {solid, wireframe, overlay}

		mixin Wrapped!Implementation;
		mixin RenderOps!wrapped;

		void set_shader (BasicShader shader)
			{/*...}*/
				this.shader = shader;
			}

		struct Implementation
			{/*...}*/
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

				BasicShader shader;
			}
	}
