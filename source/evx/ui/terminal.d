// REVIEW this is a fundamentally different type of thing than input
private {/*import}*/
	import evx.graphics;
	import evx.graphics.text;
	import evx.ui.input;
	import evx.memory;
	import evx.math;
	import evx.range;
	import evx.adaptors;
}

struct Terminal
	{/*...}*/
		Display display;
		Input input;

		VertexBuffer console_geometry;
		VertexBuffer console_border_geometry;
		Color console_color;
		Text console_text;

		Stack!(dchar[], OnOverflow.reallocate) text_buffer;

		this (size_t width, size_t height)
			{/*...}*/
				display = Display (width, height);

				input = Input (display, ·=> input.text_stream = null);

				version (none) {/*BUG prints false}*/
					with (std.stdio.stderr) input.bind (Input.Key.tilde, hit 
						=> hit? (
							input.key_mode == Input.Mode.action?
								 writeln (input.key_mode == Input.Mode.action) : writeln (input.key_mode != Input.Mode.action)//input.enter_action_mode : input.enter_text_mode // BUG gets evaluated in the wrong order : if true, RHS, else LHS
						) : {}
					);
				}
				
				input.bind (Input.Key.tilde, hit 
					=> hit? (
						input.is_streaming_text?
							 input.text_stream (null) : input.text_stream (text_buffer) // BUG gets evaluated in the wrong order : if true, RHS, else LHS
					) : {}
				);

				auto geometry = [fvec(-1, 1), fvec(1, 1), fvec(1, 0.5), fvec(-1, 0.5)];
				console_geometry = geometry;
				console_border_geometry = geometry.scale (fvec(0.995, 0.98));
				console_color = green (0.2);

				console_text = Text (Font (12), display);
			}

		void show_console () // TODO drop-down animation
			{/*...}*/
				borrow (console_geometry)
					.vertex_shader!(`verts`, q{gl_Position = vec4(verts, 0, 1);})
					.fragment_shader!(Color, `color`, q{gl_FragColor = color;})
						(console_color)
					.triangle_fan.render_to (display);

				borrow (console_border_geometry)
					.vertex_shader!(`verts`, q{gl_Position = vec4(verts, 0, 1);})
					.fragment_shader!(Color, `color`, q{gl_FragColor = color;})
						(console_color * white)
					.line_loop.render_to (display);

				console_text = text_buffer[];
				console_text[].color = console_color (1.0);
				console_text.render_to (display);
			}

		void refresh ()
			{/*...}*/
				if (input.is_streaming_text)
					show_console;

				display.post;
				input.process;
			}
	}

	void main ()
		{/*...}*/
			import core.thread;

			auto terminal = Terminal (512, 512);

			foreach (_; 0..300)
				{/*...}*/
					terminal.refresh;

					Thread.sleep (20.msecs);
				}
		}
