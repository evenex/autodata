module evx.patterns.original;

mixin template Original (alias destructor)
	{/*...}*/
		bool is_copy;

		this (this)
			{/*...}*/
				this.is_copy = true;
			}

		~this ()
			{/*...}*/
				if (this.is_copy)
					{}
				else destructor;
			}
	}
