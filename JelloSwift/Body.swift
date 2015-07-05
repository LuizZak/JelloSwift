//
//  Body.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

public func ==(lhs: Body, rhs: Body) -> Bool
{
    return lhs === rhs
}

/// Represents a soft body on the world
public final class Body: Equatable
{
    /// List of edges on the body
    internal var edges: ContiguousArray<BodyEdge> = []
    
    /// List of point normals
    internal var pointNormals:ContiguousArray<Vector2> = []
    
    /// List of body joints this body participates in
    public internal(set) var joints: [BodyJoint] = []
    
    /// The base shape for the body
    public var baseShape = ClosedShape()
    
    /// The global shape for the body - this is the same as the base shape, but rotated and translated around the world
    public var globalShape: [Vector2] = []
    
    /// The array of point masses for the body
    public private(set) var pointMasses: ContiguousArray<PointMass> = []
    
    /// An array of all the collision that involve this body
    public var pointMassCollisions: [BodyCollisionInformation] = []
    
    /// Whether to collect the collisions of this body into the pointMassCollisions array. Defaults to false
    public var collectCollisions = false
    
    /// The scale for this body's shape
    public var scale = Vector2.One
    
    /// The derived center position of this body - in world coordinates
    public private(set) var derivedPos = Vector2.Zero
    
    /// The derived velocity of this body - in world coordinates. The derivation assumes the mean of the velocity of all the point masses
    public private(set) var derivedVel = Vector2.Zero
    
    /// The velocity damping to apply to the body. Values closer to 0 deaccelerate faster, values closer to 1 deaccelerate slower.
    /// 1 never deaccelerates. Values outside the range [0, 1] inclusive may introduce instability
    public var velDamping: CGFloat = 0.999
    
    /// The array of body components for this body object
    private var components: ContiguousArray<BodyComponent> = []
    
    /// Gets the ammount of components in this body
    public var componentCount: Int { return components.count }
    
    
    // Both these properties are in radians:
    
    /// The derived rotation of the body
    public private(set) var derivedAngle: CGFloat = 0
    
    /// Omega (ω) is the relative angular speed of the body
    public private(set) var derivedOmega: CGFloat = 0
    
    // Utilize to calculate the omega for the body
    private var lastAngle: CGFloat = 0
    
    /// Gets a list of vertices that represents the current position of each PointMass in this body
    public var vertices: [Vector2]
    {
        return pointMasses.map { $0.position }
    }
    
    /// The bounding box for this body
    public var aabb = AABB()
    
    /// The index of the material in the world material array to use for this body
    public var material = 0
    
    /// Whether this body is static
    public var isStatic = false
    
    /// Whether this body is kinematic - kinematic bodies do not rotate or move their base shape, so they always appear to not move, like a static body, but can be squished and moved, like a dynamic body
    public var isKinematic = false
    
    /// Whether this body is pinned - pinned bodies rotate around their axis, but try to remain in place, like a kinematic body
    public var isPined = false
    
    /// Whether the body is able to rotate while moving
    public var freeRotate = true
    
    /// A free field that can be used to attach custom objects to a soft body instance
    public var objectTag: Any? = nil
    
    /// Whether to render this body
    public var render = true
    
    /// The colision bitmask for this body
    public var bitmask: Bitmask = 0xFFFFFFFF
    
    /// The X-axis bitmask for the body - used for collision filtering
    public var bitmaskX: Bitmask = 0
    /// The Y-axis bitmask for the body - used for collision filtering
    public var bitmaskY: Bitmask = 0
    
    public init(world: World?, shape: ClosedShape, pointMasses: [CGFloat] = [1], position: Vector2 = Vector2.Zero, angle: CGFloat = 0, scale: Vector2 = Vector2.One, kinematic: Bool = false, components: [BodyComponentCreator] = [])
    {
        self.aabb = AABB()
        self.derivedPos = position
        self.derivedAngle = angle
        self.derivedVel = Vector2()
        self.derivedOmega = 0
        self.lastAngle = derivedAngle
        self.scale = scale
        self.material = 0
        self.isStatic = false
        self.isKinematic = kinematic
        self.render = true
        self.setShape(shape)
        
        var points = pointMasses
        
        if(points.count == 1)
        {
            for _ in 0..<self.pointMasses.count - 1
            {
                points += (pointMasses[0])
            }
        }
        
        setMassFromList(points)
        
        self.updateAABB(0, forceUpdate: true)
        
        if let w = world
        {
            w.addBody(self)
        }
        
        // Add the components now
        components.forEach { $0.attachToBody(self) }
    }
    
    /// Adds a body component to this body
    public func addComponentType<T: BodyComponent>(componentType: T.Type) -> T
    {
        let instance = componentType.init(body: self)
        
        self.components += instance
        
        instance.prepare(self)
        
        return instance
    }
    
    /// Gets a component on this body that matches the given component type.
    /// If no matching components are found, nil is returned instead
    public func getComponentType<T: BodyComponent>(componentType: T.Type) -> T?
    {
        for comp in self.components
        {
            if(comp is T)
            {
                return comp as? T
            }
        }
        
        return nil
    }
    
    /// Removes a component from this body
    public func removeComponentType<T: BodyComponent>(componentType: T.Type)
    {
        for comp in self.components
        {
            if(comp is T)
            {
                self.components -= comp
                break
            }
        }
    }
    
    /// Updates the edges and normals of this body
    public func updateEdgesAndNormals()
    {
        updateEdges()
        updateNormals()
    }
    
    /// Updates the point normals of the body
    public func updateNormals()
    {
        let c = pointMasses.count
        
        if(pointNormals.count != c)
        {
            pointNormals = pointNormals.dynamicType.init(count: c, repeatedValue: Vector2.Zero)
        }
        
        for (i, curEdge) in edges.enumerate()
        {
            let prev = (i - 1) < 0 ? c - 1 : i - 1
            
            let edge1N = edges[prev].difference
            let edge2N = curEdge.difference
            
            pointNormals[i] = (edge1N + edge2N).perpendicular().normalized()
        }
    }
    
    /// Updates the cached edge information of the body
    public func updateEdges()
    {
        let c = pointMasses.count
        
        // Maintain the edge count the same as the point mass count
        if(edges.count != c)
        {
            edges = edges.dynamicType.init(count: c, repeatedValue: BodyEdge())
        }
        
        // Update edges
        for (i, curP) in pointMasses.enumerate()
        {
            let nextP = pointMasses[(i + 1) % c]
            
            edges[i] = BodyEdge(edgeIndex: i, start: curP.position, end: nextP.position)
        }
    }
    
    /// Updates a single edge in this body
    public func updateEdge(edgeIndex: Int)
    {
        let curP = pointMasses[edgeIndex]
        let nextP = pointMasses[(edgeIndex + 1) % pointMasses.count]
        
        edges[edgeIndex] = BodyEdge(edgeIndex: edgeIndex, start: curP.position, end: nextP.position)
    }
    
    public func getEdge(edgeIndex: Int) -> BodyEdge
    {
        return edges[edgeIndex]
    }
    
    /// Updates the AABB for this body, including padding for velocity given a timestep.
    /// This function is called by the World object on Update(), so the user should not need this in most cases.
    /// 
    /// - parameter elapsed: elapsed The elapsed time to update by, usually in seconds
    /// - parameter forceUpdate: Whether to force the update of the body, even if it's a static body
    public func updateAABB(elapsed: CGFloat, forceUpdate: Bool)
    {
        if(!isStatic && !forceUpdate)
        {
            return
        }
        
        aabb.clear()
        
        for point in pointMasses
        {
            aabb.expandToInclude(point.position)
            
            if(!isStatic)
            {
                aabb.expandToInclude(point.position + point.velocity * elapsed)
            }
        }
    }
    
    /// Sets the shape of this body to a new ClosedShape object.  This function
    /// will remove any existing PointMass objects, and replace them with new ones IF
    /// the new shape has a different vertex count than the previous one.  In this case
    /// the mass for each newly added point mass will be set zero.  Otherwise the shape is just
    /// updated, not affecting the existing PointMasses.
    public func setShape(shape: ClosedShape)
    {
        baseShape = shape
        
        if(baseShape.localVertices.count != pointMasses.count)
        {
            pointMasses = []
            edges = []
            globalShape = [Vector2](count: shape.localVertices.count, repeatedValue: Vector2())
            
            baseShape.transformVertices(&globalShape, worldPos: derivedPos, angleInRadians: derivedAngle, localScale: scale)
            
            for i in 0..<baseShape.localVertices.count
            {
                pointMasses += PointMass(mass: 0.0, position: globalShape[i])
            }
            
            updateEdges()
        }
    }
    
    /// Sets the mass for all the PointMass objects in this body
    public func setMassAll(mass: CGFloat)
    {
        pointMasses.forEach { $0.mass = mass }
        
        isStatic = isinf(mass)
    }
    
    /// Sets the mass for a single PointMass individually
    public func setMassIndividual(index: Int, mass: CGFloat)
    {
        self.pointMasses[index].mass = mass
    }
    
    /// Sets the mass for all the point masses from a list of masses
    public func setMassFromList(masses: [CGFloat])
    {
        isStatic = true
        
        for i in 0..<min(masses.count, self.pointMasses.count)
        {
            if(!isinf(masses[i]))
            {
                isStatic = false
            }
            
            self.pointMasses[i].mass = masses[i]
        }
    }
    
    /// Sets the position and angle of the body manually.
    /// Setting the position and angle resets the current shape to the original base shape of the object
    public func setPositionAngle(pos: Vector2, angle: CGFloat, scale: Vector2)
    {
        baseShape.transformVertices(&globalShape, worldPos: pos, angleInRadians: angle, localScale: scale)
        
        for (i, pm) in pointMasses.enumerate()
        {
            pm.position = globalShape[i]
        }
        
        updateEdges()
        
        derivedPos = pos
        derivedAngle = angle
        
        // Forcefully update the AABB when changing shapes
        if(isStatic)
        {
            updateAABB(0, forceUpdate: true)
        }
    }
    
    /// Derives the global position and angle of this body, based on the average of all the points.
    /// This updates the DerivedPosision, DerivedAngle, and DerivedVelocity properties.
    /// This is called by the World object each Update(), so usually a user does not need to call this.  Instead
    /// you can juse access the DerivedPosition, DerivedAngle, DerivedVelocity, and DerivedOmega properties.
    public func derivePositionAndAngle(elapsed: CGFloat)
    {
        // no need it this is a static body, or kinematically controlled.
        if (isStatic || isKinematic)
        {
            return
        }
        
        if(!isPined)
        {
            // Find the geometric center and average velocity
            derivedPos = averageVectors(vertices)
            derivedVel = averageVectors(pointMasses.map { $0.velocity })
        }
            
        if(freeRotate)
        {
            let meanPos = isPined ? averageVectors(vertices) : derivedPos
            
            // find the average angle of all of the masses.
            var angle: CGFloat = 0
        
            var originalSign = 1
            var originalAngle: CGFloat = 0
            
            let c = pointMasses.count
            for (i, pm) in pointMasses.enumerate()
            {
                let baseNorm = baseShape[i].normalized()
                let curNorm  = (pm.position - meanPos).normalized()
                
                var thisAngle = atan2(baseNorm.X * curNorm.Y - baseNorm.Y * curNorm.X, baseNorm =* curNorm)
                
                if (i == 0)
                {
                    originalSign = (thisAngle >= 0.0) ? 1 : -1
                    originalAngle = thisAngle
                }
                else
                {
                    let diff = (thisAngle - originalAngle)
                    let thisSign = (thisAngle >= 0.0) ? 1 : -1
                    
                    if (abs(diff) > PI && (thisSign != originalSign))
                    {
                        thisAngle = (thisSign == -1) ? (PI + (PI + thisAngle)) : ((PI - thisAngle) - PI)
                    }
                }
                
                angle += thisAngle
            }
            
            angle /= CGFloat(c)
        
            derivedAngle = angle
            
            // now calculate the derived Omega, based on change in angle over time.
            var angleChange = (derivedAngle - lastAngle)
        
            if ((angleChange < 0 ? -angleChange : angleChange) >= PI)
            {
                if (angleChange < 0)
                {
                    angleChange = angleChange + (PI * 2)
                }
                else
                {
                    angleChange = angleChange - (PI * 2)
                }
            }
        
            derivedOmega = angleChange / elapsed
        
            lastAngle = derivedAngle
        }
    }
    
    /// This function should add all internal forces to the Force member variable of each PointMass in the body.
    /// These should be forces that try to maintain the shape of the body.
    public func accumulateInternalForces()
    {
        components.forEach { $0.accumulateInternalForces() }
    }
    
    /// This function should add all external forces to the Force member variable of each PointMass in the body.
    /// These are external forces acting on the PointMasses, such as gravity, etc.
    public func accumulateExternalForces()
    {
        components.forEach { $0.accumulateExternalForces() }
    }
    
    /// Integrates the point masses for this Body.
    public func integrate(elapsed: CGFloat)
    {
        if(isStatic)
        {
            return
        }
        
        pointMasses.forEach { $0.integrate(elapsed) }
    }
    
    /// Applies the velocity damping to the point masses
    public func dampenVelocity()
    {
        if(isStatic)
        {
            return
        }
        
        pointMasses.forEach { $0.velocity *= velDamping }
    }
    
    /// Applies a rotational clockwise torque of a given force on this body
    public func applyTorque(force: CGFloat)
    {
        if(isStatic)
        {
            return
        }
        
        // Accelerate the body
        for pm in pointMasses
        {
            let diff = (pm.position - derivedPos).normalized().perpendicular()
            
            pm.applyForce(diff * force)
        }
    }
    
    /// Sets the angular velocity for this body
    public func setAngularVelocity(vel: CGFloat)
    {
        if(isStatic)
        {
            return
        }
        
        // Accelerate the body
        for pm in pointMasses
        {
            let diff = (pm.position - derivedPos).normalized().perpendicular()
            
            pm.velocity = diff * vel
        }
    }
    
    /// Accumulates the angular velocity for this body
    public func addAngularVelocity(vel: CGFloat)
    {
        if(isStatic)
        {
            return
        }
        
        // Accelerate the body
        for pm in pointMasses
        {
            let diff = (pm.position - derivedPos).normalized().perpendicular()
            
            pm.velocity += diff * vel
        }
    }
    
    /// Returns whether a global point is inside this body
    public func contains(pt: Vector2) -> Bool
    {
        // Check if the point is inside the AABB
        if(!aabb.contains(pt))
        {
            return false
        }
        
        // basic idea: draw a line from the point to a point known to be outside the body.  count the number of
        // lines in the polygon it intersects.  if that number is odd, we are inside.  if it's even, we are outside.
        // in this implementation we will always use a line that moves off in the positive X direction from the point
        // to simplify things.
        let endPt: Vector2
        
        // line we are testing against goes from pt -> endPt.
        var inside = false
        
        if(pt.X < aabb.midX)
        {
            endPt = Vector2(aabb.minimum.X - 0.1, pt.Y)
            
            for e in edges
            {
                let edgeSt = e.start
                let edgeEnd = e.end
                
                // perform check now...
                
                // The edge lies completely to the right of our imaginary line
                if(edgeSt.X > pt.X && edgeEnd.X > pt.X)
                {
                    continue
                }
                
                // Check if the edge crosses the imaginary horizontal line from top to bottom or bottom to top
                if (((edgeSt.Y <= pt.Y) && (edgeEnd.Y > pt.Y)) || ((edgeSt.Y > pt.Y) && (edgeEnd.Y <= pt.Y)))
                {
                    // this line crosses the test line at some point... does it do so within our test range?
                    let slope = (edgeEnd.X - edgeSt.X) / (edgeEnd.Y - edgeSt.Y)
                    let hitX = edgeSt.X + ((pt.Y - edgeSt.Y) * slope)
                    
                    if ((hitX <= pt.X) && (hitX >= endPt.X))
                    {
                        inside = !inside
                    }
                }
            }
        }
        else
        {
            endPt = Vector2(aabb.maximum.X + 0.1, pt.Y)
            
            for e in edges
            {
                let edgeSt = e.start
                let edgeEnd = e.end
                
                // perform check now...
                
                // The edge lies completely to the left of our imaginary line
                if(edgeSt.X < pt.X && edgeEnd.X < pt.X)
                {
                    continue
                }
                
                // Check if the edge crosses the imaginary horizontal line from top to bottom or bottom to top
                if (((edgeSt.Y <= pt.Y) && (edgeEnd.Y > pt.Y)) || ((edgeSt.Y > pt.Y) && (edgeEnd.Y <= pt.Y)))
                {
                    // this line crosses the test line at some point... does it do so within our test range?
                    let slope = (edgeEnd.X - edgeSt.X) / (edgeEnd.Y - edgeSt.Y)
                    let hitX = edgeSt.X + ((pt.Y - edgeSt.Y) * slope)
                    
                    if ((hitX >= pt.X) && (hitX <= endPt.X))
                    {
                        inside = !inside
                    }
                }
            }
        }
        
        return inside
    }
    
    /// Returns whether the given line consisting of two points intersects this body
    public func intersectsLine(start: Vector2, _ end: Vector2) -> Bool
    {
        // Test whether one or both the points of the line are inside the body
        if(contains(start) || contains(end))
        {
            return true
        }
        
        // Create and test against a temporary line AABB
        let lineAABB = AABB(points: [start, end])
        if(!aabb.intersects(lineAABB))
        {
            return false
        }
        
        // Test each edge against the line
        var p = Vector2()
        var ua: CGFloat = 0
        var ub: CGFloat = 0
        
        return edges.any { e in lineIntersect(start, ptB: end, ptC: e.start, ptD: e.end, hitPt: &p, Ua: &ua, Ub: &ub) }
    }
    
    /// Returns whether the given ray collides with this Body, changing the resulting collision vector before returning
    public func raycast(pt1: Vector2, _ pt2: Vector2, inout _ res: Vector2?, inout _ rayAABB: AABB!) -> Bool
    {
        // Create and test against a temporary line AABB
        if (rayAABB == nil)
        {
            rayAABB = AABB(points: [pt1, pt2])
        }
        
        if(!aabb.intersects(rayAABB))
        {
            return false
        }
        
        // Test each edge against the line
        var p = Vector2()
        var p1 = Vector2()
        var p2 = Vector2()
        var col = false
        var ua: CGFloat = 0
        var ub: CGFloat = 0
        
        res = pt2
        
        for e in edges
        {
            p1 = e.start
            p2 = e.end
            
            if(lineIntersect(pt1, ptB: pt2, ptC: p1, ptD: p2, hitPt: &p, Ua: &ua, Ub: &ub))
            {
                res = p
                col = true
            }
        }
        
        return col
    }
    
    /**
     * Given a global point, finds the closest point on an edge of a specified index, returning the squared distance to the edge found
     *
     * - parameter pt: The point to get the closest edge of, in world coordinates
     * - parameter edgeNum: The index of the edge to search
     * - parameter normal: A unit vector containing information about the normal of the edge found
     * - parameter hitPt: The closest point in the edge to the global point provided
     * - parameter edgeD: The ratio of the edge where the point was grabbed, [0-1] inclusive
     * - returns: The squared distance to the closest edge found
    */
    public func getClosestPointOnEdgeSquared(pt: Vector2, _ edgeNum: Int, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ edgeD: CGFloat) -> CGFloat
    {
        var dist: CGFloat = 0
        
        let edge = edges[edgeNum]
        
        let ptA = edge.start
        let ptB = edge.end
        
        let toP = pt - ptA
        
        // normal
        normal = edge.normal
        
        // calculate the distance!
        let x = toP =* edge.difference
        
        if (x <= 0.0)
        {
            // x is outside the line segment, distance is from pt to ptA.
            dist = pt.distanceToSquared(ptA)
            
            hitPt = ptA
            
            edgeD = 0
        }
        else if (x >= edge.length)
        {
            // x is outside of the line segment, distance is from pt to ptB.
            dist = pt.distanceToSquared(ptB)
            
            hitPt = ptB
            
            edgeD = 1
        }
        else
        {
            // point lies somewhere on the line segment.
            let pd = (toP =* edge.normal)
            dist = pd * pd
            
            hitPt = ptA + (edge.difference * x)
            edgeD = x / edge.length
        }
        
        return dist
    }
    
    /**
     * Given a global point, finds the closest point on an edge of a specified index, returning the distance to the edge found
     *
     * - parameter pt: The point to get the closest edge of, in world coordinates
     * - parameter edgeNum: The index of the edge to search
     * - parameter normal: A unit vector containing information about the normal of the edge found
     * - parameter hitPt: The closest point in the edge to the global point provided
     * - parameter edgeD: The ratio of the edge where the point was grabbed, [0-1] inclusive
     * - returns: The distance to the closest edge found
    */
    public func getClosestPointOnEdge(pt: Vector2, _ edgeNum: Int, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ edgeD: CGFloat) -> CGFloat
    {
        return sqrt(getClosestPointOnEdgeSquared(pt, edgeNum, &hitPt, &normal, &edgeD))
    }
    
    /**
     * Given a global point, finds the point on this body that is closest to the given global point, and if it's an edge, information about the edge it resides on
     *
     * - parameter pt: The point to get the closest edge of, in world coordinates
     * - parameter hitPt: The closest point to the pointmass or edge that was found
     * - parameter normal: A unit vector containing information about the normal of the edge found
     * - parameter pointA: The index of the first point of the closest edge found
     * - parameter pointB: The index of the second point of the closest edge found
     * - parameter edgeD: The ratio of the edge where the point was grabbed, [0-1] inclusive
     * - returns: The distance to the closest edge found
    */
    public func getClosestPoint(pt: Vector2, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ pointA: Int, inout _ pointB: Int, inout _ edgeD: CGFloat) -> CGFloat
    {
        pointA = -1
        pointB = -1
        edgeD = 0
        
        var closestD = CGFloat.max
        
        let c = pointMasses.count
        for i in 0..<c
        {
            var tempHit = Vector2()
            var tempNorm = Vector2()
            var tempEdgeD: CGFloat = 0
            
            let dist = getClosestPointOnEdgeSquared(pt, i, &tempHit, &tempNorm, &tempEdgeD)
            
            if(dist < closestD)
            {
                closestD = dist
                pointA = i
                pointB = (i + 1) % c
                
                edgeD = tempEdgeD
                normal = tempNorm
                hitPt = tempHit
            }
        }
        
        return sqrt(closestD)
    }
    
    
    /**
     * Returns the closest point to the given position on an edge of the body's shape
     * The position must be in world coordinates
     * The tolerance is the distance to the edge that will be ignored if larget than that
     * Returns nil if no edge found (no points on the shape), or an array of the parameters that can be used to track down the shape's edge
     *
     * - parameter pt: The point to get the closest edge of, in world coordinates
     * - parameter tolerance: A tolerance distance for the edges detected - any edge farther than this distance is ignored
     * - returns: A tuple containing information about the edge, if it was found, or nil if none was found.
     *  Contents of the tuple:
     *  Vector2: The edge's closest position to the point provided
     *  CGFloat: The ratio of the edge where the point was grabbed, [0-1] inclusive
     *  PointMass: The first point mass on the edge
     *  PointMass: The second point mass on the edge
     */
    public func getClosestEdge(pt: Vector2, _ tolerance: CGFloat = CGFloat.infinity) -> (edgePosition: Vector2, edgeRatio: CGFloat, edgePoint1: PointMass, edgePoint2: PointMass)?
    {
        if(pointMasses.count == 0)
        {
            return nil
        }
        
        var found = false
        var closestP1 = pointMasses[0]
        var closestP2 = pointMasses[0]
        var closestV = Vector2()
        var closestAdotB: CGFloat = 0
        var closestD = CGFloat.infinity
        
        for (i, pm) in pointMasses.enumerate()
        {
            let pm2 = pointMasses[(i + 1) % pointMasses.count]
            let len = (pm.position - pm2.position).magnitude()
            
            var d = (pm.position - pm2.position).normalized()
            
            var adotb = (pm.position - pt) =* d
            
            adotb = adotb < 0 ? 0 : (adotb > len ? len : adotb)
            
            // Apply the dot product to the normalized vector
            d *= adotb
            
            let dis = pt - (pm.position - d)
            
            // Test the distances
            let curD = dis.magnitude()
            
            if(curD < closestD && curD < tolerance)
            {
                found = true
                closestP1 = pm
                closestP2 = pm2
                closestV = pm.position - d
                closestAdotB = adotb / len
                closestD = curD
            }
        }
        
        if(found)
        {
            return (closestV, closestAdotB, closestP1, closestP2)
        }
        
        return nil
    }
    
    /// Find the closest PointMass in this body, given a global point
    public func getClosestPointMass(pos: Vector2, inout _ dist: CGFloat) -> Int
    {
        var closestSQD = CGFloat.max
        var closest = -1
        
        for (i, point) in pointMasses.enumerate()
        {
            let thisD = pos.distanceToSquared(point.position)
            
            if(thisD < closestSQD)
            {
                closestSQD = thisD
                closest = i
            }
        }
        
        dist = sqrt(closestSQD)
        
        return closest
    }
    
    /**
     * Applies a global force to all the point masses in this body at the specified point, in world coordinates.
     * Applying a force with any position off-center of the body (different than derivedPos) will result in an additional torque
     * being applied to the body
     *
     * - parameter pt: The point to apply the force, in world coordinates. Specify .derivedPos to apply a force at the exact center of the body
     * - parameter force: The force to apply to the point masses in this body
    */
    public func addGlobalForce(pt: Vector2, _ force: Vector2)
    {
        if(isStatic)
        {
            return
        }
        
        let torqueF = (derivedPos - pt) =* force.perpendicular()
        
        for point in pointMasses
        {
            let tempR = (point.position - pt).perpendicular()
            
            point.force += force + tempR * torqueF
        }
    }
    
    /**
     * Adds a velocity vector to all the point masses in this body
     *
     * - parameter velocity: The velocity to add to all the point masses in this body
     */
    public func addVelocity(velocity: Vector2)
    {
        if(isStatic)
        {
            return
        }
        
        pointMasses.forEach{ $0.velocity += velocity }
    }
    
    /// Resets the collision information of the body
    public func resetCollisionInfo()
    {
        pointMassCollisions.removeAll(keepCapacity: true)
    }
}