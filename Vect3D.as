package utilities
{
	import flash.geom.Vector3D;

	public class Vect3D extends Vector3D
	{
		public function Vect3D(x:Number=0,y:Number=0,z:Number=0,w:Number=0)
		{
			super(x,y,z,w);
		}
		public function addTo(a:Vector3D):void
		{
			x += a.x;
			y += a.y;
			z += a.z;
			w += a.w;
		}
		public function addToScaled(a:Vector3D,s:Number):void
		{
			x += a.x*s;
			y += a.y*s;
			z += a.z*s;
			w += a.w*s;
		}
	}
}