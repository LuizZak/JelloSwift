import Foundation
import CoreGraphics
import JelloSwift
import simd

extension Vector2 {
    
    /// Helper post-fix alias for global function `toWorldCoords(self)`
    var inWorldCoords: Vector2 {
        return JelloSwift.toWorldCoords(self)
    }

    /// Helper post-fix alias for global function `toScreenCoords(self)`
    var inScreenCoords: Vector2 {
        return JelloSwift.toScreenCoords(self)
    }
    
    init(x: CGFloat, y: CGFloat) {
        self.init(x: x.native, y: y.native)
    }
}

protocol DemoSceneDelegate: class {
    func didUpdatePhysicsTimer(intervalCount: Int,
                               timeMilliRounded: TimeInterval,
                               fps: TimeInterval,
                               avgMilliRounded: TimeInterval)
    func didUpdateRenderTimer(timeMilliRounded: TimeInterval, fps: TimeInterval)
}

class DemoScene {
    weak var delegate: DemoSceneDelegate?
    
    var world = World()
    
    var boundsSize: CGSize
    
    /// Main OpenGL VAO in which all bodies will be rendered on
    var vertexBuffer: VertexBuffer
    
    var updateLabelStopwatch = Stopwatch(startTime: 0)
    var renderLabelStopwatch = Stopwatch(startTime: 0)
    var intervals: [CFAbsoluteTime] = []
    
    var viewportMatrix = Vector2.matrix(scalingBy: 1.0 / (renderingScale / 2), translatingBy: renderingOffset)
    let baseRenderingScale = Vector2(x: 25.8, y: 25.8)
    
    let labelUpdateInterval = 0.5
    
    var inputMode = InputMode.dragBody
    
    // The current point being dragged around
    var draggingPoint: (Body, Int)? = nil
    
    // The location of the user's finger, in physics world coordinates
    var pointerLocation = Vector2.zero
    
    /// Whether to perform a detailed render of the scene. Detailed rendering
    /// renders, along with the body shape, the body's normals, global shape and
    /// axis, and collision normals
    var useDetailedRender = true
    
    var collisions: [BodyCollisionInformation] = []
    
    init(boundsSize: CGSize, delegate: DemoSceneDelegate?) {
        self.boundsSize = boundsSize
        self.delegate = delegate
        vertexBuffer = VertexBuffer()
        renderingOffset = Vector2(x: 300, y: 384)
        renderingScale = baseRenderingScale
    }
    
    func update(timeSinceLastFrame: TimeInterval) {
        let sw = Stopwatch()
        
        updateWithTimeSinceLastUpdate(timeSinceLastFrame)
        
        let time = sw.stop() * 1000
        
        intervals.append(time)
        if intervals.count > 200 {
            intervals = Array(intervals.dropFirst(intervals.count - 200))
        }
        
        if let duration = updateLabelStopwatch.duration, duration > labelUpdateInterval {
            updateLabelStopwatch.reset()
            
            let timeMilli = time
            let timeMilliRounded = round(timeMilli * 100) / 100
            let fps = 1000 / timeMilliRounded
            
            let avgMilli = intervals.reduce(0, +) / CFAbsoluteTime(intervals.count)
            let avgMilliRounded = round(avgMilli * 100) / 100
            
            DispatchQueue.main.async {
                self.delegate?.didUpdatePhysicsTimer(intervalCount: self.intervals.count,
                                                     timeMilliRounded: timeMilliRounded,
                                                     fps: fps,
                                                     avgMilliRounded: avgMilliRounded)
            }
        }
    }
    
    func renderToVaoBuffer() {
        vertexBuffer.clearVertices()
        
        let sw = Stopwatch.startNew()
        
        world.joints.forEach(drawJoint)
        world.bodies.forEach(drawBody)
        
        // Render rays from ray bodies
        for body in world.bodies {
            guard let comp = body.component(ofType: BodyRayComponent.self) else {
                continue
            }
            
            for point in body.pointMasses {
                let vertex = point.position
                let normal = point.normal

                let start = vertex - normal * 0.1
                let end = vertex + normal * comp.rayLength

                let pt
                    = world.rayCast(from: start,
                                    to: end,
                                    ignoreTest: { [world] in $0 == body || (comp.ignoreJoinedBodies && world.areBodiesJoined(body, $0)) })?.retPt ?? end

                drawLine(from: vertex, to: pt, color: comp.color.toUIntARGB())
                drawCircle(center: pt, radius: 0.1, color: comp.color.toUIntARGB())
            }
        }
        
        drawDrag()
        
        if useDetailedRender {
            // Draw collisions
            for info in collisions {
                let pointB = info.hitPt
                let normal = info.normal
                
                drawLine(from: pointB, to: pointB + normal / 4, color: 0xFFFF0000)
            }
        }
        
        // Adjust viewport by the aspect ratio
        let viewportMatrix = matrixForOrthoProjection(width: boundsSize.width, height: boundsSize.height)
        
        // Matrix to transform JelloSwift's coordinates into proper coordinates
        // for OpenGL
        let mat = Vector2.matrix(scalingBy: renderingScale, rotatingBy: 0, translatingBy: renderingOffset)
        
        // Convert point to screen coordinates
        vertexBuffer.applyTransformation((mat * viewportMatrix).matrix4x4())
        
        collisions.removeAll(keepingCapacity: true)
        
        if let duration = renderLabelStopwatch.duration, duration > labelUpdateInterval {
            renderLabelStopwatch.reset()
            
            let time = round(sw.stop() * 1000 * 20) / 20
            let fps = 1000 / time
            
            delegate?.didUpdateRenderTimer(timeMilliRounded: time, fps: fps)
        }
    }
    
    func updateWithTimeSinceLastUpdate(_ timeSinceLast: CFTimeInterval) {
        /* Called before each frame is rendered */
        updateDrag()
        
        // Update the physics world
        for _ in 0..<5 {
            self.world.update(1.0 / 200)
        }
    }
    
    // Updates the dragging functionality
    func updateDrag() {
        // Dragging point
        guard let (body, pIndex) = draggingPoint, inputMode == InputMode.dragBody else {
            return
        }
        
        let p = body.pointMasses[pIndex]
        
        let dragForce = calculateSpringForce(posA: p.position, 
                                             velA: p.velocity, 
                                             posB: pointerLocation,
                                             velB: Vector2.zero,
                                             distance: 0, 
                                             springK: 700, 
                                             springD: 20)
        
        body.applyForce(dragForce, toPointMassAt: pIndex)
    }
    
    /// Enum used to modify the input mode of the test simulation
    enum InputMode: Int {
        /// Creates a jiggly ball under the finger on tap
        case createBall
        /// Allows dragging bodies around
        case dragBody
    }
}

// MARK: - Input
extension DemoScene {
    func touchDown(at screenPoint: Vector2) {
        let worldPoint = screenPoint.inWorldCoords
        
        /* Called when a touch begins */
        if inputMode == .createBall {
            createBouncyBall(worldPoint)
        } else if inputMode == .dragBody {
            // Select the closest point-mass to drag
            pointerLocation = worldPoint
            
            draggingPoint = world.closestPointMass(to: pointerLocation)
        }
    }
    
    func touchMoved(at screenPoint: Vector2) {
        let worldPoint = screenPoint.inWorldCoords
        
        pointerLocation = worldPoint
    }
    
    func touchEnded(at screenPoint: Vector2) {
        // Reset dragging point
        draggingPoint = nil
    }
}

extension DemoScene {
    func initializeLevel() {
        let size = CGSize(width: 1024, height: 768)
        
        // Create basic shapes
        let vec = (Vector2(x: size.width, y: 400) / 2).inWorldCoords
        
        // Add a Raycasting component
        createBouncyBall(vec).addComponent(ofType: BodyRayComponent.self)
        
        for i in 0..<6 {
            let v = vec + Vector2(x: CGFloat(i - 3), y: CGFloat(2 + i * 1))
            
            let ball = createBouncyBall(v)
            
            let color = Color(hue: CGFloat(i) / 6, saturation: 0.8, brightness: 0.9, alpha: CGFloat(0x7D) / 255)
            ball.objectTag = color
        }
        
        // Create a few pinned bodies
        let pb1 = createBouncyBall(Vector2(x: size.width * 0.2, y: size.height / 2).inWorldCoords, pinned: true, radius: 3)
        let pb2 = createBouncyBall(Vector2(x: size.width * 0.8, y: size.height / 2).inWorldCoords, pinned: true, radius: 3)
        pb1.component(ofType: SpringComponent.self)?.setShapeMatchingConstants(200, 10)
        pb2.component(ofType: SpringComponent.self)?.setShapeMatchingConstants(200, 10)
        
        pb1.objectTag = UInt(0x7DEFEF99)
        pb2.objectTag = UInt(0x7DEFEF99)
        
        // Create some free boxes around the level
        createBox(Vector2(x: size.width / 2, y: size.height / 3).inWorldCoords, size: .unit * 2)
        createBox(Vector2(x: size.width * 0.4, y: size.height / 3).inWorldCoords, size: .unit * 2)
        let nonRotatingBox = createBox(Vector2(x: size.width * 0.6, y: size.height / 3).inWorldCoords, size: .unit * 2)
        
        // Lock the rotation of the third box
        nonRotatingBox.freeRotate = false
        
        // Create a pinned box in the middle of the level
        let pinnedBox = createBox(Vector2(x: size.width / 2, y: size.height / 2).inWorldCoords, size: .unit * 2, pinned: true)
        // Increase the velocity damping of the pinned box so it doesn't jiggles around nonstop
        pinnedBox.velDamping = 0.99
        
        // Create two kinematic boxes
        let box1 = createBox(Vector2(x: size.width * 0.3, y: size.height / 2).inWorldCoords, size: .unit * 4, kinematic: true)
        let box2 = createBox(Vector2(x: size.width * 0.7, y: size.height / 2).inWorldCoords, size: .unit * 4, kinematic: true)
        
        box1.objectTag = UInt(0x7DFF0000)
        box2.objectTag = UInt(0x7DFF0000)
        
        // Create a few structures to showcase the joints feature
        do {
            let (bouncy1, bouncy2) = createLinkedBouncyBalls(Vector2(x: size.width / 2, y: size.height * 0.65).inWorldCoords)
            bouncy1.objectTag = UInt(0x7DDE22DE)
            bouncy2.objectTag = UInt(0x7DDE22DE)
        }
        
        createBallBoxLinkedStructure(Vector2(x: size.width * 0.8, y: size.height * 0.8).inWorldCoords)
        
        do {
            let (left, box, right) = createScaleStructure(Vector2(x: size.width * 0.4, y: size.height * 0.8).inWorldCoords)
            
            left.objectTag = UInt(0x7D22EFEF)
            box.objectTag = UInt(0x7D116666)
            right.objectTag = UInt(0x7D22EFEF)
        }
        
        createCarStructure(Vector2(x: size.width * 0.12, y: 90).inWorldCoords)
        createBox(Vector2(x: size.width * 0.5, y: 16).inWorldCoords, size: Vector2(x: 34, y: 1), isStatic: true).objectTag = UInt(0x7D999999)
        
        // Create the ground box
        let box = ClosedShape.create { box in
            box.addVertex(x: -10, y:   1)
            box.addVertex(x:  0,  y: 0.6) // A little inward slope
            box.addVertex(x:  10, y:   1)
            box.addVertex(x:  10, y:  -1)
            box.addVertex(x: -10, y:  -1)
        }
        
        let platform = Body(world: world, shape: box, pointMasses: [JFloat.infinity], position: Vector2(x: size.width / 2, y: 150).inWorldCoords)
        platform.isStatic = true
        platform.objectTag = UInt(0x7D999999)
        
        // Relax the world a bit to reduce 'popping'
        world.relaxWorld(timestep: 1.0 / 600, iterations: 120 * 3)
    }
    
    // MARK: - Helper body creation methods
    
    /// Creates a box at the specified world coordinates with the specified size
    @discardableResult
    func createBox(_ pos: Vector2, size: Vector2, pinned: Bool = false,
                   kinematic: Bool = false, isStatic: Bool = false,
                   angle: JFloat = 0, mass: JFloat = 0.5) -> Body {
        
        // Create the closed shape for the box's physics body
        let shape = ClosedShape
            .rectangle(ofSides: size)
            .transformedBy(rotatingBy: angle)
        
        var comps = [BodyComponentCreator]()
        
        // Add a spring body component - spring bodies have string physics that attract the inner points, it's one of the
        // forces that holds a body together
        comps.append(SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 100, shapeSpringDamp: 60))
        
        if !pinned {
            // Add a gravity component that will pull the body down
            comps.append(GravityComponentCreator())
        }
        
        let body = Body(world: world, shape: shape, pointMasses: [isStatic ? JFloat.infinity : mass], position: pos, kinematic: kinematic, components: comps)
        body.isPined = pinned
        
        // In order to have the box behave correctly, we need to add some internal springs to the body
        let springComp = body.component(ofType: SpringComponent.self)
        
        // The two first arguments are the indexes of the point masses to link, the next two are the spring constants,
        // and the last one is the distance the spring will try to mantain the two point masses at.
        // Specifying the distance as -1 sets it as the current distance between the specified point masses
        springComp?.addInternalSpring(body, pointA: 0, pointB: 2, springK: 100, damping: 10)
        springComp?.addInternalSpring(body, pointA: 1, pointB: 3, springK: 100, damping: 10)
        
        return body
    }
    
    /// Creates a bouncy ball at the specified world coordinates
    @discardableResult
    func createBouncyBall(_ pos: Vector2, pinned: Bool = false, kinematic: Bool = false, radius: JFloat = 1, mass: JFloat = 0.5, def: Int = 12) -> Body {
        // Create the closed shape for the ball's physics body
        let shape = ClosedShape
            .circle(ofRadius: radius, pointCount: def)
            .transformedBy(scalingBy: Vector2(x: 0.3, y: 0.3))
        
        var comps = [BodyComponentCreator]()
        
        // Add a spring body component - spring bodies have string physics that attract the inner points, it's one of the
        // forces that holds a body together
        comps.append(SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 600, edgeSpringDamp: 20, shapeSpringK: 10, shapeSpringDamp: 20))
        
        // Add a pressure component - pressure applies an outwards-going force that basically
        // tries to expand the body as if filled with air, like a balloon
        comps.append(PressureComponentCreator(gasAmmount: 90))
        
        // Add a gravity component taht will pull the body down
        comps.append(GravityComponentCreator())
        
        let body = Body(world: world, shape: shape, pointMasses: [mass], position: pos, kinematic: kinematic, components: comps)
        
        body.isPined = pinned
        
        return body
    }
    
    /// Creates two linked bouncy balls in a given position in the world
    @discardableResult
    func createLinkedBouncyBalls(_ pos: Vector2) -> (left: Body, right: Body) {
        let b1 = createBouncyBall(pos - Vector2(x: 1, y: 0), pinned: false, kinematic: false, radius: 1)
        let b2 = createBouncyBall(pos + Vector2(x: 1, y: 0), pinned: false, kinematic: false, radius: 1)
        
        // Create the joint links
        let l1 = BodyJointLink(body: b1)
        let l2 = BodyJointLink(body: b2)
        
        let joint = SpringBodyJoint(on: world, link1: l1, link2: l2, coefficient: 100, damping: 20)
        
        world.addJoint(joint)
        
        return (b1, b2)
    }
    
    /// Creates a pinned box with a ball attached to one of its edges
    @discardableResult
    func createBallBoxLinkedStructure(_ pos: Vector2) -> (ball: Body, box: Body) {
        let b1 = createBouncyBall(pos - Vector2(x: 0, y: 2), pinned: false, kinematic: false, radius: 1, mass: 1)
        let b2 = createBox(pos, size: Vector2.unit * 2, pinned: true, kinematic: false, mass: 1)
        
        // Create the joint links
        let l1 = BodyJointLink(body: b1)
        let l2 = EdgeJointLink(body: b2, edgeIndex: 2, edgeRatio: 0.5)
        
        world.addJoint(SpringBodyJoint(on: world, link1: l1, link2: l2, coefficient: 100, damping: 20))
        
        // Allow relaxation of bodies
        b1.component(ofType: GravityComponent.self)?.relaxable = true
        b2.component(ofType: GravityComponent.self)?.relaxable = true
        b1.addComponent(ofType: StickyRayComponent.self)
        
        return (b1, b2)
    }
    
    /// Creates a pinned box with two balls attached to one of its edges
    @discardableResult
    func createScaleStructure(_ pos: Vector2) -> (leftBall: Body, scale: Body, rightBall: Body) {
        let b1 = createBox(pos, size: Vector2(x: 4, y: 2), pinned: true, kinematic: false)
        let b2 = createBouncyBall(pos + Vector2(x: -1.2, y: -2), pinned: false, kinematic: false, radius: 1)
        let b3 = createBouncyBall(pos + Vector2(x:  1.2, y: -2), pinned: false, kinematic: false, radius: 1)
        
        // Create the joints that link the box with the left sphere
        let l1 = BodyJointLink(body: b2)
        let l2 = EdgeJointLink(body: b1, edgeIndex: 2, edgeRatio: 0.8)
        
        // Create the joints that link the box with the right sphere
        let l3 = BodyJointLink(body: b3)
        let l4 = EdgeJointLink(body: b1, edgeIndex: 2, edgeRatio: 0.2)
        
        // Create the joints
        let joint1 = SpringBodyJoint(on: world, link1: l1, link2: l2, coefficient: 10, damping: 2)
        let joint2 = SpringBodyJoint(on: world, link1: l3, link2: l4, coefficient: 40, damping: 5)
        
        joint2.restDistance = joint2.restDistance.minimumDistance <-> joint2.restDistance.minimumDistance + 2
        
        // Enable collision between the bodies
        joint1.allowCollisions = true
        joint2.allowCollisions = true
        
        world.addJoint(joint1)
        world.addJoint(joint2)
        
        // Allow relaxation of bodies
        b1.component(ofType: GravityComponent.self)?.relaxable = true
        b2.component(ofType: GravityComponent.self)?.relaxable = true
        b3.component(ofType: GravityComponent.self)?.relaxable = true
        
        // Relax these bodies a bit
        world.relaxBodies(in: [b1, b2, b3], timestep: 1 / 600.0, iterations: 120 * 8)
        
        return (b2, b1, b3)
    }
    
    /// Creates a car structure
    @discardableResult
    func createCarStructure(_ pos: Vector2) -> (car: Body, leftWheel: Body, rightWheel: Body) {
        var carShape = ClosedShape()
        
        // Add the car shape vertices
        carShape.begin()
        
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
        carShape.transformOwnBy(scalingBy: Vector2(x: 0.65, y: 0.65))
        carShape.finish(recentering: true)
        
        let bodyOffset = Vector2(x: 0, y: 0.4)
        
        let carBody = Body(world: world, shape: carShape, pointMasses: [0.7], position: pos + bodyOffset, components: [SpringComponentCreator(shapeMatchingOn: true, edgeSpringK: 300, edgeSpringDamp: 30, shapeSpringK: 600, shapeSpringDamp: 30), GravityComponentCreator()])
        
        let leftWheel  = createBouncyBall(carBody.derivedPos + Vector2.rotate(Vector2(x: -1.1, y: -0.5) - bodyOffset, by: carBody.derivedAngle), pinned: false, kinematic: false, radius: 0.5, mass: 0.5)
        let rightWheel = createBouncyBall(carBody.derivedPos + Vector2.rotate(Vector2(x:  1.1, y: -0.5) - bodyOffset, by: carBody.derivedAngle), pinned: false, kinematic: false, radius: 0.5, mass: 0.5)
        
        // Create the left wheel constraint
        let ljWheel = BodyJointLink(body: leftWheel)
        let ljCar = ShapeJointLink(body: carBody, pointMassIndexes: [19, 0, 1, 2, 3, 4])
        ljCar.offset = Vector2(x: 0, y: -0.6)
        
        let leftJoint = SpringBodyJoint(on: world, link1: ljWheel, link2: ljCar, coefficient: 100, damping: 15, distance: 0.0)
        leftJoint.allowCollisions = true
        
        let rjWheel = BodyJointLink(body: rightWheel)
        let rjCar = ShapeJointLink(body: carBody, pointMassIndexes: [13, 14, 15, 16, 17, 18])
        rjCar.offset = Vector2(x: 0, y: -0.6)
        
        let rightJoint = SpringBodyJoint(on: world, link1: rjWheel, link2: rjCar, coefficient: 100, damping: 15, distance: 0.0)
        rightJoint.allowCollisions = true
        
        world.addJoint(leftJoint)
        world.addJoint(rightJoint)
        
        // Tint car
        carBody.objectTag = UInt(0x7D21AFC3)
        leftWheel.objectTag = UInt(0x7D333333)
        rightWheel.objectTag = UInt(0x7D333333)
        
        return (carBody, leftWheel, rightWheel)
    }
}

// MARK: - Rendering
extension DemoScene {
    ///                                               1
    /// Returns a 3x3 matrix for projecting onto a -1 0 1 -style space such that
    ///                                              -1
    /// a [0, 0] vector projects into the top-left (1, -1), and [width, height]
    /// projects into the bottom-right (-1, 1).
    ///
    func matrixForOrthoProjection(width: CGFloat, height: CGFloat) -> Vector2.NativeMatrixType {
        let size = Vector2(x: width, y: height)
        let scaledSize = Vector2(x: 1 / width, y: 1 / height) * 2
        
        let matrix = Vector2.matrix(translatingBy: -size / 2)
        return matrix * Vector2.matrix(scalingBy: scaledSize)
    }
    
    func drawLine(from start: Vector2, to end: Vector2, color: UInt = 0xFFFFFFFF, width: JFloat = 0.5) {
        
        let normal = ((start - end).normalized().perpendicular() / 15) * width
        
        let i0 = vertexBuffer.addVertex(start + normal, color: color)
        let i1 = vertexBuffer.addVertex(end + normal, color: color)
        let i2 = vertexBuffer.addVertex(end - normal, color: color)
        let i3 = vertexBuffer.addVertex(start - normal, color: color)
        
        vertexBuffer.addTriangleWithIndices(i0, i1, i2)
        vertexBuffer.addTriangleWithIndices(i2, i3, i0)
        
        // Draw a pointy line to make the line look less squared
        let p0 = vertexBuffer.addVertex(start - normal.perpendicular(), color: color)
        let p1 = vertexBuffer.addVertex(end + normal.perpendicular(), color: color)
        
        vertexBuffer.addTriangleWithIndices(i0, p0, i1)
        vertexBuffer.addTriangleWithIndices(i2, p1, i3)
    }
    
    func drawCircle(center point: Vector2, radius: JFloat, sides: Int = 10, color: UInt = 0xFFFFFFFF) {
        let prevColor = vertexBuffer.currentColor
        vertexBuffer.currentColor = color
        defer {
            vertexBuffer.currentColor = prevColor
        }
        
        let shape =
            ClosedShape
                .circle(ofRadius: radius, pointCount: sides)
                .transformedBy(translatingBy: point)
        
        // Add triangles that connect the edges to a center vertex to form the
        // circle
        let center = vertexBuffer.addVertex(point)
        
        for vert in shape.localVertices {
            vertexBuffer.addVertex(x: vert.x, y: vert.y)
        }
        
        for vert in 0..<shape.localVertices.count {
            let next = (vert + 1) % shape.localVertices.count
            
            vertexBuffer.addTriangleWithIndices(center + UInt32(vert) + 1,
                                                center + UInt32(next) + 1,
                                                center)
        }
    }
    
    func drawPolyOutline(_ points: [Vector2], color: UInt = 0xFFFFFFFF, width: JFloat = 0.5) {
        guard var last = points.last else {
            return
        }
        
        for point in points {
            drawLine(from: point, to: last, color: color, width: width)
            last = point
        }
    }
    
    /// Renders the dragging shape line
    func drawDrag() {
        // Dragging point
        guard let (body, index) = draggingPoint, inputMode == InputMode.dragBody else {
            return
        }
        
        // Create the path to draw
        let lineStart = body.pointMasses[index].position
        let lineEnd = pointerLocation
        
        drawLine(from: lineStart, to: lineEnd, color: 0xFF00DD00)
    }
    
    func drawJoint(_ joint: BodyJoint) {
        let start = joint.bodyLink1.position
        let end = joint.bodyLink2.position
        
        var color: UInt = joint.enabled ? 0xFFEEEEEE : 0xFFCCCCCC
        
        // Color joint a different shade depending on how far from rest shape
        // its bodies are (from gray at 0% off to light-red at >100% off)
        let distance = start.distance(to: end)
        if !joint.restDistance.inRange(value: distance) {
            let clamped = joint.restDistance.clamp(value: distance)
            
            if clamped > 0 {
                var overhead: JFloat
                
                if distance < clamped {
                    overhead = distance / clamped
                } else {
                    overhead = clamped / distance
                }
                
                // Normalize to 0 - 1
                overhead = max(0, min(1, overhead))
                // Now shift range to be 0.5 - 1 (this decreases strong red shades)
                overhead = overhead / 2 + 0.5
                
                let resVector =
                    Color4.fromUIntARGB(color).vector * Color4(r: 1, g: overhead, b: overhead, a: 1).vector
                
                color = Color4(vector: resVector).toUIntARGB()
            }
        }
        
        if !useDetailedRender && joint.restDistance.minimumDistance > 0.2 {
            let springWidth = 0.2
            let segmentCount = Int((joint.restDistance.minimumDistance / 0.1).rounded(.up))
            
            func positionForSegment(_ offset: Int) -> Vector2 {
                if offset == 0 {
                    return start
                }
                if offset == segmentCount {
                    return end
                }
                
                let segPosition = start.ratio(JFloat(offset) / JFloat(segmentCount), to: end)
                let segPerp = (end - start).perpendicular().normalized() * JFloat(springWidth)
                
                let segmentPosition: Vector2
                
                if offset.isMultiple(of: 2) {
                    segmentPosition = segPosition + segPerp
                } else {
                    segmentPosition = segPosition - segPerp
                }
                
                return segmentPosition
            }
            
            for seg in 1...segmentCount {
                let start = positionForSegment(seg - 1)
                let end = positionForSegment(seg)
                
                drawLine(from: start, to: end, color: color)
            }
        } else {
            if joint.bodyLink1.linkType == .edge {
                drawCircle(center: start, radius: 0.15, color: color)
            }
            if joint.bodyLink2.linkType == .edge {
                drawCircle(center: end, radius: 0.15, color: color)
            }
            
            // Draw active range for joint
            switch joint.restDistance {
            case .fixed:
                drawLine(from: start, to: end, color: color)
                
            case let .ranged(min, max):
                let length: JFloat = 0.3
                let dir = (end - start).normalized()
                var startRange = start + dir * min
                var endRange = start + dir * max
                
                if start.distanceSquared(to: end) < (min * min) {
                    startRange = end
                }
                if start.distanceSquared(to: end) > (max * max) {
                    endRange = end
                }
                
                let perp = dir.perpendicular()
                
                drawLine(from: startRange + perp * -length,
                         to: startRange + perp * length,
                         color: color)
                
                drawLine(from: endRange + perp * -length,
                         to: endRange + perp * length,
                         color: color)
                
                drawLine(from: start, to: end, color: color)
                drawLine(from: startRange, to: endRange, color: color)
            }
        }
    }
    
    func drawBody(_ body: Body) {
        var bodyColor: UInt = 0x7DFFFFFF
        if let color = body.objectTag as? UInt {
            bodyColor = color
        } else if let color = body.objectTag as? Color4 {
            bodyColor = color.toUIntARGB()
        } else if let color = body.objectTag as? Color {
            bodyColor = Color4.fromUIColor(color).toUIntARGB()
        }
        
        // Helper lazy body fill drawing inner function
        func drawBodyFill() {
            // Triangulate body's polygon
            guard let (vertices, indices) = LibTessTriangulate.process(polygon: body.vertices) else {
                return
            }
            
            let start = UInt32(vertexBuffer.vertices.count)
            
            let prev = vertexBuffer.currentColor
            vertexBuffer.currentColor = bodyColor
            
            for vert in vertices {
                vertexBuffer.addVertex(x: vert.x, y: vert.y)
            }
            
            vertexBuffer.currentColor = prev
            
            // Add vertex index triplets
            for i in 0..<indices.count / 3 {
                vertexBuffer.addTriangleWithIndices(start + UInt32(indices[i * 3]),
                                                    start + UInt32(indices[i * 3 + 1]),
                                                    start + UInt32(indices[i * 3 + 2]))
            }
        }
        
        let shapePoints = body.vertices
        
        if !useDetailedRender {
            // Don't do any other rendering other than the body's buffer
            drawBodyFill()
            let lineColorVec = (Color4.fromUIntARGB(bodyColor).vector * Color4(r: 0.7, g: 0.6, b: 0.8, a: 1).vector)
            drawPolyOutline(shapePoints, color: Color4(vector: lineColorVec).toUIntARGB(), width: 1)
            return
        }
        
        // Draw normals, for pressure bodies
        if body.component(ofType: PressureComponent.self) != nil {
            for point in body.pointMasses {
                drawLine(from: point.position, to: point.position + point.normal / 3, color: 0xFFEC33EC)
            }
        }
        
        // Draw the body's global shape
        drawPolyOutline(body.globalShape, color: 0xFF777777)
        
        // Draw lines going from the body's outer points to the global shape indices
        for (globalShape, p) in zip(body.globalShape, body.pointMasses) {
            let start = p.position
            let end = globalShape
            
            drawLine(from: start, to: end, color: 0xFF449944)
        }
        
        // Draw the body now
        drawBodyFill()
        drawPolyOutline(shapePoints, color: 0xFF000000)
        
        // Draw the body axis
        let axisUp    = [body.derivedPos, body.derivedPos + Vector2(x: 0, y: 0.6).rotated(by: body.derivedAngle)]
        let axisRight = [body.derivedPos, body.derivedPos + Vector2(x: 0.6, y: 0).rotated(by: body.derivedAngle)]
        
        // Rep Up vector
        drawLine(from: axisUp[0], to: axisUp[1], color: 0xFFED0000)
        // Green Right vector
        drawLine(from: axisRight[0], to: axisRight[1], color: 0xFF00ED00)
    }
}

extension DemoScene: CollisionObserver {
    func bodiesDidCollide(_ infos: [BodyCollisionInformation]) {
        collisions.append(contentsOf: infos)
    }
    
    func bodyCollision(_ info: BodyCollisionInformation, didExceedPenetrationThreshold penetrationThreshold: JFloat) {
        print("penetration above Penetration Threshold!!  penetration = \(info.penetration), threshold = \(penetrationThreshold), difference = \(info.penetration-penetrationThreshold)")
    }
}

extension Vector2.NativeMatrixType {
    
    /// Returns a 4x4 floating-point transformation matrix for this matrix
    /// object
    func matrix4x4() -> float4x4 {
        var matrix = float4x4(diagonal: [1, 1, 1, 1])
        
        matrix[0] = .init(x: Float(self[0, 0]), y: Float(self[0, 1]), z: 0, w: Float(self[0, 2]))
        matrix[1] = .init(x: Float(self[1, 0]), y: Float(self[1, 1]), z: 0, w: Float(self[1, 2]))
        matrix[2] = .init(x: Float(self[2, 0]), y: Float(self[2, 1]), z: 1, w: Float(self[2, 2]))
        matrix[3] = .init(x: 0, y: 0, z: 0, w: 1)
        
        return matrix
    }
}
