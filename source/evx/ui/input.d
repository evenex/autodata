module evx.ui.input;
version(none):

private {/*imports}*/
	private {/*std}*/
		import std.datetime; // REVIEW these imports
		import std.exception;
		import std.traits;
		import std.conv;
		import std.ascii;
	}
	private {/*evx}*/
		import evx.math;
		import evx.range;
		import evx.containers;
		import evx.async;
		import evx.memory;
		import evx.graphics.display;
	}
	private {/*glfw3}*/
		import derelict.glfw3.glfw3;
	}
}

struct Input
	{/*...}*/
		public:

		this (ref Display display, void delegate(bool) main_escape_function)
			{/*...}*/
				this.display = borrow (display);

				auto window = glfwGetCurrentContext ();

				glfwSetInputMode (window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
				glfwSetKeyCallback (window, &action_key_callback);
				glfwSetMouseButtonCallback (window, &mouse_button_callback);
				glfwSetCursorPosCallback (window, &pointer_callback);
				glfwSetScrollCallback (window, &scroll_callback);

				key_map.lookup[`base`] = [Key.esc: main_escape_function];
				mouse_map.lookup[`base`] = [Mouse.left: (bool){}];

				foreach (k; EnumMembers!Key)
					keys[k] = false;
				foreach (b; EnumMembers!Mouse)
					buttons[b] = false;

				events.capacity = 256; // REVIEW
			}

		enum Key
			{/*...}*/
				ignored 	= GLFW_KEY_UNKNOWN,
				a 			= GLFW_KEY_A,
				b 			= GLFW_KEY_B,
				c 			= GLFW_KEY_C,
				d 			= GLFW_KEY_D,
				e 			= GLFW_KEY_E,
				f 			= GLFW_KEY_F,
				g 			= GLFW_KEY_G,
				h 			= GLFW_KEY_H,
				i 			= GLFW_KEY_I,
				j 			= GLFW_KEY_J,
				k 			= GLFW_KEY_K,
				l 			= GLFW_KEY_L,
				m 			= GLFW_KEY_M,
				n 			= GLFW_KEY_N,
				o 			= GLFW_KEY_O,
				p 			= GLFW_KEY_P,
				q 			= GLFW_KEY_Q,
				r 			= GLFW_KEY_R,
				s 			= GLFW_KEY_S,
				t 			= GLFW_KEY_T,
				u 			= GLFW_KEY_U,
				v 			= GLFW_KEY_V,
				w 			= GLFW_KEY_W,
				x 			= GLFW_KEY_X,
				y 			= GLFW_KEY_Y,
				z 			= GLFW_KEY_Z,
				zero 		= GLFW_KEY_0,
				one 		= GLFW_KEY_1,
				two 		= GLFW_KEY_2,
				three 		= GLFW_KEY_3,
				four 		= GLFW_KEY_4,
				five 		= GLFW_KEY_5,
				six 		= GLFW_KEY_6,
				seven 		= GLFW_KEY_7,
				eight 		= GLFW_KEY_8,
				nine 		= GLFW_KEY_9,
				space 		= GLFW_KEY_SPACE,
				enter 		= GLFW_KEY_ENTER,
				tab 		= GLFW_KEY_TAB,
				esc 		= GLFW_KEY_ESCAPE,
				up 			= GLFW_KEY_UP,
				down 		= GLFW_KEY_DOWN,
				left 		= GLFW_KEY_LEFT,
				right 		= GLFW_KEY_RIGHT,
				n_up 		= GLFW_KEY_KP_8,
				n_down 		= GLFW_KEY_KP_2,
				n_left 		= GLFW_KEY_KP_4,
				n_right 	= GLFW_KEY_KP_6,
				n_plus 		= GLFW_KEY_KP_ADD,
				n_minus 	= GLFW_KEY_KP_SUBTRACT,
				left_shift 	= GLFW_KEY_LEFT_SHIFT,
				right_shift = GLFW_KEY_RIGHT_SHIFT,
				left_ctrl 	= GLFW_KEY_LEFT_CONTROL,
				right_ctrl 	= GLFW_KEY_RIGHT_CONTROL,
				left_alt 	= GLFW_KEY_LEFT_ALT,
				right_alt 	= GLFW_KEY_RIGHT_ALT,
				backspace 	= GLFW_KEY_BACKSPACE,
				tilde 		= GLFW_KEY_GRAVE_ACCENT,
			}
		enum Mouse
			{/*...}*/
				ignored = GLFW_KEY_UNKNOWN - 1,
				left 	= GLFW_MOUSE_BUTTON_LEFT,
				middle	= GLFW_MOUSE_BUTTON_MIDDLE,
				right 	= GLFW_MOUSE_BUTTON_RIGHT,
				aux_4 	= GLFW_MOUSE_BUTTON_4,
				aux_5 	= GLFW_MOUSE_BUTTON_5
			}

		public {/*input state}*/
			const @property:

			bool is_streaming_text ()
				{/*...}*/
					return not (text_output is null || text_backspace is null);
				}

			auto key_pressed (Key key)
				{/*...}*/
					return keys[key];
				}
			auto keys_pressed (R)(R range)
				{/*...}*/
					return range.map!(k => keys[k]);
				}

			auto button_pressed (Mouse button)
				{/*...}*/
					return buttons[button];
				}
			auto buttons_pressed (R)(R range)
				{/*...}*/
					return range.map!(b => buttons[b]);
				}
			auto pointer ()
				{/*...}*/
					return mouse_pointer;
				}
		}
		public {/*control mapping}*/
			void bind (T)(T input, void delegate(bool) action)
				{/*...}*/
					alias map = Select!(is (T == Key), key_map, mouse_map);

					if (action is null)
						{/*...}*/
							static if (is (T == Key))
								assert (input != Key.esc,
									`cannot remove escape key action, can only overwrite`
								);

							map.current_map.remove (input);
						}
					else map[input] = action;
				}
			void push_context (string context)
				{/*...}*/
					mouse_map.push (context);
					key_map.push (context);
				}
			void pop_context ()
				{/*...}*/
					mouse_map.pop;
					key_map.pop;
				}
			void on_pop (void delegate() on_pop)
				{/*...}*/
					key_map.on_pop = on_pop;
				}
			void on_scroll (void delegate(double) nothrow action)
				{/*...}*/
					scroll_action = action;
				}
		}
		public {/*text stream}*/
			void text_stream (R)(ref R output)
				{/*...}*/
					set_callbacks (&text_key_callback, &text_character_callback);

					text_output = (dchar c){try output ~= c; catch (Exception ex) assert (0, ex.msg);};
					text_backspace = (){if (output.length > 0) output--;};
				}
			void text_stream (typeof(null))
				{/*...}*/
					set_callbacks (&action_key_callback, null);

					text_output = null;
					text_backspace = null;
				}
		}
		public {/*event processing}*/
			void process ()
				{/*...}*/
					glfwPollEvents ();

					events.buffer.swap;

					foreach (event; events.buffer.read[])
						with (event) {/*...}*/
							if (button in mouse_map)
								mouse_map[button](pressed);
							else if (key in key_map)
								key_map[key](pressed);
						}
				}
		}

		private __gshared:
		private {/*events}*/
			struct EventBuffer // REVIEW
				{/*...}*/
					DoubleBuffered!(Queue!(Event[], OnOverflow.reallocate)) 
						buffer;

					ref write () nothrow
						{/*...}*/
							return buffer.write;
						}

					alias write this;
				}
			EventBuffer events; // TODO mutexed https://issues.dlang.org/show_bug.cgi?id=14185

			struct Event
				{/*...}*/
					int code;
					bool pressed;

					nothrow @property:

					union Cast {int code; Key key; Mouse button;}

					Key key ()
						{/*...}*/
							return Cast (code).key;
						}
					Mouse button ()
						{/*...}*/
							return Cast (code).button;
						}
				}
		}
		private {/*state}*/
			ControlMap!Key key_map;
			bool[Key] keys;

			ControlMap!Mouse mouse_map;
			bool[Mouse] buttons;
			vec mouse_pointer = 0.vec;
			vec scroll_offset;

			struct ControlMap (T)
				{/*...}*/
					alias current_map this;
					void delegate() on_pop;

					public:
					public {/*interface}*/
						void pop ()
							{/*...}*/
								assert (context.length > 1, `attempt to pop base input map`);
								--context.length;

								if (on_pop !is null)
									{/*...}*/
										on_pop ();
										on_pop = null;
									}
							}
						void push (string context)
							{/*...}*/
								if (context !in lookup)
									{/*...}*/
										static if (is (T == Key))
											lookup[context] = [Key.esc: (bool pressed){if (pressed) pop;}];
										else lookup[context] = typeof(lookup[context]).init;
									}
								this.context ~= context;
							}
					}

					private:
					private {/*data}*/
						void delegate(bool)[T][string] lookup;
						string[] context = [`base`];
					}
					private {/*ops}*/
						ref @property void delegate(bool)[T] current_map ()
							{/*...}*/
								return lookup[context[$-1]];
							}
						void clear ()
							{/*...}*/
								context = null;
								lookup = null;
							}
					}
				}
		}
		private {/*services}*/
			Borrowed!Display display;
		}
		private {/*callbacks}*/
			void set_callbacks (GLFWkeyfun key_callback, GLFWcharfun char_callback)
				{/*...}*/
					auto window = glfwGetCurrentContext ();

					assert (window !is null);

					glfwSetKeyCallback (window, key_callback);
					glfwSetCharCallback (window, char_callback);

					foreach (ref key_pressed; keys.byValue)
						key_pressed = false;

					events.clear;
				}

			void delegate(double) nothrow scroll_action;
			void delegate(dchar) nothrow text_output;
			void delegate() nothrow text_backspace;
		}

		static nothrow:
		extern (C) {/*callbacks}*/
			void action_key_callback (GLFWwindow*, int key, int scancode, int state, int mods)
				{/*...}*/
					if (state == GLFW_REPEAT)
						return;

					auto event = Event (key, cast(bool)state);

					keys[event.key] = event.pressed;

					events ~= event;
				}
			void text_key_callback (GLFWwindow*, int key, int scancode, int state, int mods)
				in {/*...}*/
					assert (text_backspace);
				}
				body {/*...}*/
					auto event = Event (key, cast(bool)state);

					if (event.key in key_map)
						{/*...}*/
							keys[event.key] = event.pressed;

							events ~= event;
						}
					else if (event.key.isASCII)
						return;
					else if (event.key == Key.backspace && (event.pressed || state == GLFW_REPEAT))
						text_backspace ();
					else if (state == GLFW_REPEAT)
						return;
				}
			void text_character_callback (GLFWwindow*, uint character_code)
				in {/*...}*/
					assert (text_output);
				}
				body {/*...}*/
					auto character = cast(dchar)character_code;

					text_output (character);
				}
			void mouse_button_callback (GLFWwindow*, int button, int state, int mods)
				{/*...}*/
					if (state == GLFW_REPEAT)
						return;

					auto event = Event (button, cast(bool)state);

					buttons[event.button] = event.pressed;

					events ~= event;
				}
			void pointer_callback (GLFWwindow*, double xpos, double ypos)
				{/*...}*/
					try mouse_pointer = vec(xpos, display.pixel_dimensions.y - ypos).to_normalized_space (display);
					catch (Exception) assert (0, `coordinate transform failed`);
				}
			void scroll_callback (GLFWwindow*, double x_offset, double y_offset)
				{/*...}*/
					if (scroll_action)
						scroll_action (y_offset);
				}
		}
	}
	unittest {/*...}*/
		import evx.graphics.text;
		import evx.graphics.color;

		auto display = Display (512, 512);
		auto input = Input (display, (bool){});
		input.bind (Input.Key.esc, _ => input.text_stream = null);

		auto text = Text (Font (12), display, `q rotates color; space to edit, esc stops editing`);
		text[].color = red;

		foreach (_; 0..400)
			{/*...}*/
				static Stack!(dchar[], OnOverflow.reallocate) text_buffer;
				static i = 0;

				if (input.is_streaming_text)
					text = text_buffer[];

				text.within ([0.vec, vec(1, -1)].bounding_box.translate (input.pointer));

				if (input.key_pressed (Input.Key.q))
					++i;

				text[].color = rainbow (20)[i % $];

				if (input.key_pressed (Input.Key.space))
					input.text_stream = text_buffer;

				text.render_to (display);
				display.post;
				input.process;
				core.thread.Thread.sleep (20.msecs);
			}
	}
