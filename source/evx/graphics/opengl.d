module evx.graphics.opengl;

private {/*imports}*/
	import std.conv: to, text;
	import std.typecons: tuple;
	import std.string: toUpper;

	import evx.misc.utils;
	import evx.type;
	import evx.math;
	import evx.range;

	import evx.graphics.color;
	import evx.graphics.error;

	import derelict.glfw3.glfw3;
}
public import derelict.opengl3.gl3;

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

		static opIndex (GLenum type) {return [Typenames][[Enums].count_until (type)];}
		static opIndex (string type) {return [Enums][[Typenames].count_until (type)];}
	}

struct gl
	{/*...}*/
		template type_enum (T)
			{/*...}*/
				enum scalar_enum (U) = `GL_` ~ (is_unsigned!U? `UNSIGNED_` ~ U.stringof.toUpper[1..$] : U.stringof.toUpper);
				enum vector_enum (uint n, U) = scalar_enum!U ~ `_VEC` ~ n.text;
				enum matrix_enum (uint m, uint n, U) = scalar_enum!U ~ `_MAT` ~ n.text ~ (m == n? `` : `x` ~ m.text);

				static if (is (T == Matrix!(m,n,U), uint m, uint n, U))
					enum type_enum = mixin(matrix_enum!(m,n,U));
				else static if (is (T == Vector!(n,U), uint n, U))
					enum type_enum = mixin(vector_enum!(n,U));
				else enum type_enum = mixin(scalar_enum!T);
			}

		static:

		shared static {/*ctor/dtor}*/
			shared static this ()
				{/*...}*/
					void initialize_glfw ()
						{/*...}*/
							glfwSetErrorCallback (&error_callback);

							if (not (glfwInit ()))
								assert (0, "glfwInit failed");
						}
					void initialize_glfw_window ()
						{/*...}*/
							window = glfwCreateWindow (1, 1, ``, null, null);
		
							if (window is null)
								assert (0, `window creation failure`);

							glfwHideWindow (window);

							glfwMakeContextCurrent (window);
							glfwSwapInterval (0);

							glfwSetWindowSizeCallback (window, &resize_window_callback);
							glfwSetFramebufferSizeCallback (window, &resize_framebuffer_callback);

							glfwSetWindowTitle (window, text (
								`evx.graphics.display `,
								`(openGL `,
									glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MAJOR),
									`.`,
									glfwGetWindowAttrib (window, GLFW_CONTEXT_VERSION_MINOR),
								`)`
							).to_c.expand);
						}

					DerelictGL3.load ();
					DerelictGLFW3.load ();
					initialize_glfw;
					initialize_glfw_window;
					DerelictGL3.reload ();
				}
			shared static ~this ()
				{/*...}*/
				import evx.graphics.display;
					void terminate_glfw ()
						{/*...}*/
							if (window !is null)
								glfwDestroyWindow (window);

							glfwTerminate ();
						}

					terminate_glfw;
				}
		}

		public:
		public {/*callbacks}*/
			void delegate (size_t width, size_t height) nothrow on_resize;
		}
		public {/*state}*/
			void clear (GLbitfield mask = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
				{/*...}*/
					gl.Clear (mask);
				}
			void clear_color (Color color)
				{/*...}*/
					with (color)
						gl.ClearColor (red, green, blue, alpha);
				}
			auto clear_color ()
				{/*...}*/
					return Color (get!(Vector!(4, float)) (GL_COLOR_CLEAR_VALUE));
				}
		}
		public {/*introspection}*/
			auto get (T)(GLenum param)
				{/*...}*/
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

					mixin(q{gl.Get} ~ t_str ~ q{v (param, cast(U*)&value);});

					return value;
				}
			auto get_buffer_parameter (GLenum target, GLenum parameter)
				{/*...}*/
					int value;

					gl.GetBufferParameteriv (target, parameter, &value);
					
					return value;
				}
			auto get_program_parameter (GLuint program, GLenum param)
				{/*...}*/
					int value;

					gl.GetProgramiv (program, param, &value);

					return value;
				}
		}
		public {/*dispatch}*/
			auto opDispatch (string op, Args...)(Args args)
				{/*...}*/
					auto call ()() {return gl.call!op (args);}
					auto set ()() {set_binding!op (args);}
					auto get ()() {return get_binding!op;}

					return Match!(call, set, get);
				}
		}
		public {/*shader control}*/
			auto program (GLuint id)
				{/*...}*/
					gl.UseProgram (id);
				}
			auto program ()
				{/*...}*/
					return get!int (GL_CURRENT_PROGRAM).to!GLuint;
				}

			auto get_active_uniform (GLuint program, GLuint index)
				{/*...}*/
					struct UniformInfo
						{/*...}*/
							GLenum type;
							GLint size;
							string name;

							const toString ()
								{/*...}*/
									return [GLTypeTable[type], name].join (` `).to!string;
								}
						}

					char[256] name;
					GLint size;
					GLenum type;
					GLint length;

					gl.GetActiveUniform (program, index, name.length.to!int, &length, &size, &type, name.ptr);

					return UniformInfo (type, size, name[0..length].to!string);
				}

			void uniform (T)(T value, GLuint index = 0)
				in {/*...}*/
					assert (program != 0, `no active program`);

					assert (index < get_program_parameter (program, GL_ACTIVE_UNIFORMS), `uniform location invalid`);

					auto variable = get_active_uniform (program, index);

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

					if (variable.type != GL_SAMPLER_2D)
						assert (variable.type == gl.type_enum!T,
							`attempted to upload ` ~ T.stringof ~ ` to uniform ` ~ variable.text
							~ `, use ` ~ GLTypeTable[variable.type] ~ ` instead.`
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
		}

		package:
		package {/*window control}*/
			void window_size (size_t width, size_t height)
				{/*...}*/
					if (width * height == 0)
						glfwHideWindow (window);
					else {/*...}*/
						glfwSetWindowSize (window, width.to!int, height.to!int);
						glfwShowWindow (window);
					}
				}
			void swap_buffers ()
				{/*...}*/
					glfwSwapBuffers (window);
				}
		}

		private:
		private {/*context}*/
			GLFWwindow* window;
		}
		private {/*callbacks}*/
			extern (C) nothrow:

			void error_callback (int, const (char)* error)
				{/*...}*/
					import std.c.stdio;

					fprintf (stderr, "error glfw: %s\n", error);
				}
			void resize_framebuffer_callback (GLFWwindow* window, int width, int height)
				{/*...}*/
					glViewport (0, 0, width, height);
					//try gl.Viewport (0, 0, width, height);
					//catch (Exception ex) assert (0, ex.msg);
				}
			void resize_window_callback (GLFWwindow*, int width, int height)
				{/*...}*/
					if (gl.on_resize !is null)
						gl.on_resize (width, height);
				}
		}
		private {/*direct call}*/
			template call (string name)
				{/*...}*/
					auto call (Args...)(Args args)
						out {/*...}*/
							error_check!name (args);
						}
						body {/*...}*/
							mixin (q{
								return gl} ~ name ~ q{ (args.to_c.expand);
							});
						}
				}

		}
		private {/*binding points}*/
			void set_binding (string target)(GLuint id)
				{/*...}*/
					enum set_target = q{GL_} ~ target.toUpper;

					static if (target.contains (`texture`))
						enum set_call = q{BindTexture};
					else static if (target.contains (`framebuffer`))
						enum set_call = q{BindFramebuffer};
					else static if (target.contains (`buffer`))
						enum set_call = q{BindBuffer};

					gl.opDispatch!set_call (mixin(set_target), id);
				}
			auto get_binding (string target)()
				{/*...}*/
					static if (target.contains (`texture`))
						enum get_target = q{GL_TEXTURE_BINDING} ~ target.find (`_`).toUpper;
					else enum get_target = q{GL_} ~ target.toUpper ~ q{_BINDING};

					return get!int (mixin(get_target));
				}
		}
		private {/*error checking}*/
			void error_check (string name, Args...) (Args args)
				{/*...}*/
					Map!(Λ!q{(T) = Select!(is (T == uint), string, T)}, Args)
						mapped_args;

					foreach (i, Arg; Args)
						static if (is (Arg == GLuint))
							mapped_args[i] = constant_string (args[i]);
						else mapped_args[i] = args[i];

					GLenum error;

					while ((error = glGetError ()) != GL_NO_ERROR)
						assert (0, `OpenGL error ` ~ error.text ~ `: ` ~ constant_string (error) ~ "\n"
							`    calling gl` ~ function_call_to_string!name (mapped_args)
						);
				}
		}
	}
