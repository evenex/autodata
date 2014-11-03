module evx.misc.tuple;

private {/*...}*/
	import std.typecons;
}

alias τ = std.typecons.tuple;
template Τ (T...) {alias Τ = T;}
