module evx.graphics.buffer;

private {/*imports}*/
	import std.conv;
	import std.array;

	import evx.operators;
	import evx.misc.tuple;

	import evx.graphics.opengl;

	import evx.math;
	import evx.range;
}

struct GLBuffer (T, GLenum target, GLenum usage)
	{/*...}*/
		enum gl_buffer;

		GLuint handle = 0;
		GLsizei _length;

		size_t length () const
			{/*...}*/
				return _length;
			}

		auto access (size_t i)
			{/*...}*/
				T value;

				push (&value, interval (i, i+1));

				return value;
			}

		auto pull (R,U)(R range, U slice)
			{/*...}*/
				static if (is (R.gl_buffer))
					{/*copy in vram}*/
						alias V = ElementType!(R.Sub!0);
						auto read_index = range.offset * V.sizeof;

						gl.BindBuffer (GL_COPY_READ_BUFFER, range.main_buffer.handle);
						gl.BindBuffer (GL_COPY_WRITE_BUFFER, handle);

						auto i = slice.left, j = slice.right;

						gl.CopyBufferSubData (GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, read_index, gl_slice (i,j).expand);
					}
				else {/*copy over pci}*/
					static if (is (typeof(range.ptr) == T*))
						auto ptr = range.ptr;
					else static if (is (typeof(range.map!(to!T))))
						{/*...}*/
							scope array = range.map!(to!T).array;

							auto ptr = array.ptr;
						}
					else {/*...}*/
						auto value = range.to!T;
						auto ptr = &value;
					}

					static if (is (U == V[2], V))
						auto i = slice.left, j = slice.right;
					else auto i = slice, j = slice + 1;

					bind;

					gl.BufferSubData (target, gl_slice (i,j).expand, ptr);
				}
			}

		auto push (U)(T* target, U slice)
			{/*...}*/
				static if (is (U == V[2], V))
					auto i = slice.left, j = slice.right;
				else auto i = slice, j = slice + 1;

				gl.BindBuffer (GL_COPY_READ_BUFFER, handle);

				gl.GetBufferSubData (GL_COPY_READ_BUFFER, gl_slice (i,j).expand, target);
			}

		auto allocate (size_t length)
			{/*...}*/
				if (length == 0)
					{/*...}*/
						free;
						return;
					}

				if (handle == 0)
					gl.GenBuffers (1, &handle);

				bind;

				gl.BufferData (target, length * T.sizeof, null, usage);

				_length = length.to!GLsizei;
			}
		auto free ()
			{/*...}*/
				gl.DeleteBuffers (1, &handle);

				_length = 0;
				handle = 0;
			}

		auto bind ()
			in {/*...}*/
				assert (handle > 0, GLBuffer.stringof~ ` uninitialized`);
			}
			body {/*...}*/
				gl.BindBuffer (target, handle);
			}

		mixin BufferOps!(allocate, pull, access, length, RangeOps);

		private:
		auto gl_slice (size_t i, size_t j)
			{/*...}*/
				return τ(i * T.sizeof, (j-i) * T.sizeof);
			}
	}

/* generic VRAM buffer 
*/
alias GPUArray (T) = GLBuffer!(T, GL_ARRAY_BUFFER, GL_DYNAMIC_DRAW);
auto gpu_array (R)(R range)
	{/*...}*/
		return GPUArray!(ElementType!R)(range);
	}
	unittest {/*...}*/
		import evx.graphics.display;//		import evx.graphics.display;
		import evx.math;//		import evx.math.sequence;
		import evx.containers;//		import evx.containers.m_array;

		scope display = new Display;

		auto vram = ℕ[0..999].gpu_array; // copies data from ram to gpu
		assert (vram[0..10] == [0,1,2,3,4,5,6,7,8,9]);

		vram[6..9] = 6.repeat (3);
		assert (vram[0..10] == [0,1,2,3,4,5,6,6,6,9]);


		vram[0] = 9001;
		assert (vram[0..2] == [9001, 1]);

		auto ram = vram[124..168].array; // copies data from gpu to ram
		assert (ram[] == vram[124..168]);

		auto vram2 = vram[0..$/2].gpu_array; // copies directly between vram buffers
		assert (vram2[] == vram[0..$/2]);

		vram2[99] = 42;
		assert (vram2[] != vram[0..$/2]);
	}

/* standard openGL buffer types 
*/
alias VertexBuffer = GLBuffer!(fvec, GL_ARRAY_BUFFER, GL_STATIC_DRAW);
alias IndexBuffer = GLBuffer!(ushort, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW);
alias UniformBuffer (T) = GLBuffer!(T, GL_UNIFORM_BUFFER, GL_STATIC_DRAW);
alias ColorBuffer = GLBuffer!(Vector!(4, float), GL_ARRAY_BUFFER, GL_STATIC_DRAW);

/* composite buffer types 
*/
struct Geometry
	{/*...}*/
		VertexBuffer vertices;
		IndexBuffer indices;

		void bind ()
			{/*...}*/
				vertices.bind;
				indices.bind;
			}
	}
