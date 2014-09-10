//
//  GameScene.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var world: World = World();
    var shape: SKShapeNode = SKShapeNode();
    var polyDrawer: PolyDrawer? = nil;
    
    required override init() {
        super.init();
    }
    
    required override init(size: CGSize) {
        super.init(size: size);
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        self.polyDrawer = PolyDrawer(scene: self);
    }
    
    // The last update time interval tick. Used to calculate a delta time (time difference) between frames
    private var _lastUpdateTimeInterval: NSTimeInterval = 0;
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!";
        myLabel.fontSize = 65;
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        self.addChild(myLabel)
        
        var vec = toWorldCoords(Vector2(550, 400) / 2);
        
        createBouncyBall(vec);
        
        for i in 0..<6
        {
            var v = vec + Vector2(CGFloat(i - 3), CGFloat(2 + i * 1));
            
            createBouncyBall(v);
        }
        
        var box = ClosedShape();
        box.begin();
        box.addVertex(Vector2(-5,  1));
        box.addVertex(Vector2( 5,  1));
        box.addVertex(Vector2( 5, -1));
        box.addVertex(Vector2(-5, -1));
        box.finish();
        
        var spring2 = Body(world: world, shape: box, pointMasses: [CGFloat.infinity], position: toWorldCoords(Vector2(550 / 2, 150)));
        
        self.addChild(shape);
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            
            let vecLoc = toWorldCoords(Vector2(location.x, location.y));
            
            createBouncyBall(vecLoc);
        }
    }
    
    func createBouncyBall(pos: Vector2)
    {
        // Create the closed shape for the player's physics body
        var def: CGFloat = 12;
        var ball = ClosedShape();
        ball.begin();
        for var n: CGFloat = 0; n < CGFloat(M_PI * 2); n += CGFloat(M_PI * 2) / def
        {
            ball.addVertex(Vector2(cos(-n), sin(-n)));
        }
        ball.transformOwn(0, localScale: Vector2(0.3, 0.3));
        ball.finish();
        
        var spring = Body(world: world, shape: ball, pointMasses: [0.5], position: pos, components: [SpringComponentCreator(shapeMatchingOn: false, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 10, shapeSpringDamp: 20), PressureComponentCreator(gasAmmount: 90), GravityComponentCreator()])
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval)
    {
        /* Called before each frame is rendered */
        for _ in 0..<5
        {
            world.update(1.0 / 200);
        }
        
        self.polyDrawer?.reset();
        
        for body in world.bodies
        {
            drawBody(body, shape: shape);
        }
        
        self.polyDrawer?.flushPolys();
    }
    
    func drawBody(body: Body, shape: SKShapeNode)
    {
        var shapePoints = body.pointMasses;
        var points = [CGPoint]();
        
        for i in 0..<shapePoints.count
        {
            let vec = toScreenCoords(shapePoints[i].position);
            
            points += CGPoint(x: vec.X, y: vec.Y);
        }
        
        polyDrawer?.drawPoly(points, fillColor: 0xFFFFFFFF, strokeColor: 0xFF000000);
    }
    
    override func update(currentTime: NSTimeInterval)
    {
        // Handle time delta.
        // If we drop below 60fps, we still want everything to move the same distance.
        var timeSinceLast = currentTime - self._lastUpdateTimeInterval;
        self._lastUpdateTimeInterval = currentTime;
        
        if (timeSinceLast > 1)
        {
            // more than a second since last update
            timeSinceLast = 1.0 / 60.0;
            self._lastUpdateTimeInterval = currentTime;
        }
        
        self.updateWithTimeSinceLastUpdate(timeSinceLast);
    }
}
