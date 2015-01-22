module evx.graphics.opengl;

private {/*imports}*/
	import std.conv;
	import std.typecons;
	import std.string;

	import evx.misc.utils;
	import evx.type;
	import evx.math;
	import evx.range;

	import derelict.glfw3.glfw3;
	import derelict.opengl3.gl3;

	import evx.graphics.error;
}

//TODO make specific error messages for all the openGL calls
// TODO Type ↔ GLenum ↔ GLSLType

struct GLTypeTable
	{/*...}*/
		public {/*list}*/
			alias List = Cons!(
				GL_FLOAT, `float`,
				GL_FLOAT_VEC2, `vec2`,
				GL_FLOAT_VEC3, `vec3`,
				GL_FLOAT_VEC4, `vec4`,
				GL_DOUBLE, `double`,
				GL_DOUBLE_VEC2, `dvec2`,
				GL_DOUBLE_VEC3, `dvec3`,
				GL_DOUBLE_VEC4, `dvec4`,
				GL_INT, `int`,
				GL_INT_VEC2, `ivec2`,
				GL_INT_VEC3, `ivec3`,
				GL_INT_VEC4, `ivec4`,
				GL_UNSIGNED_INT, `uint`,
				GL_UNSIGNED_INT_VEC2, `uvec2`,
				GL_UNSIGNED_INT_VEC3, `uvec3`,
				GL_UNSIGNED_INT_VEC4, `uvec4`,
				GL_BOOL, `bool`,
				GL_BOOL_VEC2, `bvec2`,
				GL_BOOL_VEC3, `bvec3`,
				GL_BOOL_VEC4, `bvec4`,
				GL_FLOAT_MAT2, `mat2`,
				GL_FLOAT_MAT3, `mat3`,
				GL_FLOAT_MAT4, `mat4`,
				GL_FLOAT_MAT2x3, `mat2x3`,
				GL_FLOAT_MAT2x4, `mat2x4`,
				GL_FLOAT_MAT3x2, `mat3x2`,
				GL_FLOAT_MAT3x4, `mat3x4`,
				GL_FLOAT_MAT4x2, `mat4x2`,
				GL_FLOAT_MAT4x3, `mat4x3`,
				GL_DOUBLE_MAT2, `dmat2`,
				GL_DOUBLE_MAT3, `dmat3`,
				GL_DOUBLE_MAT4, `dmat4`,
				GL_DOUBLE_MAT2x3, `dmat2x3`,
				GL_DOUBLE_MAT2x4, `dmat2x4`,
				GL_DOUBLE_MAT3x2, `dmat3x2`,
				GL_DOUBLE_MAT3x4, `dmat3x4`,
				GL_DOUBLE_MAT4x2, `dmat4x2`,
				GL_DOUBLE_MAT4x3, `dmat4x3`,
				GL_SAMPLER_1D, `sampler1D`,
				GL_SAMPLER_2D, `sampler2D`,
				GL_SAMPLER_3D, `sampler3D`,
				GL_SAMPLER_CUBE, `samplerCube`,
				GL_SAMPLER_1D_SHADOW, `sampler1DShadow`,
				GL_SAMPLER_2D_SHADOW, `sampler2DShadow`,
				GL_SAMPLER_1D_ARRAY, `sampler1DArray`,
				GL_SAMPLER_2D_ARRAY, `sampler2DArray`,
				GL_SAMPLER_1D_ARRAY_SHADOW, `sampler1DArrayShadow`,
				GL_SAMPLER_2D_ARRAY_SHADOW, `sampler2DArrayShadow`,
				GL_SAMPLER_2D_MULTISAMPLE, `sampler2DMS`,
				GL_SAMPLER_2D_MULTISAMPLE_ARRAY, `sampler2DMSArray`,
				GL_SAMPLER_CUBE_SHADOW, `samplerCubeShadow`,
				GL_SAMPLER_BUFFER, `samplerBuffer`,
				GL_SAMPLER_2D_RECT, `sampler2DRect`,
				GL_SAMPLER_2D_RECT_SHADOW, `sampler2DRectShadow`,
				GL_INT_SAMPLER_1D, `isampler1D`,
				GL_INT_SAMPLER_2D, `isampler2D`,
				GL_INT_SAMPLER_3D, `isampler3D`,
				GL_INT_SAMPLER_CUBE, `isamplerCube`,
				GL_INT_SAMPLER_1D_ARRAY, `isampler1DArray`,
				GL_INT_SAMPLER_2D_ARRAY, `isampler2DArray`,
				GL_INT_SAMPLER_2D_MULTISAMPLE, `isampler2DMS`,
				GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY, `isampler2DMSArray`,
				GL_INT_SAMPLER_BUFFER, `isamplerBuffer`,
				GL_INT_SAMPLER_2D_RECT, `isampler2DRect`,
				GL_UNSIGNED_INT_SAMPLER_1D, `usampler1D`,
				GL_UNSIGNED_INT_SAMPLER_2D, `usampler2D`,
				GL_UNSIGNED_INT_SAMPLER_3D, `usampler3D`,
				GL_UNSIGNED_INT_SAMPLER_CUBE, `usamplerCube`,
				GL_UNSIGNED_INT_SAMPLER_1D_ARRAY, `usampler2DArray`,
				GL_UNSIGNED_INT_SAMPLER_2D_ARRAY, `usampler2DArray`,
				GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE, `usampler2DMS`,
				GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY, `usampler2DMSArray`,
				GL_UNSIGNED_INT_SAMPLER_BUFFER, `usamplerBuffer`,
				GL_UNSIGNED_INT_SAMPLER_2D_RECT, `usampler2DRect`,
				GL_IMAGE_1D, `image1D`,
				GL_IMAGE_2D, `image2D`,
				GL_IMAGE_3D, `image3D`,
				GL_IMAGE_2D_RECT, `image2DRect`,
				GL_IMAGE_CUBE, `imageCube`,
				GL_IMAGE_BUFFER, `imageBuffer`,
				GL_IMAGE_1D_ARRAY, `image1DArray`,
				GL_IMAGE_2D_ARRAY, `image2DArray`,
				GL_IMAGE_2D_MULTISAMPLE, `image2DMS`,
				GL_IMAGE_2D_MULTISAMPLE_ARRAY, `image2DMSArray`,
				GL_INT_IMAGE_1D, `iimage1D`,
				GL_INT_IMAGE_2D, `iimage2D`,
				GL_INT_IMAGE_3D, `iimage3D`,
				GL_INT_IMAGE_2D_RECT, `iimage2DRect`,
				GL_INT_IMAGE_CUBE, `iimageCube`,
				GL_INT_IMAGE_BUFFER, `iimageBuffer`,
				GL_INT_IMAGE_1D_ARRAY, `iimage1DArray`,
				GL_INT_IMAGE_2D_ARRAY, `iimage2DArray`,
				GL_INT_IMAGE_2D_MULTISAMPLE, `iimage2DMS`,
				GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY, `iimage2DMSArray`,
				GL_UNSIGNED_INT_IMAGE_1D, `uimage1D`,
				GL_UNSIGNED_INT_IMAGE_2D, `uimage2D`,
				GL_UNSIGNED_INT_IMAGE_3D, `uimage3D`,
				GL_UNSIGNED_INT_IMAGE_2D_RECT, `uimage2DRect`,
				GL_UNSIGNED_INT_IMAGE_CUBE, `uimageCube`,
				GL_UNSIGNED_INT_IMAGE_BUFFER, `uimageBuffer`,
				GL_UNSIGNED_INT_IMAGE_1D_ARRAY, `uimage1DArray`,
				GL_UNSIGNED_INT_IMAGE_2D_ARRAY, `uimage2DArray`,
				GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE, `uimage2DMS`,
				GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY, `uimage2DMSArray`,
				GL_UNSIGNED_INT_ATOMIC_COUNTER, `atomic_uint`,
			);
		}

		alias Enums = Deinterleave!List[0..$/2];
		alias Typenames = Deinterleave!List[$/2..$];

		enum translate (GLenum type) = Typenames[IndexOf!(type, Enums)];
		enum translate (string type) = Enums[IndexOf!(type, Typenames)];

		static opIndex (GLenum type) {return [Typenames][[Enums].countUntil (type).length];}
		static opIndex (string type) {return [Enums][[Typenames].countUntil (type).length];}
	}

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

		auto get (T)(GLenum param)
			out {/*...}*/
				handle (GL_INVALID_ENUM)
					(param.text ~ ` is not an accepted value`)
				.handle (GL_INVALID_VALUE)
					(`index is outside of valid range`);
			}
			body {/*...}*/
				T value;

				static if (is (T == Vector!(n,U), uint n, U))
					{}
				else alias U = T;

				static if (is (U == bool))
					enum t_str = `Boolean`;
				else static if (is (U == int))
					enum t_str = `Integer`;
				else static if (is (U == float))
					enum t_str = `Float`;
				else static if (is (U == double))
					enum t_str = `Double`;
				else static assert (0, `glGet ` ~ T.stringof ~ ` not implemented`);

				mixin(q{glGet} ~ t_str ~ q{v (param, cast(U*)&value);});

				return value;
			}

		public {/*vertex_attrib_array}*/
			template switch_vertex_attrib_array (string polarity)
				if (polarity == `Enable` || polarity == `Disable`)
				{/*...}*/
					void enable_vertex_attrib_array (GLuint index)
						out {/*...}*/
							handle (GL_INVALID_OPERATION)
								(() => is_buffer (gl.array_buffer),
									`no buffer bound to array buffer`
								)
							handle (GL_INVALID_VALUE)
								(
									`index exceeds max vertex attributes `
									` (` ~ get!int (GL_MAX_VERTEX_ATTRIBS) ~ `)`
								);
						}
						body {/*...}*/
							mixin(q{
								gl} ~ polarity ~ q{VertexAttribArray (index);
							});
						}
				}

			alias enable_vertex_attrib_array = switch_vertex_attrib_array!`Enable`;
			alias disable_vertex_attrib_array = switch_vertex_attrib_array!`Disable`;
		}
		public {/*enable}*/
			void enable (GLenum capability)
				out {/*...}*/
					handle (GL_INVALID_ENUM)
						(capability.text ~ ` is not a GL capability`)
					handle (GL_INVALID_VALUE)
						(`index exceeds the maximum for ` ~ capability.text);
				}
				body {/*...}*/
					glEnable (capability);
				}
		}
		public {/*blending}*/
			void blend_func (GLenum source_factor, GLenum target_factor)
				out {/*...}*/
					handle (GL_INVALID_ENUM)
						(
							source_factor.text ~ ` or ` ~ target_factor.text
							~ ` is not an accepted blending factor enum`
						);
				}
				body {/*...}*/
					glBlendFunc (source_factor, target_factor);
				}
		}
		public {/*clear}*/
			void clear (GLenum mask)
				out {/*...}*/
					handle (GL_INVALID_VALUE)
						(`mask contains set bits other than defined mask bits`)
					.handle (GL_INVALID_OPERATION)
						(`executed during immediate mode`);
				}
				body {/*...}*/
					glClear (mask);
				}

			void clear_color (Color color)
				{/*...}*/
					with (color) 
						glClearColor (r,g,b,a);
				}
			auto clear_color ()
				{/*...}*/
					return Color (get!fvec (GL_COLOR_CLEAR_VALUE));
				}
		}
		public {/*buffer}*/
			bool is_buffer (GLuint buffer_id)
				{/*...}*/
					return glIsBuffer (buffer_id);
				}
		}
		public {/*framebuffer}*/
			auto check_framebuffer_status (GLenum target)
				out {/*...}*/
					handle (GL_INVALUD_ENUM)
						(target.text ~ `is not a valid framebuffer target`);
				}
				body {/*...}*/
					return gl.CheckFramebufferStatus (GL_FRAMEBUFFER);
				}

			void framebuffer_texture (Glenum target, GLenum attachment, GLuint texture, GLint level)
				out {/*...}*/
					handle (GL_INVALID_ENUM)
						(`target is not one of the accepted tokens`)
					.handle (GL_INVALID_OPERATION)
						(() => get!int (target) == 0,
							`0 is bound to ` ~ target.text
						)
						(`texture is not compatible with texture target`);
				}
				body {/*...}*/
					glFramebufferTexture (target, attachment, texture, level);
				}
		}
		public {/*fragment output}*/
			void draw_buffer (GLenum buffer_target)
				out {/*..}*/
					handle (GL_INVALID_ENUM)
						(buffer_target.text ~ ` is not an accepted buffer target`)
					.handle (GL_INVALID_OPERATION)
						(`the buffer indicated by ` ~ buffer_target.text ~ ` does not exist`);
				}
				body {/*...}*/
					glDrawBuffer (buffer_target);
				}
		}
		public {/*program}*/
			auto get_program_param (GLuint program, GLenum param)
				out {/*...}*/
					string program_error_msg = program.text ~ ` is not a valid program`

					handle (GL_INVALID_ENUM)
						(param.text ~ ` is not an accepted value`)
					handle (GL_INVALID_VALUE)
						(program_error_msg)
					handle (GL_INVALID_OPERATION)
						(program_error_msg);
				}
				body {/*...}*/
					int value;

					glGetProgramiv (program, param, &value);

					return value;
				}

			auto current_program ()
				{/*...}*/
					return get!int (GL_CURRENT_PROGRAM);
				}

			auto is_program (GLuint program)
				{/*...}*/
					// TODO Errchk
					return glIsProgram (program);
				}
		}
		public {/*uniforms}*/
			// REFACTOR this is old-style introspection
			// REFACTOR to interface-based introspection
			// TODO start with all the latest introspection tools,
			//		then build up an internal verificaton API from there
			//		then use that to aid structural planning
			//		and error tracing
			//		then build out the planned structures
			//		then preplan the bridge to functional layer
			//		and finalize the intermediate structures towards that
			//		then we can build structural/dataflow top layer
			/*
					REFACTOR
						
					opengl api
					error handling
					shader introspection
					shader compilation
					resource management
					resource interop
					graphics/compute pipeline chaining
					pipeline/resource interop (hidden allocation glue layer)
			*/

			debug auto get_active_uniform (GLuint program, GLuint index)
				out {/*...}*/
					string invalid_program = `program ` ~ program.text ~ ` is not a valid program`;

					handle (GL_INVALID_VALUE)
						(invalid_program)
					.handle (GL_INVALID_OPERATION)
						(invalid_program)
					.handle (GL_INVALID_VALUE)
						(
							index.text ~ ` exceeds number of program uniforms`
							` (` ~ get_program_param (program, GL_ACTIVE_UNIFORMS).text ~ `)`
						);
				}
				body {/*...}*/
					struct UniformInfo
						{/*...}*/
							GLenum type;
							GLint size;
							string name;

							const toString ()
								{/*...}*/
									return [GLTypeTable.translate[type], name].join (` `).to!string;
								}
						}

					char[256] name;
					GLint size;
					GLenum type;
					GLint length;

					glGetActiveUniform (program, index, name.length.to!int, &length, &size, &type, name.ptr);

					return UniformInfo (type, sizeof, name[0..length].to!string);
				}
			debug auto get_uniform_location (GLuint program, string name)
				out {/*...}*/
					// TODO
				}
				body {/*...}*/
					return glGetUniformLocation (program, name.to_c.expand);
				}

			template uniform_type_suffix (T)
				{/*...}*/
					static if (is (T == uint))
						enum type = `ui`;
					else static if (is (T == int))
						enum type = `i`;
					else static if (is (T == float))
						enum type = `f`;
					else static assert (0);

					enum uniform_type_suffix = type;
				}

			// TODO GL/GLSL type/enum/string lookup database
			// REVIEW maybe move library-specialized uniforms out of here to a separate middle layer
			void uniform (uint m, uint n, T)(GLint location, Matrix!(m,n,T) matrix)
				{/*...}*/
					enum size = m == n? m.text : n.text ~ `x` ~ m.text; 
					enum count = 1;
					enum transpose = GL_TRUE;

					uniform!(size ~ `fv`)
						(location, count, transpose, matrix.ptr);
				}
			void uniform (uint n, T)(GLint location, Vector!(n,T) vector)
				{/*...}*/
					uniform!(n.text ~ uniform_type_suffix!T)
						(location, value.tuple.expand); // REVIEW how to rewrite with DIP32?
				}
			void uniform (T)(GLint location, T value)
				if (Contains!(T, uint, int, float))
				{/*...}*/
					uniform!(`1` ~ uniform_type_suffix!T)
						(location, value);
				}

			// TODO separate direct uniform call from lib-specialized calls
			void uniform (string suffix, T...)(GLint location, T args)
				out {/*...}*/
					auto info = get_active_uniform (current_program, location);

					handle (GL_INVALID_OPERATION)
						(() => is_program (current_program), 
							() => `there is no current program object.`
						)
						(() => info.size == suffix.extract_number.to!int, 
							() => `the size of the uniform variable declared in the shader `
							`(` ~ info.text ~ `) `
							`does not match the size indicated by the glUniform command`
						)
						(() => suffix[0] == GLTypeTable[info.type][0],
							() => `glUniform` ~ suffix ~ ` is used to load mismatching type ` ~ info.text
						)
						(() => location == get_uniform_location (program, info.name),
							() =>`location ` ~ location.text ~ ` is an invalid uniform location for the current program object`
						)
					.handle (GL_INVALID_VALUE)
						(() => count < 0, 
							() = `count is less than 0.`
						)
					.handle (GL_INVALID_OPERATION)
						(() => count > 1 && info.type != ARRAY_STANDIN,
							() => `count is greater than 1 and the indicated uniform variable is not an array variable.`
						)
						(() => info.type == SAMPLER_STANDIN && suffix != `1i` && suffix != `1iv`,
							() => `a sampler is loaded using a command other than glUniform1i and glUniform1iv.`
						);
				}
				body {/*...}*/
					mixin(q{
						glUniform} ~ suffix ~ q{ (location, args);
					});
				}

			void _checked_uniform (T)(T value, GLint location)
				in {/*...}*/
					assert (current_program != 0,
						`no active program`
					);
					assert (get_program_param (program, GL_ACTIVE_UNIFORMS) < n_uniforms,
						`uniform location invalid`
					);

					GLenum type;
					int sizeof;
					string name;

					get_active_uniform (program, location, type, length, sizeof, name);

					auto uniform_type (T)()
						{/*...}*/
							alias ConversionTable = Cons!(
								float,	`FLOAT`,
								double, `DOUBLE`,
								int, 	`INT`,
								uint, 	`UNSIGNED_INT`,
								bool, 	`BOOL`,
							);

							static if (is (T == Vector!(n,U), uint n, U))
								enum components = `_VEC` ~ n.text;
							else static if (is (T == Matrix!(m,n,U), uint m, uint n, U))
								enum components = `_MAT` ~ m.text ~ (m == n? `` : `x` ~ n.text);
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

					static if (is (typeof(uniform_type!T)))
						{/*...}*/
							if (type == -1)
								assert (0, T.stringof ~ ` does not convert to any known GLSL type`);
							else if (type != GL_SAMPLER_2D)
								{/*...}*/
									else assert (type == uniform_type!T,
										`attempted to upload ` ~ T.stringof ~ ` to uniform ` ~ uniform_call (type) ~ ` ` ~ name[0..length]
										~ `, use ` ~ uniform_call (type) ~ ` instead.`
									);
								}
							else assert (is (T == int),
								`texture sampler uniform must bind a texture unit index, not a ` ~ T.stringof
							);
						}
					else static assert (0, T.stringof ~ ` is currently unsupported`);
				}
				body {/*...}*/
					static if (is (T == Matrix!(m,n,U), uint m, uint n, U))
						{/*...}*/
							static assert (is (U == float));

							static if (m == n)
								enum dims = `Matrix` ~ m.text;
							else enum dims = `Matrix` ~ m.text ~ `x` ~ n.text;

							enum transposed = GL_TRUE; // REVIEW i think my matrices are transposed according to openGL

							mixin(q{
								glUniform} ~ dims ~ q{fv (location, 1, transposed, value.ptr);
							});
						}
					else {/*...}*/
						static if (is (T == Vector!(n,U), uint n, U))
							{}
						else {/*...}*/
							enum n = 1;
							alias U = T;
						}

						static if (is (U == uint))
							enum type = `ui`;
						else static if (is (U == int))
							enum type = `i`;
						else static if (is (U == float))
							enum type = `f`;
						
						mixin(q{
							glUniform} ~ n.text ~ type ~ q{ (location, value.tuple.expand);
						});
					}
				}
		}


		///////////////////////
		private {/*///////// ↓ OLD ↓ /////////////////}*/
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
		}
		///////////////////////
		///////////////////////
	}

// gl

enum {/*TODO organize enums - GL_TEXTURE_2D, GL_READ_COPY_BUFFER, GL_COMPUTE_SHADER, ETC}*/
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
enum {/*...}*/
	// ARB_depth_buffer_float
	GL_DEPTH_COMPONENT32F             = 0x8CAC,
	GL_DEPTH32F_STENCIL8              = 0x8CAD,
	GL_FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD,

	// ARB_framebuffer_object
	GL_INVALID_FRAMEBUFFER_OPERATION  = 0x0506,
	GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210,
	GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211,
	GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212,
	GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213,
	GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214,
	GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215,
	GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216,
	GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217,
	GL_FRAMEBUFFER_DEFAULT            = 0x8218,
	GL_FRAMEBUFFER_UNDEFINED          = 0x8219,
	GL_DEPTH_STENCIL_ATTACHMENT       = 0x821A,
	GL_MAX_RENDERBUFFER_SIZE          = 0x84E8,
	GL_DEPTH_STENCIL                  = 0x84F9,
	GL_UNSIGNED_INT_24_8              = 0x84FA,
	GL_DEPTH24_STENCIL8               = 0x88F0,
	GL_TEXTURE_STENCIL_SIZE           = 0x88F1,
	GL_TEXTURE_RED_TYPE               = 0x8C10,
	GL_TEXTURE_GREEN_TYPE             = 0x8C11,
	GL_TEXTURE_BLUE_TYPE              = 0x8C12,
	GL_TEXTURE_ALPHA_TYPE             = 0x8C13,
	GL_TEXTURE_DEPTH_TYPE             = 0x8C16,
	GL_UNSIGNED_NORMALIZED            = 0x8C17,
	GL_FRAMEBUFFER_BINDING            = 0x8CA6,
	GL_DRAW_FRAMEBUFFER_BINDING       = GL_FRAMEBUFFER_BINDING,
	GL_RENDERBUFFER_BINDING           = 0x8CA7,
	GL_READ_FRAMEBUFFER               = 0x8CA8,
	GL_DRAW_FRAMEBUFFER               = 0x8CA9,
	GL_READ_FRAMEBUFFER_BINDING       = 0x8CAA,
	GL_RENDERBUFFER_SAMPLES           = 0x8CAB,
	GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0,
	GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1,
	GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2,
	GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3,
	GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4,
	GL_FRAMEBUFFER_COMPLETE           = 0x8CD5,
	GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6,
	GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7,
	GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB,
	GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC,
	GL_FRAMEBUFFER_UNSUPPORTED        = 0x8CDD,
	GL_MAX_COLOR_ATTACHMENTS          = 0x8CDF,
	GL_COLOR_ATTACHMENT0              = 0x8CE0,
	GL_COLOR_ATTACHMENT1              = 0x8CE1,
	GL_COLOR_ATTACHMENT2              = 0x8CE2,
	GL_COLOR_ATTACHMENT3              = 0x8CE3,
	GL_COLOR_ATTACHMENT4              = 0x8CE4,
	GL_COLOR_ATTACHMENT5              = 0x8CE5,
	GL_COLOR_ATTACHMENT6              = 0x8CE6,
	GL_COLOR_ATTACHMENT7              = 0x8CE7,
	GL_COLOR_ATTACHMENT8              = 0x8CE8,
	GL_COLOR_ATTACHMENT9              = 0x8CE9,
	GL_COLOR_ATTACHMENT10             = 0x8CEA,
	GL_COLOR_ATTACHMENT11             = 0x8CEB,
	GL_COLOR_ATTACHMENT12             = 0x8CEC,
	GL_COLOR_ATTACHMENT13             = 0x8CED,
	GL_COLOR_ATTACHMENT14             = 0x8CEE,
	GL_COLOR_ATTACHMENT15             = 0x8CEF,
	GL_DEPTH_ATTACHMENT               = 0x8D00,
	GL_STENCIL_ATTACHMENT             = 0x8D20,
	GL_FRAMEBUFFER                    = 0x8D40,
	GL_RENDERBUFFER                   = 0x8D41,
	GL_RENDERBUFFER_WIDTH             = 0x8D42,
	GL_RENDERBUFFER_HEIGHT            = 0x8D43,
	GL_RENDERBUFFER_INTERNAL_FORMAT   = 0x8D44,
	GL_STENCIL_INDEX1                 = 0x8D46,
	GL_STENCIL_INDEX4                 = 0x8D47,
	GL_STENCIL_INDEX8                 = 0x8D48,
	GL_STENCIL_INDEX16                = 0x8D49,
	GL_RENDERBUFFER_RED_SIZE          = 0x8D50,
	GL_RENDERBUFFER_GREEN_SIZE        = 0x8D51,
	GL_RENDERBUFFER_BLUE_SIZE         = 0x8D52,
	GL_RENDERBUFFER_ALPHA_SIZE        = 0x8D53,
	GL_RENDERBUFFER_DEPTH_SIZE        = 0x8D54,
	GL_RENDERBUFFER_STENCIL_SIZE      = 0x8D55,
	GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56,
	GL_MAX_SAMPLES                    = 0x8D57,

	// ARB_framebuffer_sRGB
	GL_FRAMEBUFFER_SRGB               = 0x8DB9,

	// ARB_half_float_vertex
	GL_HALF_FLOAT                     = 0x140B,

	// ARB_map_buffer_range
	GL_MAP_READ_BIT                   = 0x0001,
	GL_MAP_WRITE_BIT                  = 0x0002,
	GL_MAP_INVALIDATE_RANGE_BIT       = 0x0004,
	GL_MAP_INVALIDATE_BUFFER_BIT      = 0x0008,
	GL_MAP_FLUSH_EXPLICIT_BIT         = 0x0010,
	GL_MAP_UNSYNCHRONIZED_BIT         = 0x0020,

	// ARB_texture_compression_rgtc
	GL_COMPRESSED_RED_RGTC1           = 0x8DBB,
	GL_COMPRESSED_SIGNED_RED_RGTC1    = 0x8DBC,
	GL_COMPRESSED_RG_RGTC2            = 0x8DBD,
	GL_COMPRESSED_SIGNED_RG_RGTC2     = 0x8DBE,

	// ARB_texture_rg
	GL_RG                             = 0x8227,
	GL_RG_INTEGER                     = 0x8228,
	GL_R8                             = 0x8229,
	GL_R16                            = 0x822A,
	GL_RG8                            = 0x822B,
	GL_RG16                           = 0x822C,
	GL_R16F                           = 0x822D,
	GL_R32F                           = 0x822E,
	GL_RG16F                          = 0x822F,
	GL_RG32F                          = 0x8230,
	GL_R8I                            = 0x8231,
	GL_R8UI                           = 0x8232,
	GL_R16I                           = 0x8233,
	GL_R16UI                          = 0x8234,
	GL_R32I                           = 0x8235,
	GL_R32UI                          = 0x8236,
	GL_RG8I                           = 0x8237,
	GL_RG8UI                          = 0x8238,
	GL_RG16I                          = 0x8239,
	GL_RG16UI                         = 0x823A,
	GL_RG32I                          = 0x823B,
	GL_RG32UI                         = 0x823C,

	// ARB_vertex_array_object
	GL_VERTEX_ARRAY_BINDING           = 0x85B5,

	// ARB_uniform_buffer_object
	GL_UNIFORM_BUFFER                 = 0x8A11,
	GL_UNIFORM_BUFFER_BINDING         = 0x8A28,
	GL_UNIFORM_BUFFER_START           = 0x8A29,
	GL_UNIFORM_BUFFER_SIZE            = 0x8A2A,
	GL_MAX_VERTEX_UNIFORM_BLOCKS      = 0x8A2B,
	GL_MAX_GEOMETRY_UNIFORM_BLOCKS    = 0x8A2C,
	GL_MAX_FRAGMENT_UNIFORM_BLOCKS    = 0x8A2D,
	GL_MAX_COMBINED_UNIFORM_BLOCKS    = 0x8A2E,
	GL_MAX_UNIFORM_BUFFER_BINDINGS    = 0x8A2F,
	GL_MAX_UNIFORM_BLOCK_SIZE         = 0x8A30,
	GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31,
	GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS = 0x8A32,
	GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33,
	GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34,
	GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH = 0x8A35,
	GL_ACTIVE_UNIFORM_BLOCKS          = 0x8A36,
	GL_UNIFORM_TYPE                   = 0x8A37,
	GL_UNIFORM_SIZE                   = 0x8A38,
	GL_UNIFORM_NAME_LENGTH            = 0x8A39,
	GL_UNIFORM_BLOCK_INDEX            = 0x8A3A,
	GL_UNIFORM_OFFSET                 = 0x8A3B,
	GL_UNIFORM_ARRAY_STRIDE           = 0x8A3C,
	GL_UNIFORM_MATRIX_STRIDE          = 0x8A3D,
	GL_UNIFORM_IS_ROW_MAJOR           = 0x8A3E,
	GL_UNIFORM_BLOCK_BINDING          = 0x8A3F,
	GL_UNIFORM_BLOCK_DATA_SIZE        = 0x8A40,
	GL_UNIFORM_BLOCK_NAME_LENGTH      = 0x8A41,
	GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS  = 0x8A42,
	GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43,
	GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44,
	GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER = 0x8A45,
	GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46,
	GL_INVALID_INDEX                  = 0xFFFFFFFFu,

	// ARB_copy_buffer
	GL_COPY_READ_BUFFER               = 0x8F36,
	GL_COPY_WRITE_BUFFER              = 0x8F37,

	// ARB_depth_clamp
	GL_DEPTH_CLAMP                    = 0x864F,

	// ARB_provoking_vertex
	GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION = 0x8E4C,
	GL_FIRST_VERTEX_CONVENTION        = 0x8E4D,
	GL_LAST_VERTEX_CONVENTION         = 0x8E4E,
	GL_PROVOKING_VERTEX               = 0x8E4F,

	// ARB_seamless_cube_map
	GL_TEXTURE_CUBE_MAP_SEAMLESS      = 0x884F,

	// ARB_sync
	GL_MAX_SERVER_WAIT_TIMEOUT        = 0x9111,
	GL_OBJECT_TYPE                    = 0x9112,
	GL_SYNC_CONDITION                 = 0x9113,
	GL_SYNC_STATUS                    = 0x9114,
	GL_SYNC_FLAGS                     = 0x9115,
	GL_SYNC_FENCE                     = 0x9116,
	GL_SYNC_GPU_COMMANDS_COMPLETE     = 0x9117,
	GL_UNSIGNALED                     = 0x9118,
	GL_SIGNALED                       = 0x9119,
	GL_ALREADY_SIGNALED               = 0x911A,
	GL_TIMEOUT_EXPIRED                = 0x911B,
	GL_CONDITION_SATISFIED            = 0x911C,
	GL_WAIT_FAILED                    = 0x911D,
	GL_SYNC_FLUSH_COMMANDS_BIT        = 0x00000001,

	// ARB_texture_multisample
	GL_SAMPLE_POSITION                = 0x8E50,
	GL_SAMPLE_MASK                    = 0x8E51,
	GL_SAMPLE_MASK_VALUE              = 0x8E52,
	GL_MAX_SAMPLE_MASK_WORDS          = 0x8E59,
	GL_TEXTURE_2D_MULTISAMPLE         = 0x9100,
	GL_PROXY_TEXTURE_2D_MULTISAMPLE   = 0x9101,
	GL_TEXTURE_2D_MULTISAMPLE_ARRAY   = 0x9102,
	GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9103,
	GL_TEXTURE_BINDING_2D_MULTISAMPLE = 0x9104,
	GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY = 0x9105,
	GL_TEXTURE_SAMPLES                = 0x9106,
	GL_TEXTURE_FIXED_SAMPLE_LOCATIONS = 0x9107,
	GL_SAMPLER_2D_MULTISAMPLE         = 0x9108,
	GL_INT_SAMPLER_2D_MULTISAMPLE     = 0x9109,
	GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = 0x910A,
	GL_SAMPLER_2D_MULTISAMPLE_ARRAY   = 0x910B,
	GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C,
	GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D,
	GL_MAX_COLOR_TEXTURE_SAMPLES      = 0x910E,
	GL_MAX_DEPTH_TEXTURE_SAMPLES      = 0x910F,
	GL_MAX_INTEGER_SAMPLES            = 0x9110,

	// ARB_sample_shading
	GL_SAMPLE_SHADING_ARB             = 0x8C36,
	GL_MIN_SAMPLE_SHADING_VALUE_ARB   = 0x8C37,

	// ARB_texture_cube_map_array
	GL_TEXTURE_CUBE_MAP_ARRAY_ARB     = 0x9009,
	GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB = 0x900A,
	GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB = 0x900B,
	GL_SAMPLER_CUBE_MAP_ARRAY_ARB     = 0x900C,
	GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB = 0x900D,
	GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 0x900E,
	GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 0x900F,

	// ARB_texture_gather
	GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB = 0x8E5E,
	GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB = 0x8E5F,

	// ARB_shading_language_include
	GL_SHADER_INCLUDE_ARB             = 0x8DAE,
	GL_NAMED_STRING_LENGTH_ARB        = 0x8DE9,
	GL_NAMED_STRING_TYPE_ARB          = 0x8DEA,

	// ARB_texture_compression_bptc
	GL_COMPRESSED_RGBA_BPTC_UNORM_ARB = 0x8E8C,
	GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB = 0x8E8D,
	GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB = 0x8E8E,
	GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB = 0x8E8F,

	// ARB_blend_func_extended
	GL_SRC1_COLOR                     = 0x88F9,
	GL_ONE_MINUS_SRC1_COLOR           = 0x88FA,
	GL_ONE_MINUS_SRC1_ALPHA           = 0x88FB,
	GL_MAX_DUAL_SOURCE_DRAW_BUFFERS   = 0x88FC,

	// ARB_occlusion_query2
	GL_ANY_SAMPLES_PASSED             = 0x8C2F,

	// ARB_sampler_objects
	GL_SAMPLER_BINDING                = 0x8919,

	// ARB_texture_rgb10_a2ui
	GL_RGB10_A2UI                     = 0x906F,

	// ARB_texture_swizzle
	GL_TEXTURE_SWIZZLE_R              = 0x8E42,
	GL_TEXTURE_SWIZZLE_G              = 0x8E43,
	GL_TEXTURE_SWIZZLE_B              = 0x8E44,
	GL_TEXTURE_SWIZZLE_A              = 0x8E45,
	GL_TEXTURE_SWIZZLE_RGBA           = 0x8E46,

	// ARB_timer_query
	GL_TIME_ELAPSED                   = 0x88BF,
	GL_TIMESTAMP                      = 0x8E28,

	// ARB_vertex_type_2_10_10_10_rev
	GL_INT_2_10_10_10_REV             = 0x8D9F,

	// ARB_draw_indirect
	GL_DRAW_INDIRECT_BUFFER           = 0x8F3F,
	GL_DRAW_INDIRECT_BUFFER_BINDING   = 0x8F43,

	// ARB_gpu_shader5
	GL_GEOMETRY_SHADER_INVOCATIONS    = 0x887F,
	GL_MAX_GEOMETRY_SHADER_INVOCATIONS = 0x8E5A,
	GL_MIN_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5B,
	GL_MAX_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5C,
	GL_FRAGMENT_INTERPOLATION_OFFSET_BITS = 0x8E5D,

	// ARB_gpu_shader_fp64
	GL_DOUBLE_VEC2                    = 0x8FFC,
	GL_DOUBLE_VEC3                    = 0x8FFD,
	GL_DOUBLE_VEC4                    = 0x8FFE,
	GL_DOUBLE_MAT2                    = 0x8F46,
	GL_DOUBLE_MAT3                    = 0x8F47,
	GL_DOUBLE_MAT4                    = 0x8F48,
	GL_DOUBLE_MAT2x3                  = 0x8F49,
	GL_DOUBLE_MAT2x4                  = 0x8F4A,
	GL_DOUBLE_MAT3x2                  = 0x8F4B,
	GL_DOUBLE_MAT3x4                  = 0x8F4C,
	GL_DOUBLE_MAT4x2                  = 0x8F4D,
	GL_DOUBLE_MAT4x3                  = 0x8F4E,

	// ARB_shader_subroutine
	GL_ACTIVE_SUBROUTINES             = 0x8DE5,
	GL_ACTIVE_SUBROUTINE_UNIFORMS     = 0x8DE6,
	GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS = 0x8E47,
	GL_ACTIVE_SUBROUTINE_MAX_LENGTH   = 0x8E48,
	GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH = 0x8E49,
	GL_MAX_SUBROUTINES                = 0x8DE7,
	GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS = 0x8DE8,
	GL_NUM_COMPATIBLE_SUBROUTINES     = 0x8E4A,
	GL_COMPATIBLE_SUBROUTINES         = 0x8E4B,

	// ARB_tessellation_shader
	GL_PATCHES                        = 0x000E,
	GL_PATCH_VERTICES                 = 0x8E72,
	GL_PATCH_DEFAULT_INNER_LEVEL      = 0x8E73,
	GL_PATCH_DEFAULT_OUTER_LEVEL      = 0x8E74,
	GL_TESS_CONTROL_OUTPUT_VERTICES   = 0x8E75,
	GL_TESS_GEN_MODE                  = 0x8E76,
	GL_TESS_GEN_SPACING               = 0x8E77,
	GL_TESS_GEN_VERTEX_ORDER          = 0x8E78,
	GL_TESS_GEN_POINT_MODE            = 0x8E79,
	GL_ISOLINES                       = 0x8E7A,
	GL_FRACTIONAL_ODD                 = 0x8E7B,
	GL_FRACTIONAL_EVEN                = 0x8E7C,
	GL_MAX_PATCH_VERTICES             = 0x8E7D,
	GL_MAX_TESS_GEN_LEVEL             = 0x8E7E,
	GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E7F,
	GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E80,
	GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS = 0x8E81,
	GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS = 0x8E82,
	GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS = 0x8E83,
	GL_MAX_TESS_PATCH_COMPONENTS      = 0x8E84,
	GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS = 0x8E85,
	GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS = 0x8E86,
	GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS = 0x8E89,
	GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS = 0x8E8A,
	GL_MAX_TESS_CONTROL_INPUT_COMPONENTS = 0x886C,
	GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS = 0x886D,
	GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E1E,
	GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E1F,
	GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER = 0x84F0,
	GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x84F1,
	GL_TESS_EVALUATION_SHADER         = 0x8E87,
	GL_TESS_CONTROL_SHADER            = 0x8E88,

	// ARB_transform_feedback2
	GL_TRANSFORM_FEEDBACK             = 0x8E22,
	GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED = 0x8E23,
	GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE = 0x8E24,
	GL_TRANSFORM_FEEDBACK_BINDING     = 0x8E25,

	// ARB_transform_feedback3
	GL_MAX_TRANSFORM_FEEDBACK_BUFFERS = 0x8E70,
	GL_MAX_VERTEX_STREAMS             = 0x8E71,

	// ARB_ES2_compatibility
	GL_FIXED                          = 0x140C,
	GL_IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A,
	GL_IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B,
	GL_LOW_FLOAT                      = 0x8DF0,
	GL_MEDIUM_FLOAT                   = 0x8DF1,
	GL_HIGH_FLOAT                     = 0x8DF2,
	GL_LOW_INT                        = 0x8DF3,
	GL_MEDIUM_INT                     = 0x8DF4,
	GL_HIGH_INT                       = 0x8DF5,
	GL_SHADER_COMPILER                = 0x8DFA,
	GL_NUM_SHADER_BINARY_FORMATS      = 0x8DF9,
	GL_MAX_VERTEX_UNIFORM_VECTORS     = 0x8DFB,
	GL_MAX_VARYING_VECTORS            = 0x8DFC,
	GL_MAX_FRAGMENT_UNIFORM_VECTORS   = 0x8DFD,

	// ARB_get_program_binary
	GL_PROGRAM_BINARY_RETRIEVABLE_HINT = 0x8257,
	GL_PROGRAM_BINARY_LENGTH          = 0x8741,
	GL_NUM_PROGRAM_BINARY_FORMATS     = 0x87FE,
	GL_PROGRAM_BINARY_FORMATS         = 0x87FF,

	// ARB_separate_shader_objects
	GL_VERTEX_SHADER_BIT              = 0x00000001,
	GL_FRAGMENT_SHADER_BIT            = 0x00000002,
	GL_GEOMETRY_SHADER_BIT            = 0x00000004,
	GL_TESS_CONTROL_SHADER_BIT        = 0x00000008,
	GL_TESS_EVALUATION_SHADER_BIT     = 0x00000010,
	GL_ALL_SHADER_BITS                = 0xFFFFFFFF,
	GL_PROGRAM_SEPARABLE              = 0x8258,
	GL_ACTIVE_PROGRAM                 = 0x8259,
	GL_PROGRAM_PIPELINE_BINDING       = 0x825A,

	// ARB_viewport_array
	GL_MAX_VIEWPORTS                  = 0x825B,
	GL_VIEWPORT_SUBPIXEL_BITS         = 0x825C,
	GL_VIEWPORT_BOUNDS_RANGE          = 0x825D,
	GL_LAYER_PROVOKING_VERTEX         = 0x825E,
	GL_VIEWPORT_INDEX_PROVOKING_VERTEX = 0x825F,
	GL_UNDEFINED_VERTEX               = 0x8260,

	// ARB_cl_event
	GL_SYNC_CL_EVENT_ARB              = 0x8240,
	GL_SYNC_CL_EVENT_COMPLETE_ARB     = 0x8241,

	// ARB_debug_output
	GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB   = 0x8242,
	GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB = 0x8243,
	GL_DEBUG_CALLBACK_FUNCTION_ARB    = 0x8244,
	GL_DEBUG_CALLBACK_USER_PARAM_ARB  = 0x8245,
	GL_DEBUG_SOURCE_API_ARB           = 0x8246,
	GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB = 0x8247,
	GL_DEBUG_SOURCE_SHADER_COMPILER_ARB = 0x8248,
	GL_DEBUG_SOURCE_THIRD_PARTY_ARB   = 0x8249,
	GL_DEBUG_SOURCE_APPLICATION_ARB   = 0x824A,
	GL_DEBUG_SOURCE_OTHER_ARB         = 0x824B,
	GL_DEBUG_TYPE_ERROR_ARB           = 0x824C,
	GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB = 0x824D,
	GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB = 0x824E,
	GL_DEBUG_TYPE_PORTABILITY_ARB     = 0x824F,
	GL_DEBUG_TYPE_PERFORMANCE_ARB     = 0x8250,
	GL_DEBUG_TYPE_OTHER_ARB           = 0x8251,
	GL_MAX_DEBUG_MESSAGE_LENGTH_ARB   = 0x9143,
	GL_MAX_DEBUG_LOGGED_MESSAGES_ARB  = 0x9144,
	GL_DEBUG_LOGGED_MESSAGES_ARB      = 0x9145,
	GL_DEBUG_SEVERITY_HIGH_ARB        = 0x9146,
	GL_DEBUG_SEVERITY_MEDIUM_ARB      = 0x9147,
	GL_DEBUG_SEVERITY_LOW_ARB         = 0x9148,

	// ARB_robustness
	GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB = 0x00000004,
	GL_LOSE_CONTEXT_ON_RESET_ARB      = 0x8252,
	GL_GUILTY_CONTEXT_RESET_ARB       = 0x8253,
	GL_INNOCENT_CONTEXT_RESET_ARB     = 0x8254,
	GL_UNKNOWN_CONTEXT_RESET_ARB      = 0x8255,
	GL_RESET_NOTIFICATION_STRATEGY_ARB = 0x8256,
	GL_NO_RESET_NOTIFICATION_ARB      = 0x8261,

	// ARB_compressed_texture_pixel_storage
	GL_UNPACK_COMPRESSED_BLOCK_WIDTH  = 0x9127,
	GL_UNPACK_COMPRESSED_BLOCK_HEIGHT = 0x9128,
	GL_UNPACK_COMPRESSED_BLOCK_DEPTH  = 0x9129,
	GL_UNPACK_COMPRESSED_BLOCK_SIZE   = 0x912A,
	GL_PACK_COMPRESSED_BLOCK_WIDTH    = 0x912B,
	GL_PACK_COMPRESSED_BLOCK_HEIGHT   = 0x912C,
	GL_PACK_COMPRESSED_BLOCK_DEPTH    = 0x912D,
	GL_PACK_COMPRESSED_BLOCK_SIZE     = 0x912E,

	// ARB_internalformat_query
	GL_NUM_SAMPLE_COUNTS              = 0x9380,

	// ARB_map_buffer_alignment
	GL_MIN_MAP_BUFFER_ALIGNMENT       = 0x90BC,

	// ARB_shader_atomic_counters
	GL_ATOMIC_COUNTER_BUFFER          = 0x92C0,
	GL_ATOMIC_COUNTER_BUFFER_BINDING  = 0x92C1,
	GL_ATOMIC_COUNTER_BUFFER_START    = 0x92C2,
	GL_ATOMIC_COUNTER_BUFFER_SIZE     = 0x92C3,
	GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE = 0x92C4,
	GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS = 0x92C5,
	GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES = 0x92C6,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER = 0x92C7,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER = 0x92C8,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x92C9,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER = 0x92CA,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER = 0x92CB,
	GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS = 0x92CC,
	GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS = 0x92CD,
	GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS = 0x92CE,
	GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS = 0x92CF,
	GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS = 0x92D0,
	GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS = 0x92D1,
	GL_MAX_VERTEX_ATOMIC_COUNTERS     = 0x92D2,
	GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS = 0x92D3,
	GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS = 0x92D4,
	GL_MAX_GEOMETRY_ATOMIC_COUNTERS   = 0x92D5,
	GL_MAX_FRAGMENT_ATOMIC_COUNTERS   = 0x92D6,
	GL_MAX_COMBINED_ATOMIC_COUNTERS   = 0x92D7,
	GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE = 0x92D8,
	GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS = 0x92DC,
	GL_ACTIVE_ATOMIC_COUNTER_BUFFERS  = 0x92D9,
	GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX = 0x92DA,
	GL_UNSIGNED_INT_ATOMIC_COUNTER    = 0x92DB,

	// ARB_shader_image_load_store
	GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT = 0x00000001,
	GL_ELEMENT_ARRAY_BARRIER_BIT      = 0x00000002,
	GL_UNIFORM_BARRIER_BIT            = 0x00000004,
	GL_TEXTURE_FETCH_BARRIER_BIT      = 0x00000008,
	GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020,
	GL_COMMAND_BARRIER_BIT            = 0x00000040,
	GL_PIXEL_BUFFER_BARRIER_BIT       = 0x00000080,
	GL_TEXTURE_UPDATE_BARRIER_BIT     = 0x00000100,
	GL_BUFFER_UPDATE_BARRIER_BIT      = 0x00000200,
	GL_FRAMEBUFFER_BARRIER_BIT        = 0x00000400,
	GL_TRANSFORM_FEEDBACK_BARRIER_BIT = 0x00000800,
	GL_ATOMIC_COUNTER_BARRIER_BIT     = 0x00001000,
	GL_ALL_BARRIER_BITS               = 0xFFFFFFFF,
	GL_MAX_IMAGE_UNITS                = 0x8F38,
	GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS = 0x8F39,
	GL_IMAGE_BINDING_NAME             = 0x8F3A,
	GL_IMAGE_BINDING_LEVEL            = 0x8F3B,
	GL_IMAGE_BINDING_LAYERED          = 0x8F3C,
	GL_IMAGE_BINDING_LAYER            = 0x8F3D,
	GL_IMAGE_BINDING_ACCESS           = 0x8F3E,
	GL_IMAGE_1D                       = 0x904C,
	GL_IMAGE_2D                       = 0x904D,
	GL_IMAGE_3D                       = 0x904E,
	GL_IMAGE_2D_RECT                  = 0x904F,
	GL_IMAGE_CUBE                     = 0x9050,
	GL_IMAGE_BUFFER                   = 0x9051,
	GL_IMAGE_1D_ARRAY                 = 0x9052,
	GL_IMAGE_2D_ARRAY                 = 0x9053,
	GL_IMAGE_CUBE_MAP_ARRAY           = 0x9054,
	GL_IMAGE_2D_MULTISAMPLE           = 0x9055,
	GL_IMAGE_2D_MULTISAMPLE_ARRAY     = 0x9056,
	GL_INT_IMAGE_1D                   = 0x9057,
	GL_INT_IMAGE_2D                   = 0x9058,
	GL_INT_IMAGE_3D                   = 0x9059,
	GL_INT_IMAGE_2D_RECT              = 0x905A,
	GL_INT_IMAGE_CUBE                 = 0x905B,
	GL_INT_IMAGE_BUFFER               = 0x905C,
	GL_INT_IMAGE_1D_ARRAY             = 0x905D,
	GL_INT_IMAGE_2D_ARRAY             = 0x905E,
	GL_INT_IMAGE_CUBE_MAP_ARRAY       = 0x905F,
	GL_INT_IMAGE_2D_MULTISAMPLE       = 0x9060,
	GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061,
	GL_UNSIGNED_INT_IMAGE_1D          = 0x9062,
	GL_UNSIGNED_INT_IMAGE_2D          = 0x9063,
	GL_UNSIGNED_INT_IMAGE_3D          = 0x9064,
	GL_UNSIGNED_INT_IMAGE_2D_RECT     = 0x9065,
	GL_UNSIGNED_INT_IMAGE_CUBE        = 0x9066,
	GL_UNSIGNED_INT_IMAGE_BUFFER      = 0x9067,
	GL_UNSIGNED_INT_IMAGE_1D_ARRAY    = 0x9068,
	GL_UNSIGNED_INT_IMAGE_2D_ARRAY    = 0x9069,
	GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY = 0x906A,
	GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE = 0x906B,
	GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C,
	GL_MAX_IMAGE_SAMPLES              = 0x906D,
	GL_IMAGE_BINDING_FORMAT           = 0x906E,
	GL_IMAGE_FORMAT_COMPATIBILITY_TYPE = 0x90C7,
	GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE = 0x90C8,
	GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS = 0x90C9,
	GL_MAX_VERTEX_IMAGE_UNIFORMS      = 0x90CA,
	GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS = 0x90CB,
	GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS = 0x90CC,
	GL_MAX_GEOMETRY_IMAGE_UNIFORMS    = 0x90CD,
	GL_MAX_FRAGMENT_IMAGE_UNIFORMS    = 0x90CE,
	GL_MAX_COMBINED_IMAGE_UNIFORMS    = 0x90CF,

	// ARB_texture_storage
	GL_TEXTURE_IMMUTABLE_FORMAT       = 0x912F,

	// ARB_ES3_compatibility
	GL_COMPRESSED_RGB8_ETC2           = 0x9274,
	GL_COMPRESSED_SRGB8_ETC2          = 0x9275,
	GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276,
	GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277,
	GL_COMPRESSED_RGBA8_ETC2_EAC      = 0x9278,
	GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279,
	GL_COMPRESSED_R11_EAC             = 0x9270,
	GL_COMPRESSED_SIGNED_R11_EAC      = 0x9271,
	GL_COMPRESSED_RG11_EAC            = 0x9272,
	GL_COMPRESSED_SIGNED_RG11_EAC     = 0x9273,
	GL_PRIMITIVE_RESTART_FIXED_INDEX  = 0x8D69,
	GL_ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A,
	GL_MAX_ELEMENT_INDEX              = 0x8D6B,

	// ARB_compute_shader
	GL_COMPUTE_SHADER                 = 0x91B9,
	GL_MAX_COMPUTE_UNIFORM_BLOCKS     = 0x91BB,
	GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = 0x91BC,
	GL_MAX_COMPUTE_IMAGE_UNIFORMS     = 0x91BD,
	GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = 0x8262,
	GL_MAX_COMPUTE_UNIFORM_COMPONENTS = 0x8263,
	GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = 0x8264,
	GL_MAX_COMPUTE_ATOMIC_COUNTERS    = 0x8265,
	GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = 0x8266,
	GL_MAX_COMPUTE_LOCAL_INVOCATIONS  = 0x90EB,
	GL_MAX_COMPUTE_WORK_GROUP_COUNT   = 0x91BE,
	GL_MAX_COMPUTE_WORK_GROUP_SIZE    = 0x91BF,
	GL_COMPUTE_LOCAL_WORK_SIZE        = 0x8267,
	GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER = 0x90EC,
	GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER = 0x90ED,
	GL_DISPATCH_INDIRECT_BUFFER       = 0x90EE,
	GL_DISPATCH_INDIRECT_BUFFER_BINDING = 0x90EF,
	GL_COMPUTE_SHADER_BIT             = 0x00000020,

	// KHR_debug
	GL_DEBUG_OUTPUT_SYNCHRONOUS       = 0x8242,
	GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH = 0x8243,
	GL_DEBUG_CALLBACK_FUNCTION        = 0x8244,
	GL_DEBUG_CALLBACK_USER_PARAM      = 0x8245,
	GL_DEBUG_SOURCE_API               = 0x8246,
	GL_DEBUG_SOURCE_WINDOW_SYSTEM     = 0x8247,
	GL_DEBUG_SOURCE_SHADER_COMPILER   = 0x8248,
	GL_DEBUG_SOURCE_THIRD_PARTY       = 0x8249,
	GL_DEBUG_SOURCE_APPLICATION       = 0x824A,
	GL_DEBUG_SOURCE_OTHER             = 0x824B,
	GL_DEBUG_TYPE_ERROR               = 0x824C,
	GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR = 0x824D,
	GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR  = 0x824E,
	GL_DEBUG_TYPE_PORTABILITY         = 0x824F,
	GL_DEBUG_TYPE_PERFORMANCE         = 0x8250,
	GL_DEBUG_TYPE_OTHER               = 0x8251,
	GL_DEBUG_TYPE_MARKER              = 0x8268,
	GL_DEBUG_TYPE_PUSH_GROUP          = 0x8269,
	GL_DEBUG_TYPE_POP_GROUP           = 0x826A,
	GL_DEBUG_SEVERITY_NOTIFICATION    = 0x826B,
	GL_MAX_DEBUG_GROUP_STACK_DEPTH    = 0x826C,
	GL_DEBUG_GROUP_STACK_DEPTH        = 0x826D,
	GL_BUFFER                         = 0x82E0,
	GL_SHADER                         = 0x82E1,
	GL_PROGRAM                        = 0x82E2,
	GL_QUERY                          = 0x82E3,
	GL_PROGRAM_PIPELINE               = 0x82E4,
	GL_SAMPLER                        = 0x82E6,
	GL_DISPLAY_LIST                   = 0x82E7,
	GL_MAX_LABEL_LENGTH               = 0x82E8,
	GL_MAX_DEBUG_MESSAGE_LENGTH       = 0x9143,
	GL_MAX_DEBUG_LOGGED_MESSAGES      = 0x9144,
	GL_DEBUG_LOGGED_MESSAGES          = 0x9145,
	GL_DEBUG_SEVERITY_HIGH            = 0x9146,
	GL_DEBUG_SEVERITY_MEDIUM          = 0x9147,
	GL_DEBUG_SEVERITY_LOW             = 0x9148,
	GL_DEBUG_OUTPUT                   = 0x92E0,
	GL_CONTEXT_FLAG_DEBUG_BIT         = 0x00000002,

	// ARB_explicit_uniform_location
	GL_MAX_UNIFORM_LOCATIONS = 0x826E,

	// ARB_framebuffer_no_attachments
	GL_FRAMEBUFFER_DEFAULT_WIDTH      = 0x9310,
	GL_FRAMEBUFFER_DEFAULT_HEIGHT     = 0x9311,
	GL_FRAMEBUFFER_DEFAULT_LAYERS     = 0x9312,
	GL_FRAMEBUFFER_DEFAULT_SAMPLES    = 0x9313,
	GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS = 0x9314,
	GL_MAX_FRAMEBUFFER_WIDTH          = 0x9315,
	GL_MAX_FRAMEBUFFER_HEIGHT         = 0x9316,
	GL_MAX_FRAMEBUFFER_LAYERS         = 0x9317,
	GL_MAX_FRAMEBUFFER_SAMPLES        = 0x9318,

	// ARB_internalformat_query2
	GL_INTERNALFORMAT_SUPPORTED       = 0x826F,
	GL_INTERNALFORMAT_PREFERRED       = 0x8270,
	GL_INTERNALFORMAT_RED_SIZE        = 0x8271,
	GL_INTERNALFORMAT_GREEN_SIZE      = 0x8272,
	GL_INTERNALFORMAT_BLUE_SIZE       = 0x8273,
	GL_INTERNALFORMAT_ALPHA_SIZE      = 0x8274,
	GL_INTERNALFORMAT_DEPTH_SIZE      = 0x8275,
	GL_INTERNALFORMAT_STENCIL_SIZE    = 0x8276,
	GL_INTERNALFORMAT_SHARED_SIZE     = 0x8277,
	GL_INTERNALFORMAT_RED_TYPE        = 0x8278,
	GL_INTERNALFORMAT_GREEN_TYPE      = 0x8279,
	GL_INTERNALFORMAT_BLUE_TYPE       = 0x827A,
	GL_INTERNALFORMAT_ALPHA_TYPE      = 0x827B,
	GL_INTERNALFORMAT_DEPTH_TYPE      = 0x827C,
	GL_INTERNALFORMAT_STENCIL_TYPE    = 0x827D,
	GL_MAX_WIDTH                      = 0x827E,
	GL_MAX_HEIGHT                     = 0x827F,
	GL_MAX_DEPTH                      = 0x8280,
	GL_MAX_LAYERS                     = 0x8281,
	GL_MAX_COMBINED_DIMENSIONS        = 0x8282,
	GL_COLOR_COMPONENTS               = 0x8283,
	GL_DEPTH_COMPONENTS               = 0x8284,
	GL_STENCIL_COMPONENTS             = 0x8285,
	GL_COLOR_RENDERABLE               = 0x8286,
	GL_DEPTH_RENDERABLE               = 0x8287,
	GL_STENCIL_RENDERABLE             = 0x8288,
	GL_FRAMEBUFFER_RENDERABLE         = 0x8289,
	GL_FRAMEBUFFER_RENDERABLE_LAYERED = 0x828A,
	GL_FRAMEBUFFER_BLEND              = 0x828B,
	GL_READ_PIXELS                    = 0x828C,
	GL_READ_PIXELS_FORMAT             = 0x828D,
	GL_READ_PIXELS_TYPE               = 0x828E,
	GL_TEXTURE_IMAGE_FORMAT           = 0x828F,
	GL_TEXTURE_IMAGE_TYPE             = 0x8290,
	GL_GET_TEXTURE_IMAGE_FORMAT       = 0x8291,
	GL_GET_TEXTURE_IMAGE_TYPE         = 0x8292,
	GL_MIPMAP                         = 0x8293,
	GL_MANUAL_GENERATE_MIPMAP         = 0x8294,
	GL_AUTO_GENERATE_MIPMAP           = 0x8295,
	GL_COLOR_ENCODING                 = 0x8296,
	GL_SRGB_READ                      = 0x8297,
	GL_SRGB_WRITE                     = 0x8298,
	GL_SRGB_DECODE_ARB                = 0x8299,
	GL_FILTER                         = 0x829A,
	GL_VERTEX_TEXTURE                 = 0x829B,
	GL_TESS_CONTROL_TEXTURE           = 0x829C,
	GL_TESS_EVALUATION_TEXTURE        = 0x829D,
	GL_GEOMETRY_TEXTURE               = 0x829E,
	GL_FRAGMENT_TEXTURE               = 0x829F,
	GL_COMPUTE_TEXTURE                = 0x82A0,
	GL_TEXTURE_SHADOW                 = 0x82A1,
	GL_TEXTURE_GATHER                 = 0x82A2,
	GL_TEXTURE_GATHER_SHADOW          = 0x82A3,
	GL_SHADER_IMAGE_LOAD              = 0x82A4,
	GL_SHADER_IMAGE_STORE             = 0x82A5,
	GL_SHADER_IMAGE_ATOMIC            = 0x82A6,
	GL_IMAGE_TEXEL_SIZE               = 0x82A7,
	GL_IMAGE_COMPATIBILITY_CLASS      = 0x82A8,
	GL_IMAGE_PIXEL_FORMAT             = 0x82A9,
	GL_IMAGE_PIXEL_TYPE               = 0x82AA,
	GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST = 0x82AC,
	GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST = 0x82AD,
	GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE = 0x82AE,
	GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE = 0x82AF,
	GL_TEXTURE_COMPRESSED_BLOCK_WIDTH = 0x82B1,
	GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT = 0x82B2,
	GL_TEXTURE_COMPRESSED_BLOCK_SIZE  = 0x82B3,
	GL_CLEAR_BUFFER                   = 0x82B4,
	GL_TEXTURE_VIEW                   = 0x82B5,
	GL_VIEW_COMPATIBILITY_CLASS       = 0x82B6,
	GL_FULL_SUPPORT                   = 0x82B7,
	GL_CAVEAT_SUPPORT                 = 0x82B8,
	GL_IMAGE_CLASS_4_X_32             = 0x82B9,
	GL_IMAGE_CLASS_2_X_32             = 0x82BA,
	GL_IMAGE_CLASS_1_X_32             = 0x82BB,
	GL_IMAGE_CLASS_4_X_16             = 0x82BC,
	GL_IMAGE_CLASS_2_X_16             = 0x82BD,
	GL_IMAGE_CLASS_1_X_16             = 0x82BE,
	GL_IMAGE_CLASS_4_X_8              = 0x82BF,
	GL_IMAGE_CLASS_2_X_8              = 0x82C0,
	GL_IMAGE_CLASS_1_X_8              = 0x82C1,
	GL_IMAGE_CLASS_11_11_10           = 0x82C2,
	GL_IMAGE_CLASS_10_10_10_2         = 0x82C3,
	GL_VIEW_CLASS_128_BITS            = 0x82C4,
	GL_VIEW_CLASS_96_BITS             = 0x82C5,
	GL_VIEW_CLASS_64_BITS             = 0x82C6,
	GL_VIEW_CLASS_48_BITS             = 0x82C7,
	GL_VIEW_CLASS_32_BITS             = 0x82C8,
	GL_VIEW_CLASS_24_BITS             = 0x82C9,
	GL_VIEW_CLASS_16_BITS             = 0x82CA,
	GL_VIEW_CLASS_8_BITS              = 0x82CB,
	GL_VIEW_CLASS_S3TC_DXT1_RGB       = 0x82CC,
	GL_VIEW_CLASS_S3TC_DXT1_RGBA      = 0x82CD,
	GL_VIEW_CLASS_S3TC_DXT3_RGBA      = 0x82CE,
	GL_VIEW_CLASS_S3TC_DXT5_RGBA      = 0x82CF,
	GL_VIEW_CLASS_RGTC1_RED           = 0x82D0,
	GL_VIEW_CLASS_RGTC2_RG            = 0x82D1,
	GL_VIEW_CLASS_BPTC_UNORM          = 0x82D2,
	GL_VIEW_CLASS_BPTC_FLOAT          = 0x82D3,

	// ARB_program_interface_query
	GL_UNIFORM                        = 0x92E1,
	GL_UNIFORM_BLOCK                  = 0x92E2,
	GL_PROGRAM_INPUT                  = 0x92E3,
	GL_PROGRAM_OUTPUT                 = 0x92E4,
	GL_BUFFER_VARIABLE                = 0x92E5,
	GL_SHADER_STORAGE_BLOCK           = 0x92E6,
	GL_VERTEX_SUBROUTINE              = 0x92E8,
	GL_TESS_CONTROL_SUBROUTINE        = 0x92E9,
	GL_TESS_EVALUATION_SUBROUTINE     = 0x92EA,
	GL_GEOMETRY_SUBROUTINE            = 0x92EB,
	GL_FRAGMENT_SUBROUTINE            = 0x92EC,
	GL_COMPUTE_SUBROUTINE             = 0x92ED,
	GL_VERTEX_SUBROUTINE_UNIFORM      = 0x92EE,
	GL_TESS_CONTROL_SUBROUTINE_UNIFORM = 0x92EF,
	GL_TESS_EVALUATION_SUBROUTINE_UNIFORM = 0x92F0,
	GL_GEOMETRY_SUBROUTINE_UNIFORM    = 0x92F1,
	GL_FRAGMENT_SUBROUTINE_UNIFORM    = 0x92F2,
	GL_COMPUTE_SUBROUTINE_UNIFORM     = 0x92F3,
	GL_TRANSFORM_FEEDBACK_VARYING     = 0x92F4,
	GL_ACTIVE_RESOURCES               = 0x92F5,
	GL_MAX_NAME_LENGTH                = 0x92F6,
	GL_MAX_NUM_ACTIVE_VARIABLES       = 0x92F7,
	GL_MAX_NUM_COMPATIBLE_SUBROUTINES = 0x92F8,
	GL_NAME_LENGTH                    = 0x92F9,
	GL_TYPE                           = 0x92FA,
	GL_ARRAY_SIZE                     = 0x92FB,
	GL_OFFSET                         = 0x92FC,
	GL_BLOCK_INDEX                    = 0x92FD,
	GL_ARRAY_STRIDE                   = 0x92FE,
	GL_MATRIX_STRIDE                  = 0x92FF,
	GL_IS_ROW_MAJOR                   = 0x9300,
	GL_ATOMIC_COUNTER_BUFFER_INDEX    = 0x9301,
	GL_BUFFER_BINDING                 = 0x9302,
	GL_BUFFER_DATA_SIZE               = 0x9303,
	GL_NUM_ACTIVE_VARIABLES           = 0x9304,
	GL_ACTIVE_VARIABLES               = 0x9305,
	GL_REFERENCED_BY_VERTEX_SHADER    = 0x9306,
	GL_REFERENCED_BY_TESS_CONTROL_SHADER = 0x9307,
	GL_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x9308,
	GL_REFERENCED_BY_GEOMETRY_SHADER  = 0x9309,
	GL_REFERENCED_BY_FRAGMENT_SHADER  = 0x930A,
	GL_REFERENCED_BY_COMPUTE_SHADER   = 0x930B,
	GL_TOP_LEVEL_ARRAY_SIZE           = 0x930C,
	GL_TOP_LEVEL_ARRAY_STRIDE         = 0x930D,
	GL_LOCATION                       = 0x930E,
	GL_LOCATION_INDEX                 = 0x930F,
	GL_IS_PER_PATCH                   = 0x92E7,

	// ARB_shader_storage_buffer_object
	GL_SHADER_STORAGE_BUFFER          = 0x90D2,
	GL_SHADER_STORAGE_BUFFER_BINDING  = 0x90D3,
	GL_SHADER_STORAGE_BUFFER_START    = 0x90D4,
	GL_SHADER_STORAGE_BUFFER_SIZE     = 0x90D5,
	GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS = 0x90D6,
	GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS = 0x90D7,
	GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS = 0x90D8,
	GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS = 0x90D9,
	GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS = 0x90DA,
	GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = 0x90DB,
	GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS = 0x90DC,
	GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = 0x90DD,
	GL_MAX_SHADER_STORAGE_BLOCK_SIZE  = 0x90DE,
	GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT = 0x90DF,
	GL_SHADER_STORAGE_BARRIER_BIT     = 0x2000,
	GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES = 0x8F39,

	// ARB_stencil_texturing
	GL_DEPTH_STENCIL_TEXTURE_MODE = 0x90EA,

	// ARB_texture_buffer_range
	GL_TEXTURE_BUFFER_OFFSET = 0x919D,
	GL_TEXTURE_BUFFER_SIZE = 0x919E,
	GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT = 0x919F,

	// ARB_texture_view
	GL_TEXTURE_VIEW_MIN_LEVEL         = 0x82DB,
	GL_TEXTURE_VIEW_NUM_LEVELS        = 0x82DC,
	GL_TEXTURE_VIEW_MIN_LAYER         = 0x82DD,
	GL_TEXTURE_VIEW_NUM_LAYERS        = 0x82DE,
	GL_TEXTURE_IMMUTABLE_LEVELS       = 0x82DF,

	// ARB_vertex_attrib_binding
	GL_VERTEX_ATTRIB_BINDING          = 0x82D4,
	GL_VERTEX_ATTRIB_RELATIVE_OFFSET  = 0x82D5,
	GL_VERTEX_BINDING_DIVISOR         = 0x82D6,
	GL_VERTEX_BINDING_OFFSET          = 0x82D7,
	GL_VERTEX_BINDING_STRIDE          = 0x82D8,
	GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D9,
	GL_MAX_VERTEX_ATTRIB_BINDINGS     = 0x82DA,

	// ARB_buffer_storage
	GL_MAP_PERSISTENT_BIT             = 0x0040,
	GL_MAP_COHERENT_BIT               = 0x0080,
	GL_DYNAMIC_STORAGE_BIT            = 0x0100,
	GL_CLIENT_STORAGE_BIT             = 0x0200,
	GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT = 0x00004000,
	GL_BUFFER_IMMUTABLE_STORAGE       = 0x821F,
	GL_BUFFER_STORAGE_FLAGS           = 0x8220,

	// ARB_clear_texture
	GL_CLEAR_TEXTURE = 0x9365,

	// ARB_enhanced_layouts
	GL_LOCATION_COMPONENT             = 0x934A,
	GL_TRANSFORM_FEEDBACK_BUFFER_INDEX = 0x934B,
	GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE = 0x934C,

	// ARB_query_buffer_object
	GL_QUERY_BUFFER                   = 0x9192,
	GL_QUERY_BUFFER_BARRIER_BIT       = 0x00008000,
	GL_QUERY_BUFFER_BINDING           = 0x9193,
	GL_QUERY_RESULT_NO_WAIT           = 0x9194,

	// ARB_texture_mirror_clamp_to_edge
	GL_MIRROR_CLAMP_TO_EDGE           = 0x8743,

	// ARB_clip_control
	GL_NEGATIVE_ONE_TO_ONE            = 0x935E,
	GL_ZERO_TO_ONE                    = 0x935F,
	GL_CLIP_ORIGIN                    = 0x935C,
	GL_CLIP_DEPTH_MODE                = 0x935D,

	// ARB_cull_distance
	GL_MAX_CULL_DISTANCES             = 0x82F9,
	GL_MAX_COMBINED_CLIP_AND_CULL_DISTANCES = 0x82FA,

	// ARB_conditional_render_inverted
	GL_QUERY_WAIT_INVERTED            = 0x8E17,
	GL_QUERY_NO_WAIT_INVERTED         = 0x8E18,
	GL_QUERY_BY_REGION_WAIT_INVERTED  = 0x8E19,
	GL_QUERY_BY_REGION_NO_WAIT_INVERTED = 0x8E1A,

	// KHR_context_flush_control
	GL_CONTEXT_RELEASE_BEHAVIOR       = 0x82FB,
	GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH = 0x82FC,

	// KHR_robustness
	GL_GUILTY_CONTEXT_RESET           = 0x8253,
	GL_INNOCENT_CONTEXT_RESET         = 0x8254,
	GL_UNKNOWN_CONTEXT_RESET          = 0x8255,
	GL_CONTEXT_ROBUST_ACCESS          = 0x90F3,
	GL_RESET_NOTIFICATION_STRATEGY    = 0x8256,
	GL_LOSE_CONTEXT_ON_RESET          = 0x8252,
	GL_NO_RESET_NOTIFICATION          = 0x8261,
	GL_CONTEXT_LOST                   = 0x0507,

}

struct glnew
	{/*...}*/
		struct state
			{/*...}*/
				GLuint framebuffer;
			}
		auto opDispatch (string op, Args...)(Args args)
			out {/*...}*/
			}
			body {/*...}*/
				
			}

		class FrameBuffer
			{/*...}*/
				GLuint id;
				// TODO color, depth, stencil
				// TODO default framebuffer

				this ()
					{/*...}*/
						glGenFramebuffers (1, &id);
						// TODO error check
					}
				~this ()
					{/*...}*/
						glDeleteFramebuffers (1, &id);
					}
			}

		public {/*framebuffers}*/

			// https://www.opengl.org/wiki/Framebuffer
			// https://www.opengl.org/wiki/Default_Framebuffer

			private struct DefaultFramebuffer (GLenum target)
				{/*...}*/
					private GLuint bound;

					ref bind (GLuint buffer_id)
						{/*...}*/
							gl.BindFrameBuffer (target, buffer_id);

							bound = buffer_id;

							return this;
						}
					auto current ()
						{/*...}*/
							return bound;
						}

					alias opAssign = bind;
					alias current this;
				}

			alias draw_framebuffer = DefaultFramebuffer!GL_DRAW_FRAMEBUFFER;
			alias read_framebuffer = DefaultFramebuffer!GL_READ_FRAMEBUFFER;

			struct framebuffer
				{/*...}*/
					ref bind (GLuint buffer_id)
						{/*...}*/
							draw_framebuffer = buffer_id;
							read_framebuffer = buffer_id;

							return this;
						}
					auto current ()
						{/*...}*/
							if (draw_framebuffer == read_framebuffer)
								return draw_framebuffer;
							else assert (0);
						}

					alias opAssign = bind;
					alias current this;
				}
		}
	}

static if (0) {/*gl calls}*/
	public {/*MAIN BUFFERS}*/
		glClear // TODO
			clear buffers to preset values

		public {/*COLOR BUFFER}*/
			glClearColor // gl.color_buffer.clear_value = XXX;
				specify clear values for the color buffers

			glColorMask, glColorMaski // gl.color_buffer.write_mask = XXX;
				enable and disable writing of frame buffer color components
		}
		public {/*DEPTH BUFFER}*/
			glClearDepth // TODO
				specify the clear value for the depth buffer
			gl.depth_buffer.clear_value = XXX; // TODO

			glDepthMask // TODO
				enable or disable writing into the depth buffer
			gl.depth_buffer.write_mask = XXX; // TODO

			glDepthFunc // TODO
				specify the value used for depth buffer comparisons

			glPolygonOffset // TODO
				set the scale and units used to calculate depth values
			glDepthRange // TODO
				specify mapping of depth values from normalized device coordinates to window coordinates
			glDepthRangeArrayv  // TODO
				???
			glDepthRangeIndexed // TODO
				specify mapping of depth values from normalized device coordinates to window coordinates for a specified viewport
		}
		public {/*STENCIL BUFFER}*/
			glClearStencil // gl.stencil_buffer.clear_value = XXX;
				specify the clear value for the stencil buffer
			

			glStencilOpSeparate // TODO
				set front and/or back stencil test actions
			glStencilFuncSeparate // TODO
				set front and/or back function and reference value for stencil testing
			glStencilMaskSeparate // TODO
				control the front and/or back writing of individual bits in the stencil planes
			glStencilMask // TODO
				control the front and back writing of individual bits in the stencil planes
			glStencilFunc // TODO
				set front and back function and reference value for stencil testing
			glStencilOp // TODO
				set front and back stencil test actions
		}
	}

	public {/*BLENDING}*/
		glBlendColor // TODO
			set the blend color
		glBlendEquation // TODO
			specify the equation used for both the RGB blend equation and the Alpha blend equation
			GL_FUNC_ADD,
			GL_FUNC_SUBTRACT,
			GL_FUNC_REVERSE_SUBTRACT,
			GL_MIN,
			GL_MAX.
		glBlendEquationSeparate // TODO
			set the RGB blend equation and the alpha blend equation separately
		glBlendEquationi  // TODO
			like -i, but for a specific draw buffer
		glBlendEquationSeparatei  // TODO
			like -i, but for a specific draw buffer

		glBlendFunc // TODO
			specify pixel arithmetic
			GL_ZERO,
			GL_ONE,
			GL_SRC_COLOR,
			GL_ONE_MINUS_SRC_COLOR,
			GL_DST_COLOR,
			GL_ONE_MINUS_DST_COLOR,
			GL_SRC_ALPHA,
			GL_ONE_MINUS_SRC_ALPHA,
			GL_DST_ALPHA,
			GL_ONE_MINUS_DST_ALPHA,
			GL_CONSTANT_COLOR,
			GL_ONE_MINUS_CONSTANT_COLOR,
			GL_CONSTANT_ALPHA,
			GL_ONE_MINUS_CONSTANT_ALPHA,
			GL_SRC_ALPHA_SATURATE,
			GL_SRC1_COLOR,
			GL_ONE_MINUS_SRC1_COLOR,
			GL_SRC1_ALPHA,
			GL_ONE_MINUS_SRC1_ALPHA.
		glBlendFuncSeparate // TODO
			specify pixel arithmetic for RGB and alpha components separately
		glBlendFunci  // TODO
			like -i, but for a specific draw buffer
		glBlendFuncSeparatei  // TODO
			like -i, but for a specific draw buffer
	}

	public {/*GENERAL}*/
		glEnablei  // TODO
			???
		glDisablei  // TODO
			???
		glIsEnabledi  // TODO
			???
		glDisable  // TODO
			???
		glEnable // TODO
			enable or disable server-side GL capabilities
		glIsEnabled, glIsEnabledi // TODO
			test whether a capability is enabled
	}
	public {/*MISC}*/
		glLineWidth // TODO
			specify the width of rasterized lines
		glPointSize // TODO
			specify the diameter of rasterized points
		glPolygonMode // TODO
			select a polygon rasterization mode
		glLogicOp // TODO
			specify a logical pixel operation for rendering
	}
	public {/*CONDITIONAL RENDERING}*/
		glBeginConditionalRender // TODO
			start conditional rendering
		glEndConditionalRender  // TODO
			???
	}
	public {/*BUFFER ↔ TEXTURE}*/
		public {/*ATTACHMENT}*/
			glTexBuffer, glTextureBuffer // TODO
				attach a buffer object's data store to a buffer texture object
		}
	}
	public {/*DRAWING}*/
		public {/*COMMANDS}*/
			glMultiDrawArraysIndirect // TODO
				render multiple sets of primitives from array data, taking parameters from memory
			glMultiDrawElementsIndirect // TODO
				render indexed primitives from array data, taking parameters from memory
			glDrawArraysInstancedBaseInstance // TODO
				draw multiple instances of a range of elements with offset applied to instanced attributes
			glDrawElementsInstancedBaseInstance // TODO
				draw multiple instances of a set of elements with offset applied to instanced attributes
			glDrawElementsInstancedBaseVertexBaseInstance // TODO
				render multiple instances of a set of primitives from array data with a per-element offset
			glDrawTransformFeedbackInstanced // TODO
				render multiple instances of primitives using a count derived from a transform feedback object
			glDrawTransformFeedbackStreamInstanced // TODO
				render multiple instances of primitives using a count derived from a specifed stream of a transform feedback object
			glDrawElementsBaseVertex // TODO
				render primitives from array data with a per-element offset
			glDrawRangeElementsBaseVertex // TODO
				render primitives from array data with a per-element offset
			glDrawElementsInstancedBaseVertex // TODO
				render multiple instances of a set of primitives from array data with a per-element offset
			glMultiDrawElementsBaseVertex // TODO
				render multiple sets of primitives by specifying indices of array data elements and an index to apply to each index
			glDrawRangeElements // TODO
				render primitives from array data
			glMultiDrawArrays // TODO
				render multiple sets of primitives from array data
			glMultiDrawElements // TODO
				render multiple sets of primitives by specifying indices of array data elements
			glDrawArraysInstanced // TODO
				draw multiple instances of a range of elements
			glDrawElementsInstanced // TODO
				draw multiple instances of a set of elements
			glDrawArrays // TODO
				render primitives from array data
			glDrawElements // TODO
				render primitives from array data
			glDrawArraysIndirect // TODO
				render primitives from array data, taking parameters from memory
			glDrawElementsIndirect // TODO
				render indexed primitives from array data, taking parameters from memory
		}
		public {/*TARGET}*/
			glDrawBuffers, glNamedFramebufferDrawBuffers // TODO
				Specifies a list of color buffers to be drawn into
		}
		public {/*MISC}*/
			glPrimitiveRestartIndex // TODO
				specify the primitive restart index
			glVertexAttribDivisor // TODO
				modify the rate at which generic vertex attributes advance during instanced rendering
		}
	}
	public {/*UNKNOWN SUBROUTINE}*/
		glGetSubroutineUniformLocation // TODO
			retrieve the location of a subroutine uniform of a given shader stage within a program
		glGetSubroutineIndex // TODO
			retrieve the index of a subroutine uniform of a given shader stage within a program
		glGetActiveSubroutineUniformiv  // TODO
			???
		glGetActiveSubroutineUniformName // TODO
			query the name of an active shader subroutine uniform
		glGetActiveSubroutineName // TODO
			query the name of an active shader subroutine
		glUniformSubroutinesuiv  // TODO
			???
		glGetUniformSubroutineuiv  // TODO
			???
		glGetProgramStageiv  // TODO
			???
	}
	public {/*UNKNOWN P}*/
		glVertexP2ui  // TODO
			???
		glVertexP2uiv  // TODO
			???
		glVertexP3ui  // TODO
			???
		glVertexP3uiv  // TODO
			???
		glVertexP4ui  // TODO
			???
		glVertexP4uiv  // TODO
			???
		glTexCoordP1ui  // TODO
			???
		glTexCoordP1uiv  // TODO
			???
		glTexCoordP2ui  // TODO
			???
		glTexCoordP2uiv  // TODO
			???
		glTexCoordP3ui  // TODO
			???
		glTexCoordP3uiv  // TODO
			???
		glTexCoordP4ui  // TODO
			???
		glTexCoordP4uiv  // TODO
			???
		glMultiTexCoordP1ui  // TODO
			???
		glMultiTexCoordP1uiv  // TODO
			???
		glMultiTexCoordP2ui  // TODO
			???
		glMultiTexCoordP2uiv  // TODO
			???
		glMultiTexCoordP3ui  // TODO
			???
		glMultiTexCoordP3uiv  // TODO
			???
		glMultiTexCoordP4ui  // TODO
			???
		glMultiTexCoordP4uiv  // TODO
			???
		glNormalP3ui  // TODO
			???
		glNormalP3uiv  // TODO
			???
		glColorP3ui  // TODO
			???
		glColorP3uiv  // TODO
			???
		glColorP4ui  // TODO
			???
		glColorP4uiv  // TODO
			???
		glSecondaryColorP3ui  // TODO
			???
		glSecondaryColorP3uiv  // TODO
			???
		glVertexAttribP1ui  // TODO
			???
		glVertexAttribP1uiv  // TODO
			???
		glVertexAttribP2ui  // TODO
			???
		glVertexAttribP2uiv  // TODO
			???
		glVertexAttribP3ui  // TODO
			???
		glVertexAttribP3uiv  // TODO
			???
		glVertexAttribP4ui  // TODO
			???
		glVertexAttribP4uiv  // TODO
			???
	}
	public {/*UNKNOWN NAMED STRING}*/
		glNamedString  // TODO
			???
		glDeleteNamedString  // TODO
			???
		glCompileShaderInclude  // TODO
			???
		glIsNamedString  // TODO
			???
		glGetNamedString  // TODO
			???
		glGetNamedStringiv  // TODO
			???
	}
	public {/*SHADER VARIABLES}*/
		public {/*OUTPUT}*/
			glBindFragDataLocation // TODO
				bind a user-defined varying out variable to a fragment shader color number
			glGetFragDataLocation // TODO
				query the bindings of color numbers to user-defined varying out variables
			glBindFragDataLocationIndexed // TODO
				bind a user-defined varying out variable to a fragment shader color number and index
			glGetFragDataIndex // TODO
				query the bindings of color indices to user-defined varying out variables
		}
	}
	public {/*VIEWPORT}*/
		glViewport // TODO
			set the viewport
		glViewportArrayv  // TODO
			???
		glViewportIndexedf  // TODO
			???
		glViewportIndexedfv  // TODO
			???
	}
	public {/*SCISSOR}*/
		glScissor // TODO
			define the scissor box
		glScissorArrayv  // TODO
			???
		glScissorIndexed // TODO
			define the scissor box for a specific viewport
		glScissorIndexedv  // TODO
			???
	}
	public {/*UNKNOWN}*/
		glShaderStorageBlockBinding // TODO
			change an active shader storage block binding
		glGetInternalformati64v  // TODO
			???
		glGetInternalformativ  // TODO
			???
		glGetnMapdv  // TODO
			???
		glGetnMapfv  // TODO
			???
		glGetnMapiv  // TODO
			???
		glGetnPixelMapfv  // TODO
			???
		glGetnPixelMapuiv  // TODO
			???
		glGetnPixelMapusv  // TODO
			???
		glGetnPolygonStipple  // TODO
			???
		glGetnColorTable  // TODO
			???
		glGetnConvolutionFilter  // TODO
			???
		glGetnSeparableFilter  // TODO
			???
		glGetnHistogram  // TODO
			???
		glGetnMinmax  // TODO
			???
		glGetnTexImage  // TODO
			???
		glReadnPixels  // TODO
			???
		glGetnCompressedTexImage  // TODO
			???
		glGetnUniformfv  // TODO
			???
		glGetnUniformiv  // TODO
			???
		glGetnUniformuiv  // TODO
			???
		glGetnUniformdv  // TODO
			???
		glGetFloati_v  // TODO
			???
		glGetDoublei_v  // TODO
			???
		glDepthRangef  // TODO
			???
		glClearDepthf  // TODO
			???
		glProvokingVertex // TODO
			specifiy the vertex to be used as the source of data for flat shaded varyings
		glGetMultisamplefv  // TODO
			???
		glGetFloatv  // TODO
			???
		glGetIntegerv  // TODO
			???
		glGetString // TODO
			return a string describing the current GL connection
		glPixelStoref  // TODO
			???
		glPixelStorei  // TODO
			???
		glGetBufferParameteriv  // TODO
			???
		glColorMaski  // TODO
			???
		glGetBooleani_v  // TODO
			???
		glGetIntegeri_v  // TODO
			???
		glGetStringi  // TODO
			???
		glGetInteger64i_v  // TODO
			???
		glGetBufferParameteri64v  // TODO
			???
		glGetnTexImage  // TODO
			???
		glHint // TODO
			specify implementation-specific hints
		glGetBooleanv  // TODO
			???
		glGetDoublev  // TODO
			???
		glGetInteger64v  // TODO
			???
	}
	public {/*COMPUTE}*/
		glDispatchCompute // TODO
			launch one or more compute work groups
		glDispatchComputeIndirect // TODO
			launch one or more compute work groups using parameters stored in a buffer
	}
	public {/*ERROR}*/
		glGetGraphicsResetStatus // TODO
			check if the rendering context has not been lost due to software or hardware issues
		glGetError // TODO
			return error information
		glDebugMessageControl // TODO
			control the reporting of debug messages in a debug context
		glDebugMessageInsert // TODO
			inject an application-supplied message into the debug message queue
		glDebugMessageCallback // TODO
			specify a callback to receive debugging messages from the GL
		glGetDebugMessageLog // TODO
			retrieve messages from the debug message log
		glGetGraphicsResetStatus // TODO
			check if the rendering context has not been lost due to software or hardware issues
		glDebugMessageControl // TODO
			control the reporting of debug messages in a debug context
		glDebugMessageInsert // TODO
			inject an application-supplied message into the debug message queue
		glDebugMessageCallback // TODO
			specify a callback to receive debugging messages from the GL
		glGetDebugMessageLog // TODO
			retrieve messages from the debug message log
		glPushDebugGroup // TODO
			push a named debug group into the command stream
		glPopDebugGroup // TODO
			pop the active debug group
	}
	public {/*OBJECT???}*/
		glObjectLabel // TODO
			label a named object identified within a namespace
		glGetObjectLabel // TODO
			retrieve the label of a named object identified within a namespace
		glObjectPtrLabel // TODO
			label a a sync object identified by a pointer
		glGetObjectPtrLabel // TODO
			retrieve the label of a sync object identified by a pointer
	}
	public {/*INVALIDATE}*/
		glInvalidateTexSubImage // TODO
			invalidate a region of a texture image
		glInvalidateTexImage // TODO
			invalidate the entirety a texture image
		glInvalidateBufferSubData // TODO
			invalidate a region of a buffer object's data store
		glInvalidateBufferData // TODO
			invalidate the content of a buffer object's data store
		glInvalidateFramebuffer, glInvalidateNamedFramebufferData // TODO
			invalidate the content of some or all of a framebuffer's attachments
		glInvalidateSubFramebuffer, glInvalidateNamedFramebufferSubData // TODO
			invalidate the content of a region of some or all of a framebuffer's attachments
	}
	public {/*ATTRIBUTES}*/
		glVertexAttribFormat, glVertexArrayAttribFormat // TODO
			specify the organization of vertex arrays
		glVertexAttribIFormat  // TODO
			???
		glVertexAttribLFormat  // TODO
			???
		glVertexAttribBinding // TODO
			associate a vertex attribute and a vertex buffer binding for a vertex array object
		glVertexBindingDivisor, glVertexArrayBindingDivisor // TODO
			modify the rate at which generic vertex attributes
			advance
		glVertexArrayBindVertexBuffer  // TODO
			???
		glVertexArrayVertexAttribFormat  // TODO
			???
		glVertexArrayVertexAttribIFormat  // TODO
			???
		glVertexArrayVertexAttribLFormat  // TODO
			???
		glVertexArrayVertexAttribBinding  // TODO
			???
		glVertexArrayVertexBindingDivisor  // TODO
			???
		glVertexAttribL1d  // TODO
			???
		glVertexAttribL2d  // TODO
			???
		glVertexAttribL3d  // TODO
			???
		glVertexAttribL4d  // TODO
			???
		glVertexAttribL1dv  // TODO
			???
		glVertexAttribL2dv  // TODO
			???
		glVertexAttribL3dv  // TODO
			???
		glVertexAttribL4dv  // TODO
			???
		glVertexAttribLPointer  // TODO
			???
		glGetVertexAttribLdv  // TODO
			???
		glBindAttribLocation // TODO
			Associates a generic vertex attribute index with a named attribute variable
		glDisableVertexAttribArray  // TODO
			???
		glEnableVertexAttribArray // TODO
			Enable or disable a generic vertex attribute array
		glGetActiveAttrib // TODO
			Returns information about an active attribute variable for the specified program object
		glGetAttribLocation // TODO
			Returns the location of an attribute variable
		glGetVertexAttribdv  // TODO
			???
		glGetVertexAttribfv  // TODO
			???
		glGetVertexAttribiv  // TODO
			???
		glGetVertexAttribPointerv // TODO
			return the address of the specified generic vertex attribute pointer
		glVertexAttribIPointer  // TODO
			???
		glGetVertexAttribIiv  // TODO
			???
		glGetVertexAttribIuiv  // TODO
			???
		glVertexAttribI1i  // TODO
			???
		glVertexAttribI2i  // TODO
			???
		glVertexAttribI3i  // TODO
			???
		glVertexAttribI4i  // TODO
			???
		glVertexAttribI1ui  // TODO
			???
		glVertexAttribI2ui  // TODO
			???
		glVertexAttribI3ui  // TODO
			???
		glVertexAttribI4ui  // TODO
			???
		glVertexAttribI1iv  // TODO
			???
		glVertexAttribI2iv  // TODO
			???
		glVertexAttribI3iv  // TODO
			???
		glVertexAttribI4iv  // TODO
			???
		glVertexAttribI1uiv  // TODO
			???
		glVertexAttribI2uiv  // TODO
			???
		glVertexAttribI3uiv  // TODO
			???
		glVertexAttribI4uiv  // TODO
			???
		glVertexAttribI4bv  // TODO
			???
		glVertexAttribI4sv  // TODO
			???
		glVertexAttribI4ubv  // TODO
			???
		glVertexAttribI4usv  // TODO
			???
	}
	public {/*CULLING}*/
		glCullFace // TODO
			specify whether front- or back-facing facets can be culled
		glFrontFace // TODO
			define front- and back-facing polygons
		glClipControl // TODO
			control clip coordinate to window coordinate behavior
	}
	public {/*SYNCHRONIZATION}*/
		glTextureBarrier // TODO
			controls the ordering of reads and writes to rendered fragments across drawing commands
		glMemoryBarrierByRegion  // TODO
			???
		glMemoryBarrier // TODO
			defines a barrier ordering memory transactions
		glGetActiveAtomicCounterBufferiv // TODO
			retrieve information about the set of active atomic counter buffers for a program
		glCreateSyncFromCLevent  // TODO
			???
		glFinish // TODO
			block until all GL execution is complete
		glFlush // TODO
			force execution of GL commands in finite time
		glFenceSync // TODO
			create a new sync object and insert it into the GL command stream
		glIsSync // TODO
			determine if a name corresponds to a sync object
		glDeleteSync // TODO
			delete a sync object
		glClientWaitSync // TODO
			block and wait for a sync object to become signaled
		glWaitSync // TODO
			instruct the GL server to block until the specified sync object becomes signaled
		glGetSynciv  // TODO
			???
	}
	public {/*TRANSFORM FEEDBACK}*/
		glBeginTransformFeedback // TODO
			start transform feedback operation
		glEndTransformFeedback  // TODO
			???
		glTransformFeedbackVaryings // TODO
			specify values to record in transform feedback buffers
		glGetTransformFeedbackVarying // TODO
			retrieve information about varying variables selected for transform feedback
		glDrawTransformFeedbackStream // TODO
			render primitives using a count derived from a specifed stream of a transform feedback object
		glBindTransformFeedback // TODO
			bind a transform feedback object
		glDeleteTransformFeedbacks // TODO
			delete transform feedback objects
		glGenTransformFeedbacks // TODO
			reserve transform feedback object names
		glIsTransformFeedback // TODO
			determine if a name corresponds to a transform feedback object
		glPauseTransformFeedback // TODO
			pause transform feedback operations
		glResumeTransformFeedback // TODO
			resume transform feedback operations
		glDrawTransformFeedback // TODO
			render primitives using a count derived from a transform feedback object
		glCreateTransformFeedbacks // TODO
			create transform feedback objects
		glTransformFeedbackBufferBase // TODO
			bind a buffer object to a transform feedback buffer object
		glTransformFeedbackBufferRange // TODO
			bind a range within a buffer object to a transform feedback buffer object
		glGetTransformFeedbackiv  // TODO
			???
		glGetTransformFeedbacki_v  // TODO
			???
		glGetTransformFeedbacki64_v  // TODO
			???
	}
	public {/*BUFFER}*/
		public {/*CLEAR}*/
			glClearBufferData, glClearNamedBufferData // TODO
				fill a buffer object's data store with a fixed value
			glClearBufferSubData, glClearNamedBufferSubData // TODO
				fill all or part of buffer object's data store with a fixed value
			glClearNamedBufferData  // TODO
				???
			glClearNamedBufferSubData  // TODO
				???
		}
		public {/*STORAGE}*/
			glBufferStorage, glNamedBufferStorage // TODO
				creates and initializes a buffer object's immutable data
				store
			glNamedBufferStorage  // TODO
				???
			glNamedBufferStorage  // TODO
				???
		}
		public {/*BUFFER STATE CONTROL}*/
			glFlushMappedNamedBufferRange  // TODO
				???
			glCreateBuffers // TODO
				create buffer objects
			glBindBuffer // TODO
				bind a named buffer object
			glDeleteBuffers // TODO
				delete named buffer objects
			glGenBuffers // TODO
				generate buffer object names
			glIsBuffer // TODO
				determine if a name corresponds to a buffer object
			glBindBufferRange // TODO
				bind a range within a buffer object to an indexed buffer target
			glBindBufferBase // TODO
				bind a buffer object to an indexed buffer target
			glFlushMappedBufferRange, glFlushMappedNamedBufferRange // TODO
				indicate modifications to a range of a mapped buffer
			glBindBuffersBase // TODO
				bind one or more buffer objects to a sequence of indexed buffer targets
			glBindBuffersRange // TODO
				bind ranges of one or more buffer objects to a sequence of indexed buffer targets
		}
		public {/*MISC}*/
			glGetNamedBufferParameteriv  // TODO
				???
			glGetNamedBufferParameteri64v  // TODO
				???
			glGetNamedBufferPointerv  // TODO
				???
		}
		public {/*BUFFER TRANSFER}*/
			public {/*G ↔ C}*/
				glMapBuffer, glMapNamedBuffer // TODO
					map all of a buffer object's data store into the client's address space
				glUnmapBuffer, glUnmapNamedBuffer // TODO
					release the mapping of a buffer object's data store into the client's address space
				glMapBufferRange, glMapNamedBufferRange // TODO
					map all or part of a buffer object's data store into the client's address space
			}
			public {/*G → G}*/
				glCopyBufferSubData, glCopyNamedBufferSubData // TODO
					copy all or part of the data store of a buffer object to the data store of another buffer object
			}
			public {/*C → G}*/
				glBufferData, glNamedBufferData // TODO
					creates and initializes a buffer object's data
					store
				glBufferSubData, glNamedBufferSubData // TODO
					updates a subset of a buffer object's data store
				glNamedBufferData  // TODO
					???
				glNamedBufferSubData  // TODO
					???
				glCopyNamedBufferSubData  // TODO
					???
				glClearNamedBufferData  // TODO
					???
				glClearNamedBufferSubData  // TODO
					???
				glMapNamedBuffer  // TODO
					???
				glMapNamedBufferRange  // TODO
					???
				glUnmapNamedBuffer  // TODO
					???
			}
			public {/*G → C}*/
				glGetBufferSubData, glGetNamedBufferSubData // TODO
					returns a subset of a buffer object's data store
				glGetBufferPointerv, glGetNamedBufferPointerv // TODO
					return the pointer to a mapped buffer object's data store
				glGetNamedBufferSubData  // TODO
					???
			}
		}
	}
	public {/*FRAMEBUFFER}*/
		public {/*DEFAULT FBO OPS}*/
			glDrawBuffer, glNamedFramebufferDrawBuffer // TODO
				specify which color buffers are to be drawn into
		}
		public {/*READING}*/
			glClampColor // TODO
				specify whether data read via glReadPixels should be clamped // TODO
			glReadBuffer, glNamedFramebufferReadBuffer // TODO
				select a color buffer source for pixels
			glReadPixels, glReadnPixels // TODO
				read a block of pixels from the frame buffer
		}
		public {/*STORAGE}*/
			glRenderbufferStorageMultisample, glNamedRenderbufferStorageMultisample // TODO
				establish data storage, format, dimensions and sample count of
				a renderbuffer object's image
		}
		public {/*ATTACHMENT}*/
			glFramebufferTexture // TODO
				attach a level of a texture object as a logical buffer of a framebuffer object
			glFramebufferTexture1D  // TODO
				???
			glFramebufferTexture2D  // TODO
				???
			glFramebufferTexture3D  // TODO
				???
			glFramebufferRenderbuffer, glNamedFramebufferRenderbuffer // TODO
				attach a renderbuffer as a logical buffer of a framebuffer object
			glFramebufferTextureLayer, glNamedFramebufferTextureLayer // TODO
				attach a single layer of a texture object as a logical buffer of a framebuffer object // TODO
			glNamedFramebufferRenderbuffer  // TODO
				???
			glNamedFramebufferParameteri  // TODO
				???
			glNamedFramebufferTexture  // TODO
				???
			glNamedFramebufferTextureLayer  // TODO
				???
			glNamedFramebufferDrawBuffer  // TODO
				???
			glNamedFramebufferDrawBuffers  // TODO
				???
			glNamedFramebufferReadBuffer  // TODO
				???
		}
		public {/*INVALIDATE}*/
			glInvalidateNamedFramebufferData  // TODO
				???
			glInvalidateNamedFramebufferSubData  // TODO
				???
		}
		public {/*TRANSFER}*/
			glReadnPixels  // TODO
				???
			glBlitFramebuffer, glBlitNamedFramebuffer // TODO
				copy a block of pixels from one framebuffer object to another
			glBlitNamedFramebuffer  // TODO
				???
		}
		public {/*QUERY}*/
			glIsFramebuffer // TODO
				determine if a name corresponds to a framebuffer object
			glCheckFramebufferStatus, glCheckNamedFramebufferStatus // TODO
				check the completeness status of a framebuffer
			glGetFramebufferAttachmentParameteriv  // TODO
				???
			glCheckNamedFramebufferStatus  // TODO
				???
		}
		public {/*PARAMETERS}*/
			glFramebufferParameteri, glNamedFramebufferParameteri // TODO
				set a named parameter of a framebuffer object
			glGetFramebufferParameteriv  // TODO
				???
			glNamedFramebufferParameteri  // TODO
				???
			glGetNamedFramebufferParameteriv  // TODO
				???
			glClearNamedFramebufferiv  // TODO
				???
			glClearNamedFramebufferuiv  // TODO
				???
			glClearNamedFramebufferfv  // TODO
				???
			glClearNamedFramebufferfi  // TODO
				???
			glGetNamedFramebufferParameteriv  // TODO
				???
			glGetNamedFramebufferAttachmentParameteriv  // TODO
				???
		}
		public {/*BINDING}*/
			glBindFramebuffer // TODO
				bind a framebuffer to a framebuffer target
			glDeleteFramebuffers // TODO
				delete framebuffer objects
			glGenFramebuffers // TODO
				generate framebuffer object names
			glCreateFramebuffers // TODO
				create framebuffer objects
		}
	}
	public {/*PATCH}*/
		glPatchParameteri  // TODO
			???
		glPatchParameterfv  // TODO
			???
	}
	public {/*RENDERBUFFER}*/
		glIsRenderbuffer // TODO
			determine if a name corresponds to a renderbuffer object
		glBindRenderbuffer // TODO
			bind a renderbuffer to a renderbuffer target
		glDeleteRenderbuffers // TODO
			delete renderbuffer objects
		glGenRenderbuffers // TODO
			generate renderbuffer object names
		glRenderbufferStorage, glNamedRenderbufferStorage // TODO
			establish data storage, format and dimensions of a
			renderbuffer object's image
		glGetRenderbufferParameteriv  // TODO
			???
		glCreateRenderbuffers // TODO
			create renderbuffer objects
		glNamedRenderbufferStorage  // TODO
			???
		glNamedRenderbufferStorageMultisample  // TODO
			???
		glGetNamedRenderbufferParameteriv  // TODO
			???
	}
	public {/*VERTEX ARRAY}*/
		glBindVertexBuffers, glVertexArrayVertexBuffers // TODO
			attach multiple buffer objects to a vertex array object
		glBindVertexArray // TODO
			bind a vertex array object
		glDeleteVertexArrays // TODO
			delete vertex array objects
		glGenVertexArrays // TODO
			generate vertex array object names
		glIsVertexArray // TODO
			determine if a name corresponds to a vertex array object
		glBindVertexBuffer, glVertexArrayVertexBuffer // TODO
			bind a buffer to a vertex buffer bind point
		glCreateVertexArrays // TODO
			create vertex array objects
		glDisableVertexArrayAttrib  // TODO
			???
		glEnableVertexArrayAttrib  // TODO
			???
		glVertexArrayElementBuffer // TODO
			configures element array buffer binding of a vertex array object
		glVertexArrayVertexBuffer  // TODO
			???
		glVertexArrayVertexBuffers  // TODO
			???
		glVertexArrayAttribBinding  // TODO
			???
		glVertexArrayAttribFormat  // TODO
			???
		glVertexArrayAttribIFormat  // TODO
			???
		glVertexArrayAttribLFormat  // TODO
			???
		glVertexArrayBindingDivisor  // TODO
			???
		glGetVertexArrayiv // TODO
			retrieve parameters of a vertex array object
		glGetVertexArrayIndexediv  // TODO
			???
		glGetVertexArrayIndexed64iv  // TODO
			???
	}
	public {/*SAMPLING}*/
		glBindSamplers // TODO
			bind one or more named sampler objects to a sequence of consecutive sampler units
		glSampleCoverage // TODO
			specify multisample coverage parameters
		glPointParameterf  // TODO
			???
		glPointParameterfv  // TODO
			???
		glPointParameteri  // TODO
			???
		glPointParameteriv  // TODO
			???
		glMinSampleShading // TODO
			specifies minimum rate at which sample shading takes place
		glGenSamplers // TODO
			generate sampler object names
		glDeleteSamplers // TODO
			delete named sampler objects
		glIsSampler // TODO
			determine if a name corresponds to a sampler object
		glBindSampler // TODO
			bind a named sampler to a texturing target
		glSamplerParameteri  // TODO
			???
		glSamplerParameteriv  // TODO
			???
		glSamplerParameterf  // TODO
			???
		glSamplerParameterfv  // TODO
			???
		glSamplerParameterIiv  // TODO
			???
		glSamplerParameterIuiv  // TODO
			???
		glGetSamplerParameteriv  // TODO
			???
		glGetSamplerParameterIiv  // TODO
			???
		glGetSamplerParameterfv  // TODO
			???
		glGetSamplerParameterIuiv  // TODO
			???
		glSampleMaski // TODO
			set the value of a sub-word of the sample mask
		glCreateSamplers // TODO
			create sampler objects
	}
	public {/*PROGRAM}*/
		glCreateProgramPipelines // TODO
			create program pipeline objects
		public {/*RESOURCE}*/
			glGetProgramResourceIndex // TODO
				query the index of a named resource within a program
			glGetProgramResourceName // TODO
				query the name of an indexed resource within a program
			glGetProgramResourceiv  // TODO
				???
			glGetProgramResourceLocation // TODO
				query the location of a named resource within a program
			glGetProgramResourceLocationIndex // TODO
				query the fragment color index of a named variable within a program
		}
		glGetProgramInterfaceiv  // TODO
			???
		glGetProgramBinary // TODO
			return a binary representation of a program object's compiled and linked executable source
		glProgramBinary // TODO
			load a program object with a program binary
		glProgramParameteri  // TODO
			???
		glUseProgramStages // TODO
			bind stages of a program object to a program pipeline
		glActiveShaderProgram // TODO
			set the active program object for a program pipeline object
		glCreateShaderProgramv  // TODO
			???
		glBindProgramPipeline // TODO
			bind a program pipeline to the current context
		glDeleteProgramPipelines // TODO
			delete program pipeline objects
		glGenProgramPipelines // TODO
			reserve program pipeline object names
		glIsProgramPipeline // TODO
			determine if a name corresponds to a program pipeline object
		glGetProgramPipelineiv  // TODO
			???
		glProgramUniform1i  // TODO
			???
		glProgramUniform1iv  // TODO
			???
		glProgramUniform1f  // TODO
			???
		glProgramUniform1fv  // TODO
			???
		glProgramUniform1d  // TODO
			???
		glProgramUniform1dv  // TODO
			???
		glProgramUniform1ui  // TODO
			???
		glProgramUniform1uiv  // TODO
			???
		glProgramUniform2i  // TODO
			???
		glProgramUniform2iv  // TODO
			???
		glProgramUniform2f  // TODO
			???
		glProgramUniform2fv  // TODO
			???
		glProgramUniform2d  // TODO
			???
		glProgramUniform2dv  // TODO
			???
		glProgramUniform2ui  // TODO
			???
		glProgramUniform2uiv  // TODO
			???
		glProgramUniform3i  // TODO
			???
		glProgramUniform3iv  // TODO
			???
		glProgramUniform3f  // TODO
			???
		glProgramUniform3fv  // TODO
			???
		glProgramUniform3d  // TODO
			???
		glProgramUniform3dv  // TODO
			???
		glProgramUniform3ui  // TODO
			???
		glProgramUniform3uiv  // TODO
			???
		glProgramUniform4i  // TODO
			???
		glProgramUniform4iv  // TODO
			???
		glProgramUniform4f  // TODO
			???
		glProgramUniform4fv  // TODO
			???
		glProgramUniform4d  // TODO
			???
		glProgramUniform4dv  // TODO
			???
		glProgramUniform4ui  // TODO
			???
		glProgramUniform4uiv  // TODO
			???
		glProgramUniformMatrix2fv  // TODO
			???
		glProgramUniformMatrix3fv  // TODO
			???
		glProgramUniformMatrix4fv  // TODO
			???
		glProgramUniformMatrix2dv  // TODO
			???
		glProgramUniformMatrix3dv  // TODO
			???
		glProgramUniformMatrix4dv  // TODO
			???
		glProgramUniformMatrix2x3fv  // TODO
			???
		glProgramUniformMatrix3x2fv  // TODO
			???
		glProgramUniformMatrix2x4fv  // TODO
			???
		glProgramUniformMatrix4x2fv  // TODO
			???
		glProgramUniformMatrix3x4fv  // TODO
			???
		glProgramUniformMatrix4x3fv  // TODO
			???
		glProgramUniformMatrix2x3dv  // TODO
			???
		glProgramUniformMatrix3x2dv  // TODO
			???
		glProgramUniformMatrix2x4dv  // TODO
			???
		glProgramUniformMatrix4x2dv  // TODO
			???
		glProgramUniformMatrix3x4dv  // TODO
			???
		glProgramUniformMatrix4x3dv  // TODO
			???
		glValidateProgramPipeline // TODO
			validate a program pipeline object against current GL state
		glGetProgramPipelineInfoLog // TODO
			retrieve the info log string from a program pipeline object
		glReleaseShaderCompiler // TODO
			release resources consumed by the implementation's shader compiler
		glShaderBinary // TODO
			load pre-compiled shader binaries
		glGetShaderPrecisionFormat // TODO
			retrieve the range and precision for numeric formats supported by the shader compiler
		glCreateProgram // TODO
			Creates a program object
		glCreateShader // TODO
			Creates a shader object
		glDeleteProgram // TODO
			Deletes a program object
		glDeleteShader // TODO
			Deletes a shader object
		// COMPILATION
		glCompileShader // TODO
			Compiles a shader object
		glGetProgramiv  // TODO
			???
		glGetProgramInfoLog // TODO
			Returns the information log for a program object
		glValidateProgram // TODO
			Validates a program object
		glGetShaderiv  // TODO
			???
		glGetShaderInfoLog // TODO
			Returns the information log for a shader object
		glGetShaderSource // TODO
			Returns the source code string from a shader object
		glIsProgram // TODO
			Determines if a name corresponds to a program object
		glIsShader // TODO
			Determines if a name corresponds to a shader object
		glLinkProgram // TODO
			Links a program object
		glShaderSource // TODO
			Replaces the source code in a shader object
		glUseProgram // TODO
			Installs a program object as part of current rendering state
		// ATTACHMENT
		glAttachShader // TODO
			Attaches a shader object to a program object
		glDetachShader // TODO
			Detaches a shader object from a program object to which it is attached
		glGetAttachedShaders // TODO
			Returns the handles of the shader objects attached to a program object
	}
	public {/*QUERY}*/
		glCreateQueries // TODO
			create query objects
		glGetQueryBufferObjecti64v  // TODO
			???
		glGetQueryBufferObjectiv  // TODO
			???
		glGetQueryBufferObjectui64v  // TODO
			???
		glGetQueryBufferObjectuiv  // TODO
			???
		glGenQueries // TODO
			generate query object names
		glDeleteQueries // TODO
			delete named query objects
		glIsQuery // TODO
			determine if a name corresponds to a query object
		glBeginQuery // TODO
			delimit the boundaries of a query object
		glEndQuery  // TODO
			???
		glGetQueryiv // TODO
			return parameters of a query object target
		glGetQueryObjectiv  // TODO
			???
		glGetQueryObjectuiv  // TODO
			???
		glBeginQueryIndexed, glEndQueryIndexed // TODO
			delimit the boundaries of a query object on an indexed target
		glEndQueryIndexed  // TODO
			???
		glGetQueryIndexediv  // TODO
			???
		glQueryCounter // TODO
			record the GL time into a query object after all previous commands have reached the GL server but have not yet necessarily executed.
		glGetQueryObjecti64v  // TODO
			???
		glGetQueryObjectui64v  // TODO
			???
	}
	public {/*TEXTURE}*/
		public {/*TRANSFER}*/
			glCopyImageSubData // TODO
				perform a raw data copy between two images

			public {/*C → G}*/
				glTexImage3D // TODO
					specify a three-dimensional texture image
				glTexSubImage3D, glTextureSubImage3D // TODO
					specify a three-dimensional texture subimage
				glCopyTexSubImage3D, glCopyTextureSubImage3D // TODO
					copy a three-dimensional texture subimage
				glTexImage1D // TODO
					specify a one-dimensional texture image
				glTexImage2D // TODO
					specify a two-dimensional texture image
				glTexSubImage1D, glTextureSubImage1D // TODO
					specify a one-dimensional texture subimage
				glTexSubImage2D, glTextureSubImage2D // TODO
					specify a two-dimensional texture subimage
				glTextureSubImage1D  // TODO
					???
				glTextureSubImage2D  // TODO
					???
				glTextureSubImage3D  // TODO
					???
			}
			public {/*MULTISAMP}*/
				glTexImage2DMultisample // TODO
					establish the data storage, format, dimensions, and number of samples of a multisample texture's image
				glTexImage3DMultisample // TODO
					establish the data storage, format, dimensions, and number of samples of a multisample texture's image
			}
			public {/*G → C COMPRESSED}*/
				glGetCompressedTexImage // TODO
					return a compressed texture image
			}
			public {/*G → G}*/
				glCopyTexImage1D // TODO
					copy pixels into a 1D texture image
				glCopyTexImage2D // TODO
					copy pixels into a 2D texture image
				glCopyTexSubImage1D, glCopyTextureSubImage1D // TODO
					copy a one-dimensional texture subimage
				glCopyTexSubImage2D, glCopyTextureSubImage2D // TODO
					copy a two-dimensional texture subimage
			}
			public {/*C → G COMPRESSED}*/
				glCompressedTexImage3D // TODO
					specify a three-dimensional texture image in a compressed format
				glCompressedTexImage2D // TODO
					specify a two-dimensional texture image in a compressed format
				glCompressedTexImage1D // TODO
					specify a one-dimensional texture image in a compressed format
				glCompressedTexSubImage3D, glCompressedTextureSubImage3D // TODO
					specify a three-dimensional texture subimage in a compressed format
				glCompressedTexSubImage2D, glCompressedTextureSubImage2D // TODO
					specify a two-dimensional texture subimage in a compressed format
				glCompressedTexSubImage1D, glCompressedTextureSubImage1D // TODO
					specify a one-dimensional texture subimage in a compressed
					format
				glCompressedTextureSubImage1D  // TODO
					???
				glCompressedTextureSubImage2D  // TODO
					???
				glCompressedTextureSubImage3D  // TODO
					???
			}
			public {/*G → G}*/
				glTexBufferRange, glTextureBufferRange // TODO
					attach a range of a buffer object's data store to a buffer texture object
				glTextureBufferRange  // TODO
					???
				glCopyTextureSubImage1D  // TODO
					???
				glCopyTextureSubImage2D  // TODO
					???
				glCopyTextureSubImage3D  // TODO
					???
			}
			public {/*G → C}*/
				glGetCompressedTextureSubImage // TODO
					retrieve a sub-region of a compressed texture image from a compressed texture object
				glGetTexImage // TODO
					return a texture image
				glGetTextureImage  // TODO
					???
				glGetCompressedTextureImage  // TODO
					???
				glGetTextureSubImage // TODO
					retrieve a sub-region of a texture image from a texture object
			}
		}
		public {/*MISC}*/
			glTextureBufferRange  // TODO
				???
			glTextureBuffer  // TODO
				???
			glTextureView // TODO
				initialize a texture as a data alias of another texture's data store
		}
		public {/*STORAGE}*/
			glTexStorage2DMultisample, glTextureStorage2DMultisample // TODO
				specify storage for a two-dimensional multisample texture
			glTexStorage3DMultisample, glTextureStorage3DMultisample // TODO
				specify storage for a two-dimensional multisample array texture
			glTextureStorage2DMultisample  // TODO
				???
			glTextureStorage3DMultisample  // TODO
				???
			glTexStorage1D, glTextureStorage1D // TODO
				simultaneously specify storage for all levels of a one-dimensional texture
			glTexStorage2D, glTextureStorage2D // TODO
				simultaneously specify storage for all levels of a two-dimensional or one-dimensional array texture
			glTexStorage3D, glTextureStorage3D // TODO
				simultaneously specify storage for all levels of a three-dimensional, two-dimensional array or cube-map array texture
			glTextureStorage1D  // TODO
				???
			glTextureStorage2D  // TODO
				???
			glTextureStorage3D  // TODO
				???
			glTextureStorage1D  // TODO
				???
			glTextureStorage2D  // TODO
				???
			glTextureStorage3D  // TODO
				???
			glTextureStorage2DMultisample  // TODO
				???
			glTextureStorage3DMultisample  // TODO
				???
		}
		public {/*CLEAR}*/
			glClearTexImage // TODO
				fills all a texture image with a constant value
			glClearTexSubImage // TODO
				fills all or part of a texture image with a constant value
		}
		public {/*MIPMAP}*/
			glGenerateMipmap, glGenerateTextureMipmap // TODO
				generate mipmaps for a specified texture object
			glGenerateTextureMipmap  // TODO
				???
		}
		public {/*TEXTURE STATE}*/
			glBindImageTextures // TODO
				bind one or more named texture images to a sequence of consecutive image units
			glBindImageTexture // TODO
				bind a level of a texture to an image unit
			glActiveTexture // TODO
				select active texture unit
			glBindTexture // TODO
				bind a named texture to a texturing target
			glDeleteTextures // TODO
				delete named textures
			glGenTextures // TODO
				generate texture names
			glIsTexture // TODO
				determine if a name corresponds to a texture
			glBindTextures // TODO
				bind one or more named textures to a sequence of consecutive texture units
			glCreateTextures // TODO
				create texture objects
			glBindTextureUnit // TODO
				bind an existing texture object to the specified texture unit
		}
		public {/*PARAMETERS}*/
			glGetTextureLevelParameterfv  // TODO
				???
			glGetTextureLevelParameteriv  // TODO
				???
			glGetTextureParameterfv  // TODO
				???
			glGetTextureParameterIiv  // TODO
				???
			glGetTextureParameterIuiv  // TODO
				???
			glGetTextureParameteriv  // TODO
				???
			glGetTexParameterfv  // TODO
				???
			glGetTexParameteriv  // TODO
				???
			glGetTexLevelParameterfv  // TODO
				???
			glGetTexLevelParameteriv  // TODO
				???
			glTexParameterIiv  // TODO
				???
			glTexParameterIuiv  // TODO
				???
			glGetTexParameterIiv  // TODO
				???
			glGetTexParameterIuiv  // TODO
				???
			glTexParameterf  // TODO
				???
			glTexParameterfv  // TODO
				???
			glTexParameteri  // TODO
				???
			glTexParameteriv  // TODO
				???
			glTextureParameterf  // TODO
				???
			glTextureParameterfv  // TODO
				???
			glTextureParameteri  // TODO
				???
			glTextureParameterIiv  // TODO
				???
			glTextureParameterIuiv  // TODO
				???
			glTextureParameteriv  // TODO
				???
		}
	}
	public {/*UNIFORM}*/
		glGetUniformIndices // TODO
			retrieve the index of a named uniform block
		glGetActiveUniformsiv // TODO
			Returns information about several active uniform variables for the specified program object
		glGetActiveUniformName // TODO
			query the name of an active uniform
		glGetUniformBlockIndex // TODO
			retrieve the index of a named uniform block
		glGetActiveUniformBlockiv  // TODO
			???
		glGetActiveUniformBlockName // TODO
			retrieve the name of an active uniform block
		glUniformBlockBinding // TODO
			assign a binding point to an active uniform block
		glGetActiveUniform // TODO
			Returns information about an active uniform variable for the specified program object
		glGetUniformLocation // TODO
			Returns the location of a uniform variable
		glGetUniformfv  // TODO
			???
		glGetUniformiv  // TODO
			???
		glUniform1f  // TODO
			???
		glUniform2f  // TODO
			???
		glUniform3f  // TODO
			???
		glUniform4f  // TODO
			???
		glUniform1i  // TODO
			???
		glUniform2i  // TODO
			???
		glUniform4i  // TODO
			???
		glUniform1fv  // TODO
			???
		glUniform2fv  // TODO
			???
		glUniform3fv  // TODO
			???
		glUniform4fv  // TODO
			???
		glUniform1iv  // TODO
			???
		glUniform2iv  // TODO
			???
		glUniform3iv  // TODO
			???
		glUniform4iv  // TODO
			???
		glUniformMatrix2fv  // TODO
			???
		glUniformMatrix3fv  // TODO
			???
		glUniformMatrix4fv  // TODO
			???
		glUniformMatrix2x3fv  // TODO
			???
		glUniformMatrix3x2fv  // TODO
			???
		glUniformMatrix2x4fv  // TODO
			???
		glUniformMatrix4x2fv  // TODO
			???
		glUniformMatrix3x4fv  // TODO
			???
		glUniformMatrix4x3fv  // TODO
			???
		glGetUniformuiv  // TODO
			???
		glUniform1ui  // TODO
			???
		glUniform2ui  // TODO
			???
		glUniform3ui  // TODO
			???
		glUniform4ui  // TODO
			???
		glUniform1uiv  // TODO
			???
		glUniform2uiv  // TODO
			???
		glUniform3uiv  // TODO
			???
		glUniform4uiv  // TODO
			???
		glUniform1d  // TODO
			???
		glUniform2d  // TODO
			???
		glUniform3d  // TODO
			???
		glUniform4d  // TODO
			???
		glUniform1dv  // TODO
			???
		glUniform2dv  // TODO
			???
		glUniform3dv  // TODO
			???
		glUniform4dv  // TODO
			???
		glUniformMatrix2dv  // TODO
			???
		glUniformMatrix3dv  // TODO
			???
		glUniformMatrix4dv  // TODO
			???
		glUniformMatrix2x3dv  // TODO
			???
		glUniformMatrix2x4dv  // TODO
			???
		glUniformMatrix3x2dv  // TODO
			???
		glUniformMatrix3x4dv  // TODO
			???
		glUniformMatrix4x2dv  // TODO
			???
		glUniformMatrix4x3dv  // TODO
			???
		glGetUniformdv  // TODO
			???
		glGetnUniformfv  // TODO
			???
		glGetnUniformiv  // TODO
			???
		glGetnUniformuiv  // TODO
			???
	}
}
