module evx.graphics.shader;


__gshared struct GraphicsContext
	{/*...}*/
		static:


	}

import evx.range;

import evx.math;
import evx.graphics.color;
import evx.misc.tuple;
import evx.containers;

alias array = evx.containers.array.array; // REVIEW how to exclude std.array.array

template vertex_shader (Code...)
	{/*...}*/
		auto vertex_shader (T...)(T args)
			{/*...}*/
				return 1;
			}
	}
template fragment_shader (Code...)
	{/*...}*/
		auto fragment_shader (T...)(T args)
			{/*...}*/
				return Array!(Color, 2)();
			}
	}


void main () // TODO the goal
	{/*...}*/
		vec[] positions;
		double[] weights;
		Color color;

		auto weight_map = τ(positions, weights, color)
			.vertex_shader!(`position`, `weight`, `color`, q{
				glPosition = position;
				frag_color = color;
				frag_alpha = weight;
			},
		).fragment_shader!(
			Color, `frag_color`, q{
				glFragColor = vec4 (frag_color.rgb, frag_alpha);
			}
		).array;

		static assert (is (typeof(weight_map) == Array!(Color, 2)));

		static if (0)
			{/*...}*/

				alias aspect_correction = vertex_shader!(`aspect_ratio`, q{
					gl_Position *= aspect_ratio;
				});
				auto aspect_ratio = vec(1.0, 2.0);

				vec[] tex_coords;
				Texture texture;

				τ(positions, tex_coords).vertex_shader!(
					`position`, `tex_coords`, q{
						glPosition = position;
						frag_tex_coords = tex_coords;
					}
				).fragment_shader!(
					vec, `frag_tex_coords`,
					Texture, `tex`, q{
						glFragColor = texture2D (tex, frag_tex_coords);
					}
				)(texture)
				.aspect_correction (aspect_ratio)
				.output_to (display);
			}
	}
