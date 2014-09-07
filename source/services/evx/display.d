module evx.display;

private {/*imports}*/
	private {/*std}*/
		import std.file;
		import std.datetime;
		import std.algorithm;
		import std.concurrency;
		import std.exception;
		import std.math;
		import std.traits;
		import std.range;
		import std.variant;
		import std.typetuple;
		import std.array;
		import std.string;
		import std.c.stdio;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.colors;
		import evx.math;
		import evx.meta;
		import evx.service;
		import evx.scheduling;
		import evx.arrays;
		import evx.buffers;
	}
	private {/*opengl}*/
		import derelict.glfw3.glfw3;
		import derelict.opengl3.gl3;
	}

	alias reduce = evx.functional.reduce;
	alias map = evx.functional.map;
	alias zip = evx.functional.zip;
	alias seconds = evx.units.seconds;
}

alias TextureId = GLuint;

enum GeometryMode
	{/*...}*/
		t_fan 	= derelict.opengl3.gl3.GL_TRIANGLE_FAN,
		t_strip = derelict.opengl3.gl3.GL_TRIANGLE_STRIP,
		lines 	= derelict.opengl3.gl3.GL_LINES,
		l_strip = derelict.opengl3.gl3.GL_LINE_STRIP,
		l_loop 	= derelict.opengl3.gl3.GL_LINE_LOOP
	}

enum PixelFormat
	{/*...}*/
		rgb = GL_RGB,
		bgr = GL_BGR,
		unsigned_byte = GL_UNSIGNED_BYTE,
	}

pure {/*coordinate transformations}*/
	public {/*from}*/
		auto from_draw_space (T)(T geometry) 
			if (is (T == vec) || is_geometric!T)
			{/*...}*/
				static if (is (T == vec))
					return Display.Coords (geometry, Display.Space.draw);
				else static if (is_geometric!T)
					return geometry.map!(v => Display.Coords (v, Display.Space.draw));
				else static assert (0);
			}
		auto from_extended_space (T)(T geometry) 
			if (is (T == vec) || is_geometric!T)
			{/*...}*/
				static if (is (T == vec))
					return Display.Coords (geometry, Display.Space.extended);
				else static if (is_geometric!T)
					return geometry.map!(v => Display.Coords (v, Display.Space.extended));
				else static assert (0);
			}
		auto from_pixel_space (T)(T geometry) 
			if (is (T == vec) || is_geometric!T)
			{/*...}*/
				static if (is (T == vec))
					return Display.Coords (geometry, Display.Space.pixel);
				else static if (is_geometric!T)
					return geometry.map!(v => Display.Coords (v, Display.Space.pixel));
				else static assert (0);
			}
	}
	public {/*to}*/
		public {/*element}*/
			vec to_draw_space ()(Display.Coords coords, Display display) 
				{/*...}*/
					with (Display.Space) final switch (coords.space)
						{/*...}*/
							case draw:
								return coords.value;
							case extended:
								{/*...}*/
									auto min = display.dimensions[].reduce!min;

									return coords.value * (min.vec / display.dimensions);
								}
							case pixel:
								return 2 * coords.value/display.dimensions * vec(1,-1) + vec(-1,1);
						}
				}
			vec to_extended_space ()(Display.Coords coords, Display display) 
				{/*...}*/
					with (Display.Space) final switch (coords.space)
						{/*...}*/
							case draw:
								{/*...}*/
									auto min = display.dimensions[].reduce!min;

									return coords.value * (display.dimensions / min.vec);
								}
							case extended:
								return coords.value;
							case pixel:
								return coords.to_draw_space (display).from_draw_space.to_extended_space (display);
						}
				}
			vec to_pixel_space ()(Display.Coords coords, Display display) 
				{/*...}*/
					with (Display.Space) final switch (coords.space)
						{/*...}*/
							case draw:
								return (coords.value - vec(-1,1)) * vec(1,-1) * display.dimensions/2; // REVIEW
							case extended:
								return coords.to_draw_space (display).from_draw_space.to_pixel_space (display);
							case pixel:
								return coords.value;
						}
				}
		}
		public {/*range}*/
			auto to_draw_space (T)(T geometry, Display display)
				if (is (ElementType!T == Display.Coords))
				{/*...}*/
					return display.repeat (geometry.length).zip (geometry)
						.map!(τ => τ[1].to_draw_space (τ[0]));
				}
			auto to_extended_space (T)(T geometry, Display display)
				if (is (ElementType!T == Display.Coords))
				{/*...}*/
					return display.repeat (geometry.length).zip (geometry)
						.map!(τ => τ[1].to_extended_space (τ[0]));
				}
			auto to_pixel_space (T)(T geometry, Display display)
				if (is (ElementType!T == Display.Coords))
				{/*...}*/
					return display.repeat (geometry.length).zip (geometry)
						.map!(τ => τ[1].to_pixel_space (τ[0]));
				}
		}
	}
	public {/*traits}*/
		template is_in_display_space (T)
			{/*...}*/
				static if (isInputRange!T)
					enum is_in_display_space = is (ElementType!T == Display.Coords);
				else enum is_in_display_space = false;
			}
	}
}
	unittest {/*...}*/
		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;
		{/*identity}*/
			assert (î.vec.approx (î.vec.from_draw_space.to_draw_space (gfx)));
			assert (î.vec.approx (î.vec.from_extended_space.to_extended_space (gfx)));
			assert (î.vec.approx (î.vec.from_pixel_space.to_pixel_space (gfx)));
		}
		{/*inverse}*/
			assert (î.vec.approx (
				î.vec.from_draw_space.to_extended_space (gfx)
					.from_extended_space.to_draw_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_draw_space.to_pixel_space (gfx)
					.from_pixel_space.to_draw_space (gfx)
			));

			assert (î.vec.approx (
				î.vec.from_extended_space.to_draw_space (gfx)
					.from_draw_space.to_extended_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_extended_space.to_pixel_space (gfx)
					.from_pixel_space.to_extended_space (gfx)
			));

			assert (î.vec.approx (
				î.vec.from_pixel_space.to_draw_space (gfx)
					.from_draw_space.to_pixel_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_pixel_space.to_extended_space (gfx)
					.from_extended_space.to_pixel_space (gfx)
			));
		}
		{/*cycle}*/
			assert (î.vec.approx (
				î.vec.from_draw_space.to_extended_space (gfx)
					.from_extended_space.to_pixel_space (gfx)
					.from_pixel_space.to_draw_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_draw_space.to_pixel_space (gfx)
					.from_pixel_space.to_extended_space (gfx)
					.from_extended_space.to_draw_space (gfx)
			));

			assert (î.vec.approx (
				î.vec.from_extended_space.to_draw_space (gfx)
					.from_draw_space.to_pixel_space (gfx)
					.from_pixel_space.to_extended_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_extended_space.to_pixel_space (gfx)
					.from_pixel_space.to_draw_space (gfx)
					.from_draw_space.to_extended_space (gfx)
			));

			assert (î.vec.approx (
				î.vec.from_pixel_space.to_draw_space (gfx)
					.from_draw_space.to_extended_space (gfx)
					.from_extended_space.to_pixel_space (gfx)
			));
			assert (î.vec.approx (
				î.vec.from_pixel_space.to_extended_space (gfx)
					.from_extended_space.to_draw_space (gfx)
					.from_draw_space.to_pixel_space (gfx)
			));
		}
	}

final class Display: Service
	{/*...}*/
		public:
		void background (Color color) // REVIEW
			{/*...}*/
				access_rendering_context (() => gl.ClearColor (color.vector.tuple.expand));
			}

		public {/*drawing}*/
			void draw (T) (Color color, T geometry, GeometryMode mode = GeometryMode.l_loop) 
				if (is_geometric!T || is_in_display_space!T)
				{/*↓}*/
					static if (is (ElementType!T == Coords))
						draw (0, geometry.to_draw_space (this), geometry.map!(c => c.value), color, mode);
					else draw (0, geometry, geometry, color, mode);
				}
			void draw (T1, T2) (GLuint texture, T1 geometry, T2 tex_coords, Color color = black.alpha (0), GeometryMode mode = GeometryMode.t_fan)
				if (allSatisfy!(Or!(is_geometric, is_in_display_space), T1, T2))
				in {/*...}*/
					assert (tex_coords.length == geometry.length, `geometry/texture coords length mismatched`);
				}
				body {/*...}*/
					if (geometry.length == 0) return;

					uint index  = buffer.vertices.length.to!uint;
					uint length = geometry.length.to!uint;
					auto data = Order!() (mode, index, length);

					auto order = Order!Basic (data);
					order.tex_id = texture;
					order.base = color;
			
					static if (is (ElementType!T1 == Coords))
						buffer.vertices ~= geometry.to_draw_space (this);
					else buffer.vertices ~= geometry;

					buffer.texture_coords ~= tex_coords;
					buffer.orders ~= RenderOrder (order);
				}
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
			void access_rendering_context (T)(T request, Seconds time_allowed = 1.second)
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
			enum Space {draw, extended, pixel}
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

			@(Space.pixel) @property auto dimensions () pure nothrow const
				{/*...}*/
					return screen_dims[].vec;
				}
		}
		public {/*ctors}*/
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
					}
					{/*GL}*/
						DerelictGL3.load ();
						DerelictGL3.reload ();
						gl.EnableVertexAttribArray (0);
						gl.EnableVertexAttribArray (1);
						gl.ClearColor (0.1, 0.1, 0.1, 1.0);
						gl.GenBuffers (1, &vertex_buffer);
						gl.GenBuffers (1, &texture_coord_buffer);
						gl.BindBuffer (GL_ARRAY_BUFFER, vertex_buffer);
						gl.VertexAttribPointer (0, 2, GL_FLOAT, GL_FALSE, 0, null);
						gl.BindBuffer (GL_ARRAY_BUFFER, texture_coord_buffer);
						gl.VertexAttribPointer (1, 2, GL_FLOAT, GL_FALSE, 0, null);
						// alpha
						gl.Enable (GL_BLEND);
						gl.BlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					}
					initialize_shaders (shaders);
					return true;
				}
			bool process ()
				{/*...}*/
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
												(cast(Shaders[i])shaders[i]).render_list ~= order;
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
					void access_rendering_context (shared void delegate() request)
						{/*...}*/
							request ();
							reply (AccessConfirmation());
						}
						
					receive (
						&render, 
						&access_rendering_context,
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
			@(`pixel`) uvec screen_dims = uvec(800, 800);

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
		extern (C) {/*callbacks}*/
			void error_callback (int, const (char)* error) nothrow
				{/*...}*/
					fprintf (stderr, "error glfw: %s\n", error);
				}
		}
	}
	unittest {/*basic}*/
		import core.thread;
		import std.datetime;

		auto colors = [red, orange, yellow, green, cyan, blue, purple, magenta, black, grey, white];

		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;

		foreach (i; 0..20)
			foreach (j; 0..20)
				gfx.draw ((i+j)%2? black: white,
					square (1.0/10, 1.0/10*vec(i,j) + vec(0.5/10) - 1.vec),
				GeometryMode.t_fan);

		foreach (i, color; colors)
			foreach (x; 0..8)
				gfx.draw (
					color.alpha ((1.0 + x)/8.0),
					square (1.0, vec(-1))
						.scale (vec(2.0/8, 2.0/colors.length))
						.translate (vec((2.0/8)*x, (2.0/colors.length)*i) + vec(1.0/8, 1.0/colors.length)),
					GeometryMode.t_fan
				);

		gfx.render;

		Thread.sleep (1.seconds);
	}
	unittest {/*animation}*/
		import core.thread;
		import std.datetime;

		scope D = new Display;
		scope S = new Scheduler;

		static auto verts = [vec(0), vec(1), vec(1,0)];
		static auto animate (Display D)
			{/*...}*/
				static int t = 0;
				t++;
				D.draw (green, verts.map!(v => v-(0.02*t)));
			}

		// ways to animate:
		static void manual_test (shared Display sD, shared Scheduler sS)
			{/*manually sync the display with a scheduler}*/
				auto D = cast()sD;
				auto S = cast()sS;
				scope (exit) {D.stop (); S.stop (); ownerTid.prioritySend (true);}
				D.start ();
				S.start ();
				S.enqueue (30.milliseconds);
				int frames = 20;
				while (frames-- && received_before (100.milliseconds,
					(Scheduler.Notification _) {animate (D); D.render (); if (frames) S.enqueue (30.milliseconds);}
				)){}
			}
		static void auto_test (shared Display sD, shared Scheduler sS)
			{/*automatically sync the display with a scheduler}*/
				auto D = cast()sD;
				auto S = cast()sS;

				scope (exit) {D.stop (); S.stop (); ownerTid.prioritySend (true);}

				verts = [vec(0), vec(1), vec(1,0)];

				D.start ();
				S.start ();

				S.enqueue (800.milliseconds); // this is our termination signal
				D.subscribe (); // to receive a service ID

				D.sync_with (S, 30.hertz);

				bool rendering = true;
				while (rendering && received_before (100.milliseconds,
					(Scheduler.Notification _)
						{rendering = false;},
					(Service.Id id)
						{animate (D);}
				)){}
			}

		bool received;
		spawn (&manual_test, cast(shared)D, cast(shared)S);
		received = receiveTimeout (2.seconds, (bool _){});
		assert (received);
		spawn (&auto_test, cast(shared)D, cast(shared)S);
		received = receiveTimeout (2.seconds, (bool _){});
		assert (received);
	}

public {/*openGL}*/
	struct gl
		{/*...}*/
			import std.string;
			static auto ref opDispatch (string name, Args...) (Args args)
				{/*...}*/
					debug scope (exit) check_GL_error!name (args);
					static if (name == "GetUniformLocation")
						mixin ("return gl"~name~" (args[0], toStringz (args[1]));");
					else mixin ("return gl"~name~" (args);");
				}
			static void check_GL_error (string name, Args...) (Args args)
				{/*...}*/
					GLenum error;
					while ((error = glGetError ()) != GL_NO_ERROR)
						{/*...}*/
							string error_msg;
							final switch (error)
								{/*...}*/
									case GL_INVALID_ENUM:
										error_msg = "GL_INVALID_ENUM";
										break;
									case GL_INVALID_VALUE:
										error_msg = "GL_INVALID_VALUE";
										break;
									case GL_INVALID_OPERATION:
										error_msg = "GL_INVALID_OPERATION";
										break;
									case GL_INVALID_FRAMEBUFFER_OPERATION:
										error_msg = "GL_INVALID_FRAMEBUFFER_OPERATION";
										break;
									case GL_OUT_OF_MEMORY:
										error_msg = "GL_OUT_OF_MEMORY";
										break;
								}
							throw new Exception ("OpenGL error " ~to!string (error)~": "~error_msg~"\n"
								"	using gl"~function_call_to_string!name (args));
						}
				}
		}
}
private {/*shaders}*/
	template ShaderName (ArtStyle) {mixin(q{alias ShaderName = }~ArtStyle.stringof~q{Shader;});}
	alias Shaders = staticMap!(ShaderName, VisualTypes);

	struct Uniform {}

	private {/*protocols}*/
		template link_uniforms (T)
			{/*...}*/
				string link_uniforms ()
					{/*...}*/
						string command;
						foreach (uniform; collect_members!(T, Uniform))
							command ~= uniform~` = gl.GetUniformLocation (program, "`~uniform~`"); `;
						return command;
					}
			}
		string uniform_protocol ()
			{/*...}*/
				return q{	
					mixin (link_uniforms!(typeof (this)));
					protocol_check = true;
				};
			}
	}
	private {/*imports}*/
		import std.file;
		import std.conv;
		import std.algorithm;
		import derelict.opengl3.gl3;
	}
	private {/*shader interface}*/
		shared interface ShaderInterface
			{/*...}*/
				void execute ();
			}
		abstract class Shader (ArtStyle): ShaderInterface
			{/*...}*/
				protected alias visual_type = ArtStyle; // REFACTOR visual/style
				public:
				public {/*render list}*/
					Appendable!(Order!ArtStyle[]) render_list; // TODO autoinit?
				}
				protected:
				shared final {/*shader interface}*/
					void execute ()
						in {/*...}*/
							assert (protocol_check, ArtStyle.stringof~" shader failed protocol");
						}
						body {/*...}*/
							gl.UseProgram (program);
							with (cast()this) // REVIEW
							foreach (order; render_list) 
								{/*...}*/
									with (cast(shared)this) // REVIEW
									preprocess (order);
									gl.DrawArrays (order.mode, order.index, order.length);
								}
							with (cast()this) // REVIEW
							render_list.clear;
						}
				}
				shared {/*shader settings}*/
					void set_texture (GLuint texture)
						{/*...}*/
							gl.BindTexture (GL_TEXTURE_2D, texture);
						}
					void set_uniform (T) (GLint handle, Vec2!T vector)
						{/*...}*/
							static if (is (T == float))
								const string type = "f";
							static if (is (T == int))
								const string type = "i";
							static if (is (T == uint))
								const string type = "ui";
							mixin ("glUniform2"~type~" (handle, vector.x, vector.y);");
						}
					void set_uniform (GLint handle, Color color)
						{/*...}*/
							gl.Uniform4f (handle, color.r, color.g, color.b, color.a);
						}
					void set_uniform (Tn...) (GLint handle, Tn args)
						{/*...}*/
							static if (is (Tn[0] : bool))
								const string type = "i";
							else static if (is (Tn[0] : int))
								const string type = "i";
							else static if (is (Tn[0] : float))
								const string type = "f";
							const string length = to!string (Tn.length);
							mixin ("glUniform"~length~type~" (handle, args);");
						}
				}
				abstract shared {/*preprocessing}*/
					void preprocess (Order!ArtStyle);
				}
				protected {/*data}*/
					GLuint program;
					bool protocol_check;
				}
				protected {/*ctor}*/
					this (string vertex_path, string fragment_path)
						{/*...}*/
							void verify (string object_type) (GLuint gl_object)
								{/*...}*/
									GLint status;

									const string glGet_iv = q{glGet} ~object_type~ q{iv};
									const string glGet_InfoLog = q{glGet} ~object_type~ q{InfoLog};
									const string glStatus = object_type == `Shader`? `COMPILE`:`LINK`;

									mixin(q{
										} ~glGet_iv~ q{ (gl_object, GL_} ~glStatus~ q{_STATUS, &status);
									});

									if (status == GL_FALSE) 
										{/*error}*/
											GLchar[] error_log; 
											GLsizei log_length;

											mixin(q{
												} ~glGet_iv~ q{(gl_object, GL_INFO_LOG_LENGTH, &log_length);
											});

											error_log.length = log_length;

											mixin (q{
												} ~glGet_InfoLog~ q{(gl_object, log_length, null, error_log.ptr);
											});

											if (error_log.startsWith (`Vertex`))
												assert (null, vertex_path~ ` error: ` ~error_log);
											else assert (null, fragment_path~ ` error: ` ~error_log);
										}
								}

							auto build_shader (GLenum shader_type, string path)
								in {/*...}*/
									if (not (exists (path)))
										assert (null, `error: couldn't find ` ~path);
								}
								out (shader) {/*...}*/
									verify!`Shader` (shader);
								}
								body {/*...}*/
									GLuint shader = gl.CreateShader (shader_type);

									auto source = readText (path).toStringz;

									gl.ShaderSource (shader, 1, &source, null);
									gl.CompileShader (shader);

									return shader;
								}

							GLuint vert_shader = build_shader (GL_VERTEX_SHADER, vertex_path);
							GLuint frag_shader = build_shader (GL_FRAGMENT_SHADER, fragment_path);

							program = gl.CreateProgram ();

							gl.AttachShader (program, vert_shader);
							gl.AttachShader (program, frag_shader);

							gl.LinkProgram (program); 
							verify!`Program` (program);

							gl.DeleteShader (vert_shader);
							gl.DeleteShader (frag_shader);
							gl.DetachShader (program, vert_shader);
							gl.DetachShader (program, frag_shader);

							gl.UseProgram (program);
						}
				}
			}
	}
	private {/*initialization}*/
		void initialize_shaders (ref ShaderInterface[] array)
			{/*...}*/
				array = new ShaderInterface[Shaders.length];
				foreach (shader_T; Shaders)
					array [staticIndexOf!(shader_T, Shaders)] = new shader_T;
			}
	}
	private {/*shaders}*/
		class BasicShader: Shader!Basic
			{/*...}*/
				public:
					this ()
						{/*...}*/
							super ("./shader/basic.vert", "./shader/basic.frag");
							mixin (uniform_protocol);
						}
				protected:
					override shared void preprocess (Order!Basic order)
						{/*...}*/
							enum: int {none = 0, basic = 1, text = 2, sprite = 3}
							auto shader_mode = none;

							if (order.tex_id != 0)
								{/*...}*/
									shader_mode = sprite;
									set_texture (order.tex_id);
								}
							if (order.base != Color (0,0,0,0))
								{/*...}*/
									if (shader_mode == sprite)
										shader_mode = text;
									else shader_mode = basic;
									set_uniform (color, order.base);
								}
							assert (shader_mode != none);

							set_uniform (mode, shader_mode);
						}
				public:
					@Uniform GLint color;
					@Uniform GLint mode;
			}
	}
}
private {/*orders}*/
	alias OrderTypes = staticMap!(Order, VisualTypes);
	alias RenderOrder = Algebraic!OrderTypes;

	struct Order (ArtStyle = byte)
		{/*...}*/
			public {/*standard}*/
				GLenum mode = int.max;
				uint index = 0;
				uint length = 0;
			}
			public {/*extended}*/
				ArtStyle visual;
				alias visual this;
			}
			public {/*☀}*/
				this (T) (T data)
					{/*...}*/
						this (data.mode, data.index, data.length);
						static if (is (T == Order))
							this.visual = data.visual;
					}
				this (GLenum mode, uint index, uint length)
					{/*...}*/
						this.mode = mode;
						this.index = index;
						this.length = length;
					}
			}
		}

	struct Basic
		{/*...}*/
			Color base = Color (0, 0, 0, 0);
			GLuint tex_id = 0;
		}
}
private {/*types}*/
	alias VisualTypes = TypeTuple!(Basic);
}
private {/*sync signals}*/
	struct RenderCommand {}
	struct AccessConfirmation {}
}
