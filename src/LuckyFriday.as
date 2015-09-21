package
{
	import citrus.core.starling.StarlingCitrusEngine;

	[SWF(frameRate = "60", width = "1024", height = "600", backgroundColor = "0x999999")]
	public class LuckyFriday extends StarlingCitrusEngine
	{
		public function LuckyFriday()
		{
			setUpStarling(true);
		}

		override public function handleStarlingReady():void {
			state = new GameState();
		}
	}
}

