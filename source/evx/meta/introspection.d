module evx.meta.introspection;

private {/*import}*/
	import std.traits;
	import std.range;
}

alias Domain = std.traits.ParameterTypeTuple;
alias Codomain = std.traits.ReturnType;

alias FieldTypes = std.traits.FieldTypeTuple;
alias ElementType = std.range.ElementType;

/* get the fully qualified name of a type, including its containing module 
*/
alias full_name = fullyQualifiedName;
