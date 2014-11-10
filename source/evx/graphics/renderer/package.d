module evx.graphics.renderer;
public:
import evx.graphics.renderer.core;
import evx.graphics.renderer.text;
import evx.graphics.renderer.mesh;
import evx.graphics.renderer.graph;

unittest {/*...}*/
	import evx.graphics;
	import evx.misc.services;
	import evx.math;
	import core.thread;

	scope display = new Display;
	scope shader = new BasicShader;
	scope mesh = new MeshRenderer;
	scope graph = new GraphRenderer;

	display.attach (shader);
	connect_services (shader).to_clients (graph, mesh);

	auto geometry = Geometry (
		VertexBuffer (circle),
		IndexBuffer ([0,1,2, 2,1,4, 6,7,5, 9,5,3, 2,9,12])
	);

	foreach (i; 0..80)
		{/*...}*/
			mesh.draw (geometry)
				.color (grey (0.1))
				.rotate (i*π/24)
				.enqueued;

			mesh.draw (geometry)
				.color (white (0.1))
				.rotate (-i*π/24)
				.enqueued;

			mesh.process;

			mesh.draw (geometry)
				.color (blue (0.1))
				.rotate ((12+i)*π/24)
				.immediately;

			graph.draw (geometry)
				.node_color (white (gaussian) * cyan (gaussian))
				.immediately;

			geometry.indices[] = ℕ[0..geometry.indices.length].map!(i => (24 * gaussian).abs.round.clamp (interval (0, 23)));

			// STICKING POINT: getting all the order variables loaded into the shader... sometimes they get missed, and the shader doesn't draw
			// STICKING POINT: remembering to bind buffers
			// STICKING POINT: attaching shit to other shit
			// other than that, pretty confortable...

			display.render;

			Thread.sleep (20.msecs);
		}
}
