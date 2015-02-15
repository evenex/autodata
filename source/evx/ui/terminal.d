// REVIEW this is a fundamentally different type of thing than input
private {/*import}*/
	import evx.graphics;
	import evx.ui.input;
	import evx.memory;
	import evx.math;
	import evx.range;
}

struct Terminal
	{/*...}*/
		Display display;
		Input input;

		VertexBuffer console_geometry;
		VertexBuffer console_border_geometry;
		Color console_color;

		this (size_t width, size_t height)
			{/*...}*/
				display = Display (width, height);

				input = Input (display, ·=> input.enter_action_mode); // TODO do some other shit in the main escape function
				input.bind (Input.Key.tilde, ·=> input.enter_text_mode);

				auto geometry = [fvec(-1, 1), fvec(1, 1), fvec(1, 0.5), fvec(-1, 0.5)];
				console_geometry = geometry;
				console_border_geometry = geometry.scale (fvec(0.99, 0.95));
				console_color = green (0.5);
			}

		void show_console ()
			{/*...}*/
				borrow (console_geometry)
					.vertex_shader!(`verts`, q{gl_Position = vec4(verts, 0, 1);})
					.fragment_shader!(Color, `color`, q{gl_FragColor = color;})
						(console_color)
					.triangle_fan.render_to (display);

				borrow (console_border_geometry)
					.vertex_shader!(`verts`, q{gl_Position = vec4(verts, 0, 1);})
					.fragment_shader!(Color, `color`, q{gl_FragColor = color;})
						(white)
					.line_loop.render_to (display);
			}

		void refresh ()
			{/*...}*/
				if (input.key_mode == Input.Mode.text)
					show_console;

				display.post;
				input.process;
			}
	}

	void main ()
		{/*...}*/
			import core.thread;

			auto terminal = Terminal (512, 512);

			foreach (_; 0..100)
				{/*...}*/
					terminal.refresh;

					Thread.sleep (20.msecs);
				}
		}
