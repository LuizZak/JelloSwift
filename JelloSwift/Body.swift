//
//  Body.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

func ==(lhs: Body, rhs: Body) -> Bool
{
    return lhs === rhs;
}

/// Represents a soft body on the world
class Body: Equatable
{
    /// List of body joints this body participates in
    var joints: [BodyJoint] = [];
    
    /// The base shape for the body
    var baseShape: ClosedShape = ClosedShape();
    
    /// The global shape for the body - this is the same as the base shape, but rotated and translated around the world
    var globalShape: [Vector2] = [];
    
    /// The array of point masses for the body
    var pointMasses: [PointMass] = [];
    /// An array of all the collision that involve this body
    var pointMassCollisions: [BodyCollisionInformation] = [];
    /// Whether to collect the collisions of this body into the pointMassCollisions array. Defaults to false
    var collectCollisions: Bool = false;
    
    /// The scale for this body's shape
    var scale: Vector2 = Vector2();
    /// The derived center position of this body - in world coordinates
    var derivedPos: Vector2 = Vector2();
    /// The derived velocity of this body - in world coordinates. The derivation assumes the mean of the velocity of all the point masses
    var derivedVel: Vector2 = Vector2();
    /// The velocity damping to apply to the body. Values closer to 0 deaccelerate faster, values closer to 1 deaccelerate slower.
    /// 1 never deaccelerates. Values outside the range [0, 1] inclusive may introduce instability
    var velDamping: CGFloat = 0.999;
    
    /// The array of body components for this body object
    var components: [BodyComponent] = [];
    
    // Both these properties are in radians:
    
    /// The derived rotation of the body
    var derivedAngle: CGFloat = 0;
    /// Omega (ω) is the relative angular speed of the body
    var derivedOmega: CGFloat = 0;
    // Utilize to calculate the omega for the body
    private var lastAngle: CGFloat = 0;
    
    /// Gets a list of vertices that represents the current position of each PointMass in this body
    var vertices: [Vector2]
    {
        return pointMasses.map({ $0.position });
    }
    
    /// The bounding box for this body
    var aabb: AABB = AABB();
    
    /// The index of the material in the world material array to use for this body
    var material: Int = 0;
    /// Whether this body is static
    var isStatic: Bool = false;
    /// Whether this body is kinematic - kinematic bodies do not rotate or move their base shape, so they always appear to not move, like a static body, but can be squished and moved, like a dynamic body
    var isKinematic: Bool = false;
    /// Whether this body is pinned - pinned bodies rotate around their axis, but try to remain in place, like a kinematic body
    var isPined: Bool = false;
    /// Whether the body is able to rotate while moving
    var freeRotate: Bool = true;
    
    /// A free field that can be used to attach custom objects to a soft body instance
    var objectTag: Any? = nil;
    
    /// Whether to render this body
    var render: Bool = true;
    
    /// The color to use when rendering this body
    var color: UInt32 = 0xFFFFFFFF;
    
    /// The colision bitmask for this body
    var bitmask: Bitmask = 0xFFFFFFFF;
    
    /// The X-axis bitmask for the body - used for collision filtering
    var bitmaskX: Bitmask = 0;
    /// The Y-axis bitmask for the body - used for collision filtering
    var bitmaskY: Bitmask = 0;
    
    init(world: World?, shape: ClosedShape, pointMasses: [CGFloat] = [1], position: Vector2 = Vector2.Zero, angle: CGFloat = 0, scale: Vector2 = Vector2.One, kinematic: Bool = false, components: [BodyComponentCreator] = [])
    {
        self.aabb = AABB();
        self.derivedPos = position;
        self.derivedAngle = angle;
        self.derivedVel = Vector2();
        self.derivedOmega = 0;
        self.lastAngle = derivedAngle;
        self.scale = scale;
        self.material = 0;
        self.isStatic = false;
        self.isKinematic = kinematic;
        self.render = true;
        self.setShape(shape);
        
        var points = pointMasses;
        
        if(points.count == 1)
        {
            for i in 0..<self.pointMasses.count - 1
            {
                points += (pointMasses[0]);
            }
        }
        
        setMassFromList(points);
        
        self.updateAABB(0, forceUpdate: true);
        
        if let w = world
        {
            w.addBody(self);
        }
        
        // Add the components now
        for comp in components
        {
            comp.attachToBody(self);
        }
    }
    
    /// Adds a body component to this body
    func addComponentType<T: BodyComponent>(componentType: T.Type) -> T
    {
        var instance = componentType(body: self);
        
        self.components += instance;
        
        instance.prepare(self);
        
        return instance;
    }
    
    /// Gets a component on this body that matches the given component type.
    /// If no matching components are found, nil is returned instead
    func getComponentType<T: BodyComponent>(componentType: T.Type) -> T?
    {
        for comp in self.components
        {
            if(comp is T)
            {
                return comp as? T;
            }
        }
        
        return nil;
    }
    
    /// Removes a component from this body
    func removeComponentType<T: BodyComponent>(componentType: T.Type)
    {
        for comp in self.components
        {
            if(comp is T)
            {
                self.components -= comp;
                break;
            }
        }
    }
    
    /// Updates the AABB for this body, including padding for velocity given a timestep.
    /// This function is called by the World object on Update(), so the user should not need this in most cases.
    /// 
    /// :param: elapsed elapsed The elapsed time to update by, usually in seconds
    /// :param: forceUpdate Whether to force the update of the body, even if it's a static body
    func updateAABB(elapsed: CGFloat, forceUpdate: Bool)
    {
        if(isStatic || forceUpdate)
        {
            aabb.clear();
            
            for point in pointMasses
            {
                aabb.expandToInclude(point.position);
                
                if(!isStatic)
                {
                    aabb.expandToInclude(point.position + point.velocity * elapsed);
                }
            }
        }
    }
    
    /// Sets the shape of this body to a new ClosedShape object.  This function
    /// will remove any existing PointMass objects, and replace them with new ones IF
    /// the new shape has a different vertex count than the previous one.  In this case
    /// the mass for each newly added point mass will be set zero.  Otherwise the shape is just
    /// updated, not affecting the existing PointMasses.
    func setShape(shape: ClosedShape)
    {
        baseShape = shape;
        
        if(baseShape.localVertices.count != pointMasses.count)
        {
            pointMasses = [];
            globalShape = [Vector2](count: shape.localVertices.count, repeatedValue: Vector2());
            
            baseShape.transformVertices(&globalShape, worldPos: derivedPos, angleInRadians: derivedAngle, localScale: scale);
            
            for i in 0..<baseShape.localVertices.count
            {
                pointMasses += PointMass(mass: 0.0, position: globalShape[i]);
            }
        }
    }
    
    /// Sets the mass for all the PointMass objects in this body
    func setMassAll(mass: CGFloat)
    {
        for point in pointMasses
        {
            point.mass = mass;
        }
        
        isStatic = isinf(mass);
    }
    
    /// Sets the mass for a single PointMass individually
    func setMassIndividual(index: Int, mass: CGFloat)
    {
        self.pointMasses[index].mass = mass;
    }
    
    /// Sets the mass for all the point masses from a list of masses
    func setMassFromList(masses: [CGFloat])
    {
        var allStatic = true;
        
        for i in 0..<min(masses.count, self.pointMasses.count)
        {
            allStatic = allStatic && isinf(masses[i]);
            
            self.pointMasses[i].mass = masses[i];
        }
        
        isStatic = allStatic;
    }
    
    /// Sets the position and angle of the body manually.
    /// Setting the position and angle resets the current shape to the original base shape of the object
    func setPositionAngle(pos: Vector2, angle: CGFloat, scale: Vector2)
    {
        baseShape.transformVertices(&globalShape, worldPos: pos, angleInRadians: angle, localScale: scale);
        
        for i in 0..<pointMasses.count
        {
            pointMasses[i].position = globalShape[i];
        }
        
        derivedPos = pos;
        derivedAngle = angle;
        
        // Forcefully update the AABB when changing shapes
        if(isStatic)
        {
            updateAABB(0, forceUpdate: true);
        }
    }
    
    /// Derives the global position and angle of this body, based on the average of all the points.
    /// This updates the DerivedPosision, DerivedAngle, and DerivedVelocity properties.
    /// This is called by the World object each Update(), so usually a user does not need to call this.  Instead
    /// you can juse access the DerivedPosition, DerivedAngle, DerivedVelocity, and DerivedOmega properties.
    func derivePositionAndAngle(elapsed: CGFloat)
    {
        // no need it this is a static body, or kinematically controlled.
        if (isStatic || isKinematic)
        {
            return;
        }
        
        if(!isPined)
        {
            // find the geometric center.
            var center = Vector2.Zero;
            var vel = Vector2.Zero;
        
            for p in pointMasses
            {
                center += p.position;
                vel += p.velocity;
            }
        
            center /= pointMasses.count;
            vel /= pointMasses.count;
        
            derivedPos = center;
            derivedVel = vel;
        }
            
        if(freeRotate)
        {
            // find the average angle of all of the masses.
            var angle: CGFloat = 0;
        
            var originalSign: Int = 1;
            var originalAngle: CGFloat = 0;
            
            let c = pointMasses.count;
            for i in 0..<c
            {
                let pm = pointMasses[i];
                
                let baseNorm = baseShape.localVertices[i].normalized();
                let curNorm  = (pm.position - derivedPos).normalized();
                
                var dot = baseNorm =* curNorm;
                
                if (dot > 1.0) { dot = 1.0; }
                if (dot < -1.0) { dot = -1.0; }
                
                var thisAngle = acos(dot);
                
                if (!vectorsAreCCW(baseNorm, curNorm)) { thisAngle = -thisAngle; }
                
                if (i == 0)
                {
                    originalSign = (thisAngle >= 0.0) ? 1 : -1;
                    originalAngle = thisAngle;
                }
                else
                {
                    let diff: CGFloat = (thisAngle - originalAngle);
                    let thisSign: Int = (thisAngle >= 0.0) ? 1 : -1;
                    
                    if (abs(diff) > PI && (thisSign != originalSign))
                    {
                        thisAngle = (thisSign == -1) ? (PI + (PI + thisAngle)) : ((PI - thisAngle) - PI);
                    }
                }
                
                angle += thisAngle;
            }
        
            angle /= CGFloat(pointMasses.count);
        
            derivedAngle = angle;
        
            // now calculate the derived Omega, based on change in angle over time.
            var angleChange = (derivedAngle - lastAngle);
        
            if ((angleChange < 0 ? -angleChange : angleChange) >= PI)
            {
                if (angleChange < 0)
                {
                    angleChange = angleChange + (PI * 2);
                }
                else
                {
                    angleChange = angleChange - (PI * 2);
                }
            }
        
            derivedOmega = angleChange / elapsed;
        
            lastAngle = derivedAngle;
        }
    }
    
    /// This function should add all internal forces to the Force member variable of each PointMass in the body.
    /// These should be forces that try to maintain the shape of the body.
    func accumulateInternalForces()
    {
        for comp in components
        {
            comp.accumulateInternalForces();
        }
    }
    
    /// This function should add all external forces to the Force member variable of each PointMass in the body.
    /// These are external forces acting on the PointMasses, such as gravity, etc.
    func accumulateExternalForces()
    {
        for comp in components
        {
            comp.accumulateExternalForces();
        }
    }
    
    /// Integrates the point masses for this Body.
    func integrate(elapsed: CGFloat)
    {
        if(isStatic)
        {
            return;
        }
        
        for c in 0..<pointMasses.count
        {
            pointMasses[c].integrate(elapsed);
        }
    }
    
    /// Applies the velocity damping to the point masses
    func dampenVelocity()
    {
        if(isStatic)
        {
            return;
        }
        
        for point in pointMasses
        {
            point.velocity *= velDamping;
        }
    }
    
    /// Applies a rotational clockwise torque of a given force on this body
    func applyTorque(force: CGFloat)
    {
        // Accelerate the body
        for var i = 0; i < pointMasses.count; i++
        {
            var pm:PointMass = pointMasses[i];
            
            var diff = (pm.position - derivedPos).normalized().perpendicular();
            
            pm.applyForce(diff * force);
        }
    }
    
    /// Sets the angular velocity for this body
    func setAngularVelocity(vel: CGFloat)
    {
        // Accelerate the body
        for var i = 0; i < pointMasses.count; i++
        {
            let pm:PointMass = pointMasses[i];
            
            var diff = (pm.position - derivedPos).normalized().perpendicular();
            
            pm.velocity = diff * vel;
        }
    }
    
    /// Accumulates the angular velocity for this body
    func addAngularVelocity(vel: CGFloat)
    {
        // Accelerate the body
        for var i = 0; i < pointMasses.count; i++
        {
            let pm:PointMass = pointMasses[i];
            
            var diff = (pm.position - derivedPos).normalized().perpendicular();
            
            pm.velocity += diff * vel;
        }
    }
    
    /// Returns whether a global point is inside this body
    func contains(pt: Vector2) -> Bool
    {
        // Check if the point is inside the AABB
        if(!aabb.contains(pt))
        {
            return false;
        }
        
        // basic idea: draw a line from the point to a point known to be outside the body.  count the number of
        // lines in the polygon it intersects.  if that number is odd, we are inside.  if it's even, we are outside.
        // in this implementation we will always use a line that moves off in the positive X direction from the point
        // to simplify things.
        let endPt = Vector2(aabb.maximum.X + 0.1, pt.Y);
        
        // line we are testing against goes from pt -> endPt.
        var inside = false;
        
        // TODO: Use a foreach instead of a simple for loop to quicken up the iteration of the point masses
        var edgeSt = pointMasses[0].position;
        
        var edgeEnd = Vector2.Zero;
        
        let c = pointMasses.count;
        for var i = 0; i < c; i++
        {
            // the current edge is defined as the line from edgeSt -> edgeEnd.
            edgeEnd = pointMasses[((i + 1) % c)].position;
            
            // perform check now...
            if (((edgeSt.Y <= pt.Y) && (edgeEnd.Y > pt.Y)) || ((edgeSt.Y > pt.Y) && (edgeEnd.Y <= pt.Y)))
            {
                // this line crosses the test line at some point... does it do so within our test range?
                var slope = (edgeEnd.X - edgeSt.X) / (edgeEnd.Y - edgeSt.Y);
                var hitX = edgeSt.X + ((pt.Y - edgeSt.Y) * slope);
                
                if ((hitX >= pt.X) && (hitX <= endPt.X))
                {
                    inside = !inside;
                }
            }
            edgeSt = edgeEnd;
        }
        
        return inside;
    }
    
    /// Returns whether the given line consisting of two points intersects this body
    func intersectsLine(start: Vector2, _ end: Vector2) -> Bool
    {
        // Test whether one or both the points of the line are inside the body
        if(contains(start) || contains(end))
        {
            return true;
        }
        
        // Create and test against a temporary line AABB
        let lineAABB: AABB = AABB(points: [start, end]);
        if(!aabb.intersects(lineAABB))
        {
            return false;
        }
        
        // Test each edge against the line
        var p = Vector2();
        var p1 = Vector2();
        var p2 = Vector2();
        var ua: CGFloat = 0;
        var ub: CGFloat = 0;
        for i in 0..<pointMasses.count
        {
            p1 = pointMasses[i].position;
            p2 = pointMasses[(i + 1) % pointMasses.count].position;
            
            if(lineIntersect(start, end, p1, p2, &p, &ua, &ub))
            {
                return true;
            }
        }
        
        return false;
    }
    
    /// Returns whether the given ray collides with this Body, changing the resulting collision vector before returning
    func raycast(pt1: Vector2, _ pt2: Vector2, inout _ res: Vector2, inout _ rayAABB: AABB?) -> Bool
    {
        // Test whether one or both the points of the line are inside the body
        if(contains(pt1) || contains(pt2))
        {
            return true;
        }
        
        // Create and test against a temporary line AABB
        if let raabb = rayAABB
        {
            
        }
        else
        {
            rayAABB = AABB(points: [pt1, pt2]);
        }
        
        if(!aabb.intersects(rayAABB!))
        {
            return false;
        }
        
        // Test each edge against the line
        let c = pointMasses.count;
        var p = Vector2();
        var p1 = Vector2();
        var p2 = Vector2();
        var col = false;
        var ua: CGFloat = 0;
        var ub: CGFloat = 0;
        
        res = pt2;
        
        for i in 0..<c
        {
            p1 = pointMasses[i].position;
            p2 = pointMasses[(i + 1) % c].position;
            
            if(lineIntersect(pt1, pt2, p1, p2, &p, &ua, &ub))
            {
                res = p;
                col = true;
            }
        }
        
        return col;
    }
    
    /**
     * Given a global point, finds the closest point on an edge of a specified index, returning the squared distance to the edge found
     *
     * :param: pt The point to get the closest edge of, in world coordinates
     * :param: edgeNum The index of the edge to search
     * :param: normal A unit vector containing information about the normal of the edge found
     * :param: hitPt The closest point in the edge to the global point provided
     * :param: edgeD The ratio of the edge where the point was grabbed, [0-1] inclusive
     * :returns: The squared distance to the closest edge found
    */
    func getClosestPointOnEdgeSquared(pt: Vector2, _ edgeNum: Int, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ edgeD: CGFloat) -> CGFloat
    {
        edgeD = 0;
        var dist: CGFloat = 0;
        
        var ptA = pointMasses[edgeNum].position;
        var ptB = pointMasses[(edgeNum + 1) % pointMasses.count].position;
        
        let toP = pt - ptA;
        var E = ptB - ptA;
        
        // get the length of the edge, and use that to normalize the vector.
        let edgeLength = E.magnitude();
        
        if (edgeLength > 0.0000001)
        {
            E /= edgeLength;
        }
        
        // normal
        normal = E.perpendicular();
        
        // calculate the distance!
        let x = toP =* E;
        
        if (x <= 0.0)
        {
            // x is outside the line segment, distance is from pt to ptA.
            dist = pt.distanceToSquared(ptA);
            
            hitPt = ptA;
            
            edgeD = 0;
        }
        else if (x >= edgeLength)
        {
            // x is outside of the line segment, distance is from pt to ptB.
            dist = pt.distanceToSquared(ptB);
            
            hitPt = ptB;
            
            edgeD = 1;
        }
        else
        {
            // point lies somewhere on the line segment.
            let toP3 = Vector3(vec2: toP, z: 0);
            let E3 = toP3 =/ Vector3(vec2: E, z: 0);
            
            dist = E3.Z * E3.Z;
            
            hitPt = ptA + (E * x);
            edgeD = x / edgeLength;
        }
        
        return dist;
    }
    
    /**
     * Given a global point, finds the closest point on an edge of a specified index, returning the distance to the edge found
     *
     * :param: pt The point to get the closest edge of, in world coordinates
     * :param: edgeNum The index of the edge to search
     * :param: normal A unit vector containing information about the normal of the edge found
     * :param: hitPt The closest point in the edge to the global point provided
     * :param: edgeD The ratio of the edge where the point was grabbed, [0-1] inclusive
     * :returns: The distance to the closest edge found
    */
    func getClosestPointOnEdge(pt: Vector2, _ edgeNum: Int, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ edgeD: CGFloat) -> CGFloat
    {
        return sqrt(getClosestPointOnEdgeSquared(pt, edgeNum, &hitPt, &normal, &edgeD));
    }
    
    /**
     * Given a global point, finds the point on this body that is closest to the given global point, and if it's an edge, information about the edge it resides on
     *
     * :param: pt The point to get the closest edge of, in world coordinates
     * :param: hitPt The closest point to the pointmass or edge that was found
     * :param: normal A unit vector containing information about the normal of the edge found
     * :param: pointA The index of the first point of the closest edge found
     * :param: pointB The index of the second point of the closest edge found
     * :param: edgeD The ratio of the edge where the point was grabbed, [0-1] inclusive
     * :returns: The distance to the closest edge found
    */
    func getClosestPoint(pt: Vector2, inout _ hitPt: Vector2, inout _ normal: Vector2, inout _ pointA: Int, inout _ pointB: Int, inout _ edgeD: CGFloat) -> CGFloat
    {
        pointA = -1;
        pointB = -1;
        edgeD = 0;
        
        var closestD = CGFloat.max;
        
        for i in 0..<pointMasses.count
        {
            var tempHit = Vector2();
            var tempNorm = Vector2();
            var tempEdgeD: CGFloat = 0;
            
            let dist = getClosestPointOnEdgeSquared(pt, i, &tempHit, &tempNorm, &tempEdgeD);
            
            if(dist < closestD)
            {
                closestD = dist;
                pointA = i;
                
                if(i < (pointMasses.count - 1))
                {
                    pointB = i + 1;
                }
                else
                {
                    pointB = 0;
                }
                
                edgeD = tempEdgeD;
                normal = tempNorm;
                hitPt = tempHit;
            }
        }
        
        return sqrt(closestD);
    }
    
    
    /**
     * Returns the closest point to the given position on an edge of the body's shape
     * The position must be in world coordinates
     * The tolerance is the distance to the edge that will be ignored if larget than that
     * Returns nil if no edge found (no points on the shape), or an array of the parameters that can be used to track down the shape's edge
     *
     * :param: pt The point to get the closest edge of, in world coordinates
     * :param: tolerance A tolerance distance for the edges detected - any edge farther than this distance is ignored
     * :returns: A tuple containing information about the edge, if it was found, or nil if none was found.
     *  Contents of the tuple:
     *  Vector2: The edge's closest position to the point provided
     *  CGFloat: The ratio of the edge where the point was grabbed, [0-1] inclusive
     *  PointMass: The first point mass on the edge
     *  PointMass: The second point mass on the edge
     */
    func getClosestEdge(pt: Vector2, _ tolerance: CGFloat = CGFloat.infinity) -> (Vector2, CGFloat, PointMass, PointMass)?
    {
        if(pointMasses.count == 0)
        {
            return nil;
        }
        
        var found = false;
        var closestP1 = pointMasses[0];
        var closestP2 = pointMasses[0];
        var closestV = Vector2();
        var closestAdotB: CGFloat = 0;
        var closestD: CGFloat = CGFloat.infinity;
        
        for i in 0..<pointMasses.count
        {
            let pm = pointMasses[i];
            let pm2 = pointMasses[(i + 1) % pointMasses.count];
            let len = (pm.position - pm2.position).magnitude();
            
            var d = (pm.position - pm2.position).normalized();
            
            var adotb = (pm.position - pt) =* d;
            
            adotb = adotb < 0 ? 0 : (adotb > len ? len : adotb);
            
            // Apply the dot product to the normalized vector
            d *= adotb;
            
            let dis = pt - (pm.position - d);
            
            // Test the distances
            let curD = dis.magnitude();
            
            if(curD < closestD && curD < tolerance)
            {
                found = true;
                closestP1 = pm;
                closestP2 = pm2;
                closestV = pm.position - d;
                closestAdotB = adotb / len;
                closestD = curD;
            }
        }
        
        if(found)
        {
            return (closestV, closestAdotB, closestP1, closestP2);
        }
        
        return nil;
    }
    
    /// Find the closest PointMass in this body, given a global point
    func getClosestPointMass(pos: Vector2, inout _ dist: CGFloat) -> Int
    {
        var closestSQD = CGFloat.max;
        var closest = -1;
        var i = 0;
        
        for point in pointMasses
        {
            let thisD = pos.distanceToSquared(point.position);
            
            if(thisD < closestSQD)
            {
                closestSQD = thisD;
                closest = i;
            }
            i++;
        }
        
        dist = sqrt(closestSQD);
        
        return closest;
    }
    
    /**
     * Applies a global force to all the point masses in this body at the specified point, in world coordinates.
     * Applying a force with any position off-center of the body (different than derivedPos) will result in an additional torque
     * being applied to the body
     *
     * :param: pt The point to apply the force, in world coordinates. Specify .derivedPos to apply a force at the exact center of the body
     * :param: force The force to apply to the point masses in this body
    */
    func addGlobalForce(pt: Vector2, _ force: Vector2)
    {
        let tempV1 = Vector3(vec2: derivedPos - pt, z: 0);
        let tempV2 = Vector3(vec2: force, z: 0);
        let torqueF = tempV1.cross2Z(tempV2);
        
        for point in pointMasses
        {
            let tempR = (point.position - pt).perpendicular();
            
            point.force += tempR * torqueF;
            point.force += force;
        }
    }
    
    /// Resets the collision information of the body
    func resetCollisionInfo()
    {
        pointMassCollisions.removeAll(keepCapacity: true);
    }
}