module tools.image;

import std.conv;
import std.stdio;
import std.range;
import std.algorithm;

import derelict.opengl3.gl3;

import services.display;
import memory.resource;
import utils;
import math;

struct Pixel
	{/*...}*/
		union {/*...}*/
			struct {ubyte b, g, r, a;}
			ubyte[4] raw;
		}
	}
struct TGA_Header 
	{/*...}*/
		align (1):
		ubyte  id_length;
		ubyte  color_map_type;
		ubyte  image_type;
		ushort c_map_start;
		ushort c_map_length;
		ubyte  c_map_depth;
		ushort x_offset;
		ushort y_offset;
		ushort width;
		ushort height;
		ubyte  pixel_depth;
		ubyte  image_descriptor;
		///
		@property origin_bottom_left ()
			{/*...}*/
				return image_descriptor == 0x28;
			}
	}
struct Image
	{/*...}*/
		Allocator!Pixel memory;

		Allocator!Pixel.Resource data;
		uint height;
		uint width;
		Format format; enum Format {rgba = GL_RGBA, bgra = GL_BGRA, gray = GL_ALPHA}

		enum SupportedExtensions
			{/*...}*/
				tga = `tga`
			}
		this (string path) // BUG this wont be platform independent
			{/*...}*/
				// TEMP
				if (memory is null)
					memory = new Allocator!Pixel (1024*1024);

				auto file = File (path, `r`);

				auto extension = path[$-path.retro.countUntil ('.')..$];

				with (SupportedExtensions)
				final switch (extension)
					{/*...}*/
						case tga:
							TGA_Header[1] header_data;
							file.rawRead (header_data);
							auto header = header_data[0];
							{/*header contract}*/
								assert (header.id_length 	  == 0x00);
								assert (header.color_map_type == 0x00);
								assert (header.image_type 	  == 0x0A);
								assert (header.c_map_start 	  == 0x0000);
								assert (header.c_map_length   == 0x0000);
								assert (header.c_map_depth 	  == 0x00);
								assert (header.x_offset 	  == 0x0000);
								if (header.y_offset != 0x0000)
									assert (header.origin_bottom_left);
								assert (header.width          != 0x0000);
								assert (header.height         != 0x0000);
								assert (header.pixel_depth == 32, 
									`only 32-bit TGA textures currently supported (` ~ path ~ ` is ` ~ header.pixel_depth.text ~ `-bit)`
								);
							}

							this.width = header.width;
							this.height = header.height;
							this.format = Format.rgba; // TEMP until if/when i need more TGA modes

							data = memory.allocate (width*height);
							file.stream_tga (data);

							if (header.origin_bottom_left)
								foreach (row; 0..height/2)
									data[row*width..(row+1)*width]
									.swapRanges (data[(height-row-1)*width..(height-row)*width]);

							break;
					}
			}

		auto upload_to (Display display)
			{/*...}*/
				TextureId texture_id;
				display.access_rendering_context (()
					{/*...}*/
						{/*generate texture_id}*/
							gl.GenTextures (1, &texture_id);
							gl.BindTexture (GL_TEXTURE_2D, texture_id);
							gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
							gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
							gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
							gl.TexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); // TODO control these options... GL_CLAMP_TO_EDGE vs GL_REPEAT?
							gl.PixelStorei (GL_UNPACK_ALIGNMENT, 1); // XXX this may need to be controlled
						}
						{/*upload texture}*/
							gl.TexImage2D (
								GL_TEXTURE_2D, 0, format,
								width, height,
								0, format, GL_UNSIGNED_BYTE,
								cast(GLvoid*)data[].ptr
							);
						}
					}
				);
				return texture_id;
			}
	}

private void stream_tga (ref File file, ref Allocator!Pixel.Resource destination) //TODO enforce depth, alignment, and 2^ dimension
	{/*...}*/
		Pixel[1] pixel;

		ubyte[1] register;

		while (destination.length < destination.capacity)
			{/*...}*/
				immutable int run_length_encoding = 0x80;

				file.rawRead (register);

				if (register[0] & run_length_encoding)
					{/*...}*/
						int run_length = (register[0] ^ run_length_encoding) + 1;

						file.rawRead (pixel);

						destination ~= pixel[0].repeat (run_length);
					}
				else {/*...}*/
					int run_length = register[0] + 1;

					destination.length += run_length;

					file.rawRead (destination[$-run_length..$]);
				}
			}
	}

unittest
	{/*...}*/
		import core.thread;
		import std.datetime;

		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop;

		auto image = Image (`/home/vlad/tcr/art/concrete.tga`);

		auto texture = image.upload_to (gfx);

		gfx.draw (texture, square, square.translate (vec(0.5)));

		gfx.render;

		Thread.sleep (100.msecs);
	}
