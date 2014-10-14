module evx.display2;

private {/*imports}*/
	private {/*std}*/
		import std.algorithm;
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

auto string_parameters (Args...)() // REFACTOR to meta
	{/*...}*/
		foreach (Arg; Args)
			{/*...}*/
				static assert (is(typeof(Arg)));
				static assert (isBuiltinType!(typeof(Arg)));
			}

		return Args.tuple.text.retro.findSplitAfter (`(`)[0].text.retro.text;
	}

/// GLSL metaprogramming stuff
template glsl_typename_enum (T)
	{/*...}*/
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

		enum glsl_typename_enum = ConversionTable[staticIndexOf!(T, ConversionTable) + 1];
	}
template glsl_typename (T)
	{/*...}*/
		static if (is_vector!T)
			{/*...}*/
				enum stringof = ElementType!T.stringof[0].text ~`vec`~ T.length.text;

				static if (is(ElementType!T == float))
					enum glsl_typename = stringof[1..$];
				else enum glsl_typename = stringof;
			}
		else static if (isScalarType!T)
			enum glsl_typename = T.stringof;
		else static assert (0, `cannot pass ` ~T.stringof~ ` directly to shader`);
	}
template glsl_declaration (T, Args...)
	{/*...}*/
		enum glsl_declaration = glsl_typename!T~ ` ` ~string_parameters!Args;
	}

// array ctor functions
auto gpu_array (R)(R range)
	{/*...}*/
		alias T = ElementType!R;

		struct GPUArray
			{mixin GLBuffer!(T, GL_ARRAY_BUFFER, GL_DYNAMIC_DRAW);}

		return GPUArray (range);
	}

public:
public {/*buffers}*/
	private {/*base}*/
		mixin template GLBuffer (T, GLenum target, GLenum usage)
			{/*...}*/
				alias Buffer = typeof(this);

				/////////

				GLuint buffer_object = 0;
				GLsizei length;

				/////////

				this (R)(R data)
					{/*...}*/
						this = data;
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

						static if (is_vector!T) // TODO this should be handled by shader
							gl.VertexAttribPointer (0, T.length.to!uint, glsl_typename_enum!(ElementType!T), GL_FALSE, 0, null); // TODO watch out for attribute indices
					}


				/////////
				auto pointer_to (R)(R data)
					{/*...}*/
						static if (is(R == T[]))
							return data.ptr;
						else return data[].map!(to!T).array.ptr;
					}

				auto opIndex ()
					{/*...}*/
						return this;
					}
				auto opIndex (size_t i)
					{/*...}*/
						
					}
				auto opIndex (size_t[2] slice)
					{/*...}*/
						struct Sub
							{/*...}*/
								Buffer buffer;

								Indices indices;

								auto length ()
									{/*...}*/
										return indices.length;
									}

								this (Buffer buffer, size_t[2] slice)
									{/*...}*/
										this.buffer = buffer;
										indices = slice;
									}

								auto opIndex ()
									{/*...}*/
										return this;
									}
								auto opIndex (size_t i)
									{/*...}*/
										return buffer[indices.start + i];
									}
								auto opIndex (size_t[2] slice)
									{/*...}*/
										return Sub (buffer, (indices.start + slice.vector).array);
									}

								auto opIndexAssign (T data, size_t i)
									{/*...}*/
										this[i..i+1] = (&data)[0..1];
									}
								auto opIndexAssign (R)(R data)
									{/*...}*/
										this[0..$] = data;
									}
								auto opIndexAssign (R)(R data, size_t[2] slice)
									{/*...}*/
										auto range = indices.start + slice.vector;

										buffer[range[0]..range[1]] = data;
									}

								auto opSlice (size_t d:0)(size_t i, size_t j)
									{/*...}*/
										return vector (i,j).array;
									}
							}

						return Sub (this, slice);
					}
				auto opSlice (size_t d:0)(size_t i, size_t j)
					{/*...}*/
						return vector (i,j).array;
					}

				auto opIndexAssign (T data, size_t i)
					{/*...}*/
						this[i..i+1] = (&data)[0..1];
					}
				auto opIndexAssign (R)(R data)
					in {/*...}*/
						assert (range.length == this.length);
					}
					body {/*...}*/
						this[0..$] = data;
					}
				auto opIndexAssign (R)(R data, size_t[2] indices)
					in {/*...}*/
						assert (indices.interval.size <= length);
					}
					body {/*...}*/
						bind;

						gl.BufferSubData (target, indices[0], indices.interval.size * T.sizeof, pointer_to (data));
					}

				auto opAssign (Buffer that)
					{/*...}*/
						this.buffer_object = that.buffer_object;
						this.length = that.length;
					}
				auto opAssign (R)(R data)
					{/*...}*/
						if (buffer_object == 0)
							initialize;

						length = data.length.to!GLsizei;

						bind;

						gl.BufferData (target, length * T.sizeof, pointer_to (data), usage);
					}
				auto opAssign (typeof(null)) // TODO make sure this shit frees GPU memory
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
				mixin GLBuffer!(fvec, GL_ARRAY_BUFFER, GL_STATIC_DRAW); // OUTSIDE BUG runtime crash if this is a template struct alias. works as a mixin. wtf??
			}

		struct IndexBuffer
			{/*...}*/
				mixin GLBuffer!(ushort, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW);
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
							vertices = geometry;
							indices = triangle_corner_indices;
						}
				}
				private {/*ops}*/
					void bind ()
						{/*...}*/
							vertices.bind;
							indices.bind;
						}

					void free () // TODO opassign
						{/*...}*/
							vertices = null;
							indices = null;
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
	template is_initializer (T...)
		if (T.length == 1)
		{/*...}*/
			enum is_initializer = allSatisfy!(has_trait!`is_initializer`, T);
		}

	struct Input (Args...)
		{/*...}*/
			enum is_input_params;

			mixin ParameterSplitter!(
				`Types`, is_type,
				`Names`, is_string_param,
				Filter!(not!is_initializer, Args)
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
										return generate_smooth_declaration!(Types[i], Names[i])
											~ generate!(param_index + 1);
									else static assert (0);
								}
							else {/*...}*/
								enum init_index = staticIndexOf!(Names[i], Args) + 1;

								static if (init_index < Args.length)
									return generate_uniform_declaration!(Types[i], Names[i], Args[init_index])
											~ generate!(param_index + 1, layout_index);
								else return generate_uniform_declaration!(Types[i], Names[i])
										~ generate!(param_index + 1, layout_index);
							}
						}

					return generate;
				}

			template generate_layout_declaration (T, string name, uint index)
				{/*...}*/
					enum generate_layout_declaration = q{
						layout (location = } ~index.text~ q{) in } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
			template generate_smooth_declaration (T, string name)
				{/*...}*/
					enum generate_smooth_declaration = q{
						smooth in } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
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
						smooth out } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
					};
				}
			template generate_declaration (T, string name)
				{/*...}*/
					enum generate_declaration = q{
						out } ~glsl_typename!(ElementType!T)~ q{ } ~name~ q{;
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

	struct Init (T...)
		{/*...}*/
			enum is_initializer;
			enum value = T;
		}

	alias BasicShader = ShaderProgram!(
		VertexShader!(
			Input!(
				fvec[], `position`,		Init!(0,0),
				Cvec,   `color`,		Init!(1,0,1,1),
				fvec,   `translation`,	Init!(0,0),
				float,  `rotation`,		Init!(0),
				float,  `scale`,		Init!(1),
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

			enum type = glsl_typename!U[0].text;
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

	template per_vertex (T)
		{/*...}*/
			enum per_vertex = is(T == U[], U);
		}

	template generate_uniform_declaration (T, string name, Initializer...)
		{/*...}*/
			static if (Initializer.length == 0)
				enum generate_uniform_declaration = q{
					uniform } ~glsl_typename!T~ q{ } ~name~ q{;
				};
			else enum generate_uniform_declaration = q{
				uniform } ~glsl_typename!T~ q{ } ~name~ q{ = } ~glsl_declaration!(T, Initializer[0].value)~ q{;
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

		if (0)
		gfx.in_display_thread (()
			{/*...}*/
				auto m = gfx.mesh.add (square, [0,1,2, 0,2,3]);
				gfx.mesh.draw (m)
					.color (red (0.1))
					.mode (gfx.mesh.Mode.overlay)
					.enqueued;

				import std.random;
				gfx.graph.draw (gfx.graph.add (circle!12, ℕ[0..64].map!(i => uniform (0, 12))))
					.node_color (green)
					.edge_color (blue)
					.enqueued;

				gfx.mesh.assets[m].buffer.vertices[0] = 0.2.fvec; // TODO let buffers be carried out

				gfx.mesh.process;
				gfx.graph.process;
			}
		);

		gfx.in_display_thread (()
			{/*...}*/
				auto data = [-1.vec, 0.vec, vec(-1,-2)].gpu_array;

				gl.DrawArrays (GL_TRIANGLE_FAN, 0, data.length);
			}
		);

		import core.thread;
		Thread.sleep (100.msecs);

		gfx.render;
		Thread.sleep (1000.msecs);

	}

	// TODO aspect-ratio correction should be handled by the display... but how? it would have to be applied in the shaders.... so a Display should be necessary to make any draw calls (this is a +)... and also all shaders will have a mandatory parameter "aspect_ratio" and a mandatory final line "gl_Position *= vec4 (aspect_ratio, 1, 1);" so some more common shader meta tools are needed

