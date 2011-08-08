package utilities
{
	import flash.display.Bitmap;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.ui.Mouse;
	
	import mx.core.UIComponent;

	public class Profile
	{
		private static var profile:Profile;
		public var uiRoot:UIComponent;
		private var fpsGraph:ProfileGraph;
		private var memGraph:ProfileGraph;
		private var timeSlice:TimeSliceGraph;
		private var lastTime:Number;
		private var timeStart:uint;
		private var selfTimeStart:Number;
		private var fps:Number;

		public function Profile(lock:ProfileLock)
		{
			timeStart = uint.MAX_VALUE;
			selfTimeStart = uint.MAX_VALUE;
			fps = 0;
			uiRoot = new UIComponent();
		}
		public function displayFPS(rect:Rectangle):void
		{
			if (!fpsGraph)
			{
				var sprite:Sprite = new Sprite();
				uiRoot.addChild(sprite);

				fpsGraph = new ProfileGraph(getFPS,rect.width,rect.height,1,1,false,false,false,selfStart,selfStop);
				fpsGraph.x = rect.x;
				fpsGraph.y = rect.y;
				sprite.addChild(fpsGraph);
				fpsGraph.curVal.x = rect.x;
				fpsGraph.curVal.y = rect.y;
				sprite.addChild(fpsGraph.curVal);	
				lastTime = new Date().getTime();
				fpsGraph.addEventListener(Event.ENTER_FRAME,fpsUpdate);
			}
		}
		protected function getFPS():Number
		{
			return fps;
		}
		protected function getMem():Number
		{
			return System.totalMemory;
		}
		private function fpsUpdate(evt:Event):void
		{
			var thisTime:Number = new Date().getTime();
			var frameTime:Number = thisTime - lastTime;
			lastTime = thisTime;
			fps = 1000.0 / frameTime;
			
			Debug.Get().assert((frameTime < 100), "Very long frame! "+frameTime.toString()+"ms",25);
		}
		public function displayMem(rect:Rectangle):void
		{
			if(!memGraph)
			{
				var sprite:Sprite = new Sprite();
				uiRoot.addChild(sprite);
				sprite.addEventListener(MouseEvent.ROLL_OVER,memHover);
				sprite.addEventListener(MouseEvent.ROLL_OUT,memAutobots);
				memGraph = new ProfileGraph(getMem,rect.width,rect.height,10,1,true,true,true,selfStart,selfStop);
				memGraph.x = rect.x;
				memGraph.y = rect.y;
				sprite.addChild(memGraph);
				memGraph.curVal.x = rect.x;
				memGraph.curVal.y = rect.y;
				sprite.addChild(memGraph.curVal);	
			}
		}
		public function displayTimeSlice(rect:Rectangle):void
		{
			var sprite:Sprite = new Sprite();
			timeSlice = new TimeSliceGraph(rect.width,rect.height,selfStart,selfStop);
			timeSlice.x = rect.x;
			timeSlice.y = rect.y;
			sprite.addChild(timeSlice);
			uiRoot.addChild(sprite);
			sprite.addEventListener(MouseEvent.ROLL_OVER,tsHover);
			sprite.addEventListener(MouseEvent.ROLL_OUT,tsAutobots);
			timeSlice.add("self",0);
		}
		private function fpsHover(evt:MouseEvent):void
		{
			uiRoot.addChild(fpsGraph.key);
		}
		private function fpsAutobots(evt:MouseEvent):void
		{
			uiRoot.removeChild(fpsGraph.key);
		}
		private function memHover(evt:MouseEvent):void
		{
			uiRoot.addChild(memGraph.key);
		}
		private function memAutobots(evt:MouseEvent):void
		{
			uiRoot.removeChild(memGraph.key);
		}
		private function tsHover(evt:MouseEvent):void
		{
			uiRoot.addChild(timeSlice.key);
		}
		private function tsAutobots(evt:MouseEvent):void
		{
			uiRoot.removeChild(timeSlice.key);
		}
		private function callerID():String
		{
			var id:String = new Error().getStackTrace();
			return id.split("	at ")[3].match(/(.*\(\))/)[1];
		}
		public function getID():String
		{
			return callerID();
		}
		protected function selfStart():void
		{
			Debug.Get().assert(selfTimeStart == uint.MAX_VALUE, "Profiler: SELF starts and stops all fucked up",100);
			selfTimeStart = new Date().getTime();
		}
		protected function selfStop():void
		{
			var time:uint = new Date().getTime();
			timeSlice.add("self",time - selfTimeStart);
			selfTimeStart = uint.MAX_VALUE;
		}
		public function start():void
		{
			Debug.Get().assert(selfTimeStart == uint.MAX_VALUE, "Profiler: starts and stops all fucked up",75);
			timeStart = new Date().getTime();
		}
		public function stop():void
		{
			selfStart();
			var time:uint = new Date().getTime();
			timeSlice.add(callerID(),time - timeStart);
			timeStart = uint.MAX_VALUE;
			selfStop();
		}
		public function stopID(id:String):void
		{
			var time:uint = new Date().getTime();
			timeSlice.add(id,time - timeStart);
			timeStart = uint.MAX_VALUE;			
		}
		public static function Get():Profile
		{
			if(!profile)
			{
				profile = new Profile(new ProfileLock);
			}
			return profile;
		}
	}
}
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.profiler.profile;
import flash.text.TextField;
import flash.utils.ByteArray;

import mx.controls.Label;
import mx.controls.Text;

import spark.components.Label;
import spark.components.TextArea;

import utilities.Debug;
import utilities.Profile;

class TimeSliceGraph extends Bitmap
{
	private var names:Array;
	private var colors:Array;
	private var data:Object;
	private var setRect:Rectangle;
	private var sourceRect:Rectangle;
	private var destPoint:Point;
	private var _key:MovieClip;
	private var selfStart:Function;
	private var selfStop:Function;
	
	public function TimeSliceGraph(width:int, height:int,start:Function,stop:Function)
	{
		names = new Array();
		colors = new Array(	0xFFFF0000,
							0xFF00FF00,
							0xFF0000FF,
							0xFFFFFF00,
							0xFF00FFFF,
							0xFFFF00FF,
							0xFFFFFFFF,
							0xFF88FF00,
							0xFF8800FF,
							0xFFFF8800,
							0xFF0088FF,
							0xFFFF0088,
							0xFF00FF88
		);
		data = new Object();
		setRect = new Rectangle(0,height-1,width,1);
		sourceRect = new Rectangle(0,1,width,height-1);
		destPoint = new Point(0,0);
		addEventListener(Event.EXIT_FRAME,onExitFrame);
		_key = new MovieClip();
		_key.mouseEnabled = false;
		selfStart = start;
		selfStop = stop;
		super(new BitmapData(width,height));
	}
	public function add(name:String, time:uint):void
	{
		if(!data.hasOwnProperty(name))
		{
			data[name] = 0;
			names.push(name);
		}
		data[name] += time;
	}
	public function get key():MovieClip
	{
		if(!_key.parent)
		{
			_key.x = x;
			_key.y = y;
			_key.graphics.clear();
			while(_key.numChildren)
				_key.removeChildAt(0);
			_key.graphics.beginFill(0xFFFFFF,0.5);
			_key.graphics.drawRect(0,0,width,names.length*25);
			_key.graphics.endFill();
			for (var i:int=0; i<names.length; i++)
			{
				_key.graphics.beginFill(0x000000,0.5)
				_key.graphics.drawRect(4,5*(i+1)+i*20-1,22,22);
				_key.graphics.endFill();
				_key.graphics.beginFill(colors[i] - 0xFF000000,1.0)
				_key.graphics.drawRect(5,5*(i+1)+i*20,20,20);
				_key.graphics.endFill();
				var label:TextField = new TextField();
				label.mouseEnabled = false;
				label.text = names[i];
				label.height = 20;
				label.width = width;
				label.x = 30;
				label.y = 5*(i+1)+i*20;
				_key.addChild(label);
			}
		}
		return _key;
	}
	private function onExitFrame(evt:Event):void
	{
		var dataPoint:uint = 0;
		var name:String;
		setRect.x = 0;
		bitmapData.copyPixels(bitmapData,sourceRect,destPoint);
		setRect.x = 0;
		setRect.width = width;
		bitmapData.fillRect(setRect,0x88000000);
		for(var i:int=0; i<names.length; i++)
		{
			name = names[i];
			Debug.Get().assert(data.hasOwnProperty(name), "How the function? Shit does not exist...", 80);						
			setRect.width = data[name]*2;
			if(setRect.width)
				bitmapData.fillRect(setRect,colors[i]);
			setRect.x += setRect.width;
			data[name] = 0;
		}
		setRect.x += setRect.width;
		setRect.width = width - setRect.x;
		bitmapData.fillRect(setRect,0x88000000);
	}
}
class ProfileGraph extends Bitmap
{
	private var data:Array;
	private var counter:Number;
	private var runningTotal:Number;
	private var getData:Function;
	private var sourceRect:Rectangle;
	private var setRect:Rectangle;
	private var destPoint:Point;
	private var highest:Number;
	private var startHighest:Number;
	private var max:Number;
	private var min:Number;
	private var autoCeil:Boolean;
	private var autoFloor:Boolean;
	private var xScale:Number;
	private var yScale:Number;
	private var _key:MovieClip;
	public var curVal:TextField;
	private var selfStart:Function;
	private var selfStop:Function;
	
	public function ProfileGraph(getData:Function, width:int, height:int, xScale:int, yScale:Number, autoCeil:Boolean, autoFloor:Boolean, highWater:Boolean, start:Function,stop:Function)
	{
		super(new BitmapData(width,height));
		
		selfStart=start;
		selfStop=stop;
		runningTotal=0;
		counter=xScale;
		max = height/yScale;

		if(autoFloor)
			min = Number.MAX_VALUE;
		else
			min = 0;

		startHighest = 0;
		if(highWater)
		{
			highest = 0;
		}
		else
			highest = Number.MAX_VALUE;
		
		this.xScale = xScale;
		this.yScale = yScale;
		this.getData = getData;
		this.autoCeil = autoCeil;
		this.autoFloor = autoFloor;
		curVal = new TextField();
		curVal.textColor = 0xFFFFFF;
		
		data = new Array(width);
		sourceRect = new Rectangle(1,0,width-1,height);
		setRect = new Rectangle(width-1,0,1,height);
		destPoint = new Point(0,0);
		_key = new MovieClip();
		_key.mouseEnabled = false;
		addEventListener(Event.ENTER_FRAME,update);
	}
	private function update(evt:Event):void
	{
		selfStart();
		runningTotal += getData();
		if(!--counter)
		{
			var dataPoint:Number = runningTotal / xScale;
			counter = xScale;
			runningTotal = 0;
				
			if (autoFloor && dataPoint < min)
			{
				redraw();
			}
			if (autoCeil && dataPoint > max)
			{
				redraw();
			}
						
			if(dataPoint > highest)
			{
				highest = dataPoint;
			}
			
			var removed:Number = data.pop();
			if (removed > startHighest)
			{
				startHighest = removed;
			}
			if ( autoCeil && removed >= max / 1.35 || autoFloor && removed <= min * 1.35 )
			{
				redraw();
			}
				
			data.unshift(dataPoint);
			shiftAndDraw(dataPoint);
			curVal.text = dataPoint.toFixed().toString();
		}
		selfStop();
	}
	private function shiftAndDraw(dataPoint:Number):void
	{
		if (isNaN(dataPoint))
			dataPoint = 0;
		else
			dataPoint = (dataPoint-min) / (max-min) * height;
		
		bitmapData.copyPixels(bitmapData,sourceRect,destPoint);
		setRect.y = height-dataPoint;
		setRect.height = dataPoint;
		bitmapData.fillRect(setRect,0xFF0000FF);
		setRect.height = height-dataPoint;
		setRect.y = 0;
		bitmapData.fillRect(setRect,0x88000000);
		if(highest != Number.MAX_VALUE)
			bitmapData.setPixel(width-1,height - (highest-min) / (max-min) * height, 0xFFFF0000);
	}
	private function redraw():void
	{
		var localMin:Number = Number.MAX_VALUE;
		var localMax:Number = Number.MIN_VALUE;
		if(autoCeil || autoFloor)
		{
			for each (var dataPoint:Number in data)
			{
				if (isNaN(dataPoint))
					continue;
				if (dataPoint > localMax)
					localMax = dataPoint;
				if (dataPoint < localMin)
					localMin = dataPoint;
			}
			if(autoFloor)
				min = localMin / 1.25;
			if(autoCeil)
				max = localMax * 1.25;			
		}
		highest = startHighest;
		
		for(var x:int = width; x > 0; x--)
		{
			if (data[x] > highest)
				highest = data[x];
			shiftAndDraw(data[x]);
		}
	}
	public function get key():MovieClip
	{
		if(!_key.parent)
		{
			_key.x = x;
			_key.y = y;
			while(_key.numChildren)
				_key.removeChildAt(0);
			var label:TextField = new TextField();
			label.mouseEnabled = false;
			label.height = 60;
			label.textColor = 0xFFFFFF;
			label.appendText("y_max: " + max.toFixed(0).toString());
			label.appendText("\ny_min: " + min.toFixed(0).toString());
			label.appendText("\nhighest: " + highest.toFixed(0).toString());
			label.width = width;
			label.x = 10;
			label.y = 10;
			_key.addChild(label);
		}
		return _key;
	}
}

class ProfileLock {}