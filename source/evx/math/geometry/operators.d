module evx.math.geometry.operators;

/* define affine transformation operators in a Builder pattern 
*/
mixin template AffineTransform (T = double)
	{/*...}*/
		auto translation ()
			{/*...}*/
				return _translation;
			}
		ref translate (Vector!(2,T) Δ)
			{/*...}*/
				_translation = Δ;

				return this;
			}

		auto rotation ()
			{/*...}*/
				return _rotation;
			}
		ref rotate (T θ)
			{/*...}*/
				_rotation = θ;

				return this;
			}

		auto scale ()
			{/*...}*/
				return _scale;
			}
		ref scale (T s)
			{/*...}*/
				_scale = s;

				return this;
			}

		private {/*...}*/
			Vector!(2,T) _translation = zero!(Vector!(2,T));
			T _rotation = zero!T;
			T _scale = unity!T;
		}
	}
