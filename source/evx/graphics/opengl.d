module evx.graphics.opengl;

private {/*imports}*/
	import std.conv;
	import std.typecons;
	import std.string;

	import evx.misc.utils;
	import evx.type;
	import evx.math;
	import evx.range;
}
public:
	import derelict.glfw3.glfw3;
	import derelict.opengl3.gl3;

//TODO make specific error messages for all the openGL calls
class Context
	{/*...}*/
		this ()
			{/*...}*/
				DerelictGL3.load ();

				DerelictGLFW3.load ();

				glfwSetErrorCallback (&error_callback);

				auto initialized = glfwInit ()? true: false;

				assert (initialized, "glfwInit failed");
					
				void initialize_glfw_window ()
					{/*...}*/
						window = glfwCreateWindow (0, 0, ``, null, null); // REVIEW hidden window
	
	???

						if (window is null)
							assert (0, `window creation failure`);

						//glfwShowWindow (window);
						//glfwHideWindow (window);

						glfwMakeContextCurrent (window);
						glfwSwapInterval (0);

						glfwSetWindowSizeCallback (window, &resize_window_callback);
						glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

						glfwSetWindowUserPointer (window, cast(void*)this);

						glfwSetWindowTitle (window, text (
							`evx.graphics.display `,
							`(openGL `,
								glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MAJOR),
								`.`,
								glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MINOR),
							`)`
						).to_c.expand);
					}
				void initialize_gl ()
					{/*...}*/
						gl.ClearColor (0.1, 0.1, 0.1, 1.0);

						gl.Enable (GL_BLEND);
						gl.BlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
					}
			}
		~this ()
			{/*...}*/
				void terminate_glfw () // TODO shared static this??
					{/*...}*/
						if (window !is null)
							glfwDestroyWindow (window);

						glfwTerminate ();
					}

				gl.reset;
			}

		void clear ()
			{/*...}*/
				gl.Clear (GL_COLOR_BUFFER_BIT);
			}
		void swap ()
			{/*...}*/
				gl.clear;

				glfwSwapBuffers (window);
			}

		void delegate (size_t width, size_t height) nothrow on_resize; // REVIEW

		private:

		GLFWwindow* window;
		GLuint[] programs; 

		union {/*buffers}*/
			static if (0) // BUG https://issues.dlang.org/show_bug.cgi?id=13891
			GLuint[10] buffers;
			struct {/*...}*/
				GLuint 
				array_buffer,
				element_array_buffer,
				copy_read_buffer,
				copy_write_buffer,
				pixel_pack_buffer,
				pixel_unpack_buffer,
				query_buffer,
				shader_storage_buffer,
				transform_feedback_buffer,
				uniform_buffer;
			}
		}
		union {/*framebuffers}*/
			static if (0) // BUG https://issues.dlang.org/show_bug.cgi?id=13891
			GLuint[2] framebuffers;
			struct {/*...}*/
				GLuint
					draw_framebuffer,
					read_framebuffer;
			}
		}
		union {/*textures}*/
			static if (0) // BUG https://issues.dlang.org/show_bug.cgi?id=13891
			GLuint[11] textures;
			struct {/*...}*/
				GLuint
				texture_1D,
				texture_2D,
				texture_3D,
				texture_1D_array,
				texture_2D_array,
				texture_rectangle,
				texture_cube_map,
				texture_cube_map_array,
				texture_buffer,
				texture_2D_multisample,
				texture_2D_multisample_array;
			}
		}

		auto buffers ()  // HACK https://issues.dlang.org/show_bug.cgi?id=13891
			{/*...}*/
				return (&array_buffer)[0..10];
			}
		auto framebuffers ()  // HACK https://issues.dlang.org/show_bug.cgi?id=13891
			{/*...}*/
				return (&draw_framebuffer)[0..2];
			}
		auto textures ()  // HACK https://issues.dlang.org/show_bug.cgi?id=13891
			{/*...}*/
				return (&texture_1D)[0..11];
			}

		auto framebuffer (GLuint buffer)
			out {/*...}*/
				void check_framebuffer ()
					{/*...}*/
						switch (gl.CheckFramebufferStatus (GL_FRAMEBUFFER)) 
							{/*...}*/
								case GL_FRAMEBUFFER_COMPLETE:
									return;

								case GL_FRAMEBUFFER_UNDEFINED:
									assert(0, `target is the default framebuffer, but the default framebuffer does not exist.`);

								case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
									assert(0, `some of the framebuffer attachment points are framebuffer incomplete.`);

								case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
									assert(0, `framebuffer does not have at least one image attached to it.`);

								case GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER:
									assert(0, `value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for some color attachment point(s) named by GL_DRAW_BUFFERi.`);

								case GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER:
									assert(0, `GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for the color attachment point named by GL_READ_BUFFER.`);

								case GL_FRAMEBUFFER_UNSUPPORTED:
									assert(0, `combination of internal formats of the attached images violates an implementation-dependent set of restrictions.`);

								case GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE:
									assert(0, `value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers; or the value of GL_TEXTURE_SAMPLES is the not same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_RENDERBUFFER_SAMPLES does not match the value of GL_TEXTURE_SAMPLES.`
										"\n"`or the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not the same for all attached textures; or the attached images are a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not GL_TRUE for all attached textures.`
									);

								case GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS:
									assert(0, `some framebuffer attachment is layered, and some populated attachment is not layered, or all populated color attachments are not from textures of the same target.`);

								default:
									assert (0, `framebuffer error`);
							}
					}

				//check_framebuffer; TEMP
			}
			body {/*...}*/
				return draw_framebuffer = read_framebuffer = buffer;
			}
		auto framebuffer ()
			in {/*...}*/
				assert (draw_framebuffer == read_framebuffer);
			}
			body {/*...}*/
				return draw_framebuffer;
			}
	}
struct gl
	{/*...}*/
		static:

		Context context;

		template type (T)
			{/*...}*/
				alias ConversionTable = Cons!(
					byte,   GL_BYTE,
					ubyte,  GL_UNSIGNED_BYTE,
					short,  GL_SHORT,
					ushort, GL_UNSIGNED_SHORT,
					int,    GL_INT,
					uint,   GL_UNSIGNED_INT,
					float,  GL_FLOAT,
					double, GL_DOUBLE,
				);

				enum index = IndexOf!(T, ConversionTable) + 1;

				static if (0 < index && index < ConversionTable.length - 1)
					enum type = ConversionTable[index];
				else static assert (0, T.stringof ~ ` has no opengl equivalent`);
			}

		auto opDispatch (string name, Args...)(auto ref Args args)
			in {/*...}*/
				enum errmsg (string target) = `set gl.` ~ target ~ ` = ` ~ target ~ ` id or an object containing a ` ~ target ~ `_id instead`;

				static assert (name.not!contains (`UseProgram`), errmsg!`program`);
				static assert (name.not!contains (`Bind`), errmsg!(name[4..$].toLower));

				assert (not (this.context is null),
					`no rendering context available to call ` ~ name
				);
			}
			body {/*...}*/
				auto use_program ()()
					{/*...}*/
						static assert (name == `program`);

						static if (is (Args[0]))
							{/*...}*/
								auto has_id ()() {return args[0].program_id;}
								auto is_id ()() {return args[0];}

								GLuint id = Match!(has_id, is_id);

								if (this.context.program == id)
									return;

								call!`UseProgram` (id);

								this.context.program = id;
							}
						else return this.context.program;
					}
				auto bind_buffer ()()
					{/*...}*/
						static assert (name != `program`);

						enum target = mixin(q{GL_} ~ name.toUpper);

						static if (is (Args[0]))
							{/*...}*/
								auto has_id ()() // REVIEW to be removed once all graphics resource bind_bufferings are standardized
									{/*...}*/
										static if (name.contains (`texture`))
											return args[0].texture_id;

										else static if (name.contains (`framebuffer`)) // REVIEW CanvasOps will handle this, to be removed..
											return args[0].framebuffer_id;

										else return args[0].buffer_id;
									}
								auto is_id ()()
									{/*...}*/
										return args[0];
									}

								GLuint id = Match!(has_id, is_id);

								if (mixin(q{this.context.} ~ name) == id)
									return;

								static if (name.contains (`texture`))
									call!`BindTexture` (target, id);

								else static if (name.contains (`framebuffer`))
									{/*...}*/
										call!`BindFramebuffer` (target, id);

										void render_to_texture ()()
											{/*...}*/
												gl.FramebufferTexture (GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, args[0].texture_id, 0);
											}
										void render_to_display ()() {} 

										Match!(render_to_texture, render_to_display);

										if (id == 0)
											gl.DrawBuffer (GL_BACK);
										else gl.DrawBuffer (GL_COLOR_ATTACHMENT0);
									}

								else call!`BindBuffer` (target, id);

								mixin(q{
									this.context.} ~ name ~ q{ = id;
								});
							}
						else mixin(q{
							return this.context.} ~ name ~ q{;
						});
					}
				auto unbind_buffer ()()
					{/*...}*/
						static assert (name.contains (`Delete`));

						auto buffer_group = mixin(q{this.context.} ~ name.after (`Delete`).toLower)[];
						auto n = args[0];
						auto ids = args[1];

						foreach (id; ids[0..n])
							{/*...}*/
								auto result = buffer_group[].find (id);

								if (result.empty)
									continue;
								else result.front = 0;
							}

						call!name (args);
					}
				auto forward_to_gl ()()
					{/*...}*/
						static if (name.contains (`Delete`))
							static assert (name.contains (`Program`) || name.contains (`Shader`));

						return call!name (args.to_c.expand);
					}

				return Match!(use_program, bind_buffer, unbind_buffer, forward_to_gl);
			}

		void reset ()
			{/*...}*/
				destroy (context);
			}

		void uniform (T)(T value, GLuint index = 0)
			in {/*...}*/
				GLint program, n_uniforms;

				gl.GetIntegerv (GL_CURRENT_PROGRAM, &program); // TODO replace with global gl state call
				assert (program != 0, `no active program`);

				gl.GetProgramiv (program, GL_ACTIVE_UNIFORMS, &n_uniforms);
				assert (index < n_uniforms, `uniform location invalid`);

				char[256] name;
				GLint sizeof;
				GLenum type;
				GLint length;

				gl.GetActiveUniform (program, index, name.length.to!int, &length, &sizeof, &type, name.ptr);

				auto uniform_type (T)()
					{/*...}*/
						import evx.graphics.texture;//TEMP circular dep

						alias ConversionTable = Cons!(
							float, `FLOAT`,
							double, `DOUBLE`,
							int, `INT`,
							uint, `UNSIGNED_INT`,
							bool, `BOOL`,
						);

						static if (is (T == Vector!(n,U), uint n, U))
							enum components = `_VEC` ~ n.text;
						else {/*...}*/
							enum components = ``;
							alias U = T;
						}
							
						static if (Contains!(U, ConversionTable))
							mixin(q{
								return GL_} ~ ConversionTable[IndexOf!(U, ConversionTable) + 1] ~ components ~ q{;
							});
						else return -1;
					}
				auto uniform_call (GLenum type)
					{/*...}*/
						return [
							-1: `unknown type`,

							GL_FLOAT: `float`,
							GL_FLOAT_VEC2: `vec2`,
							GL_FLOAT_VEC3: `vec3`,
							GL_FLOAT_VEC4: `vec4`,
							GL_DOUBLE: `double`,
							GL_DOUBLE_VEC2: `dvec2`,
							GL_DOUBLE_VEC3: `dvec3`,
							GL_DOUBLE_VEC4: `dvec4`,
							GL_INT: `int`,
							GL_INT_VEC2: `ivec2`,
							GL_INT_VEC3: `ivec3`,
							GL_INT_VEC4: `ivec4`,
							GL_UNSIGNED_INT: `uint`,
							GL_UNSIGNED_INT_VEC2: `uvec2`,
							GL_UNSIGNED_INT_VEC3: `uvec3`,
							GL_UNSIGNED_INT_VEC4: `uvec4`,
							GL_BOOL: `bool`,
							GL_BOOL_VEC2: `bvec2`,
							GL_BOOL_VEC3: `bvec3`,
							GL_BOOL_VEC4: `bvec4`,
							GL_FLOAT_MAT2: `mat2`,
							GL_FLOAT_MAT3: `mat3`,
							GL_FLOAT_MAT4: `mat4`,
							GL_FLOAT_MAT2x3: `mat2x3`,
							GL_FLOAT_MAT2x4: `mat2x4`,
							GL_FLOAT_MAT3x2: `mat3x2`,
							GL_FLOAT_MAT3x4: `mat3x4`,
							GL_FLOAT_MAT4x2: `mat4x2`,
							GL_FLOAT_MAT4x3: `mat4x3`,
							GL_DOUBLE_MAT2: `dmat2`,
							GL_DOUBLE_MAT3: `dmat3`,
							GL_DOUBLE_MAT4: `dmat4`,
							GL_DOUBLE_MAT2x3: `dmat2x3`,
							GL_DOUBLE_MAT2x4: `dmat2x4`,
							GL_DOUBLE_MAT3x2: `dmat3x2`,
							GL_DOUBLE_MAT3x4: `dmat3x4`,
							GL_DOUBLE_MAT4x2: `dmat4x2`,
							GL_DOUBLE_MAT4x3: `dmat4x3`,
							GL_SAMPLER_1D: `sampler1D`,
							GL_SAMPLER_2D: `sampler2D`,
							GL_SAMPLER_3D: `sampler3D`,
							GL_SAMPLER_CUBE: `samplerCube`,
							GL_SAMPLER_1D_SHADOW: `sampler1DShadow`,
							GL_SAMPLER_2D_SHADOW: `sampler2DShadow`,
							GL_SAMPLER_1D_ARRAY: `sampler1DArray`,
							GL_SAMPLER_2D_ARRAY: `sampler2DArray`,
							GL_SAMPLER_1D_ARRAY_SHADOW: `sampler1DArrayShadow`,
							GL_SAMPLER_2D_ARRAY_SHADOW: `sampler2DArrayShadow`,
							GL_SAMPLER_2D_MULTISAMPLE: `sampler2DMS`,
							GL_SAMPLER_2D_MULTISAMPLE_ARRAY: `sampler2DMSArray`,
							GL_SAMPLER_CUBE_SHADOW: `samplerCubeShadow`,
							GL_SAMPLER_BUFFER: `samplerBuffer`,
							GL_SAMPLER_2D_RECT: `sampler2DRect`,
							GL_SAMPLER_2D_RECT_SHADOW: `sampler2DRectShadow`,
							GL_INT_SAMPLER_1D: `isampler1D`,
							GL_INT_SAMPLER_2D: `isampler2D`,
							GL_INT_SAMPLER_3D: `isampler3D`,
							GL_INT_SAMPLER_CUBE: `isamplerCube`,
							GL_INT_SAMPLER_1D_ARRAY: `isampler1DArray`,
							GL_INT_SAMPLER_2D_ARRAY: `isampler2DArray`,
							GL_INT_SAMPLER_2D_MULTISAMPLE: `isampler2DMS`,
							GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: `isampler2DMSArray`,
							GL_INT_SAMPLER_BUFFER: `isamplerBuffer`,
							GL_INT_SAMPLER_2D_RECT: `isampler2DRect`,
							GL_UNSIGNED_INT_SAMPLER_1D: `usampler1D`,
							GL_UNSIGNED_INT_SAMPLER_2D: `usampler2D`,
							GL_UNSIGNED_INT_SAMPLER_3D: `usampler3D`,
							GL_UNSIGNED_INT_SAMPLER_CUBE: `usamplerCube`,
							GL_UNSIGNED_INT_SAMPLER_1D_ARRAY: `usampler2DArray`,
							GL_UNSIGNED_INT_SAMPLER_2D_ARRAY: `usampler2DArray`,
							GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE: `usampler2DMS`,
							GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY: `usampler2DMSArray`,
							GL_UNSIGNED_INT_SAMPLER_BUFFER: `usamplerBuffer`,
							GL_UNSIGNED_INT_SAMPLER_2D_RECT: `usampler2DRect`,
							GL_IMAGE_1D: `image1D`,
							GL_IMAGE_2D: `image2D`,
							GL_IMAGE_3D: `image3D`,
							GL_IMAGE_2D_RECT: `image2DRect`,
							GL_IMAGE_CUBE: `imageCube`,
							GL_IMAGE_BUFFER: `imageBuffer`,
							GL_IMAGE_1D_ARRAY: `image1DArray`,
							GL_IMAGE_2D_ARRAY: `image2DArray`,
							GL_IMAGE_2D_MULTISAMPLE: `image2DMS`,
							GL_IMAGE_2D_MULTISAMPLE_ARRAY: `image2DMSArray`,
							GL_INT_IMAGE_1D: `iimage1D`,
							GL_INT_IMAGE_2D: `iimage2D`,
							GL_INT_IMAGE_3D: `iimage3D`,
							GL_INT_IMAGE_2D_RECT: `iimage2DRect`,
							GL_INT_IMAGE_CUBE: `iimageCube`,
							GL_INT_IMAGE_BUFFER: `iimageBuffer`,
							GL_INT_IMAGE_1D_ARRAY: `iimage1DArray`,
							GL_INT_IMAGE_2D_ARRAY: `iimage2DArray`,
							GL_INT_IMAGE_2D_MULTISAMPLE: `iimage2DMS`,
							GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY: `iimage2DMSArray`,
							GL_UNSIGNED_INT_IMAGE_1D: `uimage1D`,
							GL_UNSIGNED_INT_IMAGE_2D: `uimage2D`,
							GL_UNSIGNED_INT_IMAGE_3D: `uimage3D`,
							GL_UNSIGNED_INT_IMAGE_2D_RECT: `uimage2DRect`,
							GL_UNSIGNED_INT_IMAGE_CUBE: `uimageCube`,
							GL_UNSIGNED_INT_IMAGE_BUFFER: `uimageBuffer`,
							GL_UNSIGNED_INT_IMAGE_1D_ARRAY: `uimage1DArray`,
							GL_UNSIGNED_INT_IMAGE_2D_ARRAY: `uimage2DArray`,
							GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE: `uimage2DMS`,
							GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY: `uimage2DMSArray`,
							GL_UNSIGNED_INT_ATOMIC_COUNTER: `atomic_uint`,
						][type];
					}

				if (type != GL_SAMPLER_2D)
					assert (type == uniform_type!T,
						`attempted to upload ` ~ T.stringof ~ ` to uniform ` ~ uniform_call (type) ~ ` ` ~ name[0..length]
						~ `, use ` ~ uniform_call (type) ~ ` instead.`
					);
				else assert (is (T == int),
					`texture sampler uniform must bind a texture unit index, not a ` ~ T.stringof
				);
			}
			body {/*...}*/
				static if (is (T == Vector!(n,U), uint n, U))
					{}
				else {/*...}*/
					enum n = 1;
					alias U = T;
				}

				mixin(q{
					gl.Uniform} ~ n.text ~ U.stringof[0] ~ q{ (index, value.tuple.expand);
				});
			}

		auto verify (string object_type)(GLuint gl_object)
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

						return error_log.to!string;
					}
				else return null;
			}

		private {/*...}*/
			auto call (string name, Args...)(Args args)
				out {/*...}*/
					error_check!name (args);
				}
				body {/*...}*/
					try std.stdio.stderr.writeln (name, args);
					catch (Exception) assert (0, `fuck`);

					mixin (q{
						return gl} ~ name ~ q{ (args.to_c.expand);
					});
				}

			void error_check (string name, Args...) (Args args)
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

							assert (0, `OpenGL error ` ~error.text~ `: ` ~error_msg~ "\n"
								`    calling gl` ~function_call_to_string!name (args)
							);
						}
				}

			extern (C) nothrow {/*callbacks}*/
				void error_callback (int, const (char)* error)
					{/*...}*/
						import std.c.stdio;

						fprintf (stderr, "error glfw: %s\n", error);
					}
				void resize_framebuffer_callback (GLFWwindow* window, int width, int height)
					{/*...}*/
						gl.Viewport (0, 0, width, height);
						//try gl.Viewport (0, 0, width, height);
						//catch (Exception ex) assert (0, ex.msg);
					}
				void resize_window_callback (GLFWwindow* window, int width, int height)
					{/*...}*/
						auto context = cast(Context) glfwGetWindowUserPointer (window);

						if (context.on_resize !is null)
							context.on_resize (width, height);
					}
			}
		}

		///////////////////////
		///////////////////////
		///////////////////////
		{/*TODO organize target enums - GL_TEXTURE_2D, GL_READ_COPY_BUFFER, GL_COMPUTE_SHADER, ETC}*/
			// OpenGL 1.1
			GL_DEPTH_BUFFER_BIT               = 0x00000100,
			GL_STENCIL_BUFFER_BIT             = 0x00000400,
			GL_COLOR_BUFFER_BIT               = 0x00004000,
			GL_POINTS                         = 0x0000,
			GL_LINES                          = 0x0001,
			GL_LINE_LOOP                      = 0x0002,
			GL_LINE_STRIP                     = 0x0003,
			GL_TRIANGLES                      = 0x0004,
			GL_TRIANGLE_STRIP                 = 0x0005,
			GL_TRIANGLE_FAN                   = 0x0006,
			GL_NEVER                          = 0x0200,
			GL_LESS                           = 0x0201,
			GL_EQUAL                          = 0x0202,
			GL_LEQUAL                         = 0x0203,
			GL_GREATER                        = 0x0204,
			GL_NOTEQUAL                       = 0x0205,
			GL_GEQUAL                         = 0x0206,
			GL_ALWAYS                         = 0x0207,
			GL_ZERO                           = 0,
			GL_ONE                            = 1,
			GL_SRC_COLOR                      = 0x0300,
			GL_ONE_MINUS_SRC_COLOR            = 0x0301,
			GL_SRC_ALPHA                      = 0x0302,
			GL_ONE_MINUS_SRC_ALPHA            = 0x0303,
			GL_DST_ALPHA                      = 0x0304,
			GL_ONE_MINUS_DST_ALPHA            = 0x0305,
			GL_DST_COLOR                      = 0x0306,
			GL_ONE_MINUS_DST_COLOR            = 0x0307,
			GL_SRC_ALPHA_SATURATE             = 0x0308,
			GL_NONE                           = 0,
			GL_FRONT_LEFT                     = 0x0400,
			GL_FRONT_RIGHT                    = 0x0401,
			GL_BACK_LEFT                      = 0x0402,
			GL_BACK_RIGHT                     = 0x0403,
			GL_FRONT                          = 0x0404,
			GL_BACK                           = 0x0405,
			GL_LEFT                           = 0x0406,
			GL_RIGHT                          = 0x0407,
			GL_FRONT_AND_BACK                 = 0x0408,
			GL_NO_ERROR                       = 0,
			GL_INVALID_ENUM                   = 0x0500,
			GL_INVALID_VALUE                  = 0x0501,
			GL_INVALID_OPERATION              = 0x0502,
			GL_OUT_OF_MEMORY                  = 0x0505,
			GL_CW                             = 0x0900,
			GL_CCW                            = 0x0901,
			GL_POINT_SIZE                     = 0x0B11,
			GL_POINT_SIZE_RANGE               = 0x0B12,
			GL_POINT_SIZE_GRANULARITY         = 0x0B13,
			GL_LINE_SMOOTH                    = 0x0B20,
			GL_LINE_WIDTH                     = 0x0B21,
			GL_LINE_WIDTH_RANGE               = 0x0B22,
			GL_LINE_WIDTH_GRANULARITY         = 0x0B23,
			GL_POLYGON_SMOOTH                 = 0x0B41,
			GL_CULL_FACE                      = 0x0B44,
			GL_CULL_FACE_MODE                 = 0x0B45,
			GL_FRONT_FACE                     = 0x0B46,
			GL_DEPTH_RANGE                    = 0x0B70,
			GL_DEPTH_TEST                     = 0x0B71,
			GL_DEPTH_WRITEMASK                = 0x0B72,
			GL_DEPTH_CLEAR_VALUE              = 0x0B73,
			GL_DEPTH_FUNC                     = 0x0B74,
			GL_STENCIL_TEST                   = 0x0B90,
			GL_STENCIL_CLEAR_VALUE            = 0x0B91,
			GL_STENCIL_FUNC                   = 0x0B92,
			GL_STENCIL_VALUE_MASK             = 0x0B93,
			GL_STENCIL_FAIL                   = 0x0B94,
			GL_STENCIL_PASS_DEPTH_FAIL        = 0x0B95,
			GL_STENCIL_PASS_DEPTH_PASS        = 0x0B96,
			GL_STENCIL_REF                    = 0x0B97,
			GL_STENCIL_WRITEMASK              = 0x0B98,
			GL_VIEWPORT                       = 0x0BA2,
			GL_DITHER                         = 0x0BD0,
			GL_BLEND_DST                      = 0x0BE0,
			GL_BLEND_SRC                      = 0x0BE1,
			GL_BLEND                          = 0x0BE2,
			GL_LOGIC_OP_MODE                  = 0x0BF0,
			GL_COLOR_LOGIC_OP                 = 0x0BF2,
			GL_DRAW_BUFFER                    = 0x0C01,
			GL_READ_BUFFER                    = 0x0C02,
			GL_SCISSOR_BOX                    = 0x0C10,
			GL_SCISSOR_TEST                   = 0x0C11,
			GL_COLOR_CLEAR_VALUE              = 0x0C22,
			GL_COLOR_WRITEMASK                = 0x0C23,
			GL_DOUBLEBUFFER                   = 0x0C32,
			GL_STEREO                         = 0x0C33,
			GL_LINE_SMOOTH_HINT               = 0x0C52,
			GL_POLYGON_SMOOTH_HINT            = 0x0C53,
			GL_UNPACK_SWAP_BYTES              = 0x0CF0,
			GL_UNPACK_LSB_FIRST               = 0x0CF1,
			GL_UNPACK_ROW_LENGTH              = 0x0CF2,
			GL_UNPACK_SKIP_ROWS               = 0x0CF3,
			GL_UNPACK_SKIP_PIXELS             = 0x0CF4,
			GL_UNPACK_ALIGNMENT               = 0x0CF5,
			GL_PACK_SWAP_BYTES                = 0x0D00,
			GL_PACK_LSB_FIRST                 = 0x0D01,
			GL_PACK_ROW_LENGTH                = 0x0D02,
			GL_PACK_SKIP_ROWS                 = 0x0D03,
			GL_PACK_SKIP_PIXELS               = 0x0D04,
			GL_PACK_ALIGNMENT                 = 0x0D05,
			GL_MAX_TEXTURE_SIZE               = 0x0D33,
			GL_MAX_VIEWPORT_DIMS              = 0x0D3A,
			GL_SUBPIXEL_BITS                  = 0x0D50,
			GL_TEXTURE_1D                     = 0x0DE0,
			GL_TEXTURE_2D                     = 0x0DE1,
			GL_POLYGON_OFFSET_UNITS           = 0x2A00,
			GL_POLYGON_OFFSET_POINT           = 0x2A01,
			GL_POLYGON_OFFSET_LINE            = 0x2A02,
			GL_POLYGON_OFFSET_FILL            = 0x8037,
			GL_POLYGON_OFFSET_FACTOR          = 0x8038,
			GL_TEXTURE_BINDING_1D             = 0x8068,
			GL_TEXTURE_BINDING_2D             = 0x8069,
			GL_TEXTURE_WIDTH                  = 0x1000,
			GL_TEXTURE_HEIGHT                 = 0x1001,
			GL_TEXTURE_INTERNAL_FORMAT        = 0x1003,
			GL_TEXTURE_BORDER_COLOR           = 0x1004,
			GL_TEXTURE_RED_SIZE               = 0x805C,
			GL_TEXTURE_GREEN_SIZE             = 0x805D,
			GL_TEXTURE_BLUE_SIZE              = 0x805E,
			GL_TEXTURE_ALPHA_SIZE             = 0x805F,
			GL_DONT_CARE                      = 0x1100,
			GL_FASTEST                        = 0x1101,
			GL_NICEST                         = 0x1102,
			GL_BYTE                           = 0x1400,
			GL_UNSIGNED_BYTE                  = 0x1401,
			GL_SHORT                          = 0x1402,
			GL_UNSIGNED_SHORT                 = 0x1403,
			GL_INT                            = 0x1404,
			GL_UNSIGNED_INT                   = 0x1405,
			GL_FLOAT                          = 0x1406,
			GL_DOUBLE                         = 0x140A,
			GL_CLEAR                          = 0x1500,
			GL_AND                            = 0x1501,
			GL_AND_REVERSE                    = 0x1502,
			GL_COPY                           = 0x1503,
			GL_AND_INVERTED                   = 0x1504,
			GL_NOOP                           = 0x1505,
			GL_XOR                            = 0x1506,
			GL_OR                             = 0x1507,
			GL_NOR                            = 0x1508,
			GL_EQUIV                          = 0x1509,
			GL_INVERT                         = 0x150A,
			GL_OR_REVERSE                     = 0x150B,
			GL_COPY_INVERTED                  = 0x150C,
			GL_OR_INVERTED                    = 0x150D,
			GL_NAND                           = 0x150E,
			GL_SET                            = 0x150F,
			GL_TEXTURE                        = 0x1702,
			GL_COLOR                          = 0x1800,
			GL_DEPTH                          = 0x1801,
			GL_STENCIL                        = 0x1802,
			GL_STENCIL_INDEX                  = 0x1901,
			GL_DEPTH_COMPONENT                = 0x1902,
			GL_RED                            = 0x1903,
			GL_GREEN                          = 0x1904,
			GL_BLUE                           = 0x1905,
			GL_ALPHA                          = 0x1906,
			GL_RGB                            = 0x1907,
			GL_RGBA                           = 0x1908,
			GL_POINT                          = 0x1B00,
			GL_LINE                           = 0x1B01,
			GL_FILL                           = 0x1B02,
			GL_KEEP                           = 0x1E00,
			GL_REPLACE                        = 0x1E01,
			GL_INCR                           = 0x1E02,
			GL_DECR                           = 0x1E03,
			GL_VENDOR                         = 0x1F00,
			GL_RENDERER                       = 0x1F01,
			GL_VERSION                        = 0x1F02,
			GL_EXTENSIONS                     = 0x1F03,
			GL_NEAREST                        = 0x2600,
			GL_LINEAR                         = 0x2601,
			GL_NEAREST_MIPMAP_NEAREST         = 0x2700,
			GL_LINEAR_MIPMAP_NEAREST          = 0x2701,
			GL_NEAREST_MIPMAP_LINEAR          = 0x2702,
			GL_LINEAR_MIPMAP_LINEAR           = 0x2703,
			GL_TEXTURE_MAG_FILTER             = 0x2800,
			GL_TEXTURE_MIN_FILTER             = 0x2801,
			GL_TEXTURE_WRAP_S                 = 0x2802,
			GL_TEXTURE_WRAP_T                 = 0x2803,
			GL_PROXY_TEXTURE_1D               = 0x8063,
			GL_PROXY_TEXTURE_2D               = 0x8064,
			GL_REPEAT                         = 0x2901,
			GL_R3_G3_B2                       = 0x2A10,
			GL_RGB4                           = 0x804F,
			GL_RGB5                           = 0x8050,
			GL_RGB8                           = 0x8051,
			GL_RGB10                          = 0x8052,
			GL_RGB12                          = 0x8053,
			GL_RGB16                          = 0x8054,
			GL_RGBA2                          = 0x8055,
			GL_RGBA4                          = 0x8056,
			GL_RGB5_A1                        = 0x8057,
			GL_RGBA8                          = 0x8058,
			GL_RGB10_A2                       = 0x8059,
			GL_RGBA12                         = 0x805A,
			GL_RGBA16                         = 0x805B,

			// OpenGL 1.2
			GL_UNSIGNED_BYTE_3_3_2            = 0x8032,
			GL_UNSIGNED_SHORT_4_4_4_4         = 0x8033,
			GL_UNSIGNED_SHORT_5_5_5_1         = 0x8034,
			GL_UNSIGNED_INT_8_8_8_8           = 0x8035,
			GL_UNSIGNED_INT_10_10_10_2        = 0x8036,
			GL_TEXTURE_BINDING_3D             = 0x806A,
			GL_PACK_SKIP_IMAGES               = 0x806B,
			GL_PACK_IMAGE_HEIGHT              = 0x806C,
			GL_UNPACK_SKIP_IMAGES             = 0x806D,
			GL_UNPACK_IMAGE_HEIGHT            = 0x806E,
			GL_TEXTURE_3D                     = 0x806F,
			GL_PROXY_TEXTURE_3D               = 0x8070,
			GL_TEXTURE_DEPTH                  = 0x8071,
			GL_TEXTURE_WRAP_R                 = 0x8072,
			GL_MAX_3D_TEXTURE_SIZE            = 0x8073,
			GL_UNSIGNED_BYTE_2_3_3_REV        = 0x8362,
			GL_UNSIGNED_SHORT_5_6_5           = 0x8363,
			GL_UNSIGNED_SHORT_5_6_5_REV       = 0x8364,
			GL_UNSIGNED_SHORT_4_4_4_4_REV     = 0x8365,
			GL_UNSIGNED_SHORT_1_5_5_5_REV     = 0x8366,
			GL_UNSIGNED_INT_8_8_8_8_REV       = 0x8367,
			GL_UNSIGNED_INT_2_10_10_10_REV    = 0x8368,
			GL_BGR                            = 0x80E0,
			GL_BGRA                           = 0x80E1,
			GL_MAX_ELEMENTS_VERTICES          = 0x80E8,
			GL_MAX_ELEMENTS_INDICES           = 0x80E9,
			GL_CLAMP_TO_EDGE                  = 0x812F,
			GL_TEXTURE_MIN_LOD                = 0x813A,
			GL_TEXTURE_MAX_LOD                = 0x813B,
			GL_TEXTURE_BASE_LEVEL             = 0x813C,
			GL_TEXTURE_MAX_LEVEL              = 0x813D,
			GL_SMOOTH_POINT_SIZE_RANGE        = 0x0B12,
			GL_SMOOTH_POINT_SIZE_GRANULARITY  = 0x0B13,
			GL_SMOOTH_LINE_WIDTH_RANGE        = 0x0B22,
			GL_SMOOTH_LINE_WIDTH_GRANULARITY  = 0x0B23,
			GL_ALIASED_LINE_WIDTH_RANGE       = 0x846E,
			GL_CONSTANT_COLOR                 = 0x8001,
			GL_ONE_MINUS_CONSTANT_COLOR       = 0x8002,
			GL_CONSTANT_ALPHA                 = 0x8003,
			GL_ONE_MINUS_CONSTANT_ALPHA       = 0x8004,
			GL_BLEND_COLOR                    = 0x8005,
			GL_FUNC_ADD                       = 0x8006,
			GL_MIN                            = 0x8007,
			GL_MAX                            = 0x8008,
			GL_BLEND_EQUATION                 = 0x8009,
			GL_FUNC_SUBTRACT                  = 0x800A,
			GL_FUNC_REVERSE_SUBTRACT          = 0x800B,

			// OpenGL 1.3
			GL_TEXTURE0                       = 0x84C0,
			GL_TEXTURE1                       = 0x84C1,
			GL_TEXTURE2                       = 0x84C2,
			GL_TEXTURE3                       = 0x84C3,
			GL_TEXTURE4                       = 0x84C4,
			GL_TEXTURE5                       = 0x84C5,
			GL_TEXTURE6                       = 0x84C6,
			GL_TEXTURE7                       = 0x84C7,
			GL_TEXTURE8                       = 0x84C8,
			GL_TEXTURE9                       = 0x84C9,
			GL_TEXTURE10                      = 0x84CA,
			GL_TEXTURE11                      = 0x84CB,
			GL_TEXTURE12                      = 0x84CC,
			GL_TEXTURE13                      = 0x84CD,
			GL_TEXTURE14                      = 0x84CE,
			GL_TEXTURE15                      = 0x84CF,
			GL_TEXTURE16                      = 0x84D0,
			GL_TEXTURE17                      = 0x84D1,
			GL_TEXTURE18                      = 0x84D2,
			GL_TEXTURE19                      = 0x84D3,
			GL_TEXTURE20                      = 0x84D4,
			GL_TEXTURE21                      = 0x84D5,
			GL_TEXTURE22                      = 0x84D6,
			GL_TEXTURE23                      = 0x84D7,
			GL_TEXTURE24                      = 0x84D8,
			GL_TEXTURE25                      = 0x84D9,
			GL_TEXTURE26                      = 0x84DA,
			GL_TEXTURE27                      = 0x84DB,
			GL_TEXTURE28                      = 0x84DC,
			GL_TEXTURE29                      = 0x84DD,
			GL_TEXTURE30                      = 0x84DE,
			GL_TEXTURE31                      = 0x84DF,
			GL_ACTIVE_TEXTURE                 = 0x84E0,
			GL_MULTISAMPLE                    = 0x809D,
			GL_SAMPLE_ALPHA_TO_COVERAGE       = 0x809E,
			GL_SAMPLE_ALPHA_TO_ONE            = 0x809F,
			GL_SAMPLE_COVERAGE                = 0x80A0,
			GL_SAMPLE_BUFFERS                 = 0x80A8,
			GL_SAMPLES                        = 0x80A9,
			GL_SAMPLE_COVERAGE_VALUE          = 0x80AA,
			GL_SAMPLE_COVERAGE_INVERT         = 0x80AB,
			GL_TEXTURE_CUBE_MAP               = 0x8513,
			GL_TEXTURE_BINDING_CUBE_MAP       = 0x8514,
			GL_TEXTURE_CUBE_MAP_POSITIVE_X    = 0x8515,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_X    = 0x8516,
			GL_TEXTURE_CUBE_MAP_POSITIVE_Y    = 0x8517,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_Y    = 0x8518,
			GL_TEXTURE_CUBE_MAP_POSITIVE_Z    = 0x8519,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_Z    = 0x851A,
			GL_PROXY_TEXTURE_CUBE_MAP         = 0x851B,
			GL_MAX_CUBE_MAP_TEXTURE_SIZE      = 0x851C,
			GL_COMPRESSED_RGB                 = 0x84ED,
			GL_COMPRESSED_RGBA                = 0x84EE,
			GL_TEXTURE_COMPRESSION_HINT       = 0x84EF,
			GL_TEXTURE_COMPRESSED_IMAGE_SIZE  = 0x86A0,
			GL_TEXTURE_COMPRESSED             = 0x86A1,
			GL_NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2,
			GL_COMPRESSED_TEXTURE_FORMATS     = 0x86A3,
			GL_CLAMP_TO_BORDER                = 0x812D,

			// OpenGL 1.4
			GL_BLEND_DST_RGB                  = 0x80C8,
			GL_BLEND_SRC_RGB                  = 0x80C9,
			GL_BLEND_DST_ALPHA                = 0x80CA,
			GL_BLEND_SRC_ALPHA                = 0x80CB,
			GL_POINT_FADE_THRESHOLD_SIZE      = 0x8128,
			GL_DEPTH_COMPONENT16              = 0x81A5,
			GL_DEPTH_COMPONENT24              = 0x81A6,
			GL_DEPTH_COMPONENT32              = 0x81A7,
			GL_MIRRORED_REPEAT                = 0x8370,
			GL_MAX_TEXTURE_LOD_BIAS           = 0x84FD,
			GL_TEXTURE_LOD_BIAS               = 0x8501,
			GL_INCR_WRAP                      = 0x8507,
			GL_DECR_WRAP                      = 0x8508,
			GL_TEXTURE_DEPTH_SIZE             = 0x884A,
			GL_TEXTURE_COMPARE_MODE           = 0x884C,
			GL_TEXTURE_COMPARE_FUNC           = 0x884D,

			// OpenGL 1.5
			GL_BUFFER_SIZE                    = 0x8764,
			GL_BUFFER_USAGE                   = 0x8765,
			GL_QUERY_COUNTER_BITS             = 0x8864,
			GL_CURRENT_QUERY                  = 0x8865,
			GL_QUERY_RESULT                   = 0x8866,
			GL_QUERY_RESULT_AVAILABLE         = 0x8867,
			GL_ARRAY_BUFFER                   = 0x8892,
			GL_ELEMENT_ARRAY_BUFFER           = 0x8893,
			GL_ARRAY_BUFFER_BINDING           = 0x8894,
			GL_ELEMENT_ARRAY_BUFFER_BINDING   = 0x8895,
			GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F,
			GL_READ_ONLY                      = 0x88B8,
			GL_WRITE_ONLY                     = 0x88B9,
			GL_READ_WRITE                     = 0x88BA,
			GL_BUFFER_ACCESS                  = 0x88BB,
			GL_BUFFER_MAPPED                  = 0x88BC,
			GL_BUFFER_MAP_POINTER             = 0x88BD,
			GL_STREAM_DRAW                    = 0x88E0,
			GL_STREAM_READ                    = 0x88E1,
			GL_STREAM_COPY                    = 0x88E2,
			GL_STATIC_DRAW                    = 0x88E4,
			GL_STATIC_READ                    = 0x88E5,
			GL_STATIC_COPY                    = 0x88E6,
			GL_DYNAMIC_DRAW                   = 0x88E8,
			GL_DYNAMIC_READ                   = 0x88E9,
			GL_DYNAMIC_COPY                   = 0x88EA,
			GL_SAMPLES_PASSED                 = 0x8914,

			// OpenGL 2.0
			GL_BLEND_EQUATION_RGB             = 0x8009,
			GL_VERTEX_ATTRIB_ARRAY_ENABLED    = 0x8622,
			GL_VERTEX_ATTRIB_ARRAY_SIZE       = 0x8623,
			GL_VERTEX_ATTRIB_ARRAY_STRIDE     = 0x8624,
			GL_VERTEX_ATTRIB_ARRAY_TYPE       = 0x8625,
			GL_CURRENT_VERTEX_ATTRIB          = 0x8626,
			GL_VERTEX_PROGRAM_POINT_SIZE      = 0x8642,
			GL_VERTEX_ATTRIB_ARRAY_POINTER    = 0x8645,
			GL_STENCIL_BACK_FUNC              = 0x8800,
			GL_STENCIL_BACK_FAIL              = 0x8801,
			GL_STENCIL_BACK_PASS_DEPTH_FAIL   = 0x8802,
			GL_STENCIL_BACK_PASS_DEPTH_PASS   = 0x8803,
			GL_MAX_DRAW_BUFFERS               = 0x8824,
			GL_DRAW_BUFFER0                   = 0x8825,
			GL_DRAW_BUFFER1                   = 0x8826,
			GL_DRAW_BUFFER2                   = 0x8827,
			GL_DRAW_BUFFER3                   = 0x8828,
			GL_DRAW_BUFFER4                   = 0x8829,
			GL_DRAW_BUFFER5                   = 0x882A,
			GL_DRAW_BUFFER6                   = 0x882B,
			GL_DRAW_BUFFER7                   = 0x882C,
			GL_DRAW_BUFFER8                   = 0x882D,
			GL_DRAW_BUFFER9                   = 0x882E,
			GL_DRAW_BUFFER10                  = 0x882F,
			GL_DRAW_BUFFER11                  = 0x8830,
			GL_DRAW_BUFFER12                  = 0x8831,
			GL_DRAW_BUFFER13                  = 0x8832,
			GL_DRAW_BUFFER14                  = 0x8833,
			GL_DRAW_BUFFER15                  = 0x8834,
			GL_BLEND_EQUATION_ALPHA           = 0x883D,
			GL_MAX_VERTEX_ATTRIBS             = 0x8869,
			GL_VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A,
			GL_MAX_TEXTURE_IMAGE_UNITS        = 0x8872,
			GL_FRAGMENT_SHADER                = 0x8B30,
			GL_VERTEX_SHADER                  = 0x8B31,
			GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49,
			GL_MAX_VERTEX_UNIFORM_COMPONENTS  = 0x8B4A,
			GL_MAX_VARYING_FLOATS             = 0x8B4B,
			GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C,
			GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D,
			GL_SHADER_TYPE                    = 0x8B4F,
			GL_FLOAT_VEC2                     = 0x8B50,
			GL_FLOAT_VEC3                     = 0x8B51,
			GL_FLOAT_VEC4                     = 0x8B52,
			GL_INT_VEC2                       = 0x8B53,
			GL_INT_VEC3                       = 0x8B54,
			GL_INT_VEC4                       = 0x8B55,
			GL_BOOL                           = 0x8B56,
			GL_BOOL_VEC2                      = 0x8B57,
			GL_BOOL_VEC3                      = 0x8B58,
			GL_BOOL_VEC4                      = 0x8B59,
			GL_FLOAT_MAT2                     = 0x8B5A,
			GL_FLOAT_MAT3                     = 0x8B5B,
			GL_FLOAT_MAT4                     = 0x8B5C,
			GL_SAMPLER_1D                     = 0x8B5D,
			GL_SAMPLER_2D                     = 0x8B5E,
			GL_SAMPLER_3D                     = 0x8B5F,
			GL_SAMPLER_CUBE                   = 0x8B60,
			GL_SAMPLER_1D_SHADOW              = 0x8B61,
			GL_SAMPLER_2D_SHADOW              = 0x8B62,
			GL_DELETE_STATUS                  = 0x8B80,
			GL_COMPILE_STATUS                 = 0x8B81,
			GL_LINK_STATUS                    = 0x8B82,
			GL_VALIDATE_STATUS                = 0x8B83,
			GL_INFO_LOG_LENGTH                = 0x8B84,
			GL_ATTACHED_SHADERS               = 0x8B85,
			GL_ACTIVE_UNIFORMS                = 0x8B86,
			GL_ACTIVE_UNIFORM_MAX_LENGTH      = 0x8B87,
			GL_SHADER_SOURCE_LENGTH           = 0x8B88,
			GL_ACTIVE_ATTRIBUTES              = 0x8B89,
			GL_ACTIVE_ATTRIBUTE_MAX_LENGTH    = 0x8B8A,
			GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B,
			GL_SHADING_LANGUAGE_VERSION       = 0x8B8C,
			GL_CURRENT_PROGRAM                = 0x8B8D,
			GL_POINT_SPRITE_COORD_ORIGIN      = 0x8CA0,
			GL_LOWER_LEFT                     = 0x8CA1,
			GL_UPPER_LEFT                     = 0x8CA2,
			GL_STENCIL_BACK_REF               = 0x8CA3,
			GL_STENCIL_BACK_VALUE_MASK        = 0x8CA4,
			GL_STENCIL_BACK_WRITEMASK         = 0x8CA5,

			// OpenGL 2.1
			GL_PIXEL_PACK_BUFFER              = 0x88EB,
			GL_PIXEL_UNPACK_BUFFER            = 0x88EC,
			GL_PIXEL_PACK_BUFFER_BINDING      = 0x88ED,
			GL_PIXEL_UNPACK_BUFFER_BINDING    = 0x88EF,
			GL_FLOAT_MAT2x3                   = 0x8B65,
			GL_FLOAT_MAT2x4                   = 0x8B66,
			GL_FLOAT_MAT3x2                   = 0x8B67,
			GL_FLOAT_MAT3x4                   = 0x8B68,
			GL_FLOAT_MAT4x2                   = 0x8B69,
			GL_FLOAT_MAT4x3                   = 0x8B6A,
			GL_SRGB                           = 0x8C40,
			GL_SRGB8                          = 0x8C41,
			GL_SRGB_ALPHA                     = 0x8C42,
			GL_SRGB8_ALPHA8                   = 0x8C43,
			GL_COMPRESSED_SRGB                = 0x8C48,
			GL_COMPRESSED_SRGB_ALPHA          = 0x8C49,

			// OpenGL 3.0
			GL_COMPARE_REF_TO_TEXTURE         = 0x884E,
			GL_CLIP_DISTANCE0                 = 0x3000,
			GL_CLIP_DISTANCE1                 = 0x3001,
			GL_CLIP_DISTANCE2                 = 0x3002,
			GL_CLIP_DISTANCE3                 = 0x3003,
			GL_CLIP_DISTANCE4                 = 0x3004,
			GL_CLIP_DISTANCE5                 = 0x3005,
			GL_CLIP_DISTANCE6                 = 0x3006,
			GL_CLIP_DISTANCE7                 = 0x3007,
			GL_MAX_CLIP_DISTANCES             = 0x0D32,
			GL_MAJOR_VERSION                  = 0x821B,
			GL_MINOR_VERSION                  = 0x821C,
			GL_NUM_EXTENSIONS                 = 0x821D,
			GL_CONTEXT_FLAGS                  = 0x821E,
			GL_COMPRESSED_RED                 = 0x8225,
			GL_COMPRESSED_RG                  = 0x8226,
			GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT = 0x0001,
			GL_RGBA32F                        = 0x8814,
			GL_RGB32F                         = 0x8815,
			GL_RGBA16F                        = 0x881A,
			GL_RGB16F                         = 0x881B,
			GL_VERTEX_ATTRIB_ARRAY_INTEGER    = 0x88FD,
			GL_MAX_ARRAY_TEXTURE_LAYERS       = 0x88FF,
			GL_MIN_PROGRAM_TEXEL_OFFSET       = 0x8904,
			GL_MAX_PROGRAM_TEXEL_OFFSET       = 0x8905,
			GL_CLAMP_READ_COLOR               = 0x891C,
			GL_FIXED_ONLY                     = 0x891D,
			GL_MAX_VARYING_COMPONENTS         = 0x8B4B,
			GL_TEXTURE_1D_ARRAY               = 0x8C18,
			GL_PROXY_TEXTURE_1D_ARRAY         = 0x8C19,
			GL_TEXTURE_2D_ARRAY               = 0x8C1A,
			GL_PROXY_TEXTURE_2D_ARRAY         = 0x8C1B,
			GL_TEXTURE_BINDING_1D_ARRAY       = 0x8C1C,
			GL_TEXTURE_BINDING_2D_ARRAY       = 0x8C1D,
			GL_R11F_G11F_B10F                 = 0x8C3A,
			GL_UNSIGNED_INT_10F_11F_11F_REV   = 0x8C3B,
			GL_RGB9_E5                        = 0x8C3D,
			GL_UNSIGNED_INT_5_9_9_9_REV       = 0x8C3E,
			GL_TEXTURE_SHARED_SIZE            = 0x8C3F,
			GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH = 0x8C76,
			GL_TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F,
			GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80,
			GL_TRANSFORM_FEEDBACK_VARYINGS    = 0x8C83,
			GL_TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84,
			GL_TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85,
			GL_PRIMITIVES_GENERATED           = 0x8C87,
			GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88,
			GL_RASTERIZER_DISCARD             = 0x8C89,
			GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A,
			GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B,
			GL_INTERLEAVED_ATTRIBS            = 0x8C8C,
			GL_SEPARATE_ATTRIBS               = 0x8C8D,
			GL_TRANSFORM_FEEDBACK_BUFFER      = 0x8C8E,
			GL_TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F,
			GL_RGBA32UI                       = 0x8D70,
			GL_RGB32UI                        = 0x8D71,
			GL_RGBA16UI                       = 0x8D76,
			GL_RGB16UI                        = 0x8D77,
			GL_RGBA8UI                        = 0x8D7C,
			GL_RGB8UI                         = 0x8D7D,
			GL_RGBA32I                        = 0x8D82,
			GL_RGB32I                         = 0x8D83,
			GL_RGBA16I                        = 0x8D88,
			GL_RGB16I                         = 0x8D89,
			GL_RGBA8I                         = 0x8D8E,
			GL_RGB8I                          = 0x8D8F,
			GL_RED_INTEGER                    = 0x8D94,
			GL_GREEN_INTEGER                  = 0x8D95,
			GL_BLUE_INTEGER                   = 0x8D96,
			GL_RGB_INTEGER                    = 0x8D98,
			GL_RGBA_INTEGER                   = 0x8D99,
			GL_BGR_INTEGER                    = 0x8D9A,
			GL_BGRA_INTEGER                   = 0x8D9B,
			GL_SAMPLER_1D_ARRAY               = 0x8DC0,
			GL_SAMPLER_2D_ARRAY               = 0x8DC1,
			GL_SAMPLER_1D_ARRAY_SHADOW        = 0x8DC3,
			GL_SAMPLER_2D_ARRAY_SHADOW        = 0x8DC4,
			GL_SAMPLER_CUBE_SHADOW            = 0x8DC5,
			GL_UNSIGNED_INT_VEC2              = 0x8DC6,
			GL_UNSIGNED_INT_VEC3              = 0x8DC7,
			GL_UNSIGNED_INT_VEC4              = 0x8DC8,
			GL_INT_SAMPLER_1D                 = 0x8DC9,
			GL_INT_SAMPLER_2D                 = 0x8DCA,
			GL_INT_SAMPLER_3D                 = 0x8DCB,
			GL_INT_SAMPLER_CUBE               = 0x8DCC,
			GL_INT_SAMPLER_1D_ARRAY           = 0x8DCE,
			GL_INT_SAMPLER_2D_ARRAY           = 0x8DCF,
			GL_UNSIGNED_INT_SAMPLER_1D        = 0x8DD1,
			GL_UNSIGNED_INT_SAMPLER_2D        = 0x8DD2,
			GL_UNSIGNED_INT_SAMPLER_3D        = 0x8DD3,
			GL_UNSIGNED_INT_SAMPLER_CUBE      = 0x8DD4,
			GL_UNSIGNED_INT_SAMPLER_1D_ARRAY  = 0x8DD6,
			GL_UNSIGNED_INT_SAMPLER_2D_ARRAY  = 0x8DD7,
			GL_QUERY_WAIT                     = 0x8E13,
			GL_QUERY_NO_WAIT                  = 0x8E14,
			GL_QUERY_BY_REGION_WAIT           = 0x8E15,
			GL_QUERY_BY_REGION_NO_WAIT        = 0x8E16,
			GL_BUFFER_ACCESS_FLAGS            = 0x911F,
			GL_BUFFER_MAP_LENGTH              = 0x9120,
			GL_BUFFER_MAP_OFFSET              = 0x9121,

			// OpenGL 3.1
			GL_SAMPLER_2D_RECT                = 0x8B63,
			GL_SAMPLER_2D_RECT_SHADOW         = 0x8B64,
			GL_SAMPLER_BUFFER                 = 0x8DC2,
			GL_INT_SAMPLER_2D_RECT            = 0x8DCD,
			GL_INT_SAMPLER_BUFFER             = 0x8DD0,
			GL_UNSIGNED_INT_SAMPLER_2D_RECT   = 0x8DD5,
			GL_UNSIGNED_INT_SAMPLER_BUFFER    = 0x8DD8,
			GL_TEXTURE_BUFFER                 = 0x8C2A,
			GL_MAX_TEXTURE_BUFFER_SIZE        = 0x8C2B,
			GL_TEXTURE_BINDING_BUFFER         = 0x8C2C,
			GL_TEXTURE_BUFFER_DATA_STORE_BINDING = 0x8C2D,
			GL_TEXTURE_BUFFER_FORMAT          = 0x8C2E,
			GL_TEXTURE_RECTANGLE              = 0x84F5,
			GL_TEXTURE_BINDING_RECTANGLE      = 0x84F6,
			GL_PROXY_TEXTURE_RECTANGLE        = 0x84F7,
			GL_MAX_RECTANGLE_TEXTURE_SIZE     = 0x84F8,
			GL_RED_SNORM                      = 0x8F90,
			GL_RG_SNORM                       = 0x8F91,
			GL_RGB_SNORM                      = 0x8F92,
			GL_RGBA_SNORM                     = 0x8F93,
			GL_R8_SNORM                       = 0x8F94,
			GL_RG8_SNORM                      = 0x8F95,
			GL_RGB8_SNORM                     = 0x8F96,
			GL_RGBA8_SNORM                    = 0x8F97,
			GL_R16_SNORM                      = 0x8F98,
			GL_RG16_SNORM                     = 0x8F99,
			GL_RGB16_SNORM                    = 0x8F9A,
			GL_RGBA16_SNORM                   = 0x8F9B,
			GL_SIGNED_NORMALIZED              = 0x8F9C,
			GL_PRIMITIVE_RESTART              = 0x8F9D,
			GL_PRIMITIVE_RESTART_INDEX        = 0x8F9E,

			// OpenGL 3.2
			GL_CONTEXT_CORE_PROFILE_BIT       = 0x00000001,
			GL_CONTEXT_COMPATIBILITY_PROFILE_BIT = 0x00000002,
			GL_LINES_ADJACENCY                = 0x000A,
			GL_LINE_STRIP_ADJACENCY           = 0x000B,
			GL_TRIANGLES_ADJACENCY            = 0x000C,
			GL_TRIANGLE_STRIP_ADJACENCY       = 0x000D,
			GL_PROGRAM_POINT_SIZE             = 0x8642,
			GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS = 0x8C29,
			GL_FRAMEBUFFER_ATTACHMENT_LAYERED = 0x8DA7,
			GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS = 0x8DA8,
			GL_GEOMETRY_SHADER                = 0x8DD9,
			GL_GEOMETRY_VERTICES_OUT          = 0x8916,
			GL_GEOMETRY_INPUT_TYPE            = 0x8917,
			GL_GEOMETRY_OUTPUT_TYPE           = 0x8918,
			GL_MAX_GEOMETRY_UNIFORM_COMPONENTS = 0x8DDF,
			GL_MAX_GEOMETRY_OUTPUT_VERTICES   = 0x8DE0,
			GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS = 0x8DE1,
			GL_MAX_VERTEX_OUTPUT_COMPONENTS   = 0x9122,
			GL_MAX_GEOMETRY_INPUT_COMPONENTS  = 0x9123,
			GL_MAX_GEOMETRY_OUTPUT_COMPONENTS = 0x9124,
			GL_MAX_FRAGMENT_INPUT_COMPONENTS  = 0x9125,
			GL_CONTEXT_PROFILE_MASK           = 0x9126,

			// OpenGL 3.3
			GL_VERTEX_ATTRIB_ARRAY_DIVISOR   = 0x88FE,

			// OpenGL 4.0
			GL_SAMPLE_SHADING                 = 0x8C36,
			GL_MIN_SAMPLE_SHADING_VALUE       = 0x8C37,
			GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5E,
			GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5F,
			GL_TEXTURE_CUBE_MAP_ARRAY         = 0x9009,
			GL_TEXTURE_BINDING_CUBE_MAP_ARRAY = 0x900A,
			GL_PROXY_TEXTURE_CUBE_MAP_ARRAY   = 0x900B,
			GL_SAMPLER_CUBE_MAP_ARRAY         = 0x900C,
			GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW  = 0x900D,
			GL_INT_SAMPLER_CUBE_MAP_ARRAY     = 0x900E,
			GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900F,

			// OpenGL 4.2
			GL_COPY_READ_BUFFER_BINDING  = 0x8F36,
			GL_COPY_WRITE_BUFFER_BINDING = 0x8F37,
			GL_TRANSFORM_FEEDBACK_PAUSED = 0x8E23,
			GL_TRANSFORM_FEEDBACK_ACTIVE = 0x8E24,

			// OpenGL 4.3
			GL_NUM_SHADING_LANGUAGE_VERSIONS = 0x82E9,
			GL_VERTEX_ATTRIB_ARRAY_LONG = 0x874E,
			GL_VERTEX_BINDING_BUFFER = 0x8F4F,

			// OpenGL 4.4
			GL_MAX_VERTEX_ATTRIB_STRIDE       = 0x82E5,
			GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED = 0x8221,
			GL_TEXTURE_BUFFER_BINDING         = 0x8C2A,
		}

		public {/*CLEARING}*/
			public {/*GET}*/
				glClearBufferiv 
					
	???
				glClearBufferuiv 
					
	???
				glClearBufferfv 
					
	???
				glClearBufferfi 
					
	???
			}
			public {/*SET}*/
				glClearDepth
					specify the clear value for the depth buffer
				glClearStencil
					specify the clear value for the stencil buffer
				glClearColor
					specify clear values for the color buffers
			}
			public {/*DO}*/
				glClear
					clear buffers to preset values
			}
		}
		public {/*DRAWING}*/
			public {/*COMMANDS}*/
				glDrawRangeElements
					render primitives from array data
				glMultiDrawArrays
					render multiple sets of primitives from array data
				glMultiDrawElements
					render multiple sets of primitives by specifying indices of array data elements
				glDrawArraysInstanced
					draw multiple instances of a range of elements
				glDrawElementsInstanced
					draw multiple instances of a set of elements
				glDrawArrays
					render primitives from array data
				glDrawElements
					render primitives from array data
			}
			public {/*TARGET}*/
				glDrawBuffers, glNamedFramebufferDrawBuffers
					Specifies a list of color buffers to be drawn into
			}
			public {/*MISC}*/
				glPrimitiveRestartIndex
					specify the primitive restart index
				glVertexAttribDivisor
					modify the rate at which generic vertex attributes advance during instanced rendering
			}
		}

		public {/*BLENDING}*/
			glBlendColor
				set the blend color
			glBlendEquation
				specify the equation used for both the RGB blend equation and the Alpha blend equation
			glBlendFuncSeparate
				specify pixel arithmetic for RGB and alpha components separately
			glBlendEquationSeparate
				set the RGB blend equation and the alpha blend equation separately
			glBlendEquationi 
				
	???
			glBlendEquationSeparatei 
				
	???
			glBlendFunci 
				
	???
			glBlendFuncSeparatei 
				
	???
			glBlendFunc
				specify pixel arithmetic
		}
		public {/*STENCIL}*/
			glStencilOpSeparate
				set front and/or back stencil test actions
			glStencilFuncSeparate
				set front and/or back function and reference value for stencil testing
			glStencilMaskSeparate
				control the front and/or back writing of individual bits in the stencil planes
			glStencilMask
				control the front and back writing of individual bits in the stencil planes
			glStencilFunc
				set front and back function and reference value for stencil testing
			glStencilOp
				set front and back stencil test actions
		}
		public {/*GENERAL}*/
			glEnablei 
				
	???
			glDisablei 
				
	???
			glIsEnabledi 
				
	???
			glDisable 
				
	???
			glEnable
				enable or disable server-side GL capabilities
			glIsEnabled, glIsEnabledi
				test whether a capability is enabled
		}
		public {/*COLOR}*/
			glClampColor
				specify whether data read via glReadPixels should be clamped
			glColorMask, glColorMaski
				enable and disable writing of frame buffer color components
		}
		public {/*CULLING}*/
			glCullFace
				specify whether front- or back-facing facets can be culled
			glFrontFace
				define front- and back-facing polygons
			glScissor
				define the scissor box
			glViewport
				set the viewport
		}
		public {/*MISC}*/
			glLineWidth
				specify the width of rasterized lines
			glPointSize
				specify the diameter of rasterized points
			glPolygonMode
				select a polygon rasterization mode
			glLogicOp
				specify a logical pixel operation for rendering
		}
		public {/*DEPTH}*/
			glPolygonOffset
				set the scale and units used to calculate depth values
			glDepthFunc
				specify the value used for depth buffer comparisons
			glDepthMask
				enable or disable writing into the depth buffer
			glDepthRange
				specify mapping of depth values from normalized device coordinates to window coordinates
		}
		public {/*TEXTURE}*/
			public {/*TRANSFER TEXTURE}*/
				// C → G
				glTexImage3D
					specify a three-dimensional texture image
				glTexSubImage3D, glTextureSubImage3D
					specify a three-dimensional texture subimage
				glCopyTexSubImage3D, glCopyTextureSubImage3D
					copy a three-dimensional texture subimage
				glTexImage1D
					specify a one-dimensional texture image
				glTexImage2D
					specify a two-dimensional texture image
				glTexSubImage1D, glTextureSubImage1D
					specify a one-dimensional texture subimage
				glTexSubImage2D, glTextureSubImage2D
					specify a two-dimensional texture subimage

				// C → G COMPRESSED
				glCompressedTexImage3D
					specify a three-dimensional texture image in a compressed format
				glCompressedTexImage2D
					specify a two-dimensional texture image in a compressed format
				glCompressedTexImage1D
					specify a one-dimensional texture image in a compressed format
				glCompressedTexSubImage3D, glCompressedTextureSubImage3D
					specify a three-dimensional texture subimage in a compressed format
				glCompressedTexSubImage2D, glCompressedTextureSubImage2D
					specify a two-dimensional texture subimage in a compressed format
				glCompressedTexSubImage1D, glCompressedTextureSubImage1D
					specify a one-dimensional texture subimage in a compressed
					format

				// G → C COMPRESSED
				glGetCompressedTexImage
					return a compressed texture image

				// G → C
				glGetTexImage
					return a texture image

				// G → G
				glCopyTexImage1D
					copy pixels into a 1D texture image
				glCopyTexImage2D
					copy pixels into a 2D texture image
				glCopyTexSubImage1D, glCopyTextureSubImage1D
					copy a one-dimensional texture subimage
				glCopyTexSubImage2D, glCopyTextureSubImage2D
					copy a two-dimensional texture subimage
			}
			public {/*TEXTURE STATE}*/
				glActiveTexture
					select active texture unit
				glBindTexture
					bind a named texture to a texturing target
				glDeleteTextures
					delete named textures
				glGenTextures
					generate texture names
				glIsTexture
					determine if a name corresponds to a texture
			}
			public {/*PARAMETERS}*/
				glGetTexParameterfv 
					
	???
				glGetTexParameteriv 
					
	???
				glGetTexLevelParameterfv 
					
	???
				glGetTexLevelParameteriv 
					
	???
				glTexParameterIiv 
					
	???
				glTexParameterIuiv 
					
	???
				glGetTexParameterIiv 
					
	???
				glGetTexParameterIuiv 
					
	???
				glTexParameterf 
					
	???
				glTexParameterfv 
					
	???
				glTexParameteri 
					
	???
				glTexParameteriv 
					
	???
			}
		}
		public {/*SAMPLING}*/
			glSampleCoverage
				specify multisample coverage parameters
			glPointParameterf 
				
	???
			glPointParameterfv 
				
	???
			glPointParameteri 
				
	???
			glPointParameteriv 
				
	???
			glMinSampleShading
				specifies minimum rate at which sample sharing takes place
		}
		public {/*QUERY}*/
			glGenQueries
				generate query object names
			glDeleteQueries
				delete named query objects
			glIsQuery
				determine if a name corresponds to a query object
			glBeginQuery
				delimit the boundaries of a query object
			glEndQuery 
				
	???
			glGetQueryiv
				return parameters of a query object target
			glGetQueryObjectiv 
				
	???
			glGetQueryObjectuiv 
				
	???
		}
		public {/*BUFFER}*/
			public {/*BUFFER STATE CONTROL}*/
				glBindBuffer
					bind a named buffer object
				glDeleteBuffers
					delete named buffer objects
				glGenBuffers
					generate buffer object names
				glIsBuffer
					determine if a name corresponds to a buffer object
			glBindBufferRange
				bind a range within a buffer object to an indexed buffer target
			glBindBufferBase
				bind a buffer object to an indexed buffer target
			}
			public {/*BUFFER TRANSFER}*/
				// C → G
				glBufferData, glNamedBufferData
					creates and initializes a buffer object's data
					store
				glBufferSubData, glNamedBufferSubData
					updates a subset of a buffer object's data store

				// G → C
				glGetBufferSubData, glGetNamedBufferSubData
					returns a subset of a buffer object's data store

				// G ↔ C
				glMapBuffer, glMapNamedBuffer
					map all of a buffer object's data store into the client's address space
				glUnmapBuffer, glUnmapNamedBuffer
					release the mapping of a buffer object's data store into the client's address space

				// G → C
				glGetBufferPointerv, glGetNamedBufferPointerv
					return the pointer to a mapped buffer object's data store
			}
		}
		public {/*PROGRAM}*/
			glCreateProgram
				Creates a program object
			glCreateShader
				Creates a shader object
			glDeleteProgram
				Deletes a program object
			glDeleteShader
				Deletes a shader object
			// COMPILATION
			glCompileShader
				Compiles a shader object
			glGetProgramiv 
				
	???
			glGetProgramInfoLog
				Returns the information log for a program object
			glValidateProgram
				Validates a program object
			glGetShaderiv 
				
	???
			glGetShaderInfoLog
				Returns the information log for a shader object
			glGetShaderSource
				Returns the source code string from a shader object
			glIsProgram
				Determines if a name corresponds to a program object
			glIsShader
				Determines if a name corresponds to a shader object
			glLinkProgram
				Links a program object
			glShaderSource
				Replaces the source code in a shader object
			glUseProgram
				Installs a program object as part of current rendering state
			// ATTACHMENT
			glAttachShader
				Attaches a shader object to a program object
			glDetachShader
				Detaches a shader object from a program object to which it is attached
			glGetAttachedShaders
				Returns the handles of the shader objects attached to a program object
		}
		public {/*SHADER VARIABLES}*/
			public {/*ATTRIBUTES}*/
				glBindAttribLocation
					Associates a generic vertex attribute index with a named attribute variable
				glDisableVertexAttribArray 
					
	???
				glEnableVertexAttribArray
					Enable or disable a generic vertex attribute array
				glGetActiveAttrib
					Returns information about an active attribute variable for the specified program object
				glGetAttribLocation
					Returns the location of an attribute variable
				glGetVertexAttribdv 
					
	???
				glGetVertexAttribfv 
					
	???
				glGetVertexAttribiv 
					
	???
				glGetVertexAttribPointerv
					return the address of the specified generic vertex attribute pointer
				glVertexAttribIPointer 
					
	???
				glGetVertexAttribIiv 
					
	???
				glGetVertexAttribIuiv 
					
	???
				glVertexAttribI1i 
					
	???
				glVertexAttribI2i 
					
	???
				glVertexAttribI3i 
					
	???
				glVertexAttribI4i 
					
	???
				glVertexAttribI1ui 
					
	???
				glVertexAttribI2ui 
					
	???
				glVertexAttribI3ui 
					
	???
				glVertexAttribI4ui 
					
	???
				glVertexAttribI1iv 
					
	???
				glVertexAttribI2iv 
					
	???
				glVertexAttribI3iv 
					
	???
				glVertexAttribI4iv 
					
	???
				glVertexAttribI1uiv 
					
	???
				glVertexAttribI2uiv 
					
	???
				glVertexAttribI3uiv 
					
	???
				glVertexAttribI4uiv 
					
	???
				glVertexAttribI4bv 
					
	???
				glVertexAttribI4sv 
					
	???
				glVertexAttribI4ubv 
					
	???
				glVertexAttribI4usv 
					
	???
			}
			public {/*UNIFORM}*/
				glGetActiveUniform
					Returns information about an active uniform variable for the specified program object
				glGetUniformLocation
					Returns the location of a uniform variable
				glGetUniformfv 
					
	???
				glGetUniformiv 
					
	???
				glUniform1f 
					
	???
				glUniform2f 
					
	???
				glUniform3f 
					
	???
				glUniform4f 
					
	???
				glUniform1i 
					
	???
				glUniform2i 
					
	???
				glUniform4i 
					
	???
				glUniform1fv 
					
	???
				glUniform2fv 
					
	???
				glUniform3fv 
					
	???
				glUniform4fv 
					
	???
				glUniform1iv 
					
	???
				glUniform2iv 
					
	???
				glUniform3iv 
					
	???
				glUniform4iv 
					
	???
				glUniformMatrix2fv 
					
	???
				glUniformMatrix3fv 
					
	???
				glUniformMatrix4fv 
					
	???
				glUniformMatrix2x3fv 
					
	???
				glUniformMatrix3x2fv 
					
	???
				glUniformMatrix2x4fv 
					
	???
				glUniformMatrix4x2fv 
					
	???
				glUniformMatrix3x4fv 
					
	???
				glUniformMatrix4x3fv 
					
	???
				glGetUniformuiv 
					
	???
				glUniform1ui 
					
	???
				glUniform2ui 
					
	???
				glUniform3ui 
					
	???
				glUniform4ui 
					
	???
				glUniform1uiv 
					
	???
				glUniform2uiv 
					
	???
				glUniform3uiv 
					
	???
				glUniform4uiv 
					
	???
			}
			public {/*OUTPUT}*/
				glBindFragDataLocation
					bind a user-defined varying out variable to a fragment shader color number
				glGetFragDataLocation
					query the bindings of color numbers to user-defined varying out variables
			}
		}
		public {/*UNKNOWN}*/
			glGetFloatv 
				
	???
			glGetIntegerv 
				
	???
			glGetString
				return a string describing the current GL connection
			glPixelStoref 
				
	???
			glPixelStorei 
				
	???
			glGetBufferParameteriv 
				
	???
			glColorMaski 
				
	???
			glGetBooleani_v 
				
	???
			glGetIntegeri_v 
				
	???
			glGetStringi 
				
	???
			glGetInteger64i_v 
				
	???
			glGetBufferParameteri64v 
				
	???
			glGetnTexImage 
				
	???
			glHint
				specify implementation-specific hints
			glGetBooleanv 
				
	???
			glGetDoublev 
				
	???
		}
		public {/*TRANSFORM FEEDBACK}*/
			glBeginTransformFeedback
				start transform feedback operation
			glEndTransformFeedback 
				
	???
			glTransformFeedbackVaryings
				specify values to record in transform feedback buffers
			glGetTransformFeedbackVarying
				retrieve information about varying variables selected for transform feedback
		}
		public {/*CONDITIONAL RENDERING}*/
			glBeginConditionalRender
				start conditional rendering
			glEndConditionalRender 
				
	???
		}
		public {/*BUFFER ↔ TEXTURE}*/
			public {/*ATTACHMENT}*/
				glTexBuffer, glTextureBuffer
					attach a buffer object's data store to a buffer texture object
			}
		}
		public {/*FRAMEBUFFER}*/
			public {/*ATTACHMENT}*/
				glFramebufferTexture
					attach a level of a texture object as a logical buffer of a framebuffer object
			}
			public {/*DEFAULT FBO OPS}*/
				glDrawBuffer, glNamedFramebufferDrawBuffer
					specify which color buffers are to be drawn into
			}
			public {/*READING}*/
				glReadBuffer, glNamedFramebufferReadBuffer
					select a color buffer source for pixels
				glReadPixels, glReadnPixels
					read a block of pixels from the frame buffer
			}
		}
		public {/*SYNCHRONIZATION}*/
			glFinish
				block until all GL execution is complete
			glFlush
				force execution of GL commands in finite time
		}
		public {/*ERROR}*/
			glGetError
				return error information
		}
	}

glIsRenderbuffer
	determine if a name corresponds to a renderbuffer object
glBindRenderbuffer
	bind a renderbuffer to a renderbuffer target
glDeleteRenderbuffers
	delete renderbuffer objects
glGenRenderbuffers
	generate renderbuffer object names
glRenderbufferStorage, glNamedRenderbufferStorage
	establish data storage, format and dimensions of a
    renderbuffer object's image
glGetRenderbufferParameteriv 
	???
glIsFramebuffer
	determine if a name corresponds to a framebuffer object
glBindFramebuffer
	bind a framebuffer to a framebuffer target
glDeleteFramebuffers
	delete framebuffer objects
glGenFramebuffers
	generate framebuffer object names
glCheckFramebufferStatus, glCheckNamedFramebufferStatus
	check the completeness status of a framebuffer
glFramebufferTexture1D 
	???
glFramebufferTexture2D 
	???
glFramebufferTexture3D 
	???
glFramebufferRenderbuffer, glNamedFramebufferRenderbuffer
	attach a renderbuffer as a logical buffer of a framebuffer object
glGetFramebufferAttachmentParameteriv 
	???
glGenerateMipmap, glGenerateTextureMipmap
	generate mipmaps for a specified texture object
glBlitFramebuffer, glBlitNamedFramebuffer
	copy a block of pixels from one framebuffer object to another
glRenderbufferStorageMultisample, glNamedRenderbufferStorageMultisample
	establish data storage, format, dimensions and sample count of
    a renderbuffer object's image
glFramebufferTextureLayer, glNamedFramebufferTextureLayer
	attach a single layer of a texture object as a logical buffer of a framebuffer object

glDrawTransformFeedbackStream
	render primitives using a count derived from a specifed stream of a transform feedback object
glBeginQueryIndexed, glEndQueryIndexed
	delimit the boundaries of a query object on an indexed target
glEndQueryIndexed 
	???
glGetQueryIndexediv 
	???
glBindTransformFeedback
	bind a transform feedback object
glDeleteTransformFeedbacks
	delete transform feedback objects
glGenTransformFeedbacks
	reserve transform feedback object names
glIsTransformFeedback
	determine if a name corresponds to a transform feedback object
glPauseTransformFeedback
	pause transform feedback operations
glResumeTransformFeedback
	resume transform feedback operations
glDrawTransformFeedback
	render primitives using a count derived from a transform feedback object
glPatchParameteri 
	???
glPatchParameterfv 
	???
glGetSubroutineUniformLocation
	retrieve the location of a subroutine uniform of a given shader stage within a program
glGetSubroutineIndex
	retrieve the index of a subroutine uniform of a given shader stage within a program
glGetActiveSubroutineUniformiv 
	???
glGetActiveSubroutineUniformName
	query the name of an active shader subroutine uniform
glGetActiveSubroutineName
	query the name of an active shader subroutine
glUniformSubroutinesuiv 
	???
glGetUniformSubroutineuiv 
	???
glGetProgramStageiv 
	???
glUniform1d 
	???
glUniform2d 
	???
glUniform3d 
	???
glUniform4d 
	???
glUniform1dv 
	???
glUniform2dv 
	???
glUniform3dv 
	???
glUniform4dv 
	???
glUniformMatrix2dv 
	???
glUniformMatrix3dv 
	???
glUniformMatrix4dv 
	???
glUniformMatrix2x3dv 
	???
glUniformMatrix2x4dv 
	???
glUniformMatrix3x2dv 
	???
glUniformMatrix3x4dv 
	???
glUniformMatrix4x2dv 
	???
glUniformMatrix4x3dv 
	???
glGetUniformdv 
	???
glDrawArraysIndirect
	render primitives from array data, taking parameters from memory
glDrawElementsIndirect
	render indexed primitives from array data, taking parameters from memory
glVertexP2ui 
	???
glVertexP2uiv 
	???
glVertexP3ui 
	???
glVertexP3uiv 
	???
glVertexP4ui 
	???
glVertexP4uiv 
	???
glTexCoordP1ui 
	???
glTexCoordP1uiv 
	???
glTexCoordP2ui 
	???
glTexCoordP2uiv 
	???
glTexCoordP3ui 
	???
glTexCoordP3uiv 
	???
glTexCoordP4ui 
	???
glTexCoordP4uiv 
	???
glMultiTexCoordP1ui 
	???
glMultiTexCoordP1uiv 
	???
glMultiTexCoordP2ui 
	???
glMultiTexCoordP2uiv 
	???
glMultiTexCoordP3ui 
	???
glMultiTexCoordP3uiv 
	???
glMultiTexCoordP4ui 
	???
glMultiTexCoordP4uiv 
	???
glNormalP3ui 
	???
glNormalP3uiv 
	???
glColorP3ui 
	???
glColorP3uiv 
	???
glColorP4ui 
	???
glColorP4uiv 
	???
glSecondaryColorP3ui 
	???
glSecondaryColorP3uiv 
	???
glVertexAttribP1ui 
	???
glVertexAttribP1uiv 
	???
glVertexAttribP2ui 
	???
glVertexAttribP2uiv 
	???
glVertexAttribP3ui 
	???
glVertexAttribP3uiv 
	???
glVertexAttribP4ui 
	???
glVertexAttribP4uiv 
	???
glQueryCounter
	record the GL time into a query object after all previous commands have reached the GL server but have not yet necessarily executed.
glGetQueryObjecti64v 
	???
glGetQueryObjectui64v 
	???
glGenSamplers
	generate sampler object names
glDeleteSamplers
	delete named sampler objects
glIsSampler
	determine if a name corresponds to a sampler object
glBindSampler
	bind a named sampler to a texturing target
glSamplerParameteri 
	???
glSamplerParameteriv 
	???
glSamplerParameterf 
	???
glSamplerParameterfv 
	???
glSamplerParameterIiv 
	???
glSamplerParameterIuiv 
	???
glGetSamplerParameteriv 
	???
glGetSamplerParameterIiv 
	???
glGetSamplerParameterfv 
	???
glGetSamplerParameterIuiv 
	???
glBindFragDataLocationIndexed
	bind a user-defined varying out variable to a fragment shader color number and index
glGetFragDataIndex
	query the bindings of color indices to user-defined varying out variables
glNamedString 
	???
glDeleteNamedString 
	???
glCompileShaderInclude 
	???
glIsNamedString 
	???
glGetNamedString 
	???
glGetNamedStringiv 
	???
glMinSampleShading
	specifies minimum rate at which sample shaing takes place
glBlendEquationi 
	???
glBlendEquationSeparatei 
	???
glBlendFunci 
	???
glBlendFuncSeparatei 
	???
glTexImage2DMultisample
	establish the data storage, format, dimensions, and number of samples of a multisample texture's image
glTexImage3DMultisample
	establish the data storage, format, dimensions, and number of samples of a multisample texture's image
glGetMultisamplefv 
	???
glSampleMaski
	set the value of a sub-word of the sample mask
glFenceSync
	create a new sync object and insert it into the GL command stream
glIsSync
	determine if a name corresponds to a sync object
glDeleteSync
	delete a sync object
glClientWaitSync
	block and wait for a sync object to become signaled
glWaitSync
	instruct the GL server to block until the specified sync object becomes signaled
glGetInteger64v 
	???
glGetSynciv 
	???
glProvokingVertex
	specifiy the vertex to be used as the source of data for flat shaded varyings
glDrawElementsBaseVertex
	render primitives from array data with a per-element offset
glDrawRangeElementsBaseVertex
	render primitives from array data with a per-element offset
glDrawElementsInstancedBaseVertex
	render multiple instances of a set of primitives from array data with a per-element offset
glMultiDrawElementsBaseVertex
	render multiple sets of primitives by specifying indices of array data elements and an index to apply to each index
glCopyBufferSubData, glCopyNamedBufferSubData
	copy all or part of the data store of a buffer object to the data store of another buffer object
glGetUniformIndices
	retrieve the index of a named uniform block
glGetActiveUniformsiv
	Returns information about several active uniform variables for the specified program object
glGetActiveUniformName
	query the name of an active uniform
glGetUniformBlockIndex
	retrieve the index of a named uniform block
glGetActiveUniformBlockiv 
	???
glGetActiveUniformBlockName
	retrieve the name of an active uniform block
glUniformBlockBinding
	assign a binding point to an active uniform block
glBindVertexArray
	bind a vertex array object
glDeleteVertexArrays
	delete vertex array objects
glGenVertexArrays
	generate vertex array object names
glIsVertexArray
	determine if a name corresponds to a vertex array object
glMapBufferRange, glMapNamedBufferRange
	map all or part of a buffer object's data store into the client's address space
glFlushMappedBufferRange, glFlushMappedNamedBufferRange
	indicate modifications to a range of a mapped buffer
glReleaseShaderCompiler
	release resources consumed by the implementation's shader compiler
glShaderBinary
	load pre-compiled shader binaries
glGetShaderPrecisionFormat
	retrieve the range and precision for numeric formats supported by the shader compiler
glDepthRangef 
	???
glClearDepthf 
	???
glGetProgramBinary
	return a binary representation of a program object's compiled and linked executable source
glProgramBinary
	load a program object with a program binary
glProgramParameteri 
	???
glUseProgramStages
	bind stages of a program object to a program pipeline
glActiveShaderProgram
	set the active program object for a program pipeline object
glCreateShaderProgramv 
	???
glBindProgramPipeline
	bind a program pipeline to the current context
glDeleteProgramPipelines
	delete program pipeline objects
glGenProgramPipelines
	reserve program pipeline object names
glIsProgramPipeline
	determine if a name corresponds to a program pipeline object
glGetProgramPipelineiv 
	???
glProgramUniform1i 
	???
glProgramUniform1iv 
	???
glProgramUniform1f 
	???
glProgramUniform1fv 
	???
glProgramUniform1d 
	???
glProgramUniform1dv 
	???
glProgramUniform1ui 
	???
glProgramUniform1uiv 
	???
glProgramUniform2i 
	???
glProgramUniform2iv 
	???
glProgramUniform2f 
	???
glProgramUniform2fv 
	???
glProgramUniform2d 
	???
glProgramUniform2dv 
	???
glProgramUniform2ui 
	???
glProgramUniform2uiv 
	???
glProgramUniform3i 
	???
glProgramUniform3iv 
	???
glProgramUniform3f 
	???
glProgramUniform3fv 
	???
glProgramUniform3d 
	???
glProgramUniform3dv 
	???
glProgramUniform3ui 
	???
glProgramUniform3uiv 
	???
glProgramUniform4i 
	???
glProgramUniform4iv 
	???
glProgramUniform4f 
	???
glProgramUniform4fv 
	???
glProgramUniform4d 
	???
glProgramUniform4dv 
	???
glProgramUniform4ui 
	???
glProgramUniform4uiv 
	???
glProgramUniformMatrix2fv 
	???
glProgramUniformMatrix3fv 
	???
glProgramUniformMatrix4fv 
	???
glProgramUniformMatrix2dv 
	???
glProgramUniformMatrix3dv 
	???
glProgramUniformMatrix4dv 
	???
glProgramUniformMatrix2x3fv 
	???
glProgramUniformMatrix3x2fv 
	???
glProgramUniformMatrix2x4fv 
	???
glProgramUniformMatrix4x2fv 
	???
glProgramUniformMatrix3x4fv 
	???
glProgramUniformMatrix4x3fv 
	???
glProgramUniformMatrix2x3dv 
	???
glProgramUniformMatrix3x2dv 
	???
glProgramUniformMatrix2x4dv 
	???
glProgramUniformMatrix4x2dv 
	???
glProgramUniformMatrix3x4dv 
	???
glProgramUniformMatrix4x3dv 
	???
glValidateProgramPipeline
	validate a program pipeline object against current GL state
glGetProgramPipelineInfoLog
	retrieve the info log string from a program pipeline object
glVertexAttribL1d 
	???
glVertexAttribL2d 
	???
glVertexAttribL3d 
	???
glVertexAttribL4d 
	???
glVertexAttribL1dv 
	???
glVertexAttribL2dv 
	???
glVertexAttribL3dv 
	???
glVertexAttribL4dv 
	???
glVertexAttribLPointer 
	???
glGetVertexAttribLdv 
	???
glViewportArrayv 
	???
glViewportIndexedf 
	???
glViewportIndexedfv 
	???
glScissorArrayv 
	???
glScissorIndexed
	define the scissor box for a specific viewport
glScissorIndexedv 
	???
glDepthRangeArrayv 
	???
glDepthRangeIndexed
	specify mapping of depth values from normalized device coordinates to window coordinates for a specified viewport
glGetFloati_v 
	???
glGetDoublei_v 
	???
glCreateSyncFromCLevent 
	???
glDebugMessageControl
	control the reporting of debug messages in a debug context
glDebugMessageInsert
	inject an application-supplied message into the debug message queue
glDebugMessageCallback
	specify a callback to receive debugging messages from the GL
glGetDebugMessageLog
	retrieve messages from the debug message log
glGetGraphicsResetStatus
	check if the rendering context has not been lost due to software or hardware issues
glGetnMapdv 
	???
glGetnMapfv 
	???
glGetnMapiv 
	???
glGetnPixelMapfv 
	???
glGetnPixelMapuiv 
	???
glGetnPixelMapusv 
	???
glGetnPolygonStipple 
	???
glGetnColorTable 
	???
glGetnConvolutionFilter 
	???
glGetnSeparableFilter 
	???
glGetnHistogram 
	???
glGetnMinmax 
	???
glGetnTexImage 
	???
glReadnPixels 
	???
glGetnCompressedTexImage 
	???
glGetnUniformfv 
	???
glGetnUniformiv 
	???
glGetnUniformuiv 
	???
glGetnUniformdv 
	???
glDrawArraysInstancedBaseInstance
	draw multiple instances of a range of elements with offset applied to instanced attributes
glDrawElementsInstancedBaseInstance
	draw multiple instances of a set of elements with offset applied to instanced attributes
glDrawElementsInstancedBaseVertexBaseInstance
	render multiple instances of a set of primitives from array data with a per-element offset
glDrawTransformFeedbackInstanced
	render multiple instances of primitives using a count derived from a transform feedback object
glDrawTransformFeedbackStreamInstanced
	render multiple instances of primitives using a count derived from a specifed stream of a transform feedback object
glGetInternalformativ 
	???
glGetActiveAtomicCounterBufferiv
	retrieve information about the set of active atomic counter buffers for a program
glBindImageTexture
	bind a level of a texture to an image unit
glMemoryBarrier
	defines a barrier ordering memory transactions
glTexStorage1D, glTextureStorage1D
	simultaneously specify storage for all levels of a one-dimensional texture
glTexStorage2D, glTextureStorage2D
	simultaneously specify storage for all levels of a two-dimensional or one-dimensional array texture
glTexStorage3D, glTextureStorage3D
	simultaneously specify storage for all levels of a three-dimensional, two-dimensional array or cube-map array texture
glTextureStorage1D 
	???
glTextureStorage2D 
	???
glTextureStorage3D 
	???
glClearBufferData, glClearNamedBufferData
	fill a buffer object's data store with a fixed value
glClearBufferSubData, glClearNamedBufferSubData
	fill all or part of buffer object's data store with a fixed value
glClearNamedBufferData 
	???
glClearNamedBufferSubData 
	???
glDispatchCompute
	launch one or more compute work groups
glDispatchComputeIndirect
	launch one or more compute work groups using parameters stored in a buffer
glCopyImageSubData
	perform a raw data copy between two images
glDebugMessageControl
	control the reporting of debug messages in a debug context
glDebugMessageInsert
	inject an application-supplied message into the debug message queue
glDebugMessageCallback
	specify a callback to receive debugging messages from the GL
glGetDebugMessageLog
	retrieve messages from the debug message log
glPushDebugGroup
	push a named debug group into the command stream
glPopDebugGroup
	pop the active debug group
glObjectLabel
	label a named object identified within a namespace
glGetObjectLabel
	retrieve the label of a named object identified within a namespace
glObjectPtrLabel
	label a a sync object identified by a pointer
glGetObjectPtrLabel
	retrieve the label of a sync object identified by a pointer
glFramebufferParameteri, glNamedFramebufferParameteri
	set a named parameter of a framebuffer object
glGetFramebufferParameteriv 
	???
glNamedFramebufferParameteri 
	???
glGetNamedFramebufferParameteriv 
	???
glGetInternalformati64v 
	???
glInvalidateTexSubImage
	invalidate a region of a texture image
glInvalidateTexImage
	invalidate the entirety a texture image
glInvalidateBufferSubData
	invalidate a region of a buffer object's data store
glInvalidateBufferData
	invalidate the content of a buffer object's data store
glInvalidateFramebuffer, glInvalidateNamedFramebufferData
	invalidate the content of some or all of a framebuffer's attachments
glInvalidateSubFramebuffer, glInvalidateNamedFramebufferSubData
	invalidate the content of a region of some or all of a framebuffer's attachments
glMultiDrawArraysIndirect
	render multiple sets of primitives from array data, taking parameters from memory
glMultiDrawElementsIndirect
	render indexed primitives from array data, taking parameters from memory
glGetProgramInterfaceiv 
	???
glGetProgramResourceIndex
	query the index of a named resource within a program
glGetProgramResourceName
	query the name of an indexed resource within a program
glGetProgramResourceiv 
	???
glGetProgramResourceLocation
	query the location of a named resource within a program
glGetProgramResourceLocationIndex
	query the fragment color index of a named variable within a program
glShaderStorageBlockBinding
	change an active shader storage block binding
glTexBufferRange, glTextureBufferRange
	attach a range of a buffer object's data store to a buffer texture object
glTextureBufferRange 
	???
glTexStorage2DMultisample, glTextureStorage2DMultisample
	specify storage for a two-dimensional multisample texture
glTexStorage3DMultisample, glTextureStorage3DMultisample
	specify storage for a two-dimensional multisample array texture
glTextureStorage2DMultisample 
	???
glTextureStorage3DMultisample 
	???
glTextureView
	initialize a texture as a data alias of another texture's data store
glBindVertexBuffer, glVertexArrayVertexBuffer
	bind a buffer to a vertex buffer bind point
glVertexAttribFormat, glVertexArrayAttribFormat
	specify the organization of vertex arrays
glVertexAttribIFormat 
	???
glVertexAttribLFormat 
	???
glVertexAttribBinding
	associate a vertex attribute and a vertex buffer binding for a vertex array object
glVertexBindingDivisor, glVertexArrayBindingDivisor
	modify the rate at which generic vertex attributes
    advance
glVertexArrayBindVertexBuffer 
	???
glVertexArrayVertexAttribFormat 
	???
glVertexArrayVertexAttribIFormat 
	???
glVertexArrayVertexAttribLFormat 
	???
glVertexArrayVertexAttribBinding 
	???
glVertexArrayVertexBindingDivisor 
	???
glBufferStorage, glNamedBufferStorage
	creates and initializes a buffer object's immutable data
    store
glNamedBufferStorage 
	???
glClearTexImage
	fills all a texture image with a constant value
glClearTexSubImage
	fills all or part of a texture image with a constant value
glBindBuffersBase
	bind one or more buffer objects to a sequence of indexed buffer targets
glBindBuffersRange
	bind ranges of one or more buffer objects to a sequence of indexed buffer targets
glBindTextures
	bind one or more named textures to a sequence of consecutive texture units
glBindSamplers
	bind one or more named sampler objects to a sequence of consecutive sampler units
glBindImageTextures
	bind one or more named texture images to a sequence of consecutive image units
glBindVertexBuffers, glVertexArrayVertexBuffers
	attach multiple buffer objects to a vertex array object
glClipControl
	control clip coordinate to window coordinate behavior
glMemoryBarrierByRegion 
	???
glCreateTransformFeedbacks
	create transform feedback objects
glTransformFeedbackBufferBase
	bind a buffer object to a transform feedback buffer object
glTransformFeedbackBufferRange
	bind a range within a buffer object to a transform feedback buffer object
glGetTransformFeedbackiv 
	???
glGetTransformFeedbacki_v 
	???
glGetTransformFeedbacki64_v 
	???
glCreateBuffers
	create buffer objects
glNamedBufferStorage 
	???
glNamedBufferData 
	???
glNamedBufferSubData 
	???
glCopyNamedBufferSubData 
	???
glClearNamedBufferData 
	???
glClearNamedBufferSubData 
	???
glMapNamedBuffer 
	???
glMapNamedBufferRange 
	???
glUnmapNamedBuffer 
	???
glFlushMappedNamedBufferRange 
	???
glGetNamedBufferParameteriv 
	???
glGetNamedBufferParameteri64v 
	???
glGetNamedBufferPointerv 
	???
glGetNamedBufferSubData 
	???
glCreateFramebuffers
	create framebuffer objects
glNamedFramebufferRenderbuffer 
	???
glNamedFramebufferParameteri 
	???
glNamedFramebufferTexture 
	???
glNamedFramebufferTextureLayer 
	???
glNamedFramebufferDrawBuffer 
	???
glNamedFramebufferDrawBuffers 
	???
glNamedFramebufferReadBuffer 
	???
glInvalidateNamedFramebufferData 
	???
glInvalidateNamedFramebufferSubData 
	???
glClearNamedFramebufferiv 
	???
glClearNamedFramebufferuiv 
	???
glClearNamedFramebufferfv 
	???
glClearNamedFramebufferfi 
	???
glBlitNamedFramebuffer 
	???
glCheckNamedFramebufferStatus 
	???
glGetNamedFramebufferParameteriv 
	???
glGetNamedFramebufferAttachmentParameteriv 
	???
glCreateRenderbuffers
	create renderbuffer objects
glNamedRenderbufferStorage 
	???
glNamedRenderbufferStorageMultisample 
	???
glGetNamedRenderbufferParameteriv 
	???
glCreateTextures
	create texture objects
glTextureBuffer 
	???
glTextureBufferRange 
	???
glTextureStorage1D 
	???
glTextureStorage2D 
	???
glTextureStorage3D 
	???
glTextureStorage2DMultisample 
	???
glTextureStorage3DMultisample 
	???
glTextureSubImage1D 
	???
glTextureSubImage2D 
	???
glTextureSubImage3D 
	???
glCompressedTextureSubImage1D 
	???
glCompressedTextureSubImage2D 
	???
glCompressedTextureSubImage3D 
	???
glCopyTextureSubImage1D 
	???
glCopyTextureSubImage2D 
	???
glCopyTextureSubImage3D 
	???
glTextureParameterf 
	???
glTextureParameterfv 
	???
glTextureParameteri 
	???
glTextureParameterIiv 
	???
glTextureParameterIuiv 
	???
glTextureParameteriv 
	???
glGenerateTextureMipmap 
	???
glBindTextureUnit
	bind an existing texture object to the specified texture unit
glGetTextureImage 
	???
glGetCompressedTextureImage 
	???
glGetTextureLevelParameterfv 
	???
glGetTextureLevelParameteriv 
	???
glGetTextureParameterfv 
	???
glGetTextureParameterIiv 
	???
glGetTextureParameterIuiv 
	???
glGetTextureParameteriv 
	???
glCreateVertexArrays
	create vertex array objects
glDisableVertexArrayAttrib 
	???
glEnableVertexArrayAttrib 
	???
glVertexArrayElementBuffer
	configures element array buffer binding of a vertex array object
glVertexArrayVertexBuffer 
	???
glVertexArrayVertexBuffers 
	???
glVertexArrayAttribBinding 
	???
glVertexArrayAttribFormat 
	???
glVertexArrayAttribIFormat 
	???
glVertexArrayAttribLFormat 
	???
glVertexArrayBindingDivisor 
	???
glGetVertexArrayiv
	retrieve parameters of a vertex array object
glGetVertexArrayIndexediv 
	???
glGetVertexArrayIndexed64iv 
	???
glCreateSamplers
	create sampler objects
glCreateProgramPipelines
	create program pipeline objects
glCreateQueries
	create query objects
glGetQueryBufferObjecti64v 
	???
glGetQueryBufferObjectiv 
	???
glGetQueryBufferObjectui64v 
	???
glGetQueryBufferObjectuiv 
	???
glGetTextureSubImage
	retrieve a sub-region of a texture image from a texture
    object
glGetCompressedTextureSubImage
	retrieve a sub-region of a compressed texture image from a
    compressed texture object
glGetGraphicsResetStatus
	check if the rendering context has not been lost due to software or hardware issues
glReadnPixels 
	???
glGetnUniformfv 
	???
glGetnUniformiv 
	???
glGetnUniformuiv 
	???
glTextureBarrier
	controls the ordering of reads and writes to rendered fragments across drawing commands

