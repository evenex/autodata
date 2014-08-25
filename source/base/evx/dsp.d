module evx.dsp;

private {/*import std}*/
	import std.traits:
		isFloatingPoint,
		isSomeFunction, ReturnType, ParameterTypeTuple,
		isBuiltinType, RepresentationTypeTuple;

	import std.typetuple:
		allSatisfy;

	import std.functional:
		toDelegate;

	import std.conv:
		to;
}
private {/*import evx}*/
	import evx.logic: 
		not;

	import evx.traits: 
		supports_arithmetic;

	import evx.algebra:
		zero, unity;

	import evx.analysis:
		interval, is_continuous, is_continuous_range;
}

struct Stream (Sample, Index)
	if (supports_arithmetic!Index)
	{/*...}*/
		enum is_continuous = .is_continuous!Index;

		public:
		const {/*[┄]}*/
			@property opDollar ()
				in {/*...}*/
					assert (last_index !is null, `attempt to access stream before ready`);
				}
				body {/*...}*/
					return last_index ();
				}

			auto opSlice ()
				in {/*...}*/
					assert (last_index !is null, `attempt to access stream before ready`);
				}
				body {/*...}*/
					return Sampler!Stream (this, zero!Index, last_index ());
				}

			auto opSlice (Index i, Index j)
				in {/*...}*/
					assert (source !is null, `attempt to access stream before ready`);
				}
				body {/*...}*/
					return Sampler!Stream (this, i, j);
				}

			auto opIndex (Index i)
				in {/*...}*/
					assert (source !is null, `attempt to access stream before ready`);
				}
				body {/*...}*/
					return source (i);
				}
		}
		public {/*frequency}*/
			static if (Stream.is_continuous)
				{/*...}*/
					alias Frequency = typeof(1.0/(Index.init));

					Frequency delegate() frequency;

					auto at (Frequency delegate() frequency)
						{/*...}*/
							this.frequency = frequency;

							return this;
						}
				}
		}
		private:
		private {/*signals}*/
			Sample delegate(Index) source;
			Index delegate() last_index;
		}
		private {/*ctor}*/
			this (Sample delegate(Index) source, Index delegate() last_index)
				{/*...}*/
					this.source = source;
					this.last_index = last_index;

					static if (Stream.is_continuous)
						this.frequency =()=> zero!Index;
				}
		}
	}
auto stream_from (F, G)(F source, G max)
	if (allSatisfy!(isSomeFunction, F, G))
	{/*...}*/
		static assert (ParameterTypeTuple!F.length == 1);
		static assert (ParameterTypeTuple!G.length == 0);

		static assert (is(ReturnType!G : ParameterTypeTuple!F[0]));

		return Stream!(ReturnType!F, ReturnType!G)(source.toDelegate, max.toDelegate);
	}

struct Sampler (Stream)
	{/*...}*/
		alias Index = ReturnType!(Stream.opDollar);
		alias Sample = ReturnType!(Stream.opIndex);

		public:
		public {/*[┄]}*/
			static if (Stream.is_continuous)
				{/*...}*/
					@property measure () const
						{/*...}*/
							return last - first;
						}

					alias opDollar = measure;

					@property length () const
						{/*...}*/
							return (measure/stride).to!size_t;
						}
			}
			else {/*...}*/
				@property length () const
					{/*...}*/
						return last - first;
					}

				alias opDollar = length;
			}

			auto opSlice ()
				{/*...}*/
					return Sampler (this, first, last);
				}

			auto opSlice (Index i, Index j)
				{/*...}*/
					return Sampler (this, first + i, first + j);
				}

			auto opIndex (Index i)
				{/*...}*/
					return source (first + i);
				}
		}
		public {/*InputRange}*/
			Sample front ()
				{/*...}*/
					return this[zero!Index];
				}

			void popFront ()
				in {/*...}*/
					assert (stride != zero!Index, no_sampling_frequency_error);
				}
				body {/*...}*/
					first += stride;
				}

			bool empty () const
				{/*...}*/
					return first >= last;
				}
		}
		public {/*BidirectionalRange}*/
			Sample back ()
				{/*...}*/
					return this[$ - stride];
				}
			void popBack ()
				in {/*...}*/
					assert (stride != zero!Index, no_sampling_frequency_error);
				}
				body {/*...}*/
					last -= stride;
				}
		}
		public {/*ForwardRange}*/
			@property save ()
				{/*...}*/
					return this;
				}
		}
		public {/*frequency}*/
			static if (Stream.is_continuous)
				{/*...}*/
					auto at (Stream.Frequency frequency)
						{/*...}*/
							this.stride = 1.0/frequency;

							return this;
						}
				}
		}
		private:
		private {/*ctor}*/
			this (Stream stream, Index first, Index last)
				{/*...}*/
					this.first = first;
					this.last = last;

					static if (Stream.is_continuous)
						{/*...}*/
							this.frequency = stream.frequency;
							this.stride = 1 / frequency ();
						}

					this.source = stream.source;
				}
			this (Sampler that, Index first, Index last)
				{/*...}*/
					this = that;

					this.first = first;
					this.last = last;

					static if (Stream.is_continuous)
						this.stride = 1 / frequency ();
				}
		}
		private {/*data}*/
			Index first = zero!Index;
			Index last = zero!Index;

			static if (Stream.is_continuous)
				Index stride = zero!Index;
			else enum stride = unity!Index;

			Sample delegate(Index) source;

			static if (Stream.is_continuous)
				Stream.Frequency delegate() frequency;
		}
		private {/*error message}*/
			enum no_sampling_frequency_error = `for floating-point samplers, sampling frequency must be set with "sampler.at (f)" before use`;
		}
	}

enum Method
	{/*interpolation}*/
		repeat
	}

struct Interpolated (S, Method method)
	if (is(S == Sampler!T, T))
	{/*...}*/
		S sampler;

		static if (method is Method.repeat)
			{/*...}*/
				const size_t dilation_factor;
				size_t remaining_front;
				size_t remaining_back;

				void popFront ()
					{/*...}*/
						if (not (--remaining_front))
							{/*...}*/
								sampler.popFront;
								remaining_front = dilation_factor;
							}
					}
				void popBack ()
					{/*...}*/
						if (not (--remaining_back))
							{/*...}*/
								sampler.popBack;
								remaining_back = dilation_factor;
							}
					}
				const length ()
					{/*...}*/
						return sampler.length * dilation_factor;
					}
				static if (not(is_continuous_range!S))
					{/*[┅]}*/
						auto opSlice ()
							{/*...}*/
								return Interpolated (sampler, dilation_factor);
							}

						auto opSlice (S.Index i, S.Index j)
							{/*...}*/
								return Interpolated (sampler[i/s..j/s], (s), (s - i % s), (s - j % s));
							}

						auto opIndex (S.Index i)
							{/*...}*/
								return sampler[i/s];
							}

						private @property s ()
							{/*...}*/
								return dilation_factor.to!(S.Index);
							}
					}

				alias sampler this;

				this (S sampler, size_t dilation_factor)
					{/*...}*/
						this.dilation_factor = dilation_factor;
						this.sampler = sampler;

						remaining_front = dilation_factor;
						remaining_back = dilation_factor;
					}
				this (S sampler, size_t dilation_factor, size_t remaining_front, size_t remaining_back)
					{/*...}*/
						this (sampler, dilation_factor);
						this.remaining_front = remaining_front;
						this.remaining_back = remaining_back;
					}
			}
	}
auto interpolate (Method method, S)(S signal, size_t factor)
	in {/*...}*/
		assert (factor > 0, `signal interpolation requires positive factor`);
	}
	body {/*...}*/
		static if (method is Method.repeat)
			return Interpolated!(S, method)(signal, factor);
	}
	unittest {/*...}*/
		import std.range: equal;

		auto z = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

		{/*discrete stream}*/
			auto x = stream_from ((size_t x) => z[x], () => z.length)[].interpolate!(Method.repeat)(4); // interpolation metafunction?

			assert (x.length == 12*4);

			assert (x[0..16].length == 16);
			assert (x[0..16].equal ([0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3]));
		}
		{/*continuous stream}*/
			import std.math: floor;

			auto y = stream_from ((double x) => z[x.floor.to!size_t], ()=> 8.0).at (()=> 4.0)[].interpolate!(Method.repeat)(4);

			assert (y.length == 8*4*4);
			assert (y.measure == 8);

			assert (y[0..4].length == 16);
			assert (y[0..4].measure == 4);
			assert (y[0..4].equal ([0,0,0,0, 1,1,1,1, 2,2,2,2, 3,3,3,3]));
		}
	}
