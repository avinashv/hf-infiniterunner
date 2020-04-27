package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class GameOverState extends FlxState {
    private var _score:Int;
    
    public function new(score:Int) {
        super();
        _score = score;
    }
    
    override public function create() {
        var scoreText = new FlxText(0, 0, -1, 'You crashed.\n\nScore: ' + _score, 32);
        scoreText.alignment = CENTER;
        scoreText.screenCenter();
        add(scoreText);
        
        super.create();
    }
    
    override public function update(elapsed:Float) {
        // return back to a fresh game state on any keypress
        if (FlxG.keys.pressed.ANY) {
            FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function() {
                FlxG.switchState(new PlayState());
            });
        }
    }
}
