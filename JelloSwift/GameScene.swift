//
//  GameScene.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import SpriteKit

/// Enum used to modify the input mode of the test simulation
enum InputMode: Int
{
    /// Creates a jiggly ball under the finger on tap
    case CreateBall
    /// Allows dragging bodies around
    case DragBody
}

class GameScene: SKScene
{
    var world: World = World();
    var polyDrawer: PolyDrawer? = nil;
    
    var inputMode: InputMode = InputMode.DragBody;
    
    // The current point being dragged around
    var draggingPoint: PointMass? = nil;
    
    // The location of the user's finger, in physics world coordinates
    var fingerLocation: Vector2 = Vector2.Zero;
    
    // Shape node used to display the dragging of a body
    var dragShape: SKShapeNode = SKShapeNode();
    
    required override init()
    {
        super.init();
    }
    
    required override init(size: CGSize)
    {
        super.init(size: size);
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder);
        self.polyDrawer = PolyDrawer(scene: self);
    }
    
    // The last update time interval tick. Used to calculate a delta time (time difference) between frames
    private var _lastUpdateTimeInterval: NSTimeInterval = 0;
    
    override func didMoveToView(view: SKView)
    {
        initializeLevel();
    }
    
    func initializeLevel()
    {
        // Create the drag shape
        dragShape.lineWidth = 2;
        dragShape.strokeColor = SKColor.blackColor();
        dragShape.lineCap = kCGLineCapRound;
        
        addChild(dragShape);
        
        // Create basic shapes
        var vec = toWorldCoords(Vector2(size.width, 400) / 2);
        
        createBouncyBall(vec);
        
        for i in 0..<6
        {
            var v = vec + Vector2(CGFloat(i - 3), CGFloat(2 + i * 1));
            
            createBouncyBall(v);
        }
        
        // Create a few pinned bodies
        createBouncyBall(toWorldCoords(Vector2(size.width * 0.2, size.height / 2)), pinned: true, radius: 3);
        createBouncyBall(toWorldCoords(Vector2(size.width * 0.8, size.height / 2)), pinned: true, radius: 3);
        
        // Create some free boxes around the level
        createBox(toWorldCoords(Vector2(size.width / 2, size.height / 3)), size: Vector2(1, 1));
        createBox(toWorldCoords(Vector2(size.width * 0.4, size.height / 3)), size: Vector2(1, 1));
        var box3 = createBox(toWorldCoords(Vector2(size.width * 0.6, size.height / 3)), size: Vector2(1, 1));
        
        // Lock the rotation of the third box
        box3.freeRotate = false;
        
        // Create a pinned box in the middle of the level
        var pinnedBox = createBox(toWorldCoords(Vector2(size.width / 2, size.height / 2)), size: Vector2(1, 1), pinned: true);
        // Increase the velocity damping of the pinned box so it doesn't jiggles around nonstop
        pinnedBox.velDamping = 0.99;
        
        // Create two kinematic boxes
        createBox(toWorldCoords(Vector2(size.width * 0.3, size.height / 2)), size: Vector2(2, 2), kinematic: true);
        createBox(toWorldCoords(Vector2(size.width * 0.7, size.height / 2)), size: Vector2(2, 2), kinematic: true);
        
        // Create a few structures to showcase the joints feature
        createLinkedBouncyBalls(toWorldCoords(Vector2(size.width / 2, size.height * 0.65)));
        createBallBoxLinkedStructure(toWorldCoords(Vector2(size.width * 0.8, size.height * 0.8)));
        createScaleStructure(toWorldCoords(Vector2(size.width * 0.4, size.height * 0.8)));
        
        // Create the ground box
        var box = ClosedShape();
        box.begin();
        box.addVertex(Vector2(-10,  1));
        box.addVertex(Vector2( 0,  0.6)); // A little inward slope
        box.addVertex(Vector2( 10,  1));
        box.addVertex(Vector2( 10, -1));
        box.addVertex(Vector2(-10, -1));
        box.finish();
        
        var platform = Body(world: world, shape: box, pointMasses: [CGFloat.infinity], position: toWorldCoords(Vector2(size.width / 2, 150)));
        platform.isStatic = true;
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        /* Called when a touch begins */
        if(inputMode == InputMode.CreateBall)
        {
            for touch: AnyObject in touches
            {
                let location = touch.locationInNode(self)
                
                let vecLoc = toWorldCoords(Vector2(location.x, location.y));
                
                createBouncyBall(vecLoc);
            }
        }
        else if(inputMode == InputMode.DragBody)
        {
            // Select the closest point-mass to drag
            let touch: AnyObject = touches.first!;
            let location = touch.locationInNode(self);
            fingerLocation = toWorldCoords(Vector2(location.x, location.y));
            
            var closest: PointMass? = nil;
            var closestD: CGFloat = CGFloat.max;
            
            for body in world.bodies
            {
                for p in body.pointMasses
                {
                    var dist = p.position.distanceTo(fingerLocation);
                    if(closest == nil || dist < closestD)
                    {
                        closest = p;
                        closestD = dist;
                    }
                }
            }
            
            draggingPoint = closest;
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        let touch: AnyObject = touches.first!;
        let location = touch.locationInNode(self);
        fingerLocation = toWorldCoords(Vector2(location.x, location.y));
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        // Reset dragging point
        draggingPoint = nil;
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
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval)
    {
        /* Called before each frame is rendered */
        
        updateDrag();
        
        // Update the physics world
        for _ in 0..<5
        {
            world.update(1.0 / 200);
        }
        
        self.polyDrawer?.reset();
        
        for joint in world.joints
        {
            drawJoint(joint);
        }
        for body in world.bodies
        {
            drawBody(body);
        }
        
        self.polyDrawer?.renderPolys();
        
        // Draw the drag line
        drawDrag();
    }
    
    // Updates the dragging functionality
    func updateDrag()
    {
        // Dragging point
        if let p = draggingPoint where inputMode == InputMode.DragBody
        {
            var spring = calculateSpringForce(p.position, p.velocity, fingerLocation, Vector2.Zero, 0, 300, 20);
            
            p.applyForce(spring);
        }
    }
    
    /// Renders the dragging shape line
    func drawDrag()
    {
        // Dragging point
        if let p = draggingPoint where inputMode == InputMode.DragBody
        {
            // Create the path to draw
            var lineStart = toScreenCoords(p.position);
            var lineEnd = toScreenCoords(fingerLocation);
            
            var path = CGPathCreateMutable();
            
            CGPathMoveToPoint(path, nil, lineStart.X, lineStart.Y);
            CGPathAddLineToPoint(path, nil, lineEnd.X, lineEnd.Y);
            
            dragShape.path = path;
            
            dragShape.hidden = false;
        }
        else
        {
            dragShape.hidden = true;
        }
    }
    
    func drawJoint(joint: BodyJoint)
    {
        let start = toScreenCoords(joint.bodyLink1.position);
        let end = toScreenCoords(joint.bodyLink2.position);
        
        let points = [CGPoint(v: start),
                      CGPoint(v: end)];
        
        polyDrawer?.queuePoly(points, fillColor: 0xFFFFFFFF, strokeColor: 0xFFEEEEEE);
    }
    
    func drawBody(body: Body)
    {
        var shapePoints = body.pointMasses;
        var points = [CGPoint](count: shapePoints.count, repeatedValue: CGPoint());
        
        for i in 0..<shapePoints.count
        {
            let vec = toScreenCoords(shapePoints[i].position);
            
            points[i] = CGPoint(x: vec.X, y: vec.Y);
        }
        
        polyDrawer?.queuePoly(points, fillColor: 0xFFFFFFFF, strokeColor: 0xFF000000);
    }
    
    /// Creates a box at the specified world coordinates with the specified size
    func createBox(pos: Vector2, size: Vector2, pinned: Bool = false, kinematic: Bool = false) -> Body
    {
        // Create the closed shape for the box's physics body
        var shape = ClosedShape();
        shape.begin();
        shape.addVertex(Vector2(-size.X,  size.Y));
        shape.addVertex(Vector2( size.X,  size.Y));
        shape.addVertex(Vector2( size.X, -size.Y));
        shape.addVertex(Vector2(-size.X, -size.Y));
        shape.finish();
        
        var comps = [BodyComponentCreator]();
        
        // Add a spring body component - spring bodies have string physics that attract the inner points, it's one of the
        // forces that holds a body together
        comps += SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 100, shapeSpringDamp: 60);
        
        if(!pinned)
        {
            // Add a gravity component taht will pull the body down
            comps += GravityComponentCreator();
        }
        
        let body = Body(world: world, shape: shape, pointMasses: [0.5], kinematic: kinematic, position: pos, components: comps)
        body.isPined = pinned;
        
        // In order to have the box behave correctly, we need to add some internal springs to the body
        let springComp = body.getComponentType(SpringComponent);
        
        // The two first arguments are the indexes of the point masses to link, the next two are the spring constants,
        // and the last one is the distance the spring will try to mantain the two point masses at.
        // Specifying the distance as -1 sets it as the current distance between the specified point masses
        springComp?.addInternalSpring(0, pointB: 2, springK: 100, damping: 10, dist: -1);
        springComp?.addInternalSpring(1, pointB: 3, springK: 100, damping: 10, dist: -1);
        
        return body;
    }
    
    /// Creates a bouncy ball at the specified world coordinates
    func createBouncyBall(pos: Vector2, pinned: Bool = false, kinematic: Bool = false, radius: CGFloat = 1, mass: CGFloat = 0.5) -> Body
    {
        // Create the closed shape for the ball's physics body
        var def: CGFloat = 12;
        var shape = ClosedShape();
        shape.begin();
        for var n: CGFloat = 0; n < CGFloat(M_PI * 2); n += CGFloat(M_PI * 2) / def
        {
            shape.addVertex(Vector2(cos(-n) * radius, sin(-n) * radius));
        }
        shape.transformOwn(0, localScale: Vector2(0.3, 0.3));
        shape.finish();
        
        var comps = [BodyComponentCreator]();
        
        // Add a spring body component - spring bodies have string physics that attract the inner points, it's one of the
        // forces that holds a body together
        comps += SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 10, shapeSpringDamp: 20);
        
        // Add a pressure component - pressure applies an outwards-going force that basically
        // tries to expand the body as if filled with air, like a balloon
        comps += PressureComponentCreator(gasAmmount: 90);
        
        // Add a gravity component taht will pull the body down
        comps += GravityComponentCreator();
        
        var body = Body(world: world, shape: shape, pointMasses: [mass], kinematic: kinematic, position: pos, components: comps)
        
        body.isPined = pinned;
        
        return body;
    }
    
    /// Creates two linked bouncy balls in a given position in the world
    func createLinkedBouncyBalls(pos: Vector2)
    {
        let b1 = createBouncyBall(pos - Vector2(1, 0), pinned: false, kinematic: false, radius: 1);
        let b2 = createBouncyBall(pos + Vector2(1, 0), pinned: false, kinematic: false, radius: 1);
        
        // Create the joint links
        let l1 = BodyJointLink(body: b1);
        let l2 = BodyJointLink(body: b2);
        
        SpringBodyJoint(world: world, link1: l1, link2: l2, springK: 100, springD: 20);
    }
    
    /// Creates a pinned box with a ball attached to one of its edges
    func createBallBoxLinkedStructure(pos: Vector2)
    {
        let b1 = createBouncyBall(pos - Vector2(0, 2), pinned: false, kinematic: false, radius: 1);
        let b2 = createBox(pos, size: Vector2(1, 1), pinned: true, kinematic: false);
        
        // Create the joint links
        let l1 = BodyJointLink(body: b1);
        let l2 = EdgeJointLink(body: b2, edgeIndex: 2, edgeRatio: 0.5);
        
        SpringBodyJoint(world: world, link1: l1, link2: l2, springK: 100, springD: 20);
    }
    
    /// Creates a pinned box with two balls attached to one of its edges
    func createScaleStructure(pos: Vector2)
    {
        let b1 = createBox(pos, size: Vector2(2, 1), pinned: true, kinematic: false);
        let b2 = createBouncyBall(pos + Vector2(-1.2, -2), pinned: false, kinematic: false, radius: 1);
        let b3 = createBouncyBall(pos + Vector2( 1.2, -2), pinned: false, kinematic: false, radius: 1);
        
        // Create the joints that link the box with the left sphere
        let l1 = BodyJointLink(body: b2);
        let l2 = EdgeJointLink(body: b1, edgeIndex: 2, edgeRatio: 0.8);
        
        // Create the joints that link the box with the right sphere
        let l3 = BodyJointLink(body: b3);
        let l4 = EdgeJointLink(body: b1, edgeIndex: 2, edgeRatio: 0.2);
        
        // Create the joints
        let joint1 = SpringBodyJoint(world: world, link1: l1, link2: l2, springK: 10, springD: 2);
        let joint2 = SpringBodyJoint(world: world, link1: l3, link2: l4, springK: 40, springD: 5);
        
        // Enable collision between the bodies
        joint1.allowCollisions = true;
        joint2.allowCollisions = true;
    }
}