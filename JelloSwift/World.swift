//
//  World.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a simulation world, containing soft bodies and the code utilized to make them interact with each other
public final class World
{
    /// The bodies contained within this world
    public var bodies: ContiguousArray<Body> = []
    /// The joints contained within this world
    public var joints: ContiguousArray<BodyJoint> = []
    
    // PRIVATE VARIABLES
    fileprivate var worldLimits = AABB()
    fileprivate var worldSize = Vector2.Zero
    fileprivate var worldGridStep = Vector2.Zero
    
    public var penetrationThreshold: CGFloat = 0
    public var penetrationCount = 0
    
    // material chart.
    public var materialPairs: [[MaterialPair]] = []
    public var defaultMatPair = MaterialPair()
    fileprivate var materialCount = 0
    
    fileprivate var collisionList: [BodyCollisionInformation] = []
    
    /// The object to report collisions to
    public weak var collisionObserver: CollisionObserver?
    
    public init()
    {
        self.clear()
    }
    
    /// Clears the world's contents and readies it to be loaded again
    public func clear()
    {
        // Clear all the bodies
        for b in bodies
        {
            b.pointMassCollisions.removeAll(keepingCapacity: true)
        }
        
        // Reset bodies
        bodies = []
        collisionList = []
        
        // Reset
        defaultMatPair = MaterialPair()
        
        materialCount = 1
        materialPairs = [[defaultMatPair]]
        
        let min = Vector2(-20.0, -20.0)
        let max = Vector2( 20.0,  20.0)
        
        setWorldLimits(min, max)
    
        penetrationThreshold = 0.3
    }
    
    /// WORLD SIZE
    public func setWorldLimits(_ min: Vector2, _ max: Vector2)
    {
        worldLimits = AABB(min: min, max: max)
        
        worldSize = max - min
        
        // Divide the world into 1024 boxes (32 x 32) for broad-phase collision detection
        worldGridStep = worldSize / 32
    }
    
    /// MATERIALS
    /// Adds a new material to the world. All previous material data is kept intact.
    public func addMaterial() -> Int
    {
        let old = materialPairs
        materialCount += 1
        
        materialPairs = []
        
        // replace old data.
        for i in 0..<materialCount
        {
            materialPairs.append([])
            
            for j in 0..<materialCount
            {
                if ((i < (materialCount - 1)) && (j < (materialCount - 1)))
                {
                    materialPairs[i] += old[i][j]
                }
                else
                {
                    materialPairs[i] += defaultMatPair
                }
            }
        }
        
        return materialCount - 1
    }
    
    /// Enables or disables collision between 2 materials.
    public func setMaterialPairCollide(_ a: Int, b: Int, collide: Bool)
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].collide = collide
            materialPairs[b][a].collide = collide
        }
    }
    
    /// Sets the collision response variables for a pair of materials.
    public func setMaterialPairData(_ a: Int, b: Int, friction: CGFloat, elasticity: CGFloat)
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].friction = friction
            materialPairs[a][b].elasticity = elasticity
            
            materialPairs[b][a].friction = friction
            materialPairs[b][a].elasticity = elasticity
        }
    }
    
    /// Sets a user function to call when 2 bodies of the given materials collide.
    public func setMaterialPairFilterCallback(_ a: Int, b: Int, filter: @escaping (Body, Int, Body, Int, Int, Vector2, CGFloat) -> (Bool))
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].collisionFilter = filter
            materialPairs[b][a].collisionFilter = filter
        }
    }
    
    /// Adds a body to the world. Bodies do this automatically on their constructors, you should not need to call this method most of the times.
    public func addBody(_ body: Body)
    {
        if(!bodies.contains(body))
        {
            bodies += body
        }
    }
    
    /// Removes a body from the world. Call this outside of an update to remove the body.
    public func removeBody(_ body: Body)
    {
        bodies -= body
    }
    
    /// Adds a joint to the world. Joints call this automatically during their initialization
    public func addJoint(_ joint: BodyJoint)
    {
        if(!joints.contains(joint))
        {
            joints += joint
            
            // Setup the joint parenthood
            joint.bodyLink1.body.joints += joint
            joint.bodyLink2.body.joints += joint
        }
    }
    
    /// Removes a joint from the world
    public func removeJoint(_ joint: BodyJoint)
    {
        joint.bodyLink1.body.joints -= joint
        joint.bodyLink2.body.joints -= joint
        
        joints -= joint
    }
    
    /// Finds the closest PointMass in the world to a given point
    public func getClosestPointMass(_ pt: Vector2) -> (Body, PointMass)?
    {
        var ret: (Body, PointMass)? = nil
        
        var closestD = CGFloat.greatestFiniteMagnitude
        
        for body in bodies
        {
            var dist:CGFloat = 0
            let pm = body.getClosestPointMass(pt, &dist)
            
            if(dist < closestD)
            {
                closestD = dist
                ret = (body, pm)
            }
        }
        
        return ret
    }
    
    /// Given a global, get a body (if any) that contains this point.
    /// Useful for picking objects with a cursor, etc.
    public func getBodyContaining(_ pt: Vector2, bit: Bitmask) -> Body?
    {
        return bodies.firstOrDefault { body in ((bit == 0 || (body.bitmask & bit) != 0) && body.contains(pt)) }
    }
    
    /// Given a global point, get all bodies (if any) that contain this point.
    /// Useful for picking objects with a cursor, etc.
    public func getBodiesContaining(_ pt: Vector2, bit: Bitmask) -> [Body]
    {
        return bodies.filter { (($0.bitmask & bit) != 0 || bit == 0) && $0.contains(pt) }
    }
    
    /// Returns a vector of bodies intersecting with the given line
    public func getBodiesIntersecting(_ start: Vector2, end: Vector2, bit: Bitmask) -> [Body]
    {
        return bodies.filter { (($0.bitmask & bit) != 0 || bit == 0) && $0.intersectsLine(start, end) }
    }
    
    /**
     * Casts a ray between the given points and returns the first body it comes in contact with
     * 
     * - parameter start: The start point to cast the ray from, in world coordinates
     * - parameter end: The end point to end the ray cast at, in world coordinates
     * - parameter bit: An optional collision bitmask that filters the bodies to collide using a bitwise AND (|) operation.
     *             If the value specified is 0, collision filtering is ignored and all bodies are considered for collision
     * - parameter ignoreList: A custom list of bodies that will be ignored during collision checking. Provide an empty list
     *                    to consider all bodies in the world
     *
     * :return: An optional tuple containing the farthest point reached by the ray, and a Body value specifying the body that was closest to the ray, if it hit any body, or nil if it hit nothing.
     */
    public func rayCast(_ start: Vector2, end: Vector2, bit: Bitmask = 0, ignoreList:[Body] = []) -> (retPt: Vector2, body: Body)?
    {
        var aabb:AABB! = nil
        var lastBody:Body? = nil
        
        var retPt: Vector2 = end
        
        for body in bodies
        {
            if((bit == 0 || (body.bitmask & bit) != 0) && !ignoreList.contains(body))
            {
                if(body.raycast(start: start, end: end, farPoint: &retPt, rayAABB: &aabb))
                {
                    lastBody = body
                }
            }
        }
        
        if let body = lastBody
        {
            return (retPt, body)
        }
        
        return nil
    }
    
    /**
     * Updates the world by a specific timestep
     *
     * - parameter elapsed: The elapsed time to update by, usually in seconds
     */
    public func update(_ elapsed: CGFloat)
    {
        penetrationCount = 0
        
        // Update the bodies
        for body in bodies
        {
            body.derivePositionAndAngle(elapsed)
            
            // Only update edge and normals pre-accumulation if the body has components
            if(body.componentCount > 0)
            {
                body.updateEdgesAndNormals()
            }
            
            body.accumulateExternalForces()
            body.accumulateInternalForces()
            
            body.integrate(elapsed)
            body.updateEdgesAndNormals()
            
            body.updateAABB(elapsed, forceUpdate: true)
            body.resetCollisionInfo()
            
            updateBodyBitmask(body)
        }
        
        // Update the joints
        for joint in joints
        {
            joint.resolve(elapsed)
        }
        
        let c = bodies.count
        for (i, body1) in bodies.enumerated()
        {
            innerLoop: for j in (i + 1)..<c
            {
                let body2 = bodies[j]
                
                // bitmask filtering
                if((body1.bitmask & body2.bitmask) == 0)
                {
                    continue
                }
                
                // another early-out - both bodies are static.
                if ((body1.isStatic && body2.isStatic) ||
                    ((body1.bitmaskX & body2.bitmaskX) == 0) &&
                    ((body1.bitmaskY & body2.bitmaskY) == 0))
                {
                    continue
                }
                
                // broad-phase collision via AABB.
                // early out
                if(!body1.aabb.intersects(body2.aabb))
                {
                    continue
                }
                
                // early out - these bodies materials are set NOT to collide
                if (!materialPairs[body1.material][body2.material].collide)
                {
                    continue
                }
                
                // Joints relationship: if on body is joined to another by a joint, check the joint's rule for collision
                for j in body1.joints
                {
                    if(j.bodyLink1.body == body1 && j.bodyLink2.body == body2 ||
                       j.bodyLink2.body == body1 && j.bodyLink1.body == body2)
                    {
                        if(!j.allowCollisions)
                        {
                            continue innerLoop
                        }
                    }
                }
                
                // okay, the AABB's of these 2 are intersecting.  now check for collision of A against B.
                bodyCollide(body1, body2)
                
                // and the opposite case, B colliding with A
                bodyCollide(body2, body1)
            }
        }
        
        // Notify collisions that will happen
        if let observer = collisionObserver
        {
            for collision in collisionList
            {
                observer.bodiesDidCollide(collision)
            }
        }
        
        handleCollisions()
        
        for body in bodies
        {
            body.dampenVelocity(elapsed)
        }
    }
    
    /// Checks collision between two bodies, and store the collision information if they do
    fileprivate func bodyCollide(_ bA: Body, _ bB: Body)
    {
        let bBpCount = bB.pointMasses.count
        
        for (i, pmA) in bA.pointMasses.enumerated()
        {
            let pt = pmA.position
            
            if (!bB.contains(pt))
            {
                continue
            }
            
            let ptNorm = bA.pointNormals[i]
            
            // this point is inside the other body.  now check if the edges on either side intersect with and edges on bodyB.
            var closestAway = CGFloat.infinity
            var closestSame = CGFloat.infinity
            
            var infoAway = BodyCollisionInformation(bodyA: bA, bodyApm: i, bodyB: bB)
            var infoSame = infoAway
            
            var found = false
            
            for j in 0..<bBpCount
            {
                let b1 = j
                let b2 = (j + 1) % (bBpCount)
                
                var normal = Vector2.Zero
                var hitPt = Vector2.Zero
                var edgeD: CGFloat = 0
                
                // test against this edge.
                let dist = bB.getClosestPointOnEdgeSquared(pt, j, &hitPt, &normal, &edgeD)
                
                // only perform the check if the normal for this edge is facing AWAY from the point normal.
                let dot = ptNorm • normal
                
                if (dot <= 0.0)
                {
                    if dist < closestAway
                    {
                        closestAway = dist
                    
                        infoAway.bodyBpmA = b1
                        infoAway.bodyBpmB = b2
                        infoAway.edgeD = edgeD
                        infoAway.hitPt = hitPt
                        infoAway.normal = normal
                        infoAway.penetration = dist
                        found = true
                    }
                }
                else
                {
                    if (dist < closestSame)
                    {
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
            
            // we've checked all edges on BodyB.  add the collision info to the stack.
            if (found && (closestAway > penetrationThreshold) && (closestSame < closestAway))
            {
                if(bA.collectCollisions)
                {
                    bA.pointMassCollisions += infoSame
                }
                
                if(bB.collectCollisions)
                {
                    bB.pointMassCollisions += infoSame
                }
                
                infoSame.penetration = sqrt(infoSame.penetration)
                collisionList += infoSame
            }
            else
            {
                if(bA.collectCollisions)
                {
                    bA.pointMassCollisions += infoAway
                }
                
                if(bB.collectCollisions)
                {
                    bB.pointMassCollisions += infoAway
                }
                
                infoAway.penetration = sqrt(infoAway.penetration)
                collisionList += infoAway
            }
        }
    }
    
    /// Solves the collisions between bodies
    fileprivate func handleCollisions()
    {
        for info in collisionList
        {
            guard let bodyA = info.bodyA, let bodyB = info.bodyB else {
                continue
            }
            
            let A = bodyA.pointMasses[info.bodyApm]
            let B1 = bodyB.pointMasses[info.bodyBpmA]
            let B2 = bodyB.pointMasses[info.bodyBpmB]
            
            // Velocity changes as a result of collision
            let bVel = (B1.velocity + B2.velocity) / 2
            
            let relVel = A.velocity - bVel
            let relDot = relVel • info.normal
            
            let material = materialPairs[bodyA.material][bodyB.material]
            
            if(!material.collisionFilter(bodyA, info.bodyApm, bodyB, info.bodyBpmA, info.bodyBpmB, info.hitPt, relDot))
            {
                continue
            }
            
            if(info.penetration > penetrationThreshold)
            {
                NSLog("penetration above Penetration Threshold!!  penetration = \(info.penetration), threshold = \(penetrationThreshold), difference = \(info.penetration-penetrationThreshold)")
                
                penetrationCount += 1
                continue
            }
            
            let b1inf = 1.0 - info.edgeD
            let b2inf = info.edgeD
            
            let b2MassSum = B1.mass + B2.mass
            
            let massSum = A.mass + b2MassSum
            
            // Amount to move each party of the collision
            let Amove: CGFloat
            let Bmove: CGFloat
            
            // Static detection - when one of the parties is static, the other should move the total amount of the penetration
            if(A.mass.isInfinite)
            {
                Amove = 0
                Bmove = info.penetration + 0.001
            }
            else if(b2MassSum.isInfinite)
            {
                Amove = info.penetration + 0.001
                Bmove = 0
            }
            else
            {
                Amove = info.penetration * (b2MassSum / massSum)
                Bmove = info.penetration * (A.mass / massSum)
            }
            
            if(!A.mass.isInfinite)
            {
                A.position += info.normal * Amove
            }
            
            if(!B1.mass.isInfinite)
            {
                B1.position -= info.normal * (Bmove * b1inf)
            }
            if(!B2.mass.isInfinite)
            {
                B2.position -= info.normal * (Bmove * b2inf)
            }
            
            if(relDot <= 0.0001 && (!A.mass.isInfinite || !b2MassSum.isInfinite))
            {
                let AinvMass: CGFloat = A.mass.isInfinite ? 0 : 1.0 / A.mass
                let BinvMass: CGFloat = b2MassSum.isInfinite ? 0 : 1.0 / b2MassSum
                
                let jDenom: CGFloat = AinvMass + BinvMass
                let elas: CGFloat = 1 + material.elasticity
                
                let j: CGFloat = -((relVel * elas) • info.normal) / jDenom
                
                let tangent: Vector2 = info.normal.perpendicular()
                
                let friction: CGFloat = material.friction
                let f: CGFloat = (relVel • tangent) * friction / jDenom
                
                if(!A.mass.isInfinite)
                {
                    A.velocity += (info.normal * (j / A.mass)) - (tangent * (f / A.mass))
                }
                
                if(!b2MassSum.isInfinite)
                {
                    let jComp = info.normal * j / b2MassSum
                    let fComp = tangent * (f * b2MassSum)
                    
                    B1.velocity -= (jComp * b1inf) - (fComp * b1inf)
                    B2.velocity -= (jComp * b2inf) - (fComp * b2inf)
                }
            }
        }
        
        collisionList.removeAll(keepingCapacity: true)
    }
    
    /// Update bodies' bitmask for early collision filtering
    fileprivate func updateBodyBitmask(_ body: Body)
    {
        let box = body.aabb
        
        let rev_Divider = worldGridStep / CGFloat(1.0)
        
        let minVec = max(Vector2.Zero, min(Vector2(32, 32), (box.minimum - worldGridStep) * rev_Divider))
        let maxVec = max(Vector2.Zero, min(Vector2(32, 32), (box.maximum - worldGridStep) * rev_Divider))
        
        assert(minVec.X >= 0 && minVec.X <= 32 && minVec.Y >= 0 && minVec.Y <= 32)
        assert(maxVec.X >= 0 && maxVec.X <= 32 && maxVec.Y >= 0 && maxVec.Y <= 32)
        
        body.bitmaskX = 0
        body.bitmaskY = 0
        
        // In case the body is contained within an invalid bound, disable collision completely
        if(minVec.X.isNaN || minVec.Y.isNaN || maxVec.X.isNaN || maxVec.Y.isNaN)
        {
            return
        }
        
        for i in Int(minVec.X)...Int(maxVec.X)
        {
            body.bitmaskX +& i
        }
        
        for i in Int(minVec.Y)...Int(maxVec.Y)
        {
            body.bitmaskY +& i
        }
    }
}
