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
		GLuint handle = 0;
		GLsizei _length;

		auto bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsBuffer (handle), GLBuffer.stringof~ ` uninitialized`);
			}
			body {/*...}*/
				gl.BindBuffer (target, handle);

				gl.EnableVertexAttribArray (index);

				static if (is (T == Vector!(n,U), int n, U))
					{}
				else {/*...}*/
					enum n = 1;
					alias U = T;
				}

				gl.VertexAttribPointer (
					index, n, gl.type!U, 
					GL_FALSE, 0, null
				);
			}

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
				static if (is (U == V[2], V))
					auto i = slice.left, j = slice.right;
				else auto i = slice, j = slice + 1;

				if (j-i == 0) // REVIEW should i be checking for this at the operator level? that would require a volume function
					return;

				static if (is (R == GLBuffer!(T,S), S...))
					{/*copy in vram}*/
						auto read_index = range.offset * T.sizeof;

						gl.BindBuffer (GL_COPY_READ_BUFFER, range[].source.handle);
						gl.BindBuffer (GL_COPY_WRITE_BUFFER, this.handle);

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

		void allocate (size_t length)
			{/*...}*/
				if (length == 0)
					{/*...}*/
						free;
						return;
					}

				if (not (gl.IsBuffer (handle)))
					gl.GenBuffers (1, &handle);

				gl.BindBuffer (target, handle);

				assert (gl.IsBuffer (handle));

				gl.BufferData (target, length * T.sizeof, null, usage);

				_length = length.to!GLsizei;
			}

		void free ()
			{/*...}*/
				gl.DeleteBuffers (1, &handle);

				_length = 0;
				handle = 0;
			}

		template GLRangeOps ()
			{/*...}*/
				auto offset ()
					{/*...}*/
						return this[].bounds.left;
					}
			}

		mixin BufferOps!(allocate, pull, access, length, RangeOps, GLRangeOps);

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

		auto vram = ℕ[0..999].map!(to!int).gpu_array; // copies data from ram to gpu
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
