module evx.misc.services;

private {/*imports}*/
	import std.typetuple;

	import evx.type;
	import evx.math.logic;
}

auto connect_services (T...)(T services)
	{/*...}*/
		return Services!T (services);
	}

struct Services (T...)
	if (All!(is_class, T))
	{/*...}*/
		T services;

		static assert (is(T == NoDuplicates!T));

		auto to_clients (U...)(U clients)
			{/*...}*/
				foreach (ref client; clients)
					{/*...}*/
						alias Client = typeof(client);
						
						foreach (member; __traits(allMembers, Client))
							static if (__traits(compiles, typeof(__traits(getMember, Client, member))))
								{/*...}*/
									alias Member = typeof(__traits(getMember, Client, member));

									static if (is_unary_function!Member)
										foreach (overload; __traits(getOverloads, Client, member))
											{/*...}*/
												enum i = staticIndexOf!(FirstParameter!overload, T);

												static if (i >= 0)
													__traits(getMember, client, member)(services[i]);
											}
									else {/*...}*/
										enum i = staticIndexOf!(Member, T);

										static if (i >= 0)
											__traits(getMember, client, member) = services[i];
									}
								}
					}
			}
	}
