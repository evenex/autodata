module autodata.meta.diagnostic;

private {/*import}*/
	import std.conv;
}

// TODO space diagnostic
// typeof(r.opIndex)
// answer: why won't this pull?
// 		why can't I index?
//		what's behind cannot infer opSlice message?

/* suppress stderr while in scope 
*/
string error_suppression (int line = __LINE__)()
	{/*...}*/
		enum ID = __LINE__.text;

		return q{
			int errstream} ~ID~ q{;
			}`{`q{
				import std.c.stdio;
				import std.c.linux.linux;
				
				errstream} ~ID~ q{ = dup (stderr.fileno);
				freopen ("/dev/null", "w", stderr);
			}`}`q{
			scope (exit) }`{`q{
				import std.c.stdio;
				import std.c.linux.linux;
				
				fflush (stderr);
				dup2 (errstream} ~ID~ q{, stderr.fileno);
			}`}`q{
		};
	}

/* print a symbol's type, name and value
*/
void print (alias symbol)()
	{/*...}*/
		import std.stdio;

		stderr.writeln (
			typeof(symbol).stringof,
			` `, 
			__traits(identifier, symbol),
			` = `,
			symbol
		);
	}
