package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxStarField.FlxStarField2D;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxShakeEffect;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxSpriteUtil;

class PlayState extends FlxState {
    static inline var SHIP_SIZE:Int = 32;
    static inline var SHIP_Y_POS:Float = 0.85;
    static inline var SHIP_X_SPEED:Int = 500;
    static inline var SHIP_COLOR:FlxColor = FlxColor.WHITE;
    
    static inline var HOLE_MIN_WIDTH:Int = SHIP_SIZE * 3;
    static inline var HOLE_MAX_WIDTH:Int = SHIP_SIZE * 5;
    static inline var BARRIER_HEIGHT:Int = SHIP_SIZE;
    static inline var BARRIER_MIN_GAP:Int = SHIP_SIZE * 6;
    static inline var BARRIER_MAX_GAP:Int = SHIP_SIZE * 10;
    static inline var BARRIER_COLOR:FlxColor = FlxColor.GRAY;
    static inline var BARRIER_SPEED_INCREMENT:Int = 10;
    
    private var BARRIER_Y_SPEED:Int = 200;
    
    private var barrierEmit:FlxSignal;
    private var barrierEmitPosition:Int;
    private var scoreUI:FlxText;
    private var scoreEffect:FlxEffectSprite;
    private var scoreShake:FlxShakeEffect;
    
    private var jetEmitter:FlxEmitter;
    
    private var ship:FlxSprite;
    private var barriers:FlxTypedGroup<FlxTypedSpriteGroup<FlxSprite>>;
    private var score:Int = -1;
    
    override public function create() {
        super.create();
        
        var sf = new FlxStarField2D(0, 0, FlxG.width, FlxG.height, 128);
        sf.starVelocityOffset.set(0, 1);
        add(sf);
        
        // create ship jetstream
        jetEmitter = new FlxEmitter(0, 0, 32);
        jetEmitter.makeParticles(4, 4, FlxColor.WHITE, 32);
        jetEmitter.setSize(8, 8);
        jetEmitter.alpha.set(1, 1, 0, 0);
        jetEmitter.color.set(FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.GRAY, FlxColor.BLACK);
        jetEmitter.angularVelocity.set(-180, 180, -90, 90);
        jetEmitter.launchAngle.set(85, 95);
        jetEmitter.lifespan.set(0.5, 0.75);
        add(jetEmitter);
        jetEmitter.start(false, 0.025);
        
        // create ship
        ship = new FlxSprite(FlxG.width / 2, FlxG.height * SHIP_Y_POS);
        ship.makeGraphic(SHIP_SIZE, SHIP_SIZE, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawTriangle(ship, 0, 0, SHIP_SIZE, SHIP_COLOR);
        add(ship);
        
        // create barriers
        barriers = new FlxTypedGroup<FlxTypedSpriteGroup<FlxSprite>>();
        barrierEmit = new FlxSignal(); // create barrier emitter to create a new barrier row
        barrierEmit.add(emitBarrier); // set up callback
        emitBarrier(); // create the first row that descends
        add(barriers);
        
        // create UI
        scoreUI = new FlxText(0, SHIP_SIZE, -1, "", SHIP_SIZE);
        scoreUI.alignment = CENTER;
        // add(scoreUI);
        add(scoreEffect = new FlxEffectSprite(scoreUI));
        scoreEffect.y = SHIP_SIZE;
        scoreShake = new FlxShakeEffect();
        scoreEffect.effects.push(scoreShake);
        
        updateScore();
    }
    
    override public function update(elapsed:Float) {
        super.update(elapsed); // game tick
        
        handleShipMovement(); // move the ship
        checkBarrierAlive(); // kill barriers that fall off the screen and increment score
        checkEmitBarrier(); // should we emit a barrier?
        
        FlxG.collide(ship, barriers, gameOver); // player collides with barriers for game over
    }
    
    private function gameOver(s:FlxSprite, b:FlxTypedSpriteGroup<FlxSprite>) {
        // make an explosion!
        var explosion = new FlxEmitter(0, 0, 256);
        explosion.makeParticles(4, 4, FlxColor.WHITE, 256);
        explosion.setSize(SHIP_SIZE / 2, SHIP_SIZE / 2);
        explosion.alpha.set(1, 1, 0.5, 0.5);
        explosion.angularVelocity.set(-180, 180, -90, 90);
        explosion.lifespan.set(0.25, 0.75);
        add(explosion);
        
        explosion.focusOn(ship); // center it on the ship
        FlxG.camera.shake(0.025, 0.5, null, false, FlxAxes.XY); // shake the screen
        ship.kill(); // kill the ship
        jetEmitter.kill(); // stop the jet stream
        explosion.start(); // boom!
        
        FlxG.camera.fade(FlxColor.BLACK, 1, false, function() {
            FlxG.switchState(new GameOverState(score));
        });
    }
    
    private function updateScore() {
        score++; // increment the score
        scoreUI.text = Std.string(score); // update the text on screen
        scoreUI.screenCenter(FlxAxes.X); // center the text
        scoreEffect.screenCenter(FlxAxes.X);
    }
    
    private function handleShipMovement() {
        var left = FlxG.keys.anyPressed([LEFT, A]);
        var right = FlxG.keys.anyPressed([RIGHT, D]);
        
        // cancel out opposing movement
        if (left && right)
            left = right = false;
            
        // control ship
        if (left)
            ship.velocity.x = -SHIP_X_SPEED;
        else if (right)
            ship.velocity.x = SHIP_X_SPEED;
        else
            ship.velocity.x = 0;
            
        // wrap the x position on the screen edge
        FlxSpriteUtil.screenWrap(ship, true, true, false, false);
        
        if (jetEmitter.alive) {
            // jet stream follows
            jetEmitter.focusOn(ship);
            jetEmitter.y += SHIP_SIZE / 2;
        }
    }
    
    private function checkBarrierAlive() {
        // kill barriers that fall off the screen
        barriers.forEachAlive(function(barrier) {
            if (barrier.y >= FlxG.height) {
                scoreShake.start(true);
                updateScore(); // increment score
                BARRIER_Y_SPEED += BARRIER_SPEED_INCREMENT;
                barrier.destroy(); // destroy this barrier
            }
        });
    }
    
    private function checkEmitBarrier() {
        // should we emit a barrier?
        var newest = FlxG.height * 1.0;
        
        barriers.forEachAlive(function(barrier) {
            newest = Math.min(newest, barrier.y);
        });
        
        if (newest >= barrierEmitPosition)
            barrierEmit.dispatch();
    }
    
    private function createBarrierRow():FlxTypedSpriteGroup<FlxSprite> {
        var barrierRow = new FlxTypedSpriteGroup<FlxSprite>(2); // hold the whole row
        var holeWidth = FlxG.random.int(HOLE_MIN_WIDTH, HOLE_MAX_WIDTH); // width of the hole
        var holePosition:Int = FlxG.random.int(0, FlxG.width - holeWidth); // x position of the hole
        var barrierY:Float = -BARRIER_HEIGHT; // barrier should start above the screen
        barrierRow.y = barrierY; // set the entire row's position
        
        // left barrier
        var barrierLeft = new FlxSprite(0, barrierY);
        barrierLeft.makeGraphic(holePosition, BARRIER_HEIGHT, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRect(barrierLeft, 0, 0, barrierLeft.width, BARRIER_HEIGHT, BARRIER_COLOR);
        
        // right barrier
        var barrierRight = new FlxSprite(barrierLeft.width + holeWidth, barrierY);
        barrierRight.makeGraphic(Std.int(FlxG.width - barrierRight.width), BARRIER_HEIGHT, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRect(barrierRight, 0, 0, barrierRight.width, BARRIER_HEIGHT, BARRIER_COLOR);
        
        // barrier is solid
        barrierLeft.immovable = true;
        barrierRight.immovable = true;
        barrierRow.immovable = true;
        
        // add the two barriers to the row
        barrierRow.add(barrierLeft);
        barrierRow.add(barrierRight);
        
        // set up barrier movement
        barrierRow.velocity.y = BARRIER_Y_SPEED;
        
        return barrierRow;
    }
    
    private function emitBarrier() {
        // if (barriers.getFirstDead() !=)
        // emit a new barrier
        barriers.add(createBarrierRow());
        
        // set the position for this barrier when the next barrier will be emitted
        barrierEmitPosition = FlxG.random.int(BARRIER_MIN_GAP, BARRIER_MAX_GAP);
    }
}
