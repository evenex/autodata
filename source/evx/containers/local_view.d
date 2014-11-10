module evx.containers.local_view;

private {/*import}*/
	import evx.containers.m_array;
	
	import evx.adaptors;
	import evx.range;
}

/* maintain a local copy of VRAM data for fast editing
	data automatically updates on bind 
*/
struct LocalView (RemoteBuffer)
	{/*...}*/
		Remote!(MArray!(ElementType!RemoteBuffer), RemoteBuffer) buffer;
		alias buffer this;

		auto bind ()
			{/*...}*/
				buffer.post;
			}
	}
