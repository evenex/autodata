module evx.graphics.renderer.mesh;

private {/*import}*/
	import std.conv;

	import evx.graphics.renderer.core;

	import evx.graphics.buffer;
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

		struct Implementation
			{/*...}*/
				struct Order
					{/*...}*/
						mixin Builder!(
							Color,   `color`,
						);

						Geometry geometry;
						Mode mode;

						auto ref wireframe (Geometry geometry)
							{/*...}*/
								this.geometry = geometry;

								this.mode = Mode.wireframe;

								return this;
							}
						auto ref solid (Geometry geometry)
							{/*...}*/
								this.geometry = geometry;

								this.mode = Mode.solid;

								return this;
							}
						auto ref overlay (Geometry geometry)
							{/*...}*/
								this.geometry = geometry;

								this.mode = Mode.overlay;

								return this;
							}

						void defaults ()
							{/*...}*/
								color = magenta;
							}

						mixin RenderOrder!MeshRenderer;
					}

				void render (Order order)
					{/*...}*/
						with (order)
						shader.position (geometry.vertices)
							.color (color);

						void draw_solid ()
							{/*...}*/
								with (order)
								gl.DrawElements (GL_TRIANGLES, geometry.indices.length.to!int, GL_UNSIGNED_SHORT, null);
							}
						void draw_wireframe ()
							{/*...}*/
								with (order)
								foreach (i; 0..geometry.indices.length/3)
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
