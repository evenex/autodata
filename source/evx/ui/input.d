module evx.ui.input;

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
		import evx.adaptors;
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
		public {/*key mode}*/
			enum Mode {action, text}

			void enter_text_mode ()
				{/*...}*/
					this.mode = Mode.text;

					{/*set callbacks}*/
						auto window = glfwGetCurrentContext();

						assert (window !is null);

						glfwSetKeyCallback (window, &text_key_callback);
						glfwSetCharCallback (window, &text_character_callback);
					}

					foreach (ref key_pressed; keys.byValue)
						key_pressed = false;

					events.clear;
				}
			void enter_action_mode ()
				{/*...}*/
					this.mode = Mode.action;

					{/*set callbacks}*/
						auto window = glfwGetCurrentContext();

						assert (window !is null);

						glfwSetKeyCallback (window, &action_key_callback);
						glfwSetCharCallback (window, null);
					}

					foreach (ref key_pressed; keys.byValue)
						key_pressed = false;

					events.clear;
				}
			auto key_mode ()
				{/*...}*/
					return mode;
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
			void on_scroll (void delegate(double) action)
				{/*...}*/
					_on_scroll = action;
				}
		}
		public {/*text input}*/
			string get_text_input ()
				{/*...}*/
					return text_buffer[].cache.to!string;
				}
			void set_text_input (string text)
				{/*...}*/
					text_buffer.clear;
					text_buffer ~= text;
				}
			void clear_text_input ()
				{/*...}*/
					return text_buffer.clear;
				}
		}
		public {/*event processing}*/
			void process ()
				{/*...}*/
					glfwPollEvents ();

					foreach (event; events[])
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
			Queue!(Event[], OnOverflow.reallocate) events;

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
		private {/*state}*/
			Mode mode;

			Stack!(dchar[36], OnOverflow.discard) text_buffer;

			ControlMap!Key key_map;
			bool[Key] keys;

			ControlMap!Mouse mouse_map;
			bool[Mouse] buttons;
			vec mouse_pointer = 0.vec;

			vec scroll_offset;
			void delegate(double) _on_scroll;

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

					if (event.key in key_map)
						{/*...}*/
							keys[event.key] = event.pressed;

							events ~= event;
						}
					else if (event.key.isASCII)
						return;
					else if (event.key == Key.backspace && (event.pressed || state == GLFW_REPEAT) && text_buffer.length > 0)
						text_buffer--;
					else if (state == GLFW_REPEAT)
						return;
				}
			void text_character_callback (GLFWwindow*, uint character_code)
				{/*...}*/
					auto character = cast(dchar)character_code;

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
					try mouse_pointer = vec(xpos, display.pixel_dimensions.y - ypos).to_normalized_space (display);
					catch (Exception) assert (0, `coordinate transform failed`);
				}
			void scroll_callback (GLFWwindow*, double x_offset, double y_offset)
				{/*...}*/
					if (_on_scroll)						
						try _on_scroll (y_offset);
					catch (Exception ex) assert (0, `scroll callback failed`);
				}
		}
	}
	unittest {/*...}*/
		import evx.graphics.text;
		import evx.graphics.color;

		auto display = Display (512, 512);
		auto input = Input (display, (bool){});
		input.bind (Input.Key.esc, _ => input.enter_action_mode);

		auto text = Text (Font (12), display, `q rotates color; space to edit, esc stops editing`);
		text[].color = red;

		foreach (_; 0..400)
			{/*...}*/
				static i = 0;

				if (input.key_mode == Input.Mode.text)
					{/*...}*/
						auto s = input.get_text_input;

						if (s.length)
							{/*...}*/
								text = s;
							}
						else text = `_`;

						text[].color = rainbow (20)[i % $];
					}

				text.within ([0.vec, vec(1, -1)].bounding_box.translate (input.pointer));

				if (input.key_pressed (Input.Key.q))
					text[].color = rainbow (20)[++i % $];

				if (input.key_pressed (Input.Key.space))
					{/*...}*/
						if (input.key_mode == Input.Mode.text)
							input.enter_action_mode;
						else input.enter_text_mode;
					}

				text.render_to (display);
				display.post;
				input.process;
				core.thread.Thread.sleep (20.msecs);
			}
	}
