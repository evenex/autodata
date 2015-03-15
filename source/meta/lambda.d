module spacecadet.meta.lambda;

template LambdaCapture ()
	{/*...}*/
		static template Λ (string op)
			{/*...}*/
				mixin(q{
					alias Λ } ~ op ~ q{;
				});
			}
		static template λ (string op)
			{/*...}*/
				mixin(q{
					enum λ } ~ op ~ q{;
				});
			}
	}

mixin LambdaCapture;
