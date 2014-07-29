module tags;

struct Tag 
	{/*...}*/
		public:
		alias Code = size_t;
		alias code this;
		public {/*toString}*/
			@property string toString () const
				{/*...}*/
					return dictionary[this.code];
				}
		}
		this (string label)
			{/*...}*/
				code = hash (label);

				if (code !in Tag.dictionary)
					Tag.dictionary.add (code, label);
				else assert (Tag.dictionary[code] == label);
			}
		private:
		private {/*data}*/
			Code code;
		}
		static:
		__gshared {/*data}*/
			Directory!(string, Code) dictionary;
			shared static this ()
				{/*...}*/
					dictionary = typeof(dictionary)(2^^8);
				}
		}
		static {/*hashing}*/
			Code hash (string str)
				{/*...}*/
					if (str.length == 0)
						return 5381;
					else {/*...}*/
						const auto tag = hash (str[1..$]);
						return (tag << 6) ^ (tag << 16) ^ str[0];
					}
				}
		}
	}
Tag tag (string label)
	{/*...}*/
		return Tag (label);
	}
Tag tag (T)()
	{/*...}*/
		return tag (T.stringof);
	}
