module evx.graphics.error;

private {/*imports}*/
	import std.conv;

	import derelict.opengl3.gl3;
}

package struct ErrorHandler (Cases...)
	{/*...}*/
		private struct Case
			{/*...}*/
				GLenum condition;
				bool delegate()[] errors;
				string [] reasons;
			}
		private Case[] cases;

		auto ref handle (GLenum condition)
			{/*...}*/
				cases ~= Case (condition);

				return this;
			}

		auto ref opCall (bool delegate() error, string reason)
			{/*...}*/
				cases.back.errors ~= error;
				cases.back.reasons ~= reason;

				return this;
			}
		auto ref opCall (string reason)
			{/*...}*/
				return this (() => true, reason);
			}

		~this ()
			{/*...}*/
				auto error = glGetError ();

				if (error != GL_NO_ERROR)
					{/*...}*/
						if (auto found = cases.find!(c => c.condition == error))
							{/*...}*/
								with (found)
									foreach (error, reason; zip (errors, reasons))
										assert (not (error ()), reason);

								assert (0, found.condition.text ~ `: cause unknown`);
							}
						else assert (0, `unknown GL error ` ~ error.text);
					}
			}

		invariant ()
			{/*...}*/
				foreach (i, handled; cases)
					{/*...}*/
						assert (handled.error.length == handled.reason.length,
							`error/reason lengths mismatch`
						);
						assert (
							not (cases[0..i].contains!(
								c => c.condition == handled.condition
							),
							`condition ` ~ handled.condition.text ~ ` already handled`
						);
					}
			}
	}
