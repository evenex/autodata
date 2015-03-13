module evx.graphics.resource.buffer;
version(none):

private {/*imports}*/
	import std.conv;
	import std.string;

	import evx.operators;
	import evx.containers;
	import evx.misc.tuple;

	import evx.graphics.opengl;
	import evx.graphics.color;

	import evx.math;
	import evx.range;
}

struct GLBuffer (T, alias target, alias usage)
	if (is (typeof(target) == GLenum) && is (typeof(usage) == GLenum) && is (typeof(gl.type_enum!T)))
	{/*...}*/
		private enum bind_call = q{gl.} ~ __traits(identifier, target)[3..$].toLower;

		GLuint buffer_id = 0;
		size_t length;

		auto bind (GLuint index = 0)
			in {/*...}*/
				assert (gl.IsBuffer (buffer_id), GLBuffer.stringof~ ` uninitialized`);
			}
			body {/*...}*/
				gl.EnableVertexAttribArray (index);

				static if (is (T == Vector!(n,U), int n, U))
					{}
				else {/*...}*/
					enum n = 1;
					alias U = T;
				}

				mixin(bind_call) = buffer_id;

				gl.VertexAttribPointer (
					index, n, gl.type_enum!U, 
					GL_FALSE, 0, null
				);
			}

		auto access (size_t i)
			{/*...}*/
				T value;

				push ((&value).array_view (1), interval (i, i+1));

				return value;
			}

		auto pull (R,U)(R range, U slice)
			{/*...}*/
				static if (is (U == V[2], V))
					auto i = slice.left, j = slice.right;
				else auto i = slice, j = slice + 1;

				/*
					zero-length condition can't be tested for at the operator level
					because, in general, coords may not have arithmetic-compatible types,
					therefore a volume function isn't necessarily well-defined
				*/
				if (j-i == 0)
					return;

				static if (is (typeof(*R.source) == GLBuffer!(T,S), S...))
					{/*copy in vram}*/
						auto read_index = range.offset * T.sizeof;

						gl.copy_read_buffer = range;
						gl.copy_write_buffer = this;

						gl.CopyBufferSubData (GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, read_index, gl_slice (i,j).expand);
					}
				else {/*copy over pci}*/
					static if (is (typeof(range.ptr) == T*))
						auto ptr = range.ptr;
					else static if (is (typeof(range.to!T) == T))
						{/*...}*/
							auto value = range.to!T;
							auto ptr = &value;
						}
					else static if (is_range!R && is (typeof(range.map!(to!T))))
						{/*...}*/
							auto array = range.map!(to!T).array;
							auto ptr = array.ptr;
						}
					else static assert (0);

					bind;

					gl.BufferSubData (target, gl_slice (i,j).expand, ptr);
				}
			}

		auto push (R,U)(R range, U slice) // TODO ensure this path is taken for write-to-pointer'd space
			{/*...}*/
				static if (is (U == V[2], V))
					auto i = slice.left, j = slice.right;
				else auto i = slice, j = slice + 1;

				gl.copy_read_buffer = this.buffer_id;

				void write_data (T* ptr)
					{/*...}*/
						gl.GetBufferSubData (GL_COPY_READ_BUFFER, gl_slice (i,j).expand, ptr);
					}

				static if (is (typeof(range.ptr) == T*))
					write_data (range.ptr);
				else {/*convert}*/
					Array!T temp;

					temp.allocate (slice.width);

					write_data (temp.ptr);

					range[] = temp[].map!(to!(Element!R));
				}
			}

		void allocate (size_t length)
			{/*...}*/
				if (length == 0)
					{/*...}*/
						free;
						return;
					}

				if (not (gl.IsBuffer (buffer_id)))
					gl.GenBuffers (1, &buffer_id);

				mixin(bind_call) = buffer_id;

				assert (gl.IsBuffer (buffer_id));

				gl.BufferData (target, length * T.sizeof, null, usage);

				this.length = length.to!GLsizei;
			}

		void free ()
			{/*...}*/
				gl.DeleteBuffers (1, &buffer_id);

				this.length = 0;
				buffer_id = 0;
			}

		template GLRangeOps ()
			{/*...}*/
				GLuint buffer_id ()
					{/*...}*/
						return source.buffer_id;
					}

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
	static if (0) // TEMP
	unittest {/*...}*/
		import evx.graphics.display;
		import evx.math;
		import evx.containers;

		auto display = Display (800, 600);

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
alias ColorBuffer = GLBuffer!(Color, GL_ARRAY_BUFFER, GL_STATIC_DRAW);

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
