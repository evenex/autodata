module models.physical;

import math;
import units;
import models.aspect;
import services.collision;

final class Physical
	{mixin Model;/*}*/
		alias Position = Vec2!Meters;
		alias Velocity = Vec2!(typeof(meters/second));

		@(2^^8)
		@Aspect struct Body
			{/*...}*/
				@(2^^16) Position[] geometry;
				Position position;
				Velocity velocity;
				Kilograms mass;
				Scalar damping;
				Meters elevation;
				Meters height;
			}

		Collision collision;

		void simulate (Entity.Id entity)
			{/*...}*/
				
			}
		void terminate (Entity.Id entity)
			{/*...}*/
				
			}
		void initialize ()
			{/*...}*/
				
			}
		void update ()
			{/*...}*/
				
			}
	}
