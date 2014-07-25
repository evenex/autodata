module models.entity;

import std.traits;
import utils;
import meta;

struct Entity
	{/*...}*/
		mixin TypeUniqueId;
		this (string name)
			{/*...}*/
				this.name = name;
				id = Id.create;
			}
		this (Entity.Id id)
			{/*...}*/
				this.id = id;
			}

		string name; // XXX this probably GCs
		Id id;

		mixin CompareBy!id;
	}
