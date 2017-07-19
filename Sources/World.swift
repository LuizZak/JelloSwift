//
//  World.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents a simulation world, containing soft bodies and the code utilized
/// to make them interact with each other
public final class World {
    /// The bodies contained within this world
    public private(set) var bodies: ContiguousArray<Body> = []
    /// The joints contained within this world
    public private(set) var joints: ContiguousArray<BodyJoint> = []
    
    // PRIVATE VARIABLES
    fileprivate(set) public var worldLimits = AABB()
    fileprivate(set) public var worldSize = Vector2.zero
    fileprivate var worldGridStep = Vector2.zero {
        didSet {
            invWorldGridStep = 1 / worldGridStep
        }
    }
    fileprivate var worldGridSubdivision: Int = MemoryLayout<UInt>.size * 8
    
    /// The threshold at which penetrations are ignored, since they are far too
    /// deep to be resolved without applying unreasonable forces that will
    /// destabilize the simulation.
    /// Usually 0.3 is a good default.
    public var penetrationThreshold: JFloat = 0.3
    
    /// Inverse of `worldGridStep`, for multiplication over coordinates when
    /// projecting AABBs into the world grid.
    fileprivate var invWorldGridStep = Vector2.zero
    
    fileprivate var relaxing: Bool = false
    
    /// Matrix of material pairs used during collision resolving
    public var materialPairs: [[MaterialPair]] = []
    
    /// The default material pair for newly created materials
    public var defaultMatPair = MaterialPair()
    
    fileprivate var materialCount = 0
    
    fileprivate var collisionList: [BodyCollisionInformation] = []
    
    /// The object to report collisions to
    public weak var collisionObserver: CollisionObserver?
    
    private var _quadTree = QuadTree<Body>(aabb: AABB())
    
    /// Inits an empty world
    public init() {
        self.clear()
        
        let min = Vector2(x: -100.0, y: -100.0)
        let max = Vector2(x:  100.0, y:  100.0)
        
        setWorldLimits(min, max)
    }
    
    deinit {
        self.clear()
    }
    
    /// Clears the world's contents and readies it to be loaded again
    public func clear() {
        // Remove all joints - this is needed to avoid retain cycles
        for joint in joints {
            removeJoint(joint)
        }
        
        // Reset bodies
        for body in bodies {
            body.joints = []
        }
        
        bodies = []
        collisionList = []
        
        // Reset
        defaultMatPair = MaterialPair()
        
        materialCount = 1
        materialPairs = [[defaultMatPair]]
    }
    
    /// WORLD SIZE
    public func setWorldLimits(_ min: Vector2, _ max: Vector2) {
        worldLimits = AABB(min: min, max: max)
        
        worldSize = max - min
        
        // Divide the world into (by default) 4096 boxes (64 x 64) for broad-phase collision
        // detection
        worldGridStep = worldSize / JFloat(worldGridSubdivision)
    }
    
    /// MATERIALS
    /// Adds a new material to the world. All previous material data is kept
    /// intact.
    public func addMaterial() -> Int {
        let old = materialPairs
        materialCount += 1
        
        materialPairs = []
        
        // replace old data.
        for i in 0..<materialCount {
            materialPairs.append([])
            
            for j in 0..<materialCount {
                if ((i < materialCount - 1) && (j < materialCount - 1)) {
                    materialPairs[i].append(old[i][j])
                } else {
                    materialPairs[i].append(defaultMatPair)
                }
            }
        }
        
        return materialCount - 1
    }
    
    /// Enables or disables collision between 2 materials.
    public func setMaterialPairCollide(_ a: Int, b: Int, collide: Bool) {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount)) {
            materialPairs[a][b].collide = collide
            materialPairs[b][a].collide = collide
        }
    }
    
    /// Sets the collision response variables for a pair of materials.
    public func setMaterialPairData(_ a: Int, b: Int, friction: JFloat, elasticity: JFloat) {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount)) {
            materialPairs[a][b].friction = friction
            materialPairs[a][b].elasticity = elasticity
            
            materialPairs[b][a].friction = friction
            materialPairs[b][a].elasticity = elasticity
        }
    }
    
    /// Sets a user function to call when 2 bodies of the given materials collide.
    public func setMaterialPairFilterCallback(_ a: Int, b: Int, filter: @escaping (BodyCollisionInformation, JFloat) -> (Bool)) {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount)) {
            materialPairs[a][b].collisionFilter = filter
            materialPairs[b][a].collisionFilter = filter
        }
    }
    
    /// Adds a body to the world. Bodies do this automatically on their 
    /// constructors, you should not need to call this method most of the times.
    public func addBody(_ body: Body) {
        if(!bodies.contains(body)) {
            bodies.append(body)
        }
    }
    
    /// Removes a body from the world. Call this outside of an update to remove 
    /// the body.
    public func removeBody(_ body: Body) {
        bodies.remove(body)
    }
    
    /// Adds a joint to the world. Joints call this automatically during their
    /// initialization
    public func addJoint(_ joint: BodyJoint) {
        if(!joints.contains(joint)) {
            joints.append(joint)
            
            // Setup the joint parenthood
            joint.bodyLink1.body.joints.append(joint)
            joint.bodyLink2.body.joints.append(joint)
        }
    }
    
    /// Removes a joint from the world
    public func removeJoint(_ joint: BodyJoint) {
        joint.bodyLink1.body.joints.remove(joint)
        joint.bodyLink2.body.joints.remove(joint)
        
        joints.remove(joint)
    }
    
    /// Finds the closest PointMass in the world to a given point
    public func closestPointMass(to pt: Vector2) -> (Body, PointMass)? {
        var ret: (Body, PointMass)? = nil
        
        var closestD = JFloat.greatestFiniteMagnitude
        
        for body in bodies {
            let (pm, dist) = body.closestPointMass(to: pt)
            
            if(dist < closestD) {
                closestD = dist
                ret = (body, pm)
            }
        }
        
        return ret
    }
    
    /// Given a global point, returns a body (if any) that contains this point.
    /// Useful for picking objects with a cursor, etc.
    public func body(under pt: Vector2, bitmask: Bitmask = 0) -> Body? {
        for body in bodies {
            if((bitmask == 0 || (body.bitmask & bitmask) != 0) && body.contains(pt)) {
                return body
            }
        }
        
        return nil
    }
    
    /// Given a global point, returns all bodies that contain this point.
    /// Useful for picking objects with a cursor, etc.
    public func bodies(under pt: Vector2, bitmask: Bitmask = 0) -> [Body] {
        return bodies.filter { (bitmask == 0 || ($0.bitmask & bitmask) != 0) && $0.contains(pt) }
    }
    
    /// Returns a vector of bodies intersecting with the given line.
    public func bodiesIntersecting(lineFrom start: Vector2, to end: Vector2, bitmask: Bitmask = 0) -> [Body] {
        return bodies.filter { body -> Bool in
            if(body._bitmasksStale) {
                updateBodyBitmask(body)
            }
            
            return
                (bitmask == 0 || (body.bitmask & bitmask) != 0) &&
                    body.intersectsLine(from: start, to: end)
        }
    }
    
    /// Returns all bodies that overlap a given closed shape, on a given point
    /// in world coordinates.
    ///
    /// - Parameters:
    ///   - closedShape: A closed shape that represents the segments to query.
    /// Should contain at least 2 points.
    ///   - worldPos: The location in world coordinates to put the closed shape's
    /// center at when performing the query. For closed shapes that have absolute
    /// coordinates, this parameter must be `Vector2.zero`.
    ///   - ignoreTest: An optional closure applied to every body intersecting 
    /// the line to filter out results. If the closure return `true`, the body
    /// is ignored in the results list.
    /// Defaults to nil.
    ///
    /// - Returns: All bodies that intersect with the closed shape. If closed
    ///            shape contains less than 2 points, returns empty.
    public func bodiesIntersecting(closedShape: ClosedShape, at worldPos: Vector2, ignoreTest: ((Body) -> Bool)? = nil) -> ContiguousArray<Body> {
        if(closedShape.localVertices.count < 2) {
            return []
        }
        
        let queryShape = closedShape.transformedBy(translatingBy: worldPos)
        let shapeAABB = AABB(points: queryShape.localVertices)
        let shapeBitmask = bitmask(for: shapeAABB)
        
        var results = ContiguousArray<Body>()
        
        for body in bodies {
            if(body._bitmasksStale) {
                updateBodyBitmask(body)
            }
            
            if !bitmasksIntersect(shapeBitmask, (body.bitmaskX, body.bitmaskY)) {
                continue
            }
            if !shapeAABB.intersects(body.aabb) {
                continue
            }
            
            // Try line-by-line intersection
            var last = queryShape.localVertices[queryShape.localVertices.count - 1]
            for point in queryShape.localVertices {
                if body.intersectsLine(from: last, to: point) {
                    if(ignoreTest?(body) == true) {
                        break
                    }
                    
                    results.append(body)
                    break
                }
                last = point
            }
        }
        
        return results
    }
    
    /// Casts a ray between the given points and returns the first body it comes
    /// in contact with
    ///
    /// - Parameters:
    ///   - start: The start point to cast the ray from, in world coordinates
    ///   - end: The end point to end the ray cast at, in world coordinates
    ///   - bitmask: An optional collision bitmask that filters the bodies to
    /// collide using a bitwise AND (|) operation.
    /// If the value specified is 0, collision filtering is ignored and all
    /// bodies are considered for collision
    ///   - ignoreTest: Optional closure that will be called for each body along
    /// the way (not guaranteed to execute in order of farthest to closest body)
    /// that tests whether the body should be ignored during ray casting.
    /// - Returns: An optional tuple containing the farthest point reached by
    /// the ray, and a Body value specifying the body that was closest to the
    /// ray, if it hit any body, or nil if it hit nothing.
    public func rayCast(from start: Vector2, to end: Vector2, bitmask: Bitmask = 0, ignoreTest: ((Body) -> Bool)? = nil) -> (retPt: Vector2, body: Body)? {
        var aabb = AABB(points: [start, end])
        var aabbBitmask = self.bitmask(for: aabb)
        var result: (Vector2, Body)?
        
        for body in bodies {
            guard (bitmask == 0 || (body.bitmask & bitmask) != 0) else {
                continue
            }
            
            if(body._bitmasksStale) {
                updateBodyBitmask(body)
            }
            
            guard bitmasksIntersect(aabbBitmask, (body.bitmaskX, body.bitmaskY)) else {
                continue
            }
            guard body.aabb.intersects(aabb) else {
                continue
            }
            guard ignoreTest?(body) != true else {
                continue
            }
            
            // If we hit the body, shorten the length of the ray and keep iterating
            guard let ret = body.raycast(from: start, to: end) else {
                continue
            }
            
            result = (ret, body)
            
            aabb = AABB(points: [start, ret])
            aabbBitmask = self.bitmask(for: aabb)
        }
        
        return result
    }
    
    /// Updates the world by a specific timestep.
    /// This method performs body point mass force/velocity/position simulation,
    /// and collision detection & resolving.
    ///
    /// - Parameter elapsed: The elapsed time to update by, usually in 1/60ths
    /// of a second.
    public func update(_ elapsed: JFloat) {
        update(elapsed, withBodies: bodies, joints: joints)
    }
    
    /// Internal updating method
    fileprivate func update(_ elapsed: JFloat, withBodies bodies: ContiguousArray<Body>, joints: ContiguousArray<BodyJoint>) {
        var _allAABB = AABB()
        
        for body in bodies {
            body._islandFlag = false
            
            body.updateAABB(elapsed, forceUpdate: true)
            
            _allAABB.expand(toFit: body.aabb)
        }
        for joint in joints {
            joint._islandFlag = false
        }
        
        // Create collision quad-tree
        var quad = QuadTree<Body>(aabb: _allAABB)
        for body in bodies {
            quad.insert(body)
        }
        
        let island = Island(bodyCapacity: bodies.count, jointCapacity: joints.count, world: self)
        island.penetrationThreshold = penetrationThreshold // Propagate penetration threshold to solver
        
        for next in bodies {
            if next._islandFlag {
                continue
            }
            if next.isStatic {
                continue
            }
            
            next._islandFlag = true
            
            island.clear()
            
            var stack: ContiguousArray<Body> = [next]
            
            while stack.count > 0 {
                let body = stack.removeFirst()
                
                island.add(body: body)
                
                if(body.isStatic) {
                    continue
                }
                
                // Query joints
                for joint in body.joints {
                    guard !joint._islandFlag else {
                        continue
                    }
                    
                    joint._islandFlag = true
                    
                    island.add(joint: joint)
                    
                    let b2: Body
                    if joint.bodyLink1.body == body {
                        b2 = joint.bodyLink2.body
                    } else {
                        b2 = joint.bodyLink1.body
                    }
                    
                    if b2._islandFlag {
                        continue
                    }
                    
                    b2._islandFlag = true
                    stack.append(b2)
                }
                
                // Query AABB for contacts
                quad.queryAABB(body.aabb) { other in
                    if other == body || other._islandFlag {
                        return
                    }
                    
                    other._islandFlag = true
                    stack.append(other)
                }
            }
            
            island.resolve(elapsed: elapsed, relaxing: relaxing)
            
            // Post solve cleanup
            // Allow static bodies to participate in other islands
            for body in island.bodies where body.isStatic {
                body._islandFlag = false
            }
        }
        
        if(!relaxing) { // Disabled during relaxation
            // Notify collisions that will happen
            if let observer = collisionObserver {
                observer.bodiesDidCollide(collisionList)
            }
        }
        
        collisionList.removeAll(keepingCapacity: true)
    }
    
    /// Returns if two grid bitmasks intersect.
    /// Returns `true` iff `((b1.x & b2.x) != 0) && ((b1.y & b2.y) != 0)`
    internal func bitmasksIntersect(_ b1: (Bitmask, Bitmask), _ b2: (Bitmask, Bitmask)) -> Bool {
        return ((b1.0 & b2.0) != 0) && ((b1.1 & b2.1) != 0)
    }
    
    /// Update bodies' bitmask for early collision filtering
    fileprivate func updateBodyBitmask(_ body: Body) {
        (body.bitmaskX, body.bitmaskY) = bitmask(for: body.aabb)
        body._bitmasksStale = false
    }
    
    /// Returns a set of X and Y bitmasks for filtering collision with objects
    /// on the current world grid.
    ///
    /// Returns 0 if any axis of the AABB projected on the grid turn into NaN.
    ///
    /// - Parameter aabb: AABB to bitmask on.
    /// - Returns: Horizontal and vertical bitmasks for the AABB on the current
    /// world grid.
    func bitmask(for aabb: AABB) -> (bitmaskX: Bitmask, bitmaskY: Bitmask) {
        // In case the AABB represents invalid boundaries, return 0-ed out bitmasks
        // that do not intersect any range
        if(aabb.minimum.x.isNaN || aabb.minimum.y.isNaN || aabb.maximum.x.isNaN || aabb.maximum.y.isNaN) {
            return (0, 0)
        }
        
        let subdiv = JFloat(worldGridSubdivision)
        
        let minVec = max(.zero, min(Vector2(x: subdiv, y: subdiv), (aabb.minimum - worldLimits.minimum) * invWorldGridStep))
        let maxVec = max(.zero, min(Vector2(x: subdiv, y: subdiv), (aabb.maximum - worldLimits.minimum) * invWorldGridStep))
        
        assert(minVec.x >= 0 && minVec.x <= subdiv && minVec.y >= 0 && minVec.y <= subdiv)
        assert(maxVec.x >= 0 && maxVec.x <= subdiv && maxVec.y >= 0 && maxVec.y <= subdiv)
        
        var bitmaskX: Bitmask = 0
        var bitmaskY: Bitmask = 0
        
        // In case the AABB is contained within invalid boundaries, return 0-ed
        // out bitmasks that do not intersect any range
        if(minVec.x.isNaN || minVec.y.isNaN || maxVec.x.isNaN || maxVec.y.isNaN) {
            return (0, 0)
        }
        
        for i in Int(minVec.x)...Int(maxVec.x) {
            bitmaskX.setBitOn(atIndex: i)
        }
        
        for i in Int(minVec.y)...Int(maxVec.y) {
            bitmaskY.setBitOn(atIndex: i)
        }
        
        return (bitmaskX, bitmaskY)
    }
}

// MARK: - Relaxation
public extension World {
    
    /// Relaxes all bodies in this simulation so they match a more approximate
    /// rest shape once simulation starts.
    ///
    /// This will move/change the position of each body after iterations are done.
    ///
    /// Performs collisions and joint resolving, and resets the velocities to 0
    /// before finishing.
    ///
    /// All body joints/velocities/components are executed (except body components
    /// w/ `relaxable == false`).
    ///
    /// - Parameters:
    ///   - iterations: The number of iterations of relaxation to apply.
    ///   - timestep: The timestep (in seconds) of each iteration.
    ///
    /// - Precondition: `iterations` > 0
    public func relaxWorld(timestep: JFloat, iterations: Int = 100) {
        relaxing = true
        
        for _ in 0...iterations {
            update(timestep)
        }
        
        relaxing = false
        
        // Reset all velocities
        for body in bodies {
            for pointMass in body.pointMasses {
                pointMass.velocity = .zero
            }
        }
    }
    
    /// Relaxes a list of bodies in this simulation so they match a more approximate
    /// rest shape once simulation starts.
    ///
    /// This will move/change the position of each body after iterations are done.
    ///
    /// Performs collisions and joint resolving only of bodies in the provided
    /// list, and other bodies that come in direct contact with them, resetting
    /// the velocities to 0 before finishing.
    ///
    /// Only Body Joints that involve bodies contained within the passed body
    /// list are executed.
    ///
    /// All body joints/velocities/components are executed (except body components
    /// w/ `relaxable == false`).
    ///
    /// - Parameters:
    ///   - bodies: List of bodies to relax, Joints that involve a body within
    /// this list and another body that is not are not resolved during relaxation.
    ///   - iterations: The number of iterations of relaxation to apply.
    ///   - timestep: The timestep (in seconds) of each iteration.
    ///
    /// - Precondition: `iterations` > 0
    public func relaxBodies(in bodies: [Body], timestep: JFloat, iterations: Int = 100) {
        relaxing = true
        
        // Find all joints for the bodies
        var joints: ContiguousArray<BodyJoint> = []
        let existingJoints =
            bodies.flatMap {
                $0.joints
            }.filter {
                bodies.contains($0.bodyLink1.body) && bodies.contains($0.bodyLink2.body)
            }
        
        // Gather joints
        for joint in existingJoints {
            if(!joints.contains(joint)) {
                joints.append(joint)
            }
        }
        
        for _ in 0...iterations {
            update(timestep, withBodies: ContiguousArray(bodies), joints: joints)
        }
        
        relaxing = false
        
        // Reset all velocities
        for body in bodies {
            for pointMass in body.pointMasses {
                pointMass.velocity = .zero
            }
        }
    }
}

/// Specifies a collection of bodies that are connected by either constraints or
/// contacts, forming a singular 'island' that is isolated and doesn't interact
/// with other 'islands'.
///
/// Island solving is inspired by Box2D's implementation, by Erin Catto.
final class Island {
    
    var collisionList: [BodyCollisionInformation] = []
    var bodies: ContiguousArray<Body> = []
    var joints: ContiguousArray<BodyJoint> = []
    
    var world: World
    
    /// The threshold at which penetrations are ignored, since they are far too
    /// deep to be resolved without applying unreasonable forces that will
    /// destabilize the simulation.
    /// Usually 0.3 is a good default.
    public var penetrationThreshold: JFloat = 0.3
    
    init(bodyCapacity: Int, jointCapacity: Int, world: World) {
        collisionList.reserveCapacity(Int(Float(bodyCapacity) * 1.5))
        bodies.reserveCapacity(bodyCapacity)
        joints.reserveCapacity(jointCapacity)
        self.world = world
    }
    
    func clear() {
        collisionList.removeAll(keepingCapacity: true)
        bodies.removeAll(keepingCapacity: true)
        joints.removeAll(keepingCapacity: true)
    }
    
    func resolve(elapsed: JFloat, relaxing: Bool) {
        
        // Update the bodies
        for body in bodies {
            body.derivePositionAndAngle(elapsed)
            
            // Only update edge and normals pre-accumulation if the body has
            // components - only components really use this information.
            if(body.componentCount > 0) {
                body.updateEdgesAndNormals()
                
                body.accumulateExternalForces(relaxing: relaxing)
                body.accumulateInternalForces(relaxing: relaxing)
            }
            
            body.integrate(elapsed)
            
            body.updateAABB(elapsed, forceUpdate: true)
        }
        
        // Update the joints
        for joint in joints {
            joint.resolve(elapsed)
        }
        
        let c = bodies.count
        for (i, body1) in bodies.enumerated() {
            innerLoop: for j in (i &+ 1)..<c {
                let body2 = bodies[j]
                
                // bitmask filtering
                if (body1.bitmask & body2.bitmask) == 0 {
                    continue
                }
                
                // another early-out - both bodies are static.
                if body1.isStatic && body2.isStatic
                {
                    continue
                }
                
                // broad-phase collision via AABB.
                // early out
                if !body1.aabb.intersects(body2.aabb) {
                    continue
                }
                
                // early out - these bodies materials are set NOT to collide
                if !world.materialPairs[body1.material][body2.material].collide {
                    continue
                }
                
                // Joints relationship: if one body is joined to another by a
                // joint, check the joint's rule for collision
                for j in body1.joints {
                    if(j.bodyLink1.body == body1 && j.bodyLink2.body == body2 ||
                        j.bodyLink2.body == body1 && j.bodyLink1.body == body2) {
                        if(!j.allowCollisions) {
                            continue innerLoop
                        }
                    }
                }
                
                // okay, the AABB's of these 2 are intersecting. now check for
                // collision of A against B.
                bodyCollide(body1, body2)
                
                // and the opposite case, B colliding with A
                bodyCollide(body2, body1)
            }
        }
        
        handleCollisions()
        
        for body in bodies {
            body.dampenVelocity(elapsed)
        }
        
        collisionList.removeAll(keepingCapacity: true)
    }
    
    /// Checks collision between two bodies, and store the collision information
    /// if they do.
    /// Returns if any collisions have been detected between the two bodies.
    @discardableResult
    func bodyCollide(_ bA: Body, _ bB: Body) -> Bool {
        let bBpCount = bB.pointMasses.count
        
        var hasCollision = false
        for (i, pmA) in bA.pointMasses.enumerated() {
            let pt = pmA.position
            
            if (!bB.contains(pt)) {
                continue
            }
            
            hasCollision = true
            
            let ptNorm = bA.pointNormals[i]
            
            // this point is inside the other body.  now check if the edges on
            // either side intersect with and edges on bodyB.
            var closestAway = JFloat.infinity
            var closestSame = JFloat.infinity
            
            var infoAway = BodyCollisionInformation(bodyA: bA, bodyApm: i, bodyB: bB)
            var infoSame = infoAway
            
            var found = false
            
            for j in 0..<bBpCount {
                let b1 = j
                let b2 = (j &+ 1) % (bBpCount)
                
                // test against this edge.
                let (hitPt, normal, edgeD, dist) = bB.closestPointSquared(to: pt, onEdge: j)
                
                // only perform the check if the normal for this edge is facing
                // AWAY from the point normal.
                let dot = ptNorm • normal
                
                if (dot <= 0.0) {
                    if dist < closestAway {
                        closestAway = dist
                    
                        infoAway.bodyBpmA = b1
                        infoAway.bodyBpmB = b2
                        infoAway.edgeD = edgeD
                        infoAway.hitPt = hitPt
                        infoAway.normal = normal
                        infoAway.penetration = dist
                        found = true
                    }
                } else {
                    if (dist < closestSame) {
                        closestSame = dist
                
                        infoSame.bodyBpmA = b1
                        infoSame.bodyBpmB = b2
                        infoSame.edgeD = edgeD
                        infoSame.hitPt = hitPt
                        infoSame.normal = normal
                        infoSame.penetration = dist
                    }
                }
            }
            
            // we've checked all edges on BodyB.  add the collision info to the
            // stack.
            if (found && (closestAway > penetrationThreshold) && (closestSame < closestAway)) {
                assert(infoSame.bodyBpmA > -1 && infoSame.bodyBpmB > -1)
                
                infoSame.penetration = infoSame.penetration.squareRoot()
                collisionList.append(infoSame)
            } else {
                assert(infoAway.bodyBpmA > -1 && infoAway.bodyBpmB > -1)
                
                infoAway.penetration = infoAway.penetration.squareRoot()
                collisionList.append(infoAway)
            }
        }
        
        return hasCollision
    }
    
    /// Solves the collisions between bodies
    fileprivate func handleCollisions() {
        for info in collisionList {
            let bodyA = info.bodyA
            let bodyB = info.bodyB
            
            let A = bodyA.pointMasses[info.bodyApm]
            let B1 = bodyB.pointMasses[info.bodyBpmA]
            let B2 = bodyB.pointMasses[info.bodyBpmB]
            
            // Velocity changes as a result of collision
            let bVel = (B1.velocity + B2.velocity) / 2
            
            let relVel = A.velocity - bVel
            let relDot = relVel • info.normal
            
            let material = world.materialPairs[bodyA.material][bodyB.material]
            
            if(!material.collisionFilter(info, relDot)) {
                continue
            }
            
            // Check exceeding point-mass penetration - we ignore the collision,
            // then.
            if(info.penetration > penetrationThreshold) {
                world.collisionObserver?.bodyCollision(info, didExceedPenetrationThreshold: penetrationThreshold)
                continue
            }
            
            let b1inf = 1.0 - info.edgeD
            let b2inf = info.edgeD
            
            let b2MassSum = B1.mass + B2.mass
            
            let massSum = A.mass + b2MassSum
            
            // Amount to move each party of the collision
            let Amove: JFloat
            let Bmove: JFloat
            
            // Static detection - when one of the parties is static, the other
            // should move the total amount of the penetration
            if(A.mass.isInfinite) {
                Amove = 0
                Bmove = info.penetration + 0.001
            } else if(b2MassSum.isInfinite) {
                Amove = info.penetration + 0.001
                Bmove = 0
            } else {
                Amove = info.penetration * (b2MassSum / massSum)
                Bmove = info.penetration * (A.mass / massSum)
            }
            
            if(A.mass.isFinite) {
                A.position += info.normal * Amove
            }
            
            if(B1.mass.isFinite) {
                B1.position -= info.normal * (Bmove * b1inf)
            }
            if(B2.mass.isFinite) {
                B2.position -= info.normal * (Bmove * b2inf)
            }
            
            if(relDot <= 0.0001 && (A.mass.isFinite || b2MassSum.isFinite)) {
                let AinvMass: JFloat = A.mass.isInfinite ? 0 : 1.0 / A.mass
                let BinvMass: JFloat = b2MassSum.isInfinite ? 0 : 1.0 / b2MassSum
                
                let jDenom: JFloat = AinvMass + BinvMass
                let elas: JFloat = 1 + material.elasticity
                
                let j: JFloat = -((relVel * elas) • info.normal) / jDenom
                
                let tangent: Vector2 = info.normal.perpendicular()
                
                let friction: JFloat = material.friction
                let f: JFloat = (relVel • tangent) * friction / jDenom
                
                if(A.mass.isFinite) {
                    A.velocity += (info.normal * (j / A.mass)) - (tangent * (f / A.mass))
                }
                
                if(b2MassSum.isFinite) {
                    let jComp = info.normal * j / b2MassSum
                    let fComp = tangent * (f * b2MassSum)
                    
                    B1.velocity -= (jComp * b1inf) - (fComp * b1inf)
                    B2.velocity -= (jComp * b2inf) - (fComp * b2inf)
                }
            }
        }
        
        world.collisionList.append(contentsOf: collisionList)
    }
    
    func add(body: Body) {
        assert(!bodies.contains(body))
        bodies.append(body)
    }

    func add(joint: BodyJoint) {
        joints.append(joint)
    }
}
