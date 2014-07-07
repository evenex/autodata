module models.integrator;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import utils;
import math;

enum Method {euler, average}
template Integrator (alias method, alias equation)
	if (is (typeof(method) == Method)
		&& isCallable!equation 
	) {/*...}*/
		alias State = ParameterTypeTuple!equation;
		struct Integrator
			{/*...}*/
				Tuple!State state;
				double step_size = 0.01;
				void delegate(State) step_callback;

				auto step (Tuple!State state)
					{/*...}*/
						static if (method == Method.euler)
							{/*...}*/
								auto diff = equation (state.expand);
								foreach (i, T; State)
									state[i] += step_size * diff[i];
							}
						else static if (method == Method.average)
							{/*...}*/
								auto diff_0 = equation (state.expand);
								auto new_state = state;
								foreach (i, T; State)
									new_state[i] += step_size * diff_0[i];
								auto diff_1 = equation (new_state.expand);

								foreach (i, T; State)
									this.state[i] += step_size * (diff_0[i] + diff_1[i]) / 2;
							}
					}

				this (State initial)
					{/*...}*/
						this.state = initial;
					}
				auto on_step (void delegate(State) callback)
					{/*...}*/
						step_callback = callback;
						return this;
					}
				auto initial_step (double initial_step)
					{/*...}*/
						this.step_size = initial_step;
						return this;
					}
				auto solve_for (T)(T exit_condition)
					if (__traits(compiles, exit_condition (state.expand) == true))
					{/*...}*/
						while (not (exit_condition (state.expand)))
							{/*...}*/
								if (step_callback !is null)
									step_callback (state.expand);
								step (state);
							}

						return state;
					}
			}
	} 

