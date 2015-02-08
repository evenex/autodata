module evx.operators.forward;

template ForwardOps (alias target)
	{/*...}*/
		auto ref opDispatch (string op, Args...)(auto ref Args args)
			{/*...}*/
				import evx.type;

				auto ref call ()() {return mixin(q{target.} ~ op ~ q{ (args)});}
				auto ref read ()() if (Args.length == 0) {return mixin(q{target.} ~ op);}

				return Match!(call, read);
			}

		mixin(parameterized_op!`opUnary`);
		mixin(parameterized_op!`opBinary`);
		mixin(parameterized_op!`opBinaryRight`);

		mixin(autodeduced_op!`opIndex`);
		mixin(autodeduced_op!`opIndexAssign`);
		mixin(parameterized_op!`opIndexOpAssign`);
		mixin(parameterized_op!`opIndexUnary`);

		mixin(parameterized_op!`opDollar`);
		mixin(parameterized_op!`opSlice`);

		mixin(parameterized_op!`opCast`);

		mixin(autodeduced_op!`opApply`);

		static if (is (typeof(__traits(isTemplate, target.opCall))))
			static if (is (typeof(target.opCall)) || __traits(isTemplate, target.opCall))
				mixin(autodeduced_op!`opCall`);

		auto ref opCmp ()(auto ref this that)
			{/*...}*/
				return target.compare (that.unwrap);
			}
		auto ref opCmp ()(auto ref typeof(target) that)
			{/*...}*/
				return target.compare (that);
			}

		auto ref opEquals ()(auto ref this that)
			{/*...}*/
				return target == that.unwrap;
			}
		auto ref opEquals ()(auto ref typeof(target) that)
			{/*...}*/
				return target == that;
			}

		auto ref opAssign ()(auto ref this that)
			{/*...}*/
				return (target = that.unwrap);
			}
		auto ref opAssign ()(auto ref typeof(target) that)
			{/*...}*/
				return (target = that);
			}
		auto ref opOpAssign (string op)(auto ref this that)
			{/*...}*/
				return (mixin(q{
					target } ~ op ~ q{ = that.unwrap
				}));
			}
		auto ref opOpAssign (string op)(auto ref typeof(target) that)
			{/*...}*/
				return (mixin(q{
					target } ~ op ~ q{ = that
				}));
			}

		private {/*...}*/
			ref unwrap ()
				{/*...}*/
					return target;
				}

			enum parameterized_op (string op_name) = q{
				template } ~ op_name ~ q{ (CTArgs...)
					}`{`q{
						auto ref } ~ op_name ~ q{(RTArgs...)(auto ref RTArgs args)
							}`{`q{
								return target.} ~ op_name ~ q{!(CTArgs)(args);
							}`}`q{
					}`}`q{
			};

			enum autodeduced_op (string op_name) = q{
				auto ref } ~ op_name ~ q{ (Args...)(auto ref Args args)
					}`{`q{
						return target.} ~ op_name ~ q{ (args);
					}`}`q{
			};
		}
	}
	unittest {/*...}*/
		struct Test
			{/*...}*/
				auto opCall (T)(T)
					{/*...}*/
						return 4;
					}

				auto opIndex ()
					{/*...}*/
						return 1;
					}
				auto func ()
					{/*...}*/
						return 2;
					}
				int var = 3;
			}
		struct TTest (T)
			{/*...}*/
				T t;

				mixin ForwardOps!t;
			}

		struct NoOp
			{/*...}*/
			}

		TTest!(NoOp) _;

		TTest!(Test) t;
		assert (t[] == 1);
		assert (t.func == 2);
		assert (t.var == 3);
		assert (t ([]) == 4);

		assert (t == Test.init);
		assert (t == TTest!Test.init);

		static assert (__traits(compiles, t = Test.init));
		static assert (__traits(compiles, t = TTest!Test.init));
	}
