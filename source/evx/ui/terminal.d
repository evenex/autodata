// REVIEW this is a fundamentally different type of thing than input
version(none):
private {/*import}*/
	import evx.graphics;
	import evx.graphics.text;
	import evx.ui.input;
	import evx.memory;
	import evx.math;
	import evx.range;
	import evx.containers;
}

struct AppendFilter(alias filter, T) // REVIEW
	{/*...}*/
		T core;
		alias core this;

		auto ref opOpAssign (string op : `~`, Args...)(Args args)
			{/*...}*/
				if (filter (args))
					core ~= args;
			}
	}

struct Terminal
	{/*...}*/
		bool is_open;
		CommandMap command_map;

		Display display;
		Input input;

		VertexBuffer console_geometry;
		VertexBuffer console_border_geometry;
		Color console_color;
		Text console_text;

		Queue!(Array!dchar, OnOverflow.reallocate)
			command_history; // REVIEW only recoverable in O(n), maybe this isn't a big deal

		AppendFilter!(x => x.not!contained_in ("~`"),
			Stack!(Array!dchar, OnOverflow.reallocate)
		) text_buffer;

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
							 input.text_stream (null)
							 : input.text_stream (text_buffer) // BUG gets evaluated in the wrong order : if true, RHS, else LHS
					) : {}
				);
				input.bind (Input.Key.enter, hit
					=> hit && input.is_streaming_text?
						apply_current_command () : {}
				);

				auto geometry = [fvec(-1, 1), fvec(1, 1), fvec(1, 0.5), fvec(-1, 0.5)];
				auto scale = vec(0.995, 0.98);

				console_geometry = geometry;
				console_border_geometry = geometry.scale (scale.to!fvec);
				console_color = green (0.2);

				console_text = Text (Font (12), display);
				console_text.within (console_border_geometry[].cache.scale (scale*scale).bounding_box) // REVIEW sucks that we have to manually convert float -> double
					.align_to (Alignment.bottom_left);

				is_open = true;
				command_map[`quit`] = (·){is_open = false;};
			}

		void show_console () // TODO drop-down animation
			{/*...}*/
				borrow (console_geometry)
					.basic_shader (console_color)
					.triangle_fan.render_to (display);

				borrow (console_border_geometry)
					.basic_shader (console_color * white)
					.line_loop.render_to (display);

				console_text = chain (command_history[], text_buffer[]);
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

		void apply_current_command ()
			{/*...}*/
				if (text_buffer[].empty)
					return;

				if (auto command = text_buffer[].split (` `).front.cache.to!string in command_map)
					(*command)([]);

				command_history ~= text_buffer[];
				command_history ~= "\n";

	//			command_history -=  TODO cull stuff past a certain amount

				text_buffer.clear;

				// HACK BUG enter key gets stuck for some reason
				input.text_stream (null);
				input.text_stream (text_buffer);
			}
	}

alias CommandMap = void delegate(string[])[string];

unittest {/*...}*/
	import core.thread;

	auto terminal = Terminal (512, 512);

	while (terminal.is_open)
		{/*...}*/
			terminal.refresh;

			Thread.sleep (20.msecs);
		}
}
