module evx.graphics.shader;


__gshared struct GraphicsContext
	{/*...}*/
		static:


	}

import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.stdio;
import std.ascii;

auto find_occurrences (string text, string word)
	{/*...}*/
		long[] indices;

		auto remaining = text;

		while (remaining.length)
			{/*...}*/
				auto found = remaining.find (word);

				if (found.empty)
					break;
				else remaining = found[1..$];

				auto word_start = long (text.length) - long (found.length);
				auto prev_char = word_start - 1;
				auto next_char = word_start + word.length;

				if (prev_char > 0 && text[prev_char].isAlphaNum)
					continue;
				else if (next_char < text.length && text[next_char].isAlphaNum)
					continue;
				else indices ~= word_start;
			}

		return indices;
	}

static if (0) void main () // TODO the goal
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

		static assert (is (typeof(weight_map) == Array!2));

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
