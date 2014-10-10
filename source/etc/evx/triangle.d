module libtriangle;
/*****************************************************************************
/*                                                                           *
/*  (triangle.h)                                                             *
/*                                                                           *
/*  Include file for programs that call Triangle.                            *
/*                                                                           *
/*  Accompanies Triangle Version 1.6                                         *
/*  July 28, 2005                                                            *
/*                                                                           *
/*  Copyright 1996, 2005                                                     *
/*  Jonathan Richard Shewchuk                                                *
/*  2360 Woolsey #H                                                          *
/*  Berkeley, California  94705-1927                                         *
/*  jrs@cs.berkeley.edu                                                      *
/*                                                                           *
/*****************************************************************************

/*****************************************************************************
/*                                                                           *
/*  How to call Triangle from another program                                *
/*                                                                           *
/*                                                                           *
/*  If you haven't read Triangle's instructions (run "triangle -h" to read   *
/*  them), you won't understand what follows.                                *
/*                                                                           *
/*  Triangle must be compiled into an object file (triangle.o) with the      *
/*  TRILIBRARY symbol defined (generally by using the -DTRILIBRARY compiler  *
/*  switch).  The makefile included with Triangle will do this for you if    *
/*  you run "make trilibrary".  The resulting object file can be called via  *
/*  the procedure triangulate().                                             *
/*                                                                           *
/*  If the size of the object file is important to you, you may wish to      *
/*  generate a reduced version of triangle.o.  The REDUCED symbol gets rid   *
/*  of all features that are primarily of research interest.  Specifically,  *
/*  the -DREDUCED switch eliminates Triangle's -i, -F, -s, and -C switches.  *
/*  The CDT_ONLY symbol gets rid of all meshing algorithms above and beyond  *
/*  constrained Delaunay triangulation.  Specifically, the -DCDT_ONLY switch *
/*  eliminates Triangle's -r, -q, -a, -u, -D, -Y, -S, and -s switches.       *
/*                                                                           *
/*  IMPORTANT:  These definitions (TRILIBRARY, REDUCED, CDT_ONLY) must be    *
/*  made in the makefile or in triangle.c itself.  Putting these definitions *
/*  in this file (triangle.h) will not create the desired effect.            *
/*                                                                           *
/*                                                                           *
/*  The calling convention for triangulate() follows.                        *
/*                                                                           *
/*      void triangulate(triswitches, in, out, vorout)                       *
/*      char *triswitches;                                                   *
/*      struct triangulateio *in;                                            *
/*      struct triangulateio *out;                                           *
/*      struct triangulateio *vorout;                                        *
/*                                                                           *
/*  `triswitches' is a string containing the command line switches you wish  *
/*  to invoke.  No initial dash is required.  Some suggestions:              *
/*                                                                           *
/*  - You'll probably find it convenient to use the `z' switch so that       *
/*    points (and other items) are numbered from zero.  This simplifies      *
/*    indexing, because the first item of any type always starts at index    *
/*    [0] of the corresponding array, whether that item's number is zero or  *
/*    one.                                                                   *
/*  - You'll probably want to use the `Q' (quiet) switch in your final code, *
/*    but you can take advantage of Triangle's printed output (including the *
/*    `V' switch) while debugging.                                           *
/*  - If you are not using the `q', `a', `u', `D', `j', or `s' switches,     *
/*    then the output points will be identical to the input points, except   *
/*    possibly for the boundary markers.  If you don't need the boundary     *
/*    markers, you should use the `N' (no nodes output) switch to save       *
/*    memory.  (If you do need boundary markers, but need to save memory, a  *
/*    good nasty trick is to set out->pointlist equal to in->pointlist       *
/*    before calling triangulate(), so that Triangle overwrites the input    *
/*    points with identical copies.)                                         *
/*  - The `I' (no iteration numbers) and `g' (.off file output) switches     *
/*    have no effect when Triangle is compiled with TRILIBRARY defined.      *
/*                                                                           *
/*  `in', `out', and `vorout' are descriptions of the input, the output,     *
/*  and the Voronoi output.  If the `v' (Voronoi output) switch is not used, *
/*  `vorout' may be NULL.  `in' and `out' may never be NULL.                 *
/*                                                                           *
/*  Certain fields of the input and output structures must be initialized,   *
/*  as described below.                                                      *
/*                                                                           *
/*****************************************************************************

/*****************************************************************************
/*                                                                           *
/*  The `triangulateio' structure.                                           *
/*                                                                           *
/*  Used to pass data into and out of the triangulate() procedure.           *
/*                                                                           *
/*                                                                           *
/*  Arrays are used to store points, triangles, markers, and so forth.  In   *
/*  all cases, the first item in any array is stored starting at index [0].  *
/*  However, that item is item number `1' unless the `z' switch is used, in  *
/*  which case it is item number `0'.  Hence, you may find it easier to      *
/*  index points (and triangles in the neighbor list) if you use the `z'     *
/*  switch.  Unless, of course, you're calling Triangle from a Fortran       *
/*  program.                                                                 *
/*                                                                           *
/*  Description of fields (except the `numberof' fields, which are obvious): *
/*                                                                           *
/*  `pointlist':  An array of point coordinates.  The first point's x        *
/*    coordinate is at index [0] and its y coordinate at index [1], followed *
/*    by the coordinates of the remaining points.  Each point occupies two   *
/*    REALs.                                                                 *
/*  `pointattributelist':  An array of point attributes.  Each point's       *
/*    attributes occupy `numberofpointattributes' REALs.                     *
/*  `pointmarkerlist':  An array of point markers; one int per point.        *
/*                                                                           *
/*  `trianglelist':  An array of triangle corners.  The first triangle's     *
/*    first corner is at index [0], followed by its other two corners in     *
/*    counterclockwise order, followed by any other nodes if the triangle    *
/*    represents a nonlinear element.  Each triangle occupies                *
/*    `numberofcorners' ints.                                                *
/*  `triangleattributelist':  An array of triangle attributes.  Each         *
/*    triangle's attributes occupy `numberoftriangleattributes' REALs.       *
/*  `trianglearealist':  An array of triangle area constraints; one REAL per *
/*    triangle.  Input only.                                                 *
/*  `neighborlist':  An array of triangle neighbors; three ints per          *
/*    triangle.  Output only.                                                *
/*                                                                           *
/*  `segmentlist':  An array of segment endpoints.  The first segment's      *
/*    endpoints are at indices [0] and [1], followed by the remaining        *
/*    segments.  Two ints per segment.                                       *
/*  `segmentmarkerlist':  An array of segment markers; one int per segment.  *
/*                                                                           *
/*  `holelist':  An array of holes.  The first hole's x and y coordinates    *
/*    are at indices [0] and [1], followed by the remaining holes.  Two      *
/*    REALs per hole.  Input only, although the pointer is copied to the     *
/*    output structure for your convenience.                                 *
/*                                                                           *
/*  `regionlist':  An array of regional attributes and area constraints.     *
/*    The first constraint's x and y coordinates are at indices [0] and [1], *
/*    followed by the regional attribute at index [2], followed by the       *
/*    maximum area at index [3], followed by the remaining area constraints. *
/*    Four REALs per area constraint.  Note that each regional attribute is  *
/*    used only if you select the `A' switch, and each area constraint is    *
/*    used only if you select the `a' switch (with no number following), but *
/*    omitting one of these switches does not change the memory layout.      *
/*    Input only, although the pointer is copied to the output structure for *
/*    your convenience.                                                      *
/*                                                                           *
/*  `edgelist':  An array of edge endpoints.  The first edge's endpoints are *
/*    at indices [0] and [1], followed by the remaining edges.  Two ints per *
/*    edge.  Output only.                                                    *
/*  `edgemarkerlist':  An array of edge markers; one int per edge.  Output   *
/*    only.                                                                  *
/*  `normlist':  An array of normal vectors, used for infinite rays in       *
/*    Voronoi diagrams.  The first normal vector's x and y magnitudes are    *
/*    at indices [0] and [1], followed by the remaining vectors.  For each   *
/*    finite edge in a Voronoi diagram, the normal vector written is the     *
/*    zero vector.  Two REALs per edge.  Output only.                        *
/*                                                                           *
/*                                                                           *
/*  Any input fields that Triangle will examine must be initialized.         *
/*  Furthermore, for each output array that Triangle will write to, you      *
/*  must either provide space by setting the appropriate pointer to point    *
/*  to the space you want the data written to, or you must initialize the    *
/*  pointer to NULL, which tells Triangle to allocate space for the results. *
/*  The latter option is preferable, because Triangle always knows exactly   *
/*  how much space to allocate.  The former option is provided mainly for    *
/*  people who need to call Triangle from Fortran code, though it also makes *
/*  possible some nasty space-saving tricks, like writing the output to the  *
/*  same arrays as the input.                                                *
/*                                                                           *
/*  Triangle will not free() any input or output arrays, including those it  *
/*  allocates itself; that's up to you.  You should free arrays allocated by *
/*  Triangle by calling the trifree() procedure defined below.  (By default, *
/*  trifree() just calls the standard free() library procedure, but          *
/*  applications that call triangulate() may replace trimalloc() and         *
/*  trifree() in triangle.c to use specialized memory allocators.)           *
/*                                                                           *
/*  Here's a guide to help you decide which fields you must initialize       *
/*  before you call triangulate().                                           *
/*                                                                           *
/*  `in':                                                                    *
/*                                                                           *
/*    - `pointlist' must always point to a list of points; `numberofpoints'  *
/*      and `numberofpointattributes' must be properly set.                  *
/*      `pointmarkerlist' must either be set to NULL (in which case all      *
/*      markers default to zero), or must point to a list of markers.  If    *
/*      `numberofpointattributes' is not zero, `pointattributelist' must     *
/*      point to a list of point attributes.                                 *
/*    - If the `r' switch is used, `trianglelist' must point to a list of    *
/*      triangles, and `numberoftriangles', `numberofcorners', and           *
/*      `numberoftriangleattributes' must be properly set.  If               *
/*      `numberoftriangleattributes' is not zero, `triangleattributelist'    *
/*      must point to a list of triangle attributes.  If the `a' switch is   *
/*      used (with no number following), `trianglearealist' must point to a  *
/*      list of triangle area constraints.  `neighborlist' may be ignored.   *
/*    - If the `p' switch is used, `segmentlist' must point to a list of     *
/*      segments, `numberofsegments' must be properly set, and               *
/*      `segmentmarkerlist' must either be set to NULL (in which case all    *
/*      markers default to zero), or must point to a list of markers.        *
/*    - If the `p' switch is used without the `r' switch, then               *
/*      `numberofholes' and `numberofregions' must be properly set.  If      *
/*      `numberofholes' is not zero, `holelist' must point to a list of      *
/*      holes.  If `numberofregions' is not zero, `regionlist' must point to *
/*      a list of region constraints.                                        *
/*    - If the `p' switch is used, `holelist', `numberofholes',              *
/*      `regionlist', and `numberofregions' is copied to `out'.  (You can    *
/*      nonetheless get away with not initializing them if the `r' switch is *
/*      used.)                                                               *
/*    - `edgelist', `edgemarkerlist', `normlist', and `numberofedges' may be *
/*      ignored.                                                             *
/*                                                                           *
/*  `out':                                                                   *
/*                                                                           *
/*    - `pointlist' must be initialized (NULL or pointing to memory) unless  *
/*      the `N' switch is used.  `pointmarkerlist' must be initialized       *
/*      unless the `N' or `B' switch is used.  If `N' is not used and        *
/*      `in->numberofpointattributes' is not zero, `pointattributelist' must *
/*      be initialized.                                                      *
/*    - `trianglelist' must be initialized unless the `E' switch is used.    *
/*      `neighborlist' must be initialized if the `n' switch is used.  If    *
/*      the `E' switch is not used and (`in->numberofelementattributes' is   *
/*      not zero or the `A' switch is used), `elementattributelist' must be  *
/*      initialized.  `trianglearealist' may be ignored.                     *
/*    - `segmentlist' must be initialized if the `p' or `c' switch is used,  *
/*      and the `P' switch is not used.  `segmentmarkerlist' must also be    *
/*      initialized under these circumstances unless the `B' switch is used. *
/*    - `edgelist' must be initialized if the `e' switch is used.            *
/*      `edgemarkerlist' must be initialized if the `e' switch is used and   *
/*      the `B' switch is not.                                               *
/*    - `holelist', `regionlist', `normlist', and all scalars may be ignored.*
/*                                                                           *
/*  `vorout' (only needed if `v' switch is used):                            *
/*                                                                           *
/*    - `pointlist' must be initialized.  If `in->numberofpointattributes'   *
/*      is not zero, `pointattributelist' must be initialized.               *
/*      `pointmarkerlist' may be ignored.                                    *
/*    - `edgelist' and `normlist' must both be initialized.                  *
/*      `edgemarkerlist' may be ignored.                                     *
/*    - Everything else may be ignored.                                      *
/*                                                                           *
/*  After a call to triangulate(), the valid fields of `out' and `vorout'    *
/*  will depend, in an obvious way, on the choice of switches used.  Note    *
/*  that when the `p' switch is used, the pointers `holelist' and            *
/*  `regionlist' are copied from `in' to `out', but no new space is          *
/*  allocated; be careful that you don't free() the same array twice.  On    *
/*  the other hand, Triangle will never copy the `pointlist' pointer (or any *
/*  others); new space is allocated for `out->pointlist', or if the `N'      *
/*  switch is used, `out->pointlist' remains uninitialized.                  *
/*                                                                           *
/*  All of the meaningful `numberof' fields will be properly set; for        *
/*  instance, `numberofedges' will represent the number of edges in the      *
/*  triangulation whether or not the edges were written.  If segments are    *
/*  not used, `numberofsegments' will indicate the number of boundary edges. *
/*                                                                           *
/*****************************************************************************/

private {/*imports}*/
	private {/*std}*/
		import std.conv;
		import std.range;
		import std.traits;
	}
	private {/*evx}*/
		import evx.math;
		import evx.meta;
		import evx.utils;
	}

	mixin(MathToolkit!());
}

private struct libtri
	{/*...}*/
		struct Args
			{/*...}*/
				/*  Here's a guide to help you decide which fields you must initialize       *
				/*  before you call triangulate().                                           *
				/*                                                                           *
				/*  `in':                                                                    *
				/*                                                                           *
				/*    - `pointlist' must always point to a list of points; `numberofpoints'  *
				/*      and `numberofpointattributes' must be properly set.                  *
				/*      `pointmarkerlist' must either be set to NULL (in which case all      *
				/*      markers default to zero), or must point to a list of markers.  If    *
				/*      `numberofpointattributes' is not zero, `pointattributelist' must     *
				/*      point to a list of point attributes.                                 *
				/*    - If the `r' switch is used, `trianglelist' must point to a list of    *
				/*      triangles, and `numberoftriangles', `numberofcorners', and           *
				/*      `numberoftriangleattributes' must be properly set.  If               *
				/*      `numberoftriangleattributes' is not zero, `triangleattributelist'    *
				/*      must point to a list of triangle attributes.  If the `a' switch is   *
				/*      used (with no number following), `trianglearealist' must point to a  *
				/*      list of triangle area constraints.  `neighborlist' may be ignored.   *
				/*    - If the `p' switch is used, `segmentlist' must point to a list of     *
				/*      segments, `numberofsegments' must be properly set, and               *
				/*      `segmentmarkerlist' must either be set to NULL (in which case all    *
				/*      markers default to zero), or must point to a list of markers.        *
				/*    - If the `p' switch is used without the `r' switch, then               *
				/*      `numberofholes' and `numberofregions' must be properly set.  If      *
				/*      `numberofholes' is not zero, `holelist' must point to a list of      *
				/*      holes.  If `numberofregions' is not zero, `regionlist' must point to *
				/*      a list of region constraints.                                        *
				/*    - If the `p' switch is used, `holelist', `numberofholes',              *
				/*      `regionlist', and `numberofregions' is copied to `out'.  (You can    *
				/*      nonetheless get away with not initializing them if the `r' switch is *
				/*      used.)                                                               *
				/*    - `edgelist', `edgemarkerlist', `normlist', and `numberofedges' may be *
				/*      ignored.                                                             *
				/*                                                                           *
				/*  `out':                                                                   *
				/*                                                                           *
				/*    - `pointlist' must be initialized (NULL or pointing to memory) unless  *
				/*      the `N' switch is used.  `pointmarkerlist' must be initialized       *
				/*      unless the `N' or `B' switch is used.  If `N' is not used and        *
				/*      `in->numberofpointattributes' is not zero, `pointattributelist' must *
				/*      be initialized.                                                      *
				/*    - `trianglelist' must be initialized unless the `E' switch is used.    *
				/*      `neighborlist' must be initialized if the `n' switch is used.  If    *
				/*      the `E' switch is not used and (`in->numberofelementattributes' is   *
				/*      not zero or the `A' switch is used), `elementattributelist' must be  *
				/*      initialized.  `trianglearealist' may be ignored.                     *
				/*    - `segmentlist' must be initialized if the `p' or `c' switch is used,  *
				/*      and the `P' switch is not used.  `segmentmarkerlist' must also be    *
				/*      initialized under these circumstances unless the `B' switch is used. *
				/*    - `edgelist' must be initialized if the `e' switch is used.            *
				/*      `edgemarkerlist' must be initialized if the `e' switch is used and   *
				/*      the `B' switch is not.                                               *
				/*    - `holelist', `regionlist', `normlist', and all scalars may be ignored.*
				/*                                                                           *
				/*  `vorout' (only needed if `v' switch is used):                            *
				/*                                                                           *
				/*    - `pointlist' must be initialized.  If `in->numberofpointattributes'   *
				/*      is not zero, `pointattributelist' must be initialized.               *
				/*      `pointmarkerlist' may be ignored.                                    *
				/*    - `edgelist' and `normlist' must both be initialized.                  *
				/*      `edgemarkerlist' may be ignored.                                     *
				/*    - Everything else may be ignored.                                      *
				/*                                                                           *
				/*  After a call to triangulate(), the valid fields of `out' and `vorout'    *
				/*  will depend, in an obvious way, on the choice of switches used.  Note    *
				/*  that when the `p' switch is used, the pointers `holelist' and            *
				/*  `regionlist' are copied from `in' to `out', but no new space is          *
				/*  allocated; be careful that you don't free() the same array twice.  On    *
				/*  the other hand, Triangle will never copy the `pointlist' pointer (or any *
				/*  others); new space is allocated for `out->pointlist', or if the `N'      *
				/*  switch is used, `out->pointlist' remains uninitialized.                  *
				/*                                                                           *
				/*  All of the meaningful `numberof' fields will be properly set; for        *
				/*  instance, `numberofedges' will represent the number of edges in the      *
				/*  triangulation whether or not the edges were written.  If segments are    *
				/*  not used, `numberofsegments' will indicate the number of boundary edges. */

				/*  `pointlist':  An array of point coordinates.  The first point's x        *
				/*    coordinate is at index [0] and its y coordinate at index [1], followed *
				/*    by the coordinates of the remaining points.  Each point occupies two   *
				/*    REALs.                                                                 */
				vec* pointlist;                                                /* In / out */

				/*  `pointattributelist':  An array of point attributes.  Each point's       *
				/*    attributes occupy `numberofpointattributes' REALs.                     */
				double* pointattributelist;                                    /* In / out */

				/*  `pointmarkerlist':  An array of point markers; one int per point.      */
				int* pointmarkerlist;                                          /* In / out */

				int numberofpoints;                                            /* In / out */
				int numberofpointattributes;                                   /* In / out */

				/*  `trianglelist':  An array of triangle corners.  The first triangle's     *
				/*    first corner is at index [0], followed by its other two corners in     *
				/*    counterclockwise order, followed by any other nodes if the triangle    *
				/*    represents a nonlinear element.  Each triangle occupies                *
				/*    `numberofcorners' ints.                                                */
				int* trianglelist;                                             /* In / out */

				/*  `triangleattributelist':  An array of triangle attributes.  Each         *
				/*    triangle's attributes occupy `numberoftriangleattributes' REALs.       */
				double* triangleattributelist;                                 /* In / out */
				
				/*  `trianglearealist':  An array of triangle area constraints; one REAL per *
				/*    triangle.  Input only.                                                 */
				double* trianglearealist;                                       /* In only */

				/*  `neighborlist':  An array of triangle neighbors; three ints per          *
				/*    triangle.  Output only.                                                */
				int* neighborlist;                                             /* Out only */

				int numberoftriangles;                                         /* In / out */
				int numberofcorners;                                           /* In / out */
				int numberoftriangleattributes;                                /* In / out */

				/*  `segmentlist':  An array of segment endpoints.  The first segment's      *
				/*    endpoints are at indices [0] and [1], followed by the remaining        *
				/*    segments.  Two ints per segment.                                       */
				int* segmentlist;                                              /* In / out */

				/*  `segmentmarkerlist':  An array of segment markers; one int per segment.  *
				/*																			 */
				int* segmentmarkerlist;                                        /* In / out */

				int numberofsegments;                                          /* In / out */

				/*  `holelist':  An array of holes.  The first hole's x and y coordinates    *
				/*    are at indices [0] and [1], followed by the remaining holes.  Two      *
				/*    REALs per hole.  Input only, although the pointer is copied to the     *
				/*    output structure for your convenience.                                 */
				vec* holelist;                         /* In / pointer to array copied out */
				int numberofholes;                                      /* In / copied out */

				/*  `regionlist':  An array of regional attributes and area constraints.     *
				/*    The first constraint's x and y coordinates are at indices [0] and [1], *
				/*    followed by the regional attribute at index [2], followed by the       *
				/*    maximum area at index [3], followed by the remaining area constraints. *
				/*    Four REALs per area constraint.  Note that each regional attribute is  *
				/*    used only if you select the `A' switch, and each area constraint is    *
				/*    used only if you select the `a' switch (with no number following), but *
				/*    omitting one of these switches does not change the memory layout.      *
				/*    Input only, although the pointer is copied to the output structure for *
				/*    your convenience.                                                      */
				double* regionlist;                    /* In / pointer to array copied out */
				int numberofregions;                                    /* In / copied out */

				/*  `edgelist':  An array of edge endpoints.  The first edge's endpoints are *
				/*    at indices [0] and [1], followed by the remaining edges.  Two ints per *
				/*    edge.  Output only.                                                    */
				int* edgelist;                                                 /* Out only */

				/*  `edgemarkerlist':  An array of edge markers; one int per edge.  Output   *
				/*    only.                                                                  */
				int* edgemarkerlist;            /* Not used with Voronoi diagram; out only */

				/*  `normlist':  An array of normal vectors, used for infinite rays in       *
				/*    Voronoi diagrams.  The first normal vector's x and y magnitudes are    *
				/*    at indices [0] and [1], followed by the remaining vectors.  For each   *
				/*    finite edge in a Voronoi diagram, the normal vector written is the     *
				/*    zero vector.  Two REALs per edge.  Output only.                        */
				double* normlist;              /* Used only with Voronoi diagram; out only */

				int numberofedges;                                             /* Out only */

				auto toString ()
					{/*...}*/
						string output;

						if (pointlist !is null)
							output ~= `pointlist = ` ~pointlist[0..numberofpoints].text~ "\n";
						if (trianglelist !is null)
							output ~= `trianglelist = ` ~trianglelist[0..numberoftriangles*numberofcorners].text~ "\n";
						if (segmentlist !is null)
							output ~= `segmentlist = ` ~segmentlist[0..numberofsegments].text~ "\n";
						if (holelist !is null)
							output ~= `holelist = ` ~holelist[0..numberofholes].text~ "\n";
						if (edgelist !is null)
							output ~= `edgelist = ` ~edgelist[0..numberofedges].text~ "\n";

						return output;
					}
			}

		__gshared:

		extern (C) {/*triangle}*/
			void function(const(char*), const(libtri.Args*), libtri.Args*, libtri.Args*) triangulate;
			void function(void*) trifree;
		}

		static mixin DynamicLibrary;
		shared static this () {load_library;}
	}
	unittest {/*...}*/
		import std.range;
		import evx.display;
		import evx.input;
		import evx.colors;

		mixin(FunctionalToolkit!());

		scope gfx = new Display;
		gfx.start; scope (exit) gfx.stop; // TODO into ctor/dtor

		bool terminated;
		scope usr = new Input (gfx, (bool){terminated = true;}); // TODO standard terminable loop

		import std.array;
		vec[] points = chain (circle.map!(to!vec), circle (0.5).map!(to!vec)).array;
		vec[] holes = [vec(0.1, 0.25)];

		alias filled = GeometryMode.t_fan;
		alias tess = GeometryMode.triangles;

		auto tri = triangulate (points, holes);

		while (not!terminated)
			{/*...}*/
				with (tri)
					{/*...}*/
						gfx.draw (blue (0.2), indices[].map!(i => vertices[i]).scale (0.25), tess);

						auto center = vertices[].mean;

						foreach (i; 0..indices.length/3)
							gfx.draw (blue, indices[3*i..3*(i+1)].map!(i => (vertices[i] - center)*0.25 + center));
					}

				foreach (pt; holes)
					gfx.draw (red, circle (0.01, (pt-points.mean) * 0.25 + points.mean), filled);

				gfx.render;
				usr.process;
			}
	}

struct Triangulation (Units)
	{/*...}*/
		alias Vertex = Vector!(2, Units);
		Vertex[] vertices;
		int[] indices;

		this (libtri.Args args)
			{/*...}*/
				with (args) {/*...}*/
					assert (numberofcorners == 3);

					vertices = (cast(Vertex*)pointlist)[0..numberofpoints];
					indices = trianglelist[0..numberoftriangles*3];
				}
			}


		int opApply (scope int delegate(Vertex[3]) op)
			{/*...}*/
				int result;
				Vector!(3, Vertex) triangle;

				foreach (i; 0..indices.length/3)
					{/*...}*/
						triangle = indices[3*i..3*(i+1)].map!(j => vertices[j]);
						
						result = op (triangle.array);

						if (result) 
							break;
					}

				return result;
			}

		version (none)
		mixin IterateOver!triangles; // OUTSIDE BUG need this to access member
		version (none)
		auto triangles ()
			{/*...}*/
				return indices[].map!(i => vertices[i]).chunks (3);
				// TODO smart slicing, saving, copying on range ops... using a centralized extraction method
			}
	}

auto triangulate (R)(R points)
	// TODO make these points into vecs and triangulate that shit and return it with the original units
	if (is_geometric!R)
	{/*...}*/
		alias Units = ElementType!(ElementType!R);
		static assert (is(RepresentationTypeTuple!Units == TypeTuple!double), RepresentationTypeTuple!Units.stringof);

		libtri.Args input;
		with (input) {/*...}*/
			pointlist = cast(vec*)points.ptr;
			numberofpoints = points.length.to!int;
		}
		libtri.Args output; 

		libtri.triangulate (to_c (`QzDq`).expand, &input, &output, null);

		return Triangulation!Units (output);
	}
