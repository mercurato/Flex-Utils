package utilities
{
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	
	public class BoundingBoxFilter
	{
		private var chain:ArrayCollection;
		private var x:BBList;
		private var y:BBList;
		public function BoundingBoxFilter()
		{
			x = new BBList(true);
			y = new BBList(false);
			chain = new ArrayCollection();
		}
		public function update():void
		{
			var link:BBChain;
			x.bubbleSort();
			y.bubbleSort();
			for each(link in chain)
			{
				link.prospects.removeAll();
			}
			x.buildProspects();
			y.pruneProspects();
		}
		public function addObject(obj:Object, rect:Rectangle):void
		{
			var link:BBChain = new BBChain(obj,rect);
			Debug.Get().assert(obj.hasOwnProperty("x"), "must have an x to bound the box",100);
			Debug.Get().assert(obj.hasOwnProperty("y"), "must have a y to bound the box",100);
			Debug.Get().assert(obj.hasOwnProperty("doesCollide"), "doesCollide function needed",100);
			Debug.Get().assert(obj.hasOwnProperty("collided"), "collided function needed",100);
			x.insertionAdd(link);
			y.insertionAdd(link);
			chain.addItem(link);
		}
		public function removeAll():void
		{
			x.removeAll();
			y.removeAll();
			chain.removeAll();
		}
		public function removeObject(obj:Object):void
		{
			x.remove(obj);
			y.remove(obj);
			for(var i:int = 0; i<chain.length; i++)
			{
				if( (chain.getItemAt(i) as BBChain).entity == obj)
				{
					chain.removeItemAt(i);
					return;
				}
			}
		}
	}
}
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.events.Event;
import flash.geom.Rectangle;

import mx.collections.ArrayCollection;

import utilities.Debug;

class BBList
{
	public var isX:Boolean;
	private var list:Array;
	private var active:ArrayCollection;
	private var collided:ArrayCollection;

	public function BBList(isX:Boolean)
	{
		list = new Array();
		active = new ArrayCollection();
		collided = new ArrayCollection();
		this.isX = isX;
		super();
	}
	
	private function get length():int
	{
		return list.length;
	}
	private function addItemAt(obj:Object,at:int):void
	{
		list.splice(at,0,obj);
	}
	private function getItemAt(at:int):Object
	{
		return list[at];
	}
	private function removeItemAt(at:int):Object
	{
		return list.splice(at,1);
	}
	private function setItemAt(obj:Object, at:int):void
	{
		list[at] = obj;
	}
	public function pruneProspects():void
	{
		active.removeAll();
		var current:BBEntity;
		var front:BBEntity;
		var i:int;
		var toRemove:int=-1;
		
		for each(current in list)
		{
			if(current.paterfamilias.prospects.length)
			{
				if(!current.isFront)
				{
					for (i=0;i<active.length;i++)
					{
						front = active.getItemAt(i) as BBEntity;
						
						if(front.paterfamilias == current.paterfamilias)
						{
							toRemove = i;
						}
						else if(current.paterfamilias.prospects.contains(front.paterfamilias))
						{
							if(current.paterfamilias.entity.doesCollide(front.paterfamilias.entity))
							{
								collided.addItem(current.paterfamilias.entity);
								collided.addItem(front.paterfamilias.entity);
							}
						}
					}
					Debug.Get().assert(toRemove>=0,"WTF son?!",100);
					active.removeItemAt(toRemove);
					toRemove=-1;
				}
				else
				{
					active.addItemAt(current,active.length);
				}
			}
		}
		Debug.Get().assert(collided.length%2 == 0,"this should not be odd, we remove in pairs!!",85);

		var a:Object;
		var b:Object;
		
		for (i=0;i<collided.length;i+=2)
		{
			a = collided[i];
			b = collided[i+1];
			a.collided(b);
			b.collided(a);
		}
		collided.removeAll();
	}
	public function buildProspects():void
	{
		active.removeAll();
		var current:BBEntity;
		var front:BBEntity;
		var i:int;
		var toRemove:int;
		
		for each(current in list)
		{
			if(!current.isFront)
			{
				toRemove = -1;
				for (i=0;i<active.length;i++)
				{
					front = active.getItemAt(i) as BBEntity;
					if(front.paterfamilias == current.paterfamilias)
					{
						Debug.Get().assert(toRemove == -1,"You have too many fronts, You better back that ass up", 100);
						toRemove = i;
					}
					else
					{
						current.paterfamilias.prospects.addItem(front.paterfamilias);
						front.paterfamilias.prospects.addItem(current.paterfamilias);
					}
				}
				Debug.Get().assert(toRemove != -1,"You have not enough fronts, You better forward that ass down", 100);
				active.removeItemAt(toRemove);
			}
			else
			{
				active.addItemAt(current,active.length);
			}
		}
	}
	public function bubbleSort():void
	{
		var i:int;
		var a:BBEntity;
		var b:BBEntity;
		var end:int=length;
		var start:int=0;
		var lastSwap:int;
		
		do
		{
			lastSwap = -1;
			a = getItemAt(start) as BBEntity;
			for(i=start+1;i<end;i++)
			{
				b = getItemAt(i) as BBEntity;
				
				if(b.val < a.val)
				{
					setItemAt(b,i-1);
					setItemAt(a,i);
					lastSwap=i;
				}
				else
				{
					a = b;
				}
			}
			if(lastSwap > 0)
			{
				end = lastSwap;
				lastSwap = -1;
				a = getItemAt(end-1) as BBEntity;
				for(i=end-2;i>start;i--)
				{
					b = getItemAt(i) as BBEntity;
					
					if(b.val > a.val)
					{
						setItemAt(b,i+1);
						setItemAt(a,i);
						lastSwap = i;
					}
					else
					{
						a = b;
					}
				}
				start = lastSwap;
			}
		} while(lastSwap > 0);
	}
	public function removeAll():void
	{
		active.removeAll();
		collided.removeAll();
		while(list.length) list.pop();
	}
	public function remove(obj:Object):void
	{
		var bbe:BBEntity;
		var front:int = -1;
		var back:int = -1;
		for(var i:int = 0; i<length; i++)
		{
			bbe = getItemAt(i) as BBEntity;
			if(bbe.paterfamilias.entity == obj)
			{
				if(bbe.isFront)
				{
					front = i;
				}
				else
				{
					back = i;
				}
			}
		}
		Debug.Get().assert(front != -1 && back != -1,"your head went up your ass",90);
		removeItemAt(back);
		removeItemAt(front);
		
	}
	public function insertionAdd(bbChain:BBChain):void
	{
		var added:int = 0;
		var i:int = 0;
		var front:BBEntity = new BBEntity(bbChain,isX,true);
		var end:BBEntity = new BBEntity(bbChain,isX,false);
		var current:BBEntity = front;

		while(i<length && current)
		{
			if(current.val < (getItemAt(i) as BBEntity).val)
			{
				added++;
				addItemAt(current,i);
				if(current == front)
				{
					current = end;
				}
				else
				{
					current = null;
				}
			}
			i++;
		}
		if(current)
		{
			if(current == front)
			{
				added++;
				addItemAt(front,length);
			}
			added++;
			addItemAt(end,length);
		}
		Debug.Get().assert(added == 2,"you're doing it wrong, or maybe I am...",60);
	}	
}

class BBChain
{
	public var prospects:ArrayCollection;
	public var entity:Object;
	public var rect:Rectangle
	
	public function BBChain(entity:Object, rect:Rectangle)
	{
		prospects = new ArrayCollection();
		this.entity = entity;
		this.rect = rect;
	}
}

class BBEntity
{
	private var isX:Boolean;
	public var isFront:Boolean;
	public var sibling:BBEntity;
	public var paterfamilias:BBChain;
	
	public function BBEntity(bbChain:BBChain, isX:Boolean, isFront:Boolean)
	{
		this.isFront = isFront;
		this.isX = isX;
		paterfamilias = bbChain;
	}
	public function get val():Number
	{
		var base:Number;
		var modifier:Number;
		
		if(isX)
		{
			modifier = paterfamilias.rect.x;
			base = paterfamilias.entity.x;
			if(!isFront)
			{
				modifier += paterfamilias.rect.width;
			}
		}
		else
		{
			modifier = paterfamilias.rect.y;
			base = paterfamilias.entity.y;
			if(!isFront)
			{
				modifier += paterfamilias.rect.height;
			}
		}
		
		return base+modifier;
	}
}
