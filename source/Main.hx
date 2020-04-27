package;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.display.Sprite;

class Main extends Sprite {
    var gameWidth:Int = 375;
    var gameHeight:Int = 812;
    var initialState:Class<FlxState> = PlayState;
    var zoom:Float = 1;
    var framerate:Int = 60;
    var skipSplash:Bool = true;
    var startFullscreen:Bool = false;
    
    public function new() {
        super();
        addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));
    }
}
