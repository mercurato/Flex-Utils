package utilities
{
	public class Debug
	{
		private static var debug:Debug;
		public var isDebug:Boolean;
		public var ignoreThreshold:int = 10;
		public var haltThreshold:int = 80;
		
		public function Debug(lock:DebugLock)
		{
			isDebug = new Error().getStackTrace().search(/:[0-9]+\]$/m) > -1;			
		}
		public static function Get():Debug
		{
			if(!debug)
			{
				debug = new Debug(new DebugLock);
			}
			return debug;
		}
		public function assert(condition:Boolean,text:String=null,severity:int=50):Boolean
		{
			if(isDebug && !condition)
			{
				if(!text)
				{
					if(severity >= haltThreshold)
						throw new Error("Assert Failed");
					else if (severity > ignoreThreshold)
						trace("Assert Failed");
				}
				else
				{
					if(severity >= haltThreshold)
						throw new Error(text);
					else if (severity > ignoreThreshold)
						trace(text);
				}
			}
			return condition;
		}
	}
}
class DebugLock {}