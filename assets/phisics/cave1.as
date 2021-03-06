package  {

	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Shape;
	import nape.shape.Polygon;
	import nape.shape.Circle;
	import nape.geom.Vec2;
	import nape.geom.Vec3;
	import nape.dynamics.InteractionFilter;
	import nape.phys.Material;
	import nape.phys.FluidProperties;
	import nape.callbacks.CbType;
	import nape.callbacks.CbTypeList;
	import nape.geom.AABB;

	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class PhysicsData {

		/**
		 * Get position and rotation for graphics placement.
		 *
		 * Example usage:
		 * <code>
		 *    space.step(1/60);
		 *    space.liveBodies.foreach(updateGraphics);
		 *    ...
		 *    function updateGraphics(body:Body):void {
		 *       var position:Vec3 = PhysicsData.graphicsPosition(body);
		 *       var graphic:DisplayObject = body.userData.graphic;
		 *       graphic.x = position.x;
		 *       graphic.y = position.y;
		 *       graphic.rotation = position.z;
		 *       position.dispose(); //release to object pool.
		 *    }
		 * </code>
		 * In the case that you are using a flash DisplayObject you can simply
		 * use <code>space.liveBodies.foreach(PhysicsData.flashGraphicsUpdate);</code>
		 * but if using, let's say Starling you should write the equivalent version
		 * of the example above.
		 *
		 * @param body The Body to get graphical position/rotation of.
		 * @return A Vec3 allocated from object pool whose x/y are the position
		 *         for graphic, and z the rotation in degrees.
		 */
		public static function graphicsPosition(body:Body):Vec3 {
			var pos:Vec2 = body.localPointToWorld(body.userData.graphicOffset as Vec2);
			var ret:Vec3 = Vec3.get(pos.x, pos.y, (body.rotation * 180/Math.PI) % 360);
			pos.dispose();
			return ret;
		}

		/**
		 * Method to update a flash DisplayObject assigned to a Body
		 *
		 * @param body The Body having a flash DisplayObject to update graphic of.
		 */
		public static function flashGraphicsUpdate(body:Body):void {
			var position:Vec3 = PhysicsData.graphicsPosition(body);
			var graphic:DisplayObject = body.userData.graphic;
			graphic.x = position.x;
			graphic.y = position.y;
			graphic.rotation = position.z;
			position.dispose(); //release to object pool.
		}

		/**
		 * Method to create a Body from the PhysicsEditor exported data.
		 *
		 * If supplying a graphic (of any type), then this will be stored
		 * in body.userData.graphic and an associated body.userData.graphicOffset
		 * Vec2 will be assigned that represents the local offset to apply to
		 * the graphics position.
		 *
		 * @param name The name of the Body from the PhysicsEditor exported data.
		 * @param graphic (optional) A graphic to assign and find a local offset for.
						  This can be of any type, but should have a getBounds function
						  that works like that of the flash DisplayObject to correctly
						  determine a graphicOffset.
		 * @return The constructed Body.
		 */
		public static function createBody(name:String,graphic:*=null):Body {
			var xret:BodyPair = lookup(name);
			if(graphic==null) return xret.body.copy();

			var ret:Body = xret.body.copy();
			graphic.x = graphic.y = 0;
			graphic.rotation = 0;
			var bounds:Rectangle = graphic.getBounds(graphic);
			var offset:Vec2 = Vec2.get(bounds.x-xret.anchor.x, bounds.y-xret.anchor.y);

			ret.userData.graphic = graphic;
			ret.userData.graphicOffset = offset;

			return ret;
		}

		/**
		 * Register a Material object with the name used in the PhysicsEditor data.
		 *
		 * @param name The name of the Material in the PhysicsEditor data.
		 * @param material The Material object to be assigned to this name.
		 */
		public static function registerMaterial(name:String,material:Material):void {
			if(materials==null) materials = new Dictionary();
			materials[name] = material;
		}

		/**
		 * Register a InteractionFilter object with the name used in the PhysicsEditor data.
		 *
		 * @param name The name of the InteractionFilter in the PhysicsEditor data.
		 * @param filter The InteractionFilter object to be assigned to this name.
		 */
		public static function registerFilter(name:String,filter:InteractionFilter):void {
			if(filters==null) filters = new Dictionary();
			filters[name] = filter;
		}

		/**
		 * Register a FluidProperties object with the name used in the PhysicsEditor data.
		 *
		 * @param name The name of the FluidProperties in the PhysicsEditor data.
		 * @param properties The FluidProperties object to be assigned to this name.
		 */
		public static function registerFluidProperties(name:String,properties:FluidProperties):void {
			if(fprops==null) fprops = new Dictionary();
			fprops[name] = properties;
		}

		/**
		 * Register a CbType object with the name used in the PhysicsEditor data.
		 *
		 * @param name The name of the CbType in the PhysicsEditor data.
		 * @param cbType The CbType object to be assigned to this name.
		 */
		public static function registerCbType(name:String,cbType:CbType):void {
			if(types==null) types = new Dictionary();
			types[name] = cbType;
		}

		//----------------------------------------------------------------------

		private static var bodies   :Dictionary;
		private static var materials:Dictionary;
		private static var filters  :Dictionary;
		private static var fprops   :Dictionary;
		private static var types    :Dictionary;
		private static function material(name:String):Material {
			if(name=="default") return new Material();
			else {
				if(materials==null || materials[name] === undefined)
					throw "Error: Material with name '"+name+"' has not been registered";
				return materials[name] as Material;
			}
		}
		private static function filter(name:String):InteractionFilter {
			if(name=="default") return new InteractionFilter();
			else {
				if(filters==null || filters[name] === undefined)
					throw "Error: InteractionFilter with name '"+name+"' has not been registered";
				return filters[name] as InteractionFilter;
			}
		}
		private static function fprop(name:String):FluidProperties {
			if(name=="default") return new FluidProperties();
			else {
				if(fprops==null || fprops[name] === undefined)
					throw "Error: FluidProperties with name '"+name+"' has not been registered";
				return fprops[name] as FluidProperties;
			}
		}
		private static function cbtype(outtypes:CbTypeList, nameList:String):void {
			var names:Array = nameList.split(",");
			for(var i:int = 0; i<names.length; i++) {
				var name:String = names[i].replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2" );
				if(name=="") continue;

				if(types[name] === undefined)
					throw "Error: CbType with name '"+name+"' has not been registered";

				outtypes.add(types[name] as CbType);
			}
		}

		private static function lookup(name:String):BodyPair {
			if(bodies==null) init();
			if(bodies[name] === undefined) throw "Error: Body with name '"+name+"' does not exist";
			return bodies[name] as BodyPair;
		}

		//----------------------------------------------------------------------

		private static function init():void {
			bodies = new Dictionary();

			var body:Body;
			var mat:Material;
			var filt:InteractionFilter;
			var prop:FluidProperties;
			var cbType:CbType;
			var s:Shape;
			var anchor:Vec2;


			body = new Body();
			cbtype(body.cbTypes,"");


			mat = material("default");
			filt = filter("default");
			prop = fprop("default");



			s = new Polygon(
				[   Vec2.weak(539.5,193)   ,  Vec2.weak(575.5,144)   ,  Vec2.weak(509.5,142)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(668,226.5)   ,  Vec2.weak(703,200.5)   ,  Vec2.weak(651.5,181)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(250,144.5)   ,  Vec2.weak(292,103.5)   ,  Vec2.weak(165,-0.5)   ,  Vec2.weak(214,109)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(144.5,84)   ,  Vec2.weak(214,109)   ,  Vec2.weak(165,-0.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(740.5,483)   ,  Vec2.weak(696.5,564)   ,  Vec2.weak(724,599.5)   ,  Vec2.weak(1012,599.5)   ,  Vec2.weak(816,507.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(606,199.5)   ,  Vec2.weak(651.5,181)   ,  Vec2.weak(533,-0.5)   ,  Vec2.weak(575.5,144)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(483,159.5)   ,  Vec2.weak(509.5,142)   ,  Vec2.weak(457.5,121)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(435,139.5)   ,  Vec2.weak(457.5,121)   ,  Vec2.weak(395.5,117)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(865,272.5)   ,  Vec2.weak(911,269.5)   ,  Vec2.weak(829,223.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(165,-0.5)   ,  Vec2.weak(292,103.5)   ,  Vec2.weak(337.5,99)   ,  Vec2.weak(533,-0.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(348,159)   ,  Vec2.weak(375,157)   ,  Vec2.weak(395.5,117)   ,  Vec2.weak(337.5,99)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(890.5,370)   ,  Vec2.weak(890,432.5)   ,  Vec2.weak(1012,599.5)   ,  Vec2.weak(935.5,327)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(816,507.5)   ,  Vec2.weak(1012,599.5)   ,  Vec2.weak(890,432.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(792.5,244)   ,  Vec2.weak(829,223.5)   ,  Vec2.weak(534,-0.5)   ,  Vec2.weak(533,-0.5)   ,  Vec2.weak(703,200.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(1012,599.5)   ,  Vec2.weak(1014,-0.5)   ,  Vec2.weak(935.5,327)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(509.5,142)   ,  Vec2.weak(575.5,144)   ,  Vec2.weak(533,-0.5)   ,  Vec2.weak(457.5,121)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(935.5,327)   ,  Vec2.weak(1014,-0.5)   ,  Vec2.weak(911,269.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(1014,-0.5)   ,  Vec2.weak(534,-0.5)   ,  Vec2.weak(829,223.5)   ,  Vec2.weak(911,269.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(395.5,117)   ,  Vec2.weak(457.5,121)   ,  Vec2.weak(533,-0.5)   ,  Vec2.weak(337.5,99)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");

			s = new Polygon(
				[   Vec2.weak(651.5,181)   ,  Vec2.weak(703,200.5)   ,  Vec2.weak(533,-0.5)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");



			mat = material("default");
			filt = filter("default");
			prop = fprop("default");



			s = new Polygon(
				[   Vec2.weak(80,232)   ,  Vec2.weak(58,223)   ,  Vec2.weak(25,228)   ,  Vec2.weak(1,243)   ,  Vec2.weak(1,283)   ,  Vec2.weak(76,258)   ],
				mat,
				filt
				);
			s.body = body;
			s.sensorEnabled = false;
			s.fluidEnabled = false;
			s.fluidProperties = prop;
			cbtype(s.cbTypes,"");




			anchor = (true) ? body.localCOM.copy() : Vec2.get(0,600);
			body.translateShapes(Vec2.weak(-anchor.x,-anchor.y));
			body.position.setxy(0,0);

			bodies["cave"] = new BodyPair(body,anchor);

		}
	}
}

import nape.phys.Body;
import nape.geom.Vec2;

class BodyPair {
	public var body:Body;
	public var anchor:Vec2;
	public function BodyPair(body:Body,anchor:Vec2):void {
		this.body = body;
		this.anchor = anchor;
	}
}


