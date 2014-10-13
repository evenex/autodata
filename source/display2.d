module evx.display2;

private {/*imports}*/
	private {/*std}*/
		import std.conv;
		import std.file;
		import std.range;
		import std.string;
		import std.array;
		import std.typetuple;
		import std.traits;
		import std.typecons;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.colors;
		import evx.math;
		import evx.meta;
		import evx.traits;
		import evx.arrays;
	}
	private {/*opengl}*/
		import derelict.glfw3.glfw3;
		import derelict.opengl3.gl3;
	}

	mixin(MathToolkit!());
}

import evx.set;
import evx.display;
import opengl;

mixin(MathToolkit!());

enum glsl_version = 420;

alias Cvec = Vector!(4, float);

enum GeometryEditing {disabled = false, enabled = true}

public:
public {/*buffers}*/
	private {/*base}*/
		mixin template GLBuffer (T, GLenum target, GLenum usage = GL_STATIC_DRAW)
			{/*...}*/
				GLuint buffer_object = 0;
				GLsizei length;

				this (R)(R data)
					{/*...}*/
						upload (data);
					}

				void initialize ()
					in {/*...}*/
						assert (buffer_object == 0, `buffer_object already initialized`);
					}
					body {/*...}*/
						gl.GenBuffers (1, &buffer_object);
					}

				void bind ()
					in {/*...}*/
						assert (buffer_object > 0, `buffer_object uninitialized`);
					}
					body {/*...}*/
						gl.BindBuffer (target, buffer_object);

						static if (is_vector!T)
							{/*...}*/
								alias U = ElementType!T;
								enum GLint length = T.length;
							}
						else {/*...}*/
							alias U = T;
							enum GLint length = 1;
						}

						alias ConversionTable = TypeTuple!(
							byte,   GL_BYTE,
							ubyte,  GL_UNSIGNED_BYTE,
							short,  GL_SHORT,
							ushort, GL_UNSIGNED_SHORT,
							int,    GL_INT,
							uint,   GL_UNSIGNED_INT,
							float,  GL_FLOAT,
							double, GL_DOUBLE
						);

						mixin ParameterSplitter!(
							`Types`, is_type,
							`Enums`, is_numerical_param,
							ConversionTable
						);
						static assert (staticIndexOf!(U, Types) >= 0, U.stringof~ ` must be one of ` ~Types.stringof);

						static if (is_vector!T)
							gl.VertexAttribPointer (0, length, Enums[staticIndexOf!(U, Types)], GL_FALSE, 0, null); // TODO watch out for attribute indices
					}

				void upload (T[] data)
					{/*...}*/
						if (buffer_object == 0)
							initialize;

						bind;

						length = data.length.to!GLsizei;

						gl.BufferData (target, length * T.sizeof, data.ptr, usage);
					}
				void upload (R)(R data)
					if (not(is(R == T[])))
					{/*...}*/
						upload (data.map!(to!T).array);
					}

				void free ()
					{/*...}*/
						gl.DeleteBuffers (1, &buffer_object);

						buffer_object = 0;
						length = 0;
					}
			}
	}
	public {/*fundamental}*/
		struct VertexBuffer
			{/*...}*/
				mixin GLBuffer!(fvec, GL_ARRAY_BUFFER); // OUTSIDE BUG runtime crash if this is a template struct alias. works as a mixin. wtf??
			}

		struct IndexBuffer
			{/*...}*/
				mixin GLBuffer!(ushort, GL_ELEMENT_ARRAY_BUFFER);
			}
	}
	public {/*compound}*/
		struct GeometryBuffer
			{/*...}*/
				public:
				public {/*hash}*/
					hash_t toHash ()
						{/*...}*/
							return vertices.buffer_object.to!hash_t;
						}
				}
				private:
				private {/*ctor}*/
					this (R,S)(R geometry, S triangle_corner_indices)
						{/*...}*/
							vertices.upload (geometry);
							indices.upload (triangle_corner_indices);
						}
				}
				private {/*ops}*/
					void bind ()
						{/*...}*/
							vertices.bind;
							indices.bind;
						}

					void free ()
						{/*...}*/
							vertices.free;
							indices.free;
						}
				}
				private {/*data}*/
					VertexBuffer vertices;
					IndexBuffer indices;
				}
			}
	}
}
public {/*shader params}*/
	struct Input (Args...)
		{/*...}*/
			enum is_input_params;

			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Args
			);

			static generate_declarations (AttributeMode mode)()
				{/*...}*/
					static generate (uint param_index = 0, uint layout_index = 0)()
						{/*...}*/
							alias i = param_index;

							static if (i >= Types.length)
								return ``;
							else static if (per_vertex!(Types[i]))
								{/*...}*/
									static if (mode is AttributeMode.layout)
										return generate_layout_declaration!(Types[i], Names[i], layout_index)
											~ generate!(param_index + 1, layout_index + 1);
									else static if (mode is AttributeMode.smooth)
										return generate_smooth_declaration!(Types[i], Names[i], layout_index)
											~ generate!(param_index + 1);
									else static assert (0);
								}
							else {/*...}*/
								return generate_uniform_declaration!(Types[i], Names[i])
										~ generate!(param_index + 1, layout_index);
							}
						}

					return generate;
				}

			template generate_layout_declaration (T, string name, uint index)
				{/*...}*/
					enum generate_layout_declaration = q{
						layout (location = } ~index.text~ q{) in } ~gl_type!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
			template generate_smooth_declaration (T, string name)
				{/*...}*/
					enum generate_smooth_declaration = q{
						smooth in } ~gl_type!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
		}
	struct Output (Args...)
		{/*...}*/
			enum is_output_params;

			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Args
			);

			static generate_declarations (AttributeMode mode)()
				{/*...}*/
					static generate (uint param_index = 0)()
						{/*...}*/
							alias i = param_index;

							static if (i >= Types.length)
								return ``;
							else static if (per_vertex!(Types[i]))
								{/*...}*/
									static if (mode is AttributeMode.smooth)
										return generate_smooth_declaration!(Types[i], Names[i])
											~ generate!(param_index + 1);
									else static if (mode is AttributeMode.none)
										return generate_declaration!(Types[i], Names[i])
											~ generate!(param_index + 1);
									else static assert (0);
								}
							else {/*...}*/
								return generate_uniform_declaration!(Types[i], Names[i])
										~ generate!(param_index + 1);
							}
						}

					return generate;
				}

			template generate_smooth_declaration (T, string name)
				{/*...}*/
					enum generate_smooth_declaration = q{
						smooth out } ~gl_type!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
			template generate_declaration (T, string name)
				{/*...}*/
					enum generate_declaration = q{
						out } ~gl_type!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
		}
}
public {/*shaders}*/
	template VertexShader (Parameters...)
		{/*...}*/
			alias VertexShader = Shader!(GL_VERTEX_SHADER, Parameters);
		}
	template FragmentShader (Parameters...)
		{/*...}*/
			alias FragmentShader = Shader!(GL_FRAGMENT_SHADER, Parameters);
		}

	alias BasicShader = ShaderProgram!(
		VertexShader!(
			Input!(
				fvec[], `position`,
				Cvec,   `color`,
				fvec,   `translation`,
				float,  `rotation`,
				float,  `scale`,
			), q{
				float c = cos(rotation);
				float s = sin(rotation);

				vec2 rotated = vec2 (c*position.x - s*position.y, s*position.x + c*position.y);

				gl_Position = vec4 (scale*rotated + translation, 0, 1);
			}
		),
		FragmentShader!(
			Input!(
				Cvec,	`color`,
			),
			Output!(
				Cvec[], `frag_color`,
			), q{
				frag_color = color;
			}
		),
	);
}
public {/*programs}*/
	void set_uniform (T)(GLuint handle, T value)
		{/*...}*/
			static if (is_vector!T)
				{/*...}*/
					enum length = T.length.text;
					alias U = ElementType!T;
				}
			else {/*...}*/
				enum length = `1`;
				alias U = T;
			}

			enum type = gl_type!U[0].text;
			enum call = "gl.Uniform" ~length~type;

			mixin(q{
				} ~call~ q{ (handle, value.tuple.expand);
			});

		}

	class ShaderProgram (Vertex, Fragment)
		{/*...}*/
			static {/*verification}*/
				static assert (is(Filter!(per_vertex, Vertex.Outputs) == Filter!(per_vertex, Fragment.Inputs)),
					`per-vertex vertex shader outputs do not match interpolated fragment shader inputs`
				);
			}

			@Uniform mixin(uniform_handles);

			void set_uniforms (Order order)
				{/*...}*/
					static code ()
						{/*...}*/
							string code;

							foreach (uniform; collect_members!(Order, Uniform))
								code ~= q{
									set_uniform (} ~uniform~ q{, order.} ~uniform~ q{);
								};

							return code;
						}

					mixin(code);
				}

			struct Order
				{/*...}*/
					@Uniform mixin(uniform_variables);
				}

			public {/*doc}*/
				static uniform_variables ()
					{/*...}*/
						return declare!(Uniforms!(Vertex.Input), Uniforms!(Fragment.Input));
					}
				static uniform_handles ()
					{/*...}*/
						alias Names = Filter!(is_string_param, Uniforms!(Vertex.Input), Uniforms!(Fragment.Input));

						template to_GLint (T...)
							{/*...}*/
								alias to_GLint = GLint;
							}

						return declare!(Names, staticMap!(to_GLint, Names));
					}
			}

			public {/*ctor}*/
				this ()
					{/*...}*/
						auto vert_shader = new Vertex;
						auto frag_shader = new Fragment;

						program = gl.CreateProgram ();

						gl.AttachShader (program, vert_shader);
						gl.AttachShader (program, frag_shader);

						gl.LinkProgram (program); 
						gl.verify!`Program` (program);

						gl.DeleteShader (vert_shader);
						gl.DeleteShader (frag_shader);
						gl.DetachShader (program, vert_shader);
						gl.DetachShader (program, frag_shader);

						link_uniforms;
					}
			}
			private {/*ops}*/
				void activate ()
					{/*...}*/
						gl.UseProgram (program);
					}

				void link_uniforms ()
					{/*...}*/
						static link ()
							{/*...}*/
								string code;

								foreach (uniform; collect_members!(ShaderProgram, Uniform))
									code ~= uniform~` = gl.GetUniformLocation (program, "`~uniform~`"); `;

								return code;
							}

						mixin(link);
					}
			}
			public {/*gl data}*/
				GLuint program;
			}
		}
}
public: // TODO a new kind of display... one that you attach ShaderPrograms to
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
						assets[graph].buffer.free;

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
							BasicShader.Order to_shader ()
								{/*...}*/
									BasicShader.Order x = {
										color: this.color.vector.to!Cvec,
										translation: this.translate.to!fvec,
										rotation: this.rotate,
										scale: this.scale,
									};

									return x;
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
						assets[mesh].buffer.free;

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
							BasicShader.Order to_shader ()
								{/*...}*/
									BasicShader.Order x = {
										color: this.color.vector.to!Cvec,
										translation: this.translate.to!fvec,
										rotation: this.rotate,
										scale: this.scale,

									};

									return x;
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
private: // TODO now all shaders have to draw through a display interface
private {/*shader implementation}*/
	class Shader (GLenum shader_type, Parameters...)
		{/*...}*/
			private {/*definitions}*/
				alias Inputs = Filter!(has_trait!`is_input_params`, Parameters);
				alias Outputs = Filter!(has_trait!`is_output_params`, Parameters);
				alias Code = Filter!(is_string_param, Parameters);

				static assert (Inputs.length <= 1);
				static assert (Outputs.length <= 1);
				static assert (Code.length == 1);

				static if (Inputs.length)
					alias Input = Inputs[0];

				static if (Outputs.length)
					alias Output = Outputs[0];

				static if (shader_type is GL_VERTEX_SHADER)
					{/*...}*/
						enum input_mode = AttributeMode.layout;
						enum output_mode = AttributeMode.smooth;
					}
				else static if (shader_type is GL_FRAGMENT_SHADER)
					{/*...}*/
						enum input_mode = AttributeMode.smooth;
						enum output_mode = AttributeMode.none;
					}
				else static assert (0);

				enum code = Code[0];
			}
			private {/*ops}*/
				static shader_code ()
					{/*...}*/
						string shader_code = q{
							#version } ~glsl_version.text~ q{

							uniform vec2 aspect_ratio = vec2 (1,1); // TODO this multiples by nans if not set, but display should set it once at the beginning of its run, and reset it every tiem it resizes
						};

						static if (Inputs.length)
							shader_code ~= Input.generate_declarations!input_mode;

						static if (Outputs.length)
							shader_code ~= Output.generate_declarations!output_mode;

						static if (shader_type is GL_VERTEX_SHADER)
							enum correction = q{gl_Position *= vec4 (aspect_ratio, 1, 1);};
						else enum correction = ``;

						shader_code ~= q{
							void main (void) 
							}`{`q{
								} ~code~ q{
								} ~correction~ q{
							}`}`q{
						};

						return shader_code;
					}

				void build ()
					{/*...}*/
						shader_object = gl.CreateShader (shader_type);

						auto source = shader_code.toStringz;

						gl.ShaderSource (shader_object, 1, &source, null);
						gl.CompileShader (shader_object);

						gl.verify!`Shader` (shader_object);
					}
			}
			private {/*ctor}*/
				this ()
					{/*...}*/
						build;
					}
			}
			public {/*gl data}*/
				GLuint shader_object;
				alias shader_object this;
			}
		}
}
private {/*shader params}*/
	template gl_type (T)
		{/*...}*/
			static if (is_vector!T)
				{/*...}*/
					enum stringof = ElementType!T.stringof[0].text ~`vec`~ T.length.text;

					static if (is(ElementType!T == float))
						enum gl_type = stringof[1..$];
					else enum gl_type = stringof;
				}
			else static if (isScalarType!T)
				enum gl_type = T.stringof;
			else static assert (0, `cannot pass ` ~T.stringof~ ` directly to shader`);
		}

	template per_vertex (T)
		{/*...}*/
			enum per_vertex = is(T == U[], U);
		}

	template generate_uniform_declaration (T, string name)
		{/*...}*/
			enum generate_uniform_declaration = q{
				uniform } ~gl_type!T~ q{ } ~name~ q{;
			};
		}

	enum Uniform;

	template Uniforms (Input)
		{/*...}*/
			static generate ()
				{/*...}*/
					string code;

					with (Input) foreach (i,_; Types)
						{/*...}*/
							static if (not (per_vertex!(Types[i])))
								code ~= Types[i].stringof~ `, "` ~Names[i]~ `", `"\n";
						}

					return `TypeTuple!(` ~code~ `)`;
				}

			mixin(q{
				alias Uniforms = } ~generate~ q{;
			});
		}

	enum AttributeMode {none, layout, smooth}
}

// TODO compile-time routing generic draw -> renderer through a router containing a list of renderers
void main ()
	{/*...}*/
		class GraphicsContext
			{/*...}*/
				Display display;

				BasicShader basic;

				MeshRenderer!() mesh;
				GraphRenderer!() graph;

				this ()
					{/*...}*/
						display = new Display;
						mesh = new MeshRenderer!();
						graph = new GraphRenderer!();

						display.in_display_thread (()
							{/*...}*/
								basic = new BasicShader;

								mesh.attach (basic);
								graph.attach (basic);
							}
						);
					}
				~this ()
					{/*...}*/
						delete display;
						delete mesh;
					}

				alias display this;
			}

		scope gfx = new GraphicsContext;

		gfx.in_display_thread (()
			{/*...}*/
				gfx.mesh.draw (gfx.mesh.add (square, [0,1,2, 0,2,3]))
					.color (red (0.1))
					.mode (gfx.mesh.Mode.overlay)
					.enqueued;

				import std.random;
				gfx.graph.draw (gfx.graph.add (circle!12, ℕ[0..64].map!(i => uniform (0, 12))))
					.node_color (green)
					.edge_color (blue)
					.enqueued;

				gfx.mesh.process;
				gfx.graph.process;
			}
		);

		import core.thread;
		Thread.sleep (100.msecs);

		gfx.render;
		Thread.sleep (1000.msecs);

	}

	// TODO aspect-ratio correction should be handled by the display... but how? it would have to be applied in the shaders.... so a Display should be necessary to make any draw calls (this is a +)... and also all shaders will have a mandatory parameter "aspect_ratio" and a mandatory final line "gl_Position *= vec4 (aspect_ratio, 1, 1);" so some more common shader meta tools are needed

void test ()
	{/*...}*/
		class Display
			{/*...}*/
				@Uniform GLuint aspect_ratio_handle;
				vec aspect_ratio;
				uvec pixel_dimensions;

			public {/*drawing}*/
				void draw_vertices (GLenum draw_mode, VertexBuffer buffer, Interval!GLint range = interval (0, GLint.max))
					{/*...}*/
						range.end = min (buffer.length, range.end);

						gl.DrawArrays (draw_mode, range.tuple.expand);
					}
				void draw_geometry (GLenum draw_mode, GeometryBuffer buffer, Interval!GLint range = interval (0, GLint.max)) 
					{/*...}*/
						range.end = min (buffer.indices.length, range.end);

						gl.DrawElements (draw_mode, range.length, GL_UNSIGNED_SHORT, (range.start*ushort.sizeof).to!size_t.voidptr);
					}

				void draw (T) (Color color, T geometry, GeometryMode mode = GeometryMode.l_loop, uint layer = 0)
					if (is_geometric!T || is_in_display_space!T)
					{/*↓}*/
						static if (is (ElementType!T == Coords))
							draw (0, geometry, geometry.map!(c => c.value), color, mode, layer);
						else draw (0, geometry, geometry, color, mode, layer);
					}
				void draw (R,S) (GLuint texture, R geometry, S tex_coords, Color color = black (0), GeometryMode mode = GeometryMode.t_fan, uint layer = 0)
					if (allSatisfy!(Or!(is_geometric, is_in_display_space), R, S))
					out {/*...}*/
						assert (buffer.texture_coords.length == buffer.vertices.length, `geometry/texture coords length mismatched`);
					}
					body {/*...}*/
						if (geometry.empty) return;

						uint index  = buffer.vertices.length.to!uint;

						static if (is (ElementType!R == Coords))
							buffer.vertices ~= geometry.to_draw_space (this);
						else buffer.vertices ~= geometry.from_extended_space.to_draw_space (this);

						buffer.texture_coords ~= tex_coords;

						uint length = buffer.vertices.length.to!uint - index;

						auto order = Order!Basic (mode, index, length, layer);
						order.tex_id = texture;
						order.base = color;
						buffer.orders ~= RenderOrder (order);
					}

				// TODO coalesce parts of process and draw into ImmediateRenderer
				bool process ()
					{/*...}*/
						if (0)
						gl.Clear (GL_COLOR_BUFFER_BIT);

						auto vertex_pool = buffer.vertices.read[];
						auto texture_coord_pool = buffer.texture_coords.read[];
						auto order_pool = buffer.orders.read[];

						if (order_pool.length)
							{/*sort orders}*/
								template take_order (ArtStyle)
									{/*...}*/
										alias take_order = λ!(
											(Order!ArtStyle order) 
												{/*...}*/
													const auto i = staticIndexOf!(ArtStyle, VisualTypes);
													(cast(Shaders[i])shaders[i]).render_list.put (order);
												}
										);
									}
								foreach (order; order_pool)
									order.visit!(staticMap!(take_order, VisualTypes));
							}
						if (vertex_pool.length) 
							{/*render orders}*/
								gl.BindBuffer (GL_ARRAY_BUFFER, vertex_buffer);
								gl.BufferData (GL_ARRAY_BUFFER, 
									vec.sizeof * vertex_pool.length, vertex_pool.ptr,
									GL_STATIC_DRAW
								);
								gl.BindBuffer (GL_ARRAY_BUFFER, texture_coord_buffer);
								gl.BufferData (GL_ARRAY_BUFFER, 
									vec.sizeof * texture_coord_pool.length, texture_coord_pool.ptr,
									GL_STATIC_DRAW
								);
								foreach (i, shader; shaders)
									(cast(shared)shader).execute;
							}

						glfwPollEvents ();
						glfwSwapBuffers (window);

						return true;
					}
			}

				this ()
					{/*...}*/
						//stuff
						set_uniform (aspect_ratio_handle, (1/aspect_ratio).to!fvec);
					}
				void resize ()
					{/*...}*/
						set_uniform (aspect_ratio_handle, (1/aspect_ratio).to!fvec);
					}

				// then immediate "easy-draw" methods here
				public:
				void background (Color color) // REVIEW
					{/*...}*/
						in_display_thread (() => gl.ClearColor (color.vector.tuple.expand));
					}
				void screenshot (void[] image_data) // REVIEW
					in {/*...}*/
						assert (image_data.length >= dimensions[].product * 3);
					}
					body {/*...}*/
						in_display_thread ((){
							gl.ReadPixels (0, 0, dimensions.x.to!int, dimensions.y.to!int, PixelFormat.bgr, PixelFormat.unsigned_byte, image_data.ptr);
						});
					}

				public {/*controls}*/
					void render ()
						in {/*...}*/
							assert (this.is_running, "attempted to render while Display offline");
						}
						body {/*...}*/
							buffer.writer_swap ();
							send (RenderCommand());
						}
					void in_display_thread (T)(T request, Seconds time_allowed = 1.second)
						if (isCallable!T)
						in {/*...}*/
							static assert (ParameterTypeTuple!T.length == 0);
							static assert (is (ReturnType!T == void));
							assert (this.is_running, "attempted to access rendering context while Display offline");
						}
						body {/*...}*/
							send (cast(shared)std.functional.toDelegate (request));
							assert (received_before (time_allowed, (AccessConfirmation _){}));
						}
				}
				public {/*coordinates}*/
					enum Space {draw, extended, pixel, inverted_pixel}
					struct Coords
						{/*...}*/
							pure nothrow:

							Space space;
							vec value;
							alias value this;

							@disable this ();
							this (vec value, Space space)
								{/*...}*/
									this.value = value;
									this.space = space;
								}
						}

					@(Space.pixel) @property dimensions () pure nothrow const
						{/*...}*/
							return screen_dims[].vec;
						}
					@(Space.extended) @property extended_bounds ()
						{/*...}*/
							return [0.vec, dimensions].from_pixel_space.to_extended_space (this).bounding_box;
						}
				}
				public {/*ctor/dtor}*/
					this (uint width, uint height)
						{/*...}*/
							this (uvec(width, height));
						}
					this (uvec dims)
						{/*...}*/
							screen_dims = dims;
							this ();
						}
					this ()
						{/*...}*/
							buffer = new typeof(buffer);

							start;
						}
					~this ()
						{/*...}*/
							stop;
						}
				}
				protected:
				@Service shared override {/*interface}*/
					bool initialize ()
						{/*...}*/
							{/*GLFW}*/
								DerelictGLFW3.load ();
								glfwSetErrorCallback (&error_callback);
								enforce (glfwInit (), "glfwInit failed");

								immutable dims = cast()screen_dims;
								window = glfwCreateWindow (dims.x.to!uint, dims.y.to!uint, "evx.display", null, null);

								enforce (window !is null);
								glfwMakeContextCurrent (window);
								glfwSwapInterval (0);

								glfwSetWindowSizeCallback (window, &resize_window_callback);
								glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

								glfwSetWindowUserPointer (window, cast(void*)this);
							}
							{/*GL}*/
								DerelictGL3.load ();
								DerelictGL3.reload ();
								gl.EnableVertexAttribArray (0);
					//			gl.EnableVertexAttribArray (1);
								gl.ClearColor (0.1, 0.1, 0.1, 1.0);
				//				gl.GenBuffers (1, &vertex_buffer);
				//				gl.GenBuffers (1, &texture_coord_buffer);
				//				gl.BindBuffer (GL_ARRAY_BUFFER, vertex_buffer);
				//				gl.VertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, 0, null);
				//				gl.BindBuffer (GL_ARRAY_BUFFER, texture_coord_buffer);
				//				gl.VertexAttribPointer (1, 2, GL_FLOAT, GL_FALSE, 0, null);
								// alpha
								gl.Enable (GL_BLEND);
								gl.BlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
							}
							initialize_shaders (shaders);

							return true;
						}
					bool listen ()
						{/*...}*/
							bool listening = true;

							void render (RenderCommand)
								{/*...}*/
									buffer.reader_swap;

									listening = false;

									assert (buffer.texture_coords.read.length == buffer.vertices.read.length, 
										`vertices and texture coords not 1-to-1`
									);
								}
							void in_display_thread (shared void delegate() request)
								{/*...}*/
									request ();
									reply (AccessConfirmation());
								}
								
							receive (
								&render, 
								&in_display_thread,
								auto_sync!(animation, (){/*...})*/
									buffer.writer_swap ();
									buffer.reader_swap ();
									listening = false;
								}).expand
							);

							return listening;
						}
					bool terminate()
						{/*...}*/
							{/*GLFW}*/
								glfwMakeContextCurrent (null);
								glfwDestroyWindow (window);
								glfwTerminate ();
							}
							return true;
						}
					const string name ()
						{/*...}*/
							return "display";
						}
				}
				private:
				static {/*context}*/
					GLFWwindow* window;

					ShaderInterface[] shaders;

					GLuint vertex_buffer;
					GLuint texture_coord_buffer;

					Scheduler animation;
				}
				private {/*data}*/
					@(Space.pixel) uvec screen_dims = uvec(800,600);

					shared BufferGroup!(
						TripleBuffer!(fvec, 2^^16), 
							`vertices`,
						TripleBuffer!(fvec, 2^^14), 
							`texture_coords`,
						TripleBuffer!(RenderOrder, 2^^12), 
							`orders`
					) buffer;
				}
				static:
				extern (C) nothrow {/*callbacks}*/
					void error_callback (int, const (char)* error)
						{/*...}*/
							fprintf (stderr, "error glfw: %s\n", error);
						}
					void resize_window_callback (GLFWwindow* window, int width, int height)
						{/*...}*/
							(cast(Display) glfwGetWindowUserPointer (window))
								.screen_dims = uvec (width, height);
						}
					void resize_framebuffer_callback (GLFWwindow* window, int width, int height)
						{/*...}*/
							try gl.Viewport (0, 0, width, height);
							catch (Exception ex) assert (0, ex.msg);
						}
				}
			}
	}
