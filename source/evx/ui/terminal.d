// REVIEW this is a fundamentally different type of thing than input
private {/*import}*/
	import evx.graphics;
	import evx.graphics.text;
	import evx.ui.input;
	import evx.memory;
	import evx.math;
	import evx.range;
	import evx.containers;
}

struct Terminal
	{/*...}*/
		Display display;
		Input input;

		VertexBuffer console_geometry;
		VertexBuffer console_border_geometry;
		Color console_color;
		Text console_text;

		Stack!(dchar[], OnOverflow.reallocate) text_buffer; // TODO filter out ~` 

		this (size_t width, size_t height)
			{/*...}*/
				display = Display (width, height);

				input = Input (display, ·=> input.text_stream = null);

				version (none) {/*BUG prints false}*/
					with (std.stdio.stderr) input.bind (Input.Key.tilde, hit 
						=> hit? (
							input.key_mode == Input.Mode.action?
								 writeln (input.key_mode == Input.Mode.action) : writeln (input.key_mode != Input.Mode.action)// BUG gets evaluated in the wrong order : if true, RHS, else LHS
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
				auto scale = vec(0.995, 0.98);

				console_geometry = geometry;
				console_border_geometry = geometry.scale (scale.to!fvec);
				console_color = green (0.2);

				console_text = Text (Font (12), display);
				console_text.within (console_border_geometry[].cache.scale (scale*scale).bounding_box); // REVIEW sucks that we have to manually convert float -> double
			}

		void show_console () // TODO drop-down animation
			{/*...}*/
				borrow (console_geometry)
					.basic_shader (console_color)
					.triangle_fan.render_to (display);

				borrow (console_border_geometry)
					.basic_shader (console_color * white)
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
