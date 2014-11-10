module evx.misc.services;

private {/*imports}*/
	import std.typetuple;

	import evx.type;
	import evx.traits;
}

auto connect_services (T...)(T services)
	{/*...}*/
		return Services!T (services);
	}

struct Services (T...)
	{/*...}*/
		T services;

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
										enum i = staticIndexOf!(FirstParameter!Member, T);
									else enum i = staticIndexOf!(Member, T);

									static if (i >= 0)
										__traits(getMember, client, member) = services[i];
								}
					}
			}
	}
