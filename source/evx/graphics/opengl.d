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
struct gl
	{/*...}*/
		static:

		bool initialized;

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

				debug assert (context_initialized,
					`rendering context must exist prior to making any openGL calls`
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

								if (current_context.program == id)
									return;

								call!`UseProgram` (id);

								current_context.program = id;
							}
						else return current_context.program;
					}
				auto bind ()()
					{/*...}*/
						static assert (name != `program`);

						enum target = mixin(q{GL_} ~ name.toUpper);

						static if (is (Args[0]))
							{/*...}*/
								auto has_id ()()
									{/*...}*/
										static if (name.contains (`texture`))
											return args[0].texture_id;

										else static if (name.contains (`framebuffer`))
											return args[0].framebuffer_id;

										else return args[0].buffer_id;
									}
								auto is_id ()()
									{/*...}*/
										return args[0];
									}

								GLuint id = Match!(has_id, is_id);

								if (mixin(q{current_context.} ~ name) == id)
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
									current_context.} ~ name ~ q{ = id;
								});
							}
						else mixin(q{
							return current_context.} ~ name ~ q{;
						});
					}
				auto unbind ()()
					{/*...}*/
						static assert (name.contains (`Delete`));

						auto group = mixin(q{current_context.} ~ name.after (`Delete`).toLower)[];
						auto n = args[0];
						auto ids = args[1];

						foreach (id; ids[0..n])
							{/*...}*/
								auto result = group[].find (id);

								if (result.empty)
									continue;
								else result.front = 0;
							}

						call!name (args);
					}
				auto forward ()()
					{/*...}*/
						static if (name.contains (`Delete`))
							static assert (name.contains (`Program`) || name.contains (`Shader`));

						return call!name (args.to_c.expand);
					}

				return Match!(use_program, bind, unbind, forward);
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

		void reset () // REFACTOR → Context?
			{/*...}*/
				foreach (member; __traits(allMembers, Context))
					{/*...}*/
						ref variable ()() {return __traits(getMember, current_context, member);}

						void reset ()() {variable = typeof(variable ()).init;}
						void pass  ()() {}

						Match!(reset, pass);
					}
			}

		void clear () // REFACTOR → Context?
			{/*...}*/
				gl.Clear (GL_COLOR_BUFFER_BIT);
			}

		class Context
			{/*...}*/
				private:

				GLFWwindow* window;
				GLuint program; 

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

				this ()
					{/*...}*/
						void initialize_glfw ()
							{/*...}*/
								auto dims = display_size.each!(to!uint);
								window = glfwCreateWindow (dims.x, dims.y, ``, null, null);

								if (window is null)
									assert (0, `window creation failure`);

								glfwShowWindow (window);
								glfwHideWindow (window); // 

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
						void terminate_glfw ()
							{/*...}*/
								if (window !is null)
									glfwDestroyWindow (window);

								glfwTerminate ();
							}
					}
			}

		auto set_context (Context context)
			{/*...}*/
				if (auto found = contexts.find (context))
					{/*...}*/
						if (*found is current_context)
							return current_context;

						*found = current_context;
						current_context = context;

						glfwMakeContextCurrent (current_context.window);
						DerelictGL3.reload ();

						return current_context;
					}
				else assert (0, `requested openGL context does not exist`);
			}
		auto new_context ()
			{/*...}*/
				if (not!initialized)
					{/*...}*/
						DerelictGL3.load ();

						DerelictGLFW3.load ();

						glfwSetErrorCallback (&error_callback);

						initialized  = glfwInit ();

						assert (initialized, "glfwInit failed");
					}
					
				contexts ~= new Context;

				return set_context (contexts.back);
			}
		auto current_context ()
			{/*...}*/
				return contexts.front;
			}

		private {/*...}*/
			__gshared Context[] contexts;

			auto call (string name, Args...)(Args args)
				out {/*...}*/
					error_check!name (args);
				}
				body {/*...}*/
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
		}
	}
