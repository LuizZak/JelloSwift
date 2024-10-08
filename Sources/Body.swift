//
//  Body.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Performs a reference-equality against two Body instances.
/// Returns true iff lhs === rhs
public func ==(lhs: Body, rhs: Body) -> Bool {
    return lhs === rhs
}

/// Represents a soft body on the world
public final class Body: Equatable {
    /// List of edges on the body
    fileprivate(set) public var edges: [BodyEdge] = []

    /// List of body joints this body participates in
    internal(set) public var joints: ContiguousArray<BodyJoint> = []

    /// The base shape for the body
    public var baseShape = ClosedShape()

    /// The global shape for the body - this is the same as the base shape, but
    /// rotated and translated around the world
    public var globalShape: [Vector2] = []

    /// The array of point masses for the body
    fileprivate(set) public var pointMasses: [PointMass] = []

    /// The scale for this body's shape
    public var scale = Vector2.unit

    /// The derived center position of this body - in world coordinates
    public fileprivate(set) var derivedPos = Vector2.zero

    /// The derived velocity of this body - in world coordinates. The derivation
    /// assumes the mean of the velocity of all the point masses
    public fileprivate(set) var derivedVel = Vector2.zero

    /// The velocity damping to apply to the body. Values closer to 0
    /// decelerate faster, values closer to 1 decelerate slower.
    ///
    /// 1 never decelerates. Values outside the range [0, 1] inclusive may
    /// introduce instability
    public var velDamping: JFloat = 0.999

    /// The array of body components for this body object
    fileprivate var components: ContiguousArray<BodyComponent> = []

    /// Gets the amount of components in this body
    public var componentCount: Int {
        return components.count
    }

    // Both these properties are in radians:

    /// The derived rotation of the body, in radians
    public fileprivate(set) var derivedAngle: JFloat = 0

    /// Omega (ω) is the relative angular speed of the body, in radians/s
    public fileprivate(set) var derivedOmega: JFloat = 0

    // Utilize to calculate the omega for the body
    fileprivate var lastAngle: JFloat = 0

    /// Gets a list of vertices that represents the current position of each
    /// PointMass in this body
    public var vertices: [Vector2] {
        return pointMasses.map { $0.position }
    }

    /// The axis-aligned bounding box for this body's point masses.
    ///
    /// Will be slightly expanded to include the velocity of the points, in case
    /// this body is kinematic, so it won't always match exactly the position of
    /// the point masses.
    public var aabb = AABB()

    /// The index of the material in the world material array to use for this
    /// body.
    public var material = 0

    /// Whether this body is static.
    public var isStatic = false

    /// Whether this body is kinematic - kinematic bodies do not rotate or move
    /// their base shape, so they always appear to not move, like a static body,
    /// but can be squished and moved, like a dynamic body. This effectively
    /// sticks their globalShape to always be around the current derived
    /// position (see `setPositionAngle`).
    public var isKinematic = false

    /// Whether this body is pinned - pinned bodies rotate around their axis,
    /// but try to remain in place, like a kinematic body.
    public var isPined = false

    /// Whether the body is able to rotate while moving.
    public var freeRotate = true

    /// A free field that can be used to attach custom objects to a soft body
    /// instance.
    public var objectTag: Any? = nil

    /// The collision bitmask for this body.
    public var bitmask: Bitmask = 0xFFFFFFFF

    /// The X-axis bitmask for the body - used for collision filtering.
    public var bitmaskX: Bitmask = 0
    /// The Y-axis bitmask for the body - used for collision filtering.
    public var bitmaskY: Bitmask = 0

    /// Whether this body's bitmaskX & bitmaskY are stale.
    /// Used to avoid recalculating bitmasks
    internal var _bitmasksStale: Bool = true

    /// Initializes a new Body instance with a given set of properties.
    ///
    /// - Parameters:
    ///   - world: World to add this body to. Can be omitted to not add it to any
    /// world yet.
    ///   - shape: Closed shape that represents this body's rest shape.
    ///   - pointMasses: An array of masses for each point mass created from the
    /// provided `shape` parameter. If an array of `.count == 1` is provided, that
    /// one mass value is used for all point masses; otherwise length must be
    /// the same as `shape.localVertices.count`, otherwise remaining point masses
    /// will have a default mass of 1.
    ///   - position: Center position for body's shape.
    ///   - angle: Angle - in radians - to initially rotate body with.
    ///   - scale: Scale of body`s rest shape. Is applied on `shape` value to
    /// calculate final rest shape of the body. Defaults to 1.
    ///   - kinematic: Whether this body is kinematic; that is, whether it can
    /// have its base shape move around. If false, the center of the body remains
    /// static while the point masses move around this center.
    ///   - components: Array of body component creators to add to this body.
    public init(
        world: World? = nil,
        shape: ClosedShape,
        pointMasses: [JFloat] = [1],
        position: Vector2 = Vector2.zero,
        angle: JFloat = 0,
        scale: Vector2 = Vector2.unit,
        kinematic: Bool = false,
        components: [BodyComponentCreator] = []
    ) {

        aabb = AABB()
        derivedPos = position
        derivedAngle = angle
        derivedVel = Vector2.zero
        derivedOmega = 0
        lastAngle = derivedAngle
        self.scale = scale
        material = 0
        isStatic = false
        isKinematic = kinematic
        setShape(shape)

        var points = pointMasses

        if points.count == 1 {
            points = .init(repeating: pointMasses[0], count: self.pointMasses.count)
        }

        setMass(fromList: points)

        updateAABB(0, forceUpdate: true)

        world?.addBody(self)

        // Add the components now
        components.forEach { $0.attach(to: self) }
    }

    /// Adds a body component to this body.
    @discardableResult
    public func addComponent(ofType componentType: BodyComponent.Type) -> BodyComponent {
        let instance = componentType.init()

        components.append(instance)

        instance.prepare(self)

        return instance
    }

    /// Gets a component on this body that matches the given component type.
    ///
    /// If no matching components are found, `nil` is returned instead.
    public func component<T: BodyComponent>(ofType componentType: T.Type) -> T? {
        for comp in components {
            if let comp = comp as? T {
                return comp
            }
        }

        return nil
    }

    /// Gets the body component of a specified type in this body and calls a
    /// closure passing it as its parameter.
    ///
    /// Returns without calling the closure, if the body component is not found.
    public func withComponent<T: BodyComponent>(ofType type: T.Type = T.self, do block: (T) throws -> Void) rethrows {
        guard let comp = component(ofType: T.self) else {
            return
        }

        try block(comp)
    }

    /// Removes a component from this body.
    public func removeComponent<T: BodyComponent>(ofType componentType: T.Type) {
        for (i, comp) in components.enumerated() {
            if comp is T {
                components.remove(at: i)
                break
            }
        }
    }

    /// Updates the edges and normals of this body.
    public func updateEdgesAndNormals() {
        updateEdges()
        updateNormals()
    }

    /// Updates the cached edge information of the body.
    public func updateEdges() {
        let c = pointMasses.count

        // Maintain the edge count the same as the point mass count
        if edges.count != c {
            edges = .init(repeating: BodyEdge(), count: c)
        }

        for (i, curP) in pointMasses.enumerated() {
            let j = (i &+ 1) % c
            let nextP = pointMasses[j]

            edges[i] = BodyEdge(
                edgeIndex: i,
                startPointIndex: i,
                endPointIndex: j,
                start: curP.position,
                end: nextP.position
            )
        }
    }

    /// Updates the point normals of the body.
    public func updateNormals() {
        guard var prev = edges.last else { return }

        for (i, curEdge) in edges.enumerated() {
            let edge1N = prev.difference
            let edge2N = curEdge.difference

            let sum = (edge1N + edge2N)

            // Edges are exactly 180º to each other - normal should be the first
            // edge's vector, then
            if sum == .zero {
                pointMasses[i].normal = edge1N
            } else {
                pointMasses[i].normal = sum.perpendicular().normalized()
            }

            prev = curEdge
        }
    }

    /// Updates a single edge in this body.
    public func updateEdge(_ edgeIndex: Int) {
        let j = (edgeIndex &+ 1) % pointMasses.count

        let curP = pointMasses[edgeIndex]
        let nextP = pointMasses[j]

        edges[edgeIndex] =
            BodyEdge(
                edgeIndex: edgeIndex,
                startPointIndex: edgeIndex,
                endPointIndex: j,
                start: curP.position,
                end: nextP.position
            )
    }

    /// Updates the AABB for this body, including padding for velocity given a
    /// time step.
    ///
    /// This function is called by `World.update()`, so the user should not need
    /// this in most cases.
    ///
    /// - parameter elapsed:
    ///     The elapsed time to update by, usually in seconds
    ///
    /// - parameter forceUpdate:
    ///     Whether to force the update of the body, even if it's a static body.
    public func updateAABB(_ elapsed: JFloat, forceUpdate: Bool) {
        guard !isStatic || forceUpdate else {
            return
        }

        aabb.clear()

        for point in pointMasses {
            aabb.expand(toInclude: point.position)

            if !isStatic {
                aabb.expand(toInclude: point.position + point.velocity * elapsed)
            }
        }

        _bitmasksStale = true
    }

    /// Sets the shape of this body to a new ClosedShape object. This function
    /// will remove any existing PointMass objects, and replace them with new
    /// ones IF the new shape has a different vertex count than the previous
    /// one. In this case the mass for each newly added point mass will be set
    /// zero. Otherwise the shape is just updated, not affecting the existing
    /// PointMasses.
    public func setShape(_ shape: ClosedShape) {
        baseShape = shape

        globalShape = .init(
            repeating: Vector2.zero,
            count: shape.localVertices.count
        )

        let matrix = Vector2.matrix(
            scalingBy: scale,
            rotatingBy: derivedAngle,
            translatingBy: derivedPos
        )

        baseShape.transformVertices(&globalShape, matrix: matrix)

        if baseShape.localVertices.count != pointMasses.count {
            pointMasses = []
            pointMasses.reserveCapacity(baseShape.localVertices.count)
            for i in 0..<baseShape.localVertices.count {
                pointMasses.append(PointMass(mass: 0.0, position: globalShape[i]))
            }
        }

        components.forEach { $0.prepare(self) }

        updateEdges()

        _bitmasksStale = true
    }

    /// Sets the mass for all the PointMass objects in this body.
    public func setMassAll(_ mass: JFloat) {
        for i in 0..<pointMasses.count {
            pointMasses[i].mass = mass
        }

        isStatic = mass.isInfinite
    }

    /// Sets the mass for a single PointMass individually.
    public func setMassForPointMass(atIndex index: Int, mass: JFloat) {
        pointMasses[index].mass = mass

        // Re-evaluate whether body is static
        isStatic = pointMasses.any { $0.mass.isInfinite }
    }

    /// Sets the mass for all the point masses from a list of masses.
    /// In case the array count is bigger than the point mass count, it only
    /// sets up to the count of masses in the array, if larger, it sets the
    /// matching masses for all point masses, and ignores the rest of the array.
    public func setMass(fromList masses: [JFloat]) {
        for (mass, i) in zip(masses, 0..<pointMasses.count) {
            pointMasses[i].mass = mass
        }

        // Re-evaluate whether body is static
        isStatic = pointMasses.any { $0.mass.isInfinite }
    }

    /// Sets the position and angle of the body manually.
    ///
    /// Setting the position and angle resets the current shape to the original
    /// base shape of the object.
    public func setPositionAngle(_ pos: Vector2, angle: JFloat, scale: Vector2) {
        let matrix = Vector2.matrix(scalingBy: scale, rotatingBy: angle, translatingBy: pos)

        baseShape.transformVertices(&globalShape, matrix: matrix)

        for (global, i) in zip(globalShape, 0..<pointMasses.count) {
            pointMasses[i].position = global
        }

        updateEdges()

        derivedPos = pos
        derivedAngle = angle

        // Forcefully update the AABB when changing shapes
        if isStatic {
            updateAABB(0, forceUpdate: true)
        }

        _bitmasksStale = true
    }

    /// Derives the global position and angle of this body, based on the average
    /// of all the points.
    ///
    /// This updates the derivedPos, derivedAngle, and derivedVel properties.
    ///
    /// This is called by `World.update()`, so usually a user does not need to
    /// call this. Instead you can just access the `derivedPosition`, `DerivedAngle`,
    /// `derivedVelocity`, and `derivedOmega` properties.
    public func derivePositionAndAngle(_ elapsed: JFloat) {
        // No need if this is a static body, or kinematically controlled.
        if isStatic || isKinematic {
            return
        }

        let currentDerivedPosition = PointMass.averagePosition(of: pointMasses)

        if !isPined {
            // Find the geometric center and average velocity
            derivedPos = currentDerivedPosition
            derivedVel = PointMass.averageVelocity(of: pointMasses)
        }

        if !freeRotate {
            return
        }

        let meanPos = isPined ? currentDerivedPosition : derivedPos

        // find the average angle of all of the masses.
        var angle: JFloat = 0

        var originalSign = 1
        var originalAngle: JFloat = 0

        let c = pointMasses.count
        var first = true
        for (base, pm) in zip(baseShape, pointMasses) {
            let baseNorm = base.normalized()
            let curNorm  = (pm.position - meanPos).normalized()

            var thisAngle = atan2(baseNorm.x * curNorm.y - baseNorm.y * curNorm.x, baseNorm • curNorm)

            if first {
                originalSign = (thisAngle >= 0.0) ? 1 : -1
                originalAngle = thisAngle

                first = false
            } else {
                let diff = (thisAngle - originalAngle)
                let thisSign = (thisAngle >= 0.0) ? 1 : -1

                if abs(diff) > .pi && (thisSign != originalSign) {
                    if thisSign == -1 {
                        thisAngle = .pi + (.pi + thisAngle)
                    } else {
                        thisAngle = (.pi - thisAngle) - .pi
                    }
                }
            }

            angle += thisAngle
        }

        angle /= JFloat(c)

        derivedAngle = angle

        // now calculate the derived Omega, based on change in angle over time.
        var angleChange = (derivedAngle - lastAngle)

        if (angleChange < 0 ? -angleChange : angleChange) >= .pi {
            if angleChange < 0 {
                angleChange = angleChange + (.pi * 2)
            } else {
                angleChange = angleChange - (.pi * 2)
            }
        }

        derivedOmega = angleChange / elapsed

        lastAngle = derivedAngle
    }

    /// This function should add all internal forces to the Force member
    /// variable of each PointMass in the body.
    ///
    /// These should be forces that try to maintain the shape of the body.
    public func accumulateInternalForces(relaxing: Bool = false) {
        for component in components {
            component.accumulateInternalForces(in: self, relaxing: relaxing)
        }
    }

    /// This function should add all external forces to the Force member
    /// variable of each PointMass in the body.
    ///
    /// These are external forces acting on the PointMasses, such as gravity,
    /// etc.
    public func accumulateExternalForces(world: World, relaxing: Bool = false) {
        for component in components {
            component.accumulateExternalForces(on: self, world: world, relaxing: relaxing)
        }
    }

    /// Integrates the point masses for this Body.
    /// Ignored, if body is static.
    public func integrate(_ elapsed: JFloat) {
        if isStatic {
            return
        }

        for i in 0..<pointMasses.count {
            pointMasses[i].integrate(elapsed)
        }

        _bitmasksStale = true
    }

    /// Applies the velocity damping to the point masses.
    /// Ignored, if body is static.
    public func dampenVelocity(_ elapsed: JFloat) {
        if isStatic {
            return
        }

        for i in 0..<pointMasses.count {
            let pointMass = pointMasses[i]

            applyVelocity(-(pointMass.velocity - (pointMass.velocity * velDamping)) * (elapsed * 200), toPointMassAt: i)
        }
    }

    /// Applies a rotational clockwise torque of a given force on this body.
    /// Ignored, if body is static.
    public func applyTorque(of force: JFloat) {
        if isStatic {
            return
        }

        // Accelerate the body
        for i in 0..<pointMasses.count {
            let pm = pointMasses[i]
            let diff = (pm.position - derivedPos).normalized().perpendicular()

            applyForce(diff * force, toPointMassAt: i)
        }
    }

    /// Sets the angular velocity for this body.
    /// Ignored, if body is static.
    ///
    /// The method keeps the average velocity of the point masses the same during
    /// the procedure.
    public func setAngularVelocity(_ vel: JFloat) {
        if isStatic {
            return
        }

        // Accelerate the body
        for (i, pm) in pointMasses.enumerated() {
            let diff = (pm.position - derivedPos).normalized().perpendicular()

            setVelocity(derivedVel + diff * vel, ofPointMassAt: i)
        }
    }

    /// Accumulates the angular velocity for this body
    public func addAngularVelocity(_ vel: JFloat) {
        if isStatic {
            return
        }

        // Accelerate the body
        for (i, pm) in pointMasses.enumerated() {
            let diff = (pm.position - derivedPos).normalized().perpendicular()

            applyVelocity(diff * vel, toPointMassAt: i)
        }
    }

    /// Returns whether a global point is inside this body.
    public func contains(_ pt: Vector2) -> Bool {
        // Check if the point is inside the AABB
        if !aabb.contains(pt) {
            return false
        }

        // basic idea: draw a line from the point to a point known to be outside
        // the body. count the number of lines in the polygon it intersects.
        // if that number is odd, we are inside.
        // if it's even, we are outside.
        // in this implementation we will always use a line that moves off in
        // the X direction from the point to simplify things.
        let endPt: Vector2

        // line we are testing against goes from pt -> endPt.
        var inside = false

        // If the line lies to the left of the body, apply the test going from
        // the point to the left this way we may end up reducing the total
        // amount of edges to test against.
        // This basic assumption may not hold for every body, but for most
        // bodies (specially round), this may hold true most of the time.
        if pt.x < aabb.midX {
            endPt = Vector2(x: aabb.minimum.x - 0.1, y: pt.y)

            for e in edges {
                let edgeSt = e.start
                let edgeEnd = e.end

                // perform check now...

                // The edge lies completely to the right of our imaginary line
                if edgeSt.x > pt.x && edgeEnd.x > pt.x {
                    continue
                }

                // Check if the edge crosses the imaginary horizontal line from
                // top to bottom or bottom to top
                if ((edgeSt.y <= pt.y) && (edgeEnd.y > pt.y)) || ((edgeSt.y > pt.y) && (edgeEnd.y <= pt.y)) {
                    // this line crosses the test line at some point... does it
                    // do so within our test range?
                    let slope = (edgeEnd.x - edgeSt.x) / (edgeEnd.y - edgeSt.y)
                    let hitX = edgeSt.x + ((pt.y - edgeSt.y) * slope)

                    if (hitX <= pt.x) && (hitX >= endPt.x) {
                        inside = !inside
                    }
                }
            }
        } else {
            endPt = Vector2(x: aabb.maximum.x + 0.1, y: pt.y)

            for e in edges {
                let edgeSt = e.start
                let edgeEnd = e.end

                // perform check now...

                // The edge lies completely to the left of our imaginary line
                if edgeSt.x < pt.x && edgeEnd.x < pt.x {
                    continue
                }

                // Check if the edge crosses the imaginary horizontal line from
                // top to bottom or bottom to top
                if ((edgeSt.y <= pt.y) && (edgeEnd.y > pt.y)) || ((edgeSt.y > pt.y) && (edgeEnd.y <= pt.y)) {
                    // this line crosses the test line at some point... does it
                    // do so within our test range?
                    let slope = (edgeEnd.x - edgeSt.x) / (edgeEnd.y - edgeSt.y)
                    let hitX = edgeSt.x + ((pt.y - edgeSt.y) * slope)

                    if (hitX >= pt.x) && (hitX <= endPt.x) {
                        inside = !inside
                    }
                }
            }
        }

        return inside
    }

    /// Returns whether the given line consisting of two points intersects this
    /// body.
    public func intersectsLine(from start: Vector2, to end: Vector2) -> Bool {
        // Create and test against a temporary line AABB
        if !aabb.intersects(AABB(min: min(start, end), max: max(start, end))) {
            return false
        }

        // Test each edge against the line
        for edge in edges {
            if lineIntersect(lineA: (start, end), lineB: (edge.start, edge.end)) != nil {
                return true
            }
        }

        return false
    }

    /// Tests a ray starting and ending at a given interval, returning the point
    /// at which the ray intersects this body the closest to `start`.
    ///
    /// If the ray does not crosses this body, `nil` is returned, instead.
    public func raycast(from start: Vector2, to end: Vector2) -> Vector2? {
        // Test against minimal ray AABB
        if !aabb.intersects(AABB(of: start, end)) {
            return nil
        }

        // Test each edge against the line
        var p1 = Vector2.zero
        var p2 = Vector2.zero

        var closestHit: Vector2?

        for e in edges {
            p1 = e.start
            p2 = e.end

            if let (p, _, _) = lineIntersect(lineA: (start, closestHit ?? end), lineB: (p1, p2)) {
                closestHit = p
            }
        }

        return closestHit
    }

    /// Given a global point, finds the closest point on an edge of a specified
    /// index, returning the squared distance to the edge found.
    ///
    /// - Precondition: Body has `pointMass.count > 0`.
    ///
    /// - Parameters:
    ///   - pt: The point to get the closest edge of, in world coordinates
    ///   - edgeNum: The index of the edge to search
    /// - Returns: A tuple containing the results of the test, with fields:
    ///      - **hitPoint**: The closest point in the edge to the global
    /// point provided
    ///      - **normal**: A unit vector containing information about the
    /// normal of the edge found
    ///      - **edgeD**: The ratio of the edge where the point was grabbed,
    /// [0-1] inclusive
    ///      - **distance**: The squared distance to the closest edge found
    public func closestPointSquared(
        to pt: Vector2,
        onEdge edgeNum: Int
    ) -> (hitPoint: Vector2, normal: Vector2, edgeD: JFloat, distance: JFloat) {
        assert(pointMasses.count > 0)

        var hitPt: Vector2 = .zero
        var normal: Vector2 = .zero
        var edgeD: JFloat = 0

        var dist: JFloat = 0

        let edge = edges[edgeNum]

        let ptA = edge.start
        let ptB = edge.end

        let toP = pt - ptA

        // normal
        normal = edge.normal

        // calculate the distance!
        let x = toP • edge.difference

        if x <= 0.0 {
            // x is outside the line segment, distance is from pt to ptA.
            dist = pt.distanceSquared(to: ptA)

            hitPt = ptA

            edgeD = 0
        } else if x >= edge.length {
            // x is outside of the line segment, distance is from pt to ptB.
            dist = pt.distanceSquared(to: ptB)

            hitPt = ptB

            edgeD = 1
        } else {
            // point lies somewhere on the line segment.
            let pd = (toP • edge.normal)
            dist = pd * pd

            hitPt = ptA + (edge.difference * x)
            edgeD = x / edge.length
        }

        return (hitPt, normal, edgeD, dist)
    }

    /// Given a global point, finds the closest point on an edge of a specified
    /// index, returning the distance to the edge found.
    ///
    /// - Precondition: Body has `pointMass.count > 0`.
    ///
    /// - Parameters:
    ///   - pt: The point to get the closest edge of, in world coordinates
    ///   - edgeNum: The index of the edge to search
    /// - Returns: A tuple containing the results of the test, with fields:
    ///      - **hitPoint**: The closest point in the edge to the global
    /// point provided
    ///      - **normal**: A unit vector containing information about the
    /// normal of the edge found
    ///      - **edgeD**: The ratio of the edge where the point was grabbed,
    /// [0-1] inclusive
    ///      - **distance**: The distance to the closest edge found
    public func closestPoint(
        to pt: Vector2,
        onEdge edgeNum: Int
    ) -> (hitPoint: Vector2, normal: Vector2, edgeD: JFloat, distance: JFloat) {
        let result = closestPointSquared(to: pt, onEdge: edgeNum)

        return (result.hitPoint, result.normal, result.edgeD, sqrt(result.distance))
    }

    /// Given a global point, finds the point on this body that is closest to the
    /// given global point, and if it's an edge, information about the edge it
    /// resides on.
    ///
    /// - Precondition: Body has `pointMass.count > 0`.
    ///
    /// - Parameter pt: The point to get the closest edge of, in world coordinates
    /// - Returns:  A tuple containing the results of the test, with fields:
    ///      - **hitPoint**: The closest point in the edge to the global
    /// point provided
    ///      - **normal**: A unit vector containing information about the
    /// normal of the edge found
    ///      - **pointA**: The index of the first point of the edge
    ///      - **pointB**: The index of the second point of the edge
    ///      - **edgeD**: The ratio of the edge where the point was grabbed,
    /// [0-1] inclusive
    ///      - **distance**: The distance to the closest edge found
    public func closestPoint(
        to pt: Vector2
    ) -> (hitPoint: Vector2, normal: Vector2, pointA: Int, pointB: Int, edgeD: JFloat, distance: JFloat) {
        assert(pointMasses.count > 0)

        var pointA = -1
        var pointB = -1
        var edgeD: JFloat = 0
        var normal: Vector2 = .zero
        var hitPt: Vector2 = .zero

        var closestD = JFloat.infinity

        let c = pointMasses.count
        for i in 0..<c {
            let (tempHit, tempNorm, tempEdgeD, dist) = closestPointSquared(to: pt, onEdge: i)

            if dist < closestD {
                closestD = dist
                pointA = i
                pointB = (i &+ 1) % c

                edgeD = tempEdgeD
                normal = tempNorm
                hitPt = tempHit
            }
        }

        return (hitPt, normal, pointA, pointB, edgeD, sqrt(closestD))
    }


    /// Returns the closest point to the given position on an edge of the body's
    /// shape.
    ///
    /// The position must be in world coordinates.
    ///
    /// The tolerance is the distance to the edge that will be ignored if larger
    /// than that.
    ///
    /// Returns nil if boy has no edges, or a tuple of the parameters that can be
    /// used to track down the shape's edge.
    ///
    /// - Parameters:
    ///   - pt: The point to get the closest edge of, in world coordinates
    ///   - tolerance: A tolerance distance for the edges detected - any edge
    ///         farther than this distance is ignored
    /// - Returns: A tuple containing information about the edge, if it was
    /// found, or nil if none was found.
    /// Contents of the tuple:
    ///     - **edgePosition**: The edge's closest position to the point provided
    ///     - **edgeRatio**: The ratio of the edge where the point was grabbed,
    /// [0-1] inclusive
    ///     - **edgePoint1**: The first point mass on the edge
    ///     - **edgePoint2**: The second point mass on the edge
    public func closestEdge(
        to pt: Vector2,
        withTolerance tolerance: JFloat = JFloat.infinity
    ) -> (edgePosition: Vector2, edgeRatio: JFloat, edgePoint1: Int, edgePoint2: Int)? {
        if edges.count == 0 || pointMasses.count == 0 {
            return nil
        }

        var found = false
        var closestP1 = 0// pointMasses[0]
        var closestP2 = 0// closestP1
        var edgePosition = Vector2.zero
        var edgeRatio: JFloat = 0
        var closestD = JFloat.infinity

        for edge in edges {
            let pm = pointMasses[edge.startPointIndex]

            let aDotB = ((pm.position - pt) • edge.difference).clamped(minimum: 0, maximum: edge.length)

            // Apply the dot product to the normalized vector - this projects
            // the point on top of the edge
            let d = edge.difference * aDotB

            let dis = pt - (pm.position - d)

            // Test the distances
            let curD = dis.magnitude

            if curD < closestD && curD < tolerance {
                found = true
                closestP1 = edge.startPointIndex
                closestP2 = edge.endPointIndex
                edgePosition = pm.position - d
                edgeRatio = aDotB / edge.length
                closestD = curD
            }
        }

        if found {
            return (edgePosition, edgeRatio, closestP1, closestP2)
        }

        return nil
    }

    /// Find the closest PointMass index in this body, given a global point
    /// - precondition: There is at least one point mass in this body
    public func closestPointMass(to pos: Vector2) -> (point: Int, distance: JFloat) {
        assert(pointMasses.count > 0)

        var closestSQD = JFloat.greatestFiniteMagnitude
        var closest: Int!

        for (i, point) in pointMasses.enumerated() {
            let thisD = pos.distanceSquared(to: point.position)

            if thisD < closestSQD {
                closestSQD = thisD
                closest = i
            }
        }

        return (closest, sqrt(closestSQD))
    }

    /// Applies a global force to all the point masses in this body at the
    /// specified point, in world coordinates.
    ///
    /// Applying a force with any position off-center of the body (different than
    /// `derivedPos`) will result in an additional torque being applied to the
    /// body, making it spin.
    ///
    /// Ignored, if body is static.
    ///
    /// - Parameters:
    ///   - force: The point to apply the force, in world coordinates.
    /// Specify .derivedPos to apply a force at the exact center of the body
    ///   - pt: The force to apply to the point masses in this body
    public func applyForce(_ force: Vector2, atGlobalPoint pt: Vector2) {
        if isStatic {
            return
        }

        let torqueF = (derivedPos - pt) • force.perpendicular()

        for i in 0..<pointMasses.count {
            let point = pointMasses[i]
            let tempR = (point.position - pt).perpendicular()

            applyForce(force + tempR * torqueF, toPointMassAt: i)
        }
    }

    /// Applies a global force to all the point masses in this body.
    ///
    /// Ignored, if body is static.
    ///
    /// - Parameters:
    ///   - force: The point to apply the force, in world coordinates.
    public func applyGlobalForce(_ force: Vector2) {
        if isStatic {
            return
        }

        for i in 0..<pointMasses.count {
            applyForce(force, toPointMassAt: i)
        }
    }

    /// Adds a velocity vector to all the point masses in this body.
    /// Does nothing, if body is static.
    ///
    /// - Parameter velocity: The velocity to add to all the point masses in this
    /// body
    public func addVelocity(_ velocity: Vector2) {
        if isStatic {
            return
        }

        for i in 0..<pointMasses.count {
            applyVelocity(velocity, toPointMassAt: i)
        }
    }

    /// Modifies the average velocity of all point masses to a certain value.
    /// The method keeps the individual difference of velocity between the point
    /// masses and the average body velocity while making the operation.
    /// Does nothing, if body is static.
    ///
    /// - Parameter velocity: The velocity to set. Set as `.zero` to reset average
    /// velocity of the body to 0.
    public func setAverageVelocity(_ velocity: Vector2) {
        if isStatic {
            return
        }

        for (i, pointMass) in pointMasses.enumerated() {
            let diff = pointMass.velocity - derivedVel

            setVelocity(velocity + diff, ofPointMassAt: i)
        }
    }
}

// MARK: - Point mass changes
extension Body {

    /// Applies a force to a single point mass.
    ///
    /// - Parameter force: A force to apply.
    /// - Parameter index: The index of the point mass on this body to affect.
    public func applyForce(_ force: Vector2, toPointMassAt index: Int) {
        pointMasses[index].applyForce(of: force)
    }

    /// Applies a relative velocity change to a single point mass.
    ///
    /// - Parameter velocity: A velocity to apply.
    /// - Parameter index: The index of the point mass on this body to affect.
    public func applyVelocity(_ velocity: Vector2, toPointMassAt index: Int) {
        pointMasses[index].velocity += velocity
    }

    /// Sets the absolute velocity of a single point mass.
    ///
    /// - Parameter velocity: The new absolute velocity of the point mass.
    /// - Parameter index: The index of the point mass on this body to affect.
    public func setVelocity(_ velocity: Vector2, ofPointMassAt index: Int) {
        pointMasses[index].velocity = velocity
    }

    /// Sets the absolute position of a single point mass.
    ///
    /// - Parameter position: The new absolute position of the point mass.
    /// - Parameter index: The index of the point mass on this body to affect.
    public func setPosition(_ position: Vector2, ofPointMassAt index: Int) {
        pointMasses[index].position = position

        _bitmasksStale = true
    }
}
