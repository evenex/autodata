module evx.input;

private {/*imports}*/
	private {/*std}*/
		import std.datetime;
		import std.exception;
		import std.range;
		import std.traits;
		import std.algorithm;
		import std.conv;
	}
	private {/*evx}*/
		import evx.utils;
		import evx.math;
		import evx.display;
		import evx.scribe;
		import evx.buffers;
		import evx.arrays;
	}
	private {/*glfw3}*/
		import derelict.glfw3.glfw3;
	}

	alias map = evx.functional.map;
}

final class Input
	{/*...}*/
		public:

		enum Mode {text, action}

		Mode mode;

		void enter_text_mode ()
			{/*...}*/
				this.mode = Mode.text;

				active_display.access_rendering_context = ()
					{/*...}*/
						auto window = glfwGetCurrentContext();

						enforce (window !is null);

						glfwSetKeyCallback (window, &text_key_callback);
						glfwSetCharCallback (window, &text_character_callback);
					};

				foreach (ref key_pressed; keys.byValue)
					key_pressed = false;
			}
		void enter_action_mode ()
			{/*...}*/
				this.mode = Mode.action;

				active_display.access_rendering_context = ()
					{/*...}*/
						auto window = glfwGetCurrentContext();

						enforce (window !is null);

						glfwSetKeyCallback (window, &action_key_callback);
						glfwSetCharCallback (window, null);
					};

				foreach (ref key_pressed; keys.byValue)
					key_pressed = false;
			}

		string get_text_input ()
			{/*...}*/
				return text_buffer[].to!string;
			}
		void clear_text_input ()
			{/*...}*/
				return text_buffer.clear;
			}

		public {/*interface}*/
			void bind (T)(T input, void delegate(bool) action)
				{/*...}*/
					static if (is (T == Key))
						{/*...}*/
							if (input == Key.esc)
								enforce (Key.esc !in key_map);

							alias map = key_map;
						}
					else alias map = mouse_map;

					if (action is null)
						{/*...}*/
							static if (is (T == Key))
								assert (input != Key.esc);

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

			const @property keys_pressed (R)(R range)
				if (is (ElementType!R == Key))
				{/*...}*/
					return range.map!(k => keys[k]);
				}

			const @property buttons_pressed (R)(R range)
				if (is (ElementType!R == Mouse))
				{/*...}*/
					return range.map!(b => buttons[b]);
				}
			const @property pointer ()
				{/*...}*/
					return mouse_pointer;
				}
		}
		public {/*inputs}*/
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
		}
		public {/*events}*/
			void process ()
				{/*...}*/
					events.swap;

					foreach (event; events.read[]) with (event) 
						if (button in mouse_map)
							mouse_map[button](pressed);
						else if (key in key_map)
							key_map[key](pressed);
				}
		}
		public {/*ctor}*/
			this (Display display, void delegate(bool) main_escape_function)
				in {/*...}*/
					assert (display.is_running);
				}
				body {/*...}*/
					import evx.utils;
					active_display = display;

					active_display.access_rendering_context = ()
						{/*...}*/
							auto window = glfwGetCurrentContext();

							enforce (window !is null);

							glfwSetInputMode (window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
							glfwSetKeyCallback (window, &action_key_callback); // XXX
							glfwSetMouseButtonCallback (window, &mouse_button_callback);
							glfwSetCursorPosCallback (window, &pointer_callback);
						};

					key_map.lookup[`base`] = [Key.esc: main_escape_function];
					mouse_map.lookup[`base`] = [Mouse.left: (bool){}];

					foreach (k; EnumMembers!Key)
						keys[k] = false;
					foreach (b; EnumMembers!Mouse)
						buttons[b] = false;

					events = new typeof(events);
				}
			~this ()
				{/*...}*/
					key_map.clear;
					mouse_map.clear;
				}
		}

		private:
		private {/*events}*/
			shared static DoubleBuffer!(Event, 2^^6) events;

			struct Event
				{/*...}*/
					private {/*data}*/
						int code;
						bool pressed;
					}
					nothrow @property {/*key/mouse}*/
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
		}
		__gshared {/*state}*/
			Display active_display;

			Appendable!(dchar[128]) text_buffer;

			Map!Key key_map;
			bool[Key] keys;

			Map!Mouse mouse_map;
			bool[Mouse] buttons;
			vec mouse_pointer = 0.vec;

			struct Map (T)
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
				{/*...}*/
					auto event = Event (key, cast(bool)state);

					if (Unicode.ascii.canFind (event.key))
						return;
					else if (event.key == Key.backspace && (event.pressed || state == GLFW_REPEAT) && text_buffer.length > 0)
						text_buffer.shrink (1);
					else if (state == GLFW_REPEAT)
						return;

					keys[event.key] = event.pressed;

					events ~= event;
				}
			void text_character_callback (GLFWwindow*, uint character_code)
				{/*...}*/
					auto character = cast(dchar)character_code;

					if (text_buffer.length < text_buffer.capacity)
						text_buffer ~= character;
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
					try mouse_pointer = vec(xpos, ypos).from_inverted_pixel_space.to_extended_space (active_display);
					catch (Exception) assert (0, `coordinate transform failed`);
				}
		}
	}
