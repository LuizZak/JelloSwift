//
//  DemoViewController.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 05/04/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import UIKit

class DemoViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var demo = DemoView(frame: self.view.frame);
        view.addSubview(demo);
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class DemoView: UIView
{
    var world: World = World();
    var timer: CADisplayLink! = nil;
    var polyDrawer: PolyDrawer;
    
    var inputMode: InputMode = InputMode.DragBody;
    
    // The current point being dragged around
    var draggingPoint: PointMass? = nil;
    
    // The location of the user's finger, in physics world coordinates
    var fingerLocation: Vector2 = Vector2.Zero;
    
    var physicsTimeLabel: UILabel;
    var renderTimeLabel: UILabel;
    
    override init(frame: CGRect)
    {
        polyDrawer = PolyDrawer();
        
        physicsTimeLabel = UILabel();
        renderTimeLabel = UILabel();
        
        super.init(frame: frame);
        
        initLabels();
        
        // Do any additional setup after loading the view.
        timer = CADisplayLink(target: self, selector: Selector("gameLoop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        initializeLevel();
        
        renderingOffset = Vector2(300, frame.size.height);
        renderingScale = Vector2(renderingScale.X, -renderingScale.Y);
        
        opaque = false;
        backgroundColor = UIColor(white: 0.7, alpha: 1);
    }

    required init(coder aDecoder: NSCoder)
    {
        polyDrawer = PolyDrawer();
        
        physicsTimeLabel = UILabel();
        renderTimeLabel = UILabel();
        
        super.init(coder: aDecoder);
        
        initLabels();
    }
    
    func initLabels()
    {
        physicsTimeLabel.frame = CGRect(x: 20, y: 20, width: 300, height: 20);
        renderTimeLabel.frame = CGRect(x: 20, y: 37, width: 300, height: 20);
        
        addSubview(physicsTimeLabel);
        addSubview(renderTimeLabel);
    }
    
    func initializeLevel()
    {
        var size = self.frame.size;
        
        // Create basic shapes
        var vec = toWorldCoords(Vector2(size.width, 400) / 2);
        
        createBouncyBall(vec);
        
        for i in 0..<6
        {
            var v = vec + Vector2(CGFloat(i - 3), CGFloat(2 + i * 1));
            
            createBouncyBall(v);
        }
        
        // Create a few pinned bodies
        let pb1 = createBouncyBall(toWorldCoords(Vector2(size.width * 0.2, size.height / 2)), pinned: true, radius: 3);
        let pb2 = createBouncyBall(toWorldCoords(Vector2(size.width * 0.8, size.height / 2)), pinned: true, radius: 3);
        pb1.getComponentType(SpringComponent)?.setShapeMatchingConstants(200, 10);
        pb2.getComponentType(SpringComponent)?.setShapeMatchingConstants(200, 10);
        
        // Create some free boxes around the level
        createBox(toWorldCoords(Vector2(size.width / 2, size.height / 3)), size: Vector2(1, 1));
        createBox(toWorldCoords(Vector2(size.width * 0.4, size.height / 3)), size: Vector2(1, 1));
        var box3 = createBox(toWorldCoords(Vector2(size.width * 0.6, size.height / 3)), size: Vector2(1, 1));
        
        // Lock the rotation of the third box
        box3.freeRotate = false;
        
        // Create a pinned box in the middle of the level
        let pinnedBox = createBox(toWorldCoords(Vector2(size.width / 2, size.height / 2)), size: Vector2(1, 1), pinned: true);
        // Increase the velocity damping of the pinned box so it doesn't jiggles around nonstop
        pinnedBox.velDamping = 0.99;
        
        // Create two kinematic boxes
        createBox(toWorldCoords(Vector2(size.width * 0.3, size.height / 2)), size: Vector2(2, 2), kinematic: true);
        createBox(toWorldCoords(Vector2(size.width * 0.7, size.height / 2)), size: Vector2(2, 2), kinematic: true);
        
        // Create a few structures to showcase the joints feature
        createLinkedBouncyBalls(toWorldCoords(Vector2(size.width / 2, size.height * 0.65)));

        createBallBoxLinkedStructure(toWorldCoords(Vector2(size.width * 0.8, size.height * 0.8)));
        createScaleStructure(toWorldCoords(Vector2(size.width * 0.4, size.height * 0.8)));
        createCarStructure(toWorldCoords(Vector2(size.width * 0.55, size.height * 0.8)));
        createBox(toWorldCoords(Vector2(size.width * 0.6, size.height * 0.7)), size: Vector2(4, 0.5), isStatic: true, angle: -0.1);
        
        // Create the ground box
        var box = ClosedShape();
        box.begin();
        box.addVertex(Vector2(-10,   1));
        box.addVertex(Vector2( 0,  0.6)); // A little inward slope
        box.addVertex(Vector2( 10,   1));
        box.addVertex(Vector2( 10,  -1));
        box.addVertex(Vector2(-10,  -1));
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
                let location = touch.locationInView(self)
                
                let vecLoc = toWorldCoords(Vector2(location.x, location.y));
                
                createBouncyBall(vecLoc);
            }
        }
        else if(inputMode == InputMode.DragBody)
        {
            // Select the closest point-mass to drag
            let touch: AnyObject = touches.first!;
            let location = touch.locationInView(self);
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
        let location = touch.locationInView(self);
        fingerLocation = toWorldCoords(Vector2(location.x, location.y));
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        // Reset dragging point
        draggingPoint = nil;
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
        autoreleasepool {
            self.render();
        }
    }
    
    func update()
    {
        let sw = Stopwatch();
        
        updateWithTimeSinceLastUpdate(1.0 / 60);
        
        physicsTimeLabel.text = String(format: "Physics update time: %0.2lfms", round(sw.stop() * 1000 * 20) / 20);
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
    }
    
    // Updates the dragging functionality
    func updateDrag()
    {
        // Dragging point
        if let p = draggingPoint where inputMode == InputMode.DragBody
        {
            var spring = calculateSpringForce(p.position, p.velocity, fingerLocation, Vector2.Zero, 0, 700, 20);
            
            p.applyForce(spring);
        }
    }
    
    func render()
    {
        let sw = Stopwatch();
        
        var context = UIGraphicsGetCurrentContext();
        
        self.polyDrawer.reset();
        
        for joint in world.joints
        {
            drawJoint(joint);
        }
        for body in world.bodies
        {
            drawBody(body);
        }
        
        drawDrag(context);
        
        polyDrawer.renderOnContext(context);
        polyDrawer.reset();
        
                                                           //  VVVVVV  AIN'T GOT NO TIME TO DYNAMICALLY ALIGN, BABEY!
        renderTimeLabel.text = String(format: "Render time:              %0.2lfms", round(sw.stop() * 1000 * 20) / 20);
    }
    
    func gameLoop()
    {
        self.update();
        self.setNeedsDisplay();
    }
    
    /// Renders the dragging shape line
    func drawDrag(context: CGContextRef)
    {
        // Dragging point
        if let p = draggingPoint where inputMode == InputMode.DragBody
        {
            // Create the path to draw
            var lineStart = toScreenCoords(p.position);
            var lineEnd = toScreenCoords(fingerLocation);
            
            let points = [CGPoint(vec: lineStart), CGPoint(vec: lineEnd)];
            
            polyDrawer.queuePoly(points, fillColor: 0xFFFFFFFF, strokeColor: 0xFF00DD00);
        }
    }
    
    func drawJoint(joint: BodyJoint)
    {
        let start = toScreenCoords(joint.bodyLink1.position);
        let end = toScreenCoords(joint.bodyLink2.position);
        
        let points = [CGPoint(vec: start), CGPoint(vec: end)];
        
        polyDrawer.queuePoly(points, fillColor: 0xFFFFFFFF, strokeColor: joint.enabled ? 0xFFEEEEEE : 0xFFCCCCCC);
    }
    
    func drawBody(body: Body)
    {
        var shapePoints = body.vertices;
        
        let points = shapePoints.map { CGPoint(vec: toScreenCoords($0)) };
        
        // Draw normals, for pressure bodies
        if let pComp = body.getComponentType(PressureComponent)
        {
            for (i, p) in enumerate(shapePoints)
            {
                let s = CGPoint(vec: toScreenCoords(p));
                let e = CGPoint(vec: toScreenCoords(p + pComp.normalList[i] / 3));
                polyDrawer.queuePoly([s, e], fillColor: 0, strokeColor: 0xFFEC33EC, lineWidth: 1);
            }
        }
        
        // Draw the body's global shape
        polyDrawer.queuePoly(body.globalShape.map { CGPoint(vec: toScreenCoords($0)) }, fillColor: 0x33FFFFFF, strokeColor: 0xFF777777, lineWidth: 1);
        
        // Draw lines going from the body's outer points to the global shape indices
        for (i, p) in enumerate(points)
        {
            let start = p;
            let end = CGPoint(vec: toScreenCoords(body.globalShape[i]));
            
            polyDrawer.queuePoly([start, end], fillColor: 0, strokeColor: 0xFF449944, lineWidth: 1);
        }
        
        // Draw the body now
        polyDrawer.queuePoly(points, fillColor: 0xADFFFFFF, strokeColor: 0xFF000000);
        
        // Draw the body axis
        let axisUp    = [body.derivedPos, body.derivedPos + rotateVector(Vector2(0, 0.6), body.derivedAngle)];
        let axisRight = [body.derivedPos, body.derivedPos + rotateVector(Vector2(0.6, 0), body.derivedAngle)];
        
        let axisUpCg = axisUp.map { CGPoint(vec: toScreenCoords($0)) };
        let axisRightCg = axisRight.map { CGPoint(vec: toScreenCoords($0)) };
        
        polyDrawer.queuePoly(axisUpCg, fillColor: 0xFFFFFFFF, strokeColor: 0xFFED0000, lineWidth: 1);
        polyDrawer.queuePoly(axisRightCg, fillColor: 0xFFFFFFFF, strokeColor: 0xFF00ED00, lineWidth: 1);
    }
    
    /// Creates a box at the specified world coordinates with the specified size
    func createBox(pos: Vector2, size: Vector2, pinned: Bool = false, kinematic: Bool = false, isStatic: Bool = false, angle: CGFloat = 0, mass: CGFloat = 0.5) -> Body
    {
        // Create the closed shape for the box's physics body
        var shape = ClosedShape();
        shape.begin();
        shape.addVertex(Vector2(-size.X,  size.Y));
        shape.addVertex(Vector2( size.X,  size.Y));
        shape.addVertex(Vector2( size.X, -size.Y));
        shape.addVertex(Vector2(-size.X, -size.Y));
        shape.finish();
        
        shape.transformOwn(angle, localScale: Vector2.One);
        
        var comps = [BodyComponentCreator]();
        
        // Add a spring body component - spring bodies have string physics that attract the inner points, it's one of the
        // forces that holds a body together
        comps += SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 100, shapeSpringDamp: 60);
        
        if(!pinned)
        {
            // Add a gravity component that will pull the body down
            comps += GravityComponentCreator();
        }
        
        let body = Body(world: world, shape: shape, pointMasses: [isStatic ? CGFloat.infinity : mass], kinematic: kinematic, position: pos, components: comps)
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
    func createBouncyBall(pos: Vector2, pinned: Bool = false, kinematic: Bool = false, radius: CGFloat = 1, mass: CGFloat = 0.5, def: Int = 12) -> Body
    {
        // Create the closed shape for the ball's physics body
        var shape = ClosedShape();
        shape.begin();
        for i in 0..<def
        {
            var n = CGFloat(PI * 2) * (CGFloat(i) / CGFloat(def));
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
        let b1 = createBouncyBall(pos - Vector2(0, 2), pinned: false, kinematic: false, radius: 1, mass: 1);
        let b2 = createBox(pos, size: Vector2(1, 1), pinned: true, kinematic: false, mass: 1);
        
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
    
    /// Creates a car structure
    func createCarStructure(pos: Vector2)
    {
        let carShape = ClosedShape();
        
        // Add the car shape vertices
        carShape.begin();
        
        // Points created in an external editor tool
        carShape.addVertex(x: -0.7937825232354604, y: -0.30250560258972364)
        carShape.addVertex(x: -1.336418182150189,  y: 0.09174228082403624)
        carShape.addVertex(x: -2.007152743584187,  y: 0.09174228082403624)
        carShape.addVertex(x: -2.549788402498916,  y: -0.30250560258972364)
        carShape.addVertex(x: -2.7570567806966455, y: -0.9404120779458979)
        carShape.addVertex(x: -4.144927650095719,  y: -0.9404120779458979)
        carShape.addVertex(x: -4.144927650095719,  y: 0.4418818905641408)
        carShape.addVertex(x: -2.982614013609058,  y: 1.4496338285486368)
        carShape.addVertex(x: -1.2336781172394489, y: 1.8443237218438626)
        carShape.addVertex(x: 1.2758186165123433,  y: 1.8443237218438626)
        carShape.addVertex(x: 3.1062068496621604,  y: 0.6077200296906478)
        carShape.addVertex(x: 4.693548953434301,   y: 0.29764251031080285)
        carShape.addVertex(x: 4.422231123976936,   y: -0.9404120779458979)
        carShape.addVertex(x: 2.59178042860568,    y: -0.9404120779458979)
        carShape.addVertex(x: 2.3845120315923336,  y: -0.3025056116022918)
        carShape.addVertex(x: 1.8418764096417257,  y: 0.09174231580466982)
        carShape.addVertex(x: 1.1711418119107195,  y: 0.09174231580466982)
        carShape.addVertex(x: 0.6285061899601116,  y: -0.3025056116022918)
        carShape.addVertex(x: 0.42123779294676533, y: -0.9404120779458979)
        carShape.addVertex(x: -0.5865141450377307, y: -0.9404120779458979)
        
        // Scale down
        carShape.transformOwn(0, localScale: Vector2(0.65, 0.65));
        carShape.finish(recenter: true);
        
        let bodyOffset = Vector2(0, 0.4);
        
        let carBody = Body(world: world, shape: carShape, pointMasses: [0.7], position: pos + bodyOffset, angle: 0, scale: Vector2.One, kinematic: false, components: [SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 300, edgeSpringDamp: 30, shapeSpringK: 600, shapeSpringDamp: 30), GravityComponentCreator()]);
        
        let leftWheel  = createBouncyBall(carBody.derivedPos + rotateVector(Vector2(-1.1, -0.5) - bodyOffset, carBody.derivedAngle), pinned: false, kinematic: false, radius: 0.5, mass: 0.5);
        let rightWheel = createBouncyBall(carBody.derivedPos + rotateVector(Vector2( 1.1, -0.5) - bodyOffset, carBody.derivedAngle), pinned: false, kinematic: false, radius: 0.5, mass: 0.5);
        
        // Create the left wheel constraint
        let ljWheel = BodyJointLink(body: leftWheel);
        let ljCar = ShapeJointLink(body: carBody, pointMassIndexes: [19, 0, 1, 2, 3, 4]);
        ljCar.offset = Vector2(0, -0.6);
        
        let leftJoint = SpringBodyJoint(world: world, link1: ljWheel, link2: ljCar, springK: 100, springD: 15, distance: 0);
        leftJoint.allowCollisions = true;
        
        let rjWheel = BodyJointLink(body: rightWheel);
        let rjCar = ShapeJointLink(body: carBody, pointMassIndexes: [13, 14, 15, 16, 17, 18]);
        rjCar.offset = Vector2(0, -0.6);
        
        let rightJoint = SpringBodyJoint(world: world, link1: rjWheel, link2: rjCar, springK: 100, springD: 15, distance: 0);
        rightJoint.allowCollisions = true;
        
    }
}

/// Enum used to modify the input mode of the test simulation
enum InputMode: Int
{
    /// Creates a jiggly ball under the finger on tap
    case CreateBall
    /// Allows dragging bodies around
    case DragBody
}

class Stopwatch
{
    var startTime:CFAbsoluteTime;
    var endTime:CFAbsoluteTime?;
    
    init()
    {
        startTime = CFAbsoluteTimeGetCurrent();
    }
    
    func start()
    {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> CFAbsoluteTime
    {
        endTime = CFAbsoluteTimeGetCurrent()
        
        return duration!
    }
    
    var duration:CFAbsoluteTime?
    {
        if let endTime = endTime
        {
            return endTime - startTime
        }
        else
        {
            return nil
        }
    }
}