module evx.graphics.buffer;

private {/*imports}*/
	import std.range;
	import std.conv;

	import evx.operators.transfer;
	import evx.operators.buffer;
	import evx.misc.utils;

	import evx.graphics.opengl;
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

		auto bind ()
			in {/*...}*/
				assert (handle > 0, GLBuffer.stringof~ ` uninitialized`);
			}
			body {/*...}*/
				gl.BindBuffer (target, handle);
			}

		public {/*operators}*/
			auto access (size_t i)
				{/*...}*/
					T value;

					push (&value, i, i+1);

					return value;
				}
			auto pull (R)(R range, size_t i, size_t j)
				{/*...}*/
					static if (is(R.Source.gl_buffer))
						{/*copy in vram}*/
							alias U = ElementType!R;
							auto read_index = range.offset * U.sizeof;

							gl.BindBuffer (GL_COPY_READ_BUFFER, range.main_buffer.handle);
							gl.BindBuffer (GL_COPY_WRITE_BUFFER, handle);

							gl.CopyBufferSubData (GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, read_index, gl_slice (i,j).expand);
						}
					else {/*copy over pci}*/
						static if (is(typeof(range.ptr) == T*))
							auto ptr = range.ptr;
						else {/*...}*/
							auto array = .array (range.map!(to!T));

							auto ptr = array.ptr;
						}

						bind;

						gl.BufferSubData (target, gl_slice (i,j).expand, ptr);
					}
				}
			auto push (T* target, size_t i, size_t j)
				{/*...}*/
					gl.BindBuffer (GL_COPY_READ_BUFFER, handle);

					gl.GetBufferSubData (GL_COPY_READ_BUFFER, gl_slice (i,j).expand, target);
				}
			auto allocate (size_t length)
				{/*...}*/
					if (handle == 0)
						gl.GenBuffers (1, &handle);

					bind;

					gl.BufferData (target, length * T.sizeof, null, usage);

					_length = length.to!GLsizei;
				}
			auto free ()
				{/*...}*/
					gl.DeleteBuffers (1, &handle);

					handle = 0;
				}
		}

		private:
		auto gl_slice (size_t i, size_t j)
			{/*...}*/
				return τ(i * T.sizeof, (j-i) * T.sizeof);
			}
	}

struct VertexBuffer
	{/*...}*/
		import evx.math.geometry.vectors;

		GLBuffer!(fvec, GL_ARRAY_BUFFER, GL_STATIC_DRAW)
			buffer;

		mixin BufferOps!buffer;
	}
struct IndexBuffer
	{/*...}*/
		GLBuffer!(ushort, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW)
			buffer;

		mixin BufferOps!buffer;
	}

struct GPUArray (T)
	{/*...}*/
		GLBuffer!(T, GL_ARRAY_BUFFER, GL_DYNAMIC_DRAW)
			buffer;

		alias buffer this;

		mixin BufferOps!buffer;
	}
auto gpu_array (R)(R range)
	{/*...}*/
		return GPUArray!(ElementType!R)(range);
	}
	unittest {/*...}*/
		import evx.graphics.display;
		import evx.math.ordinal;
		import evx.containers.m_array;

		scope display = new Display;

		auto vram = ℕ[0..999].gpu_array; // copies data from ram to gpu
		assert (vram[0..10] == [0,1,2,3,4,5,6,7,8,9]);

		vram[6..9] = 6;
		assert (vram[0..10] == [0,1,2,3,4,5,6,6,6,9]);

		vram[0] = 9001;
		assert (vram[0..2] == [9001, 1]);

		auto ram = vram[124..168].m_array; // copies data from gpu to ram
		assert (ram[] == vram[124..168]);

		auto vram2 = vram[0..$/2].gpu_array; // copies directly between vram buffers
		assert (vram2[] == vram[0..$/2]);

		vram2[99] = 42;
		assert (vram2[] != vram[0..$/2]);
	}
