module evx.graphics.renderer;
public:
import evx.graphics.renderer.core;
import evx.graphics.renderer.mesh;
import evx.graphics.renderer.graph;
import evx.graphics.renderer.text;

unittest {/*...}*/
	import evx.graphics;
	import evx.misc.services;
	import evx.math;
	import core.thread;
	import std.conv;

	scope display = new Display;
	scope shader = new BasicShader;
	scope mesh = new MeshRenderer;
	scope graph = new GraphRenderer;

	display.attach (shader);
	connect_services (shader).to_clients (graph, mesh);

	enum n_verts = 64;

	auto geometry = Geometry (
		VertexBuffer (circle!n_verts),
		IndexBuffer (ℕ[0..n_verts/2].map!(i => (n_verts * gaussian).abs.clamp (interval (0, n_verts-1)).to!size_t))
	);

	foreach (i; 0..80)
		{/*...}*/
			auto random_shade (Color color)
				{/*...}*/
					return 400.shades_of (color)[$/2 + (gaussian * 100).abs.clamp (interval (0,99)).to!size_t];
				}

			mesh.draw.solid (geometry)
				.color (random_shade (cyan (0.1)))
				.rotate (-i*π/n_verts)
				.enqueued;

			mesh.draw.solid (geometry)
				.color (random_shade ((blue*grey)(0.1)))
				.rotate (i*π/n_verts)
				.enqueued;

			mesh.process;

			mesh.draw.solid (geometry)
				.color (random_shade (blue (0.1)))
				.rotate ((12+i)*π/n_verts)
				.immediately;

			graph.draw (geometry)
				.node_color (random_shade (1000.rainbow[$/2..3*$/4][(100 * gaussian).abs.clamp (interval (0,249)).to!size_t](gaussian.abs.clamp (interval (0,0.2)))))// TODO random index
				.node_radius ((0.02 * gaussian).abs.clamp (interval (0,0.05)))
				.edge_color (random_shade (blue (gaussian.abs.clamp (interval (0, 0.1)))))
				.immediately;

			geometry.indices[].transform!(map!(i => gaussian < 0.5? i : (n_verts * gaussian).abs.round.clamp (interval (0, n_verts-1))));

			// STICKING POINT: getting all the order variables loaded into the shader... sometimes they get missed, and the shader doesn't draw
			// STICKING POINT: remembering to bind buffers
			// STICKING POINT: attaching shit to other shit
			// other than that, pretty confortable...

	display.attach (shader); // BUG need this
			display.render;

			Thread.sleep (20.msecs);
		}
}
