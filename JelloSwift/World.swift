//
//  World.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents a simulation world, containing soft bodies and the code utilized to make them interact with each other
class World: NSObject
{
    // The bodies contained within this world
    var bodies: [Body] = [];
    
    // PRIVATE VARIABLES
    var worldLimits:AABB = AABB();
    var worldSize:Vector2 = Vector2();
    var worldGridStep:Vector2 = Vector2();
    
    var penetrationThreshold: CGFloat = 0;
    var penetrationCount: Int = 0;
    
    // material chart.
    var materialPairs: [[MaterialPair]] = [];
    var defaultMatPair: MaterialPair = MaterialPair();
    var materialCount: Int = 0;
    
    var collisionList: [BodyCollisionInformation] = [];
    
    override init()
    {
        super.init();
        self.clear();
    }
    
    // Clears the world's contents and readies it to be loaded again
    func clear()
    {
        // Clear all the bodies
        for b in bodies
        {
            b.pointMassCollisions.removeAll(keepCapacity: true);
            b.pointMasses.removeAll(keepCapacity: true);
        }
        
        // Reset bodies
        bodies = [];
        collisionList = [];
        
        // Reset
        materialCount = 1;
        materialPairs = [];
        
        defaultMatPair = MaterialPair();
        
        materialPairs += [defaultMatPair];
        
        var min = Vector2(-20.0, -20.0);
        var max = Vector2( 20.0,  20.0);
        
        setWorldLimits(min, max);
    
        penetrationThreshold = 0.3;
    }
    
    // WORLD SIZE
    func setWorldLimits(min: Vector2, _ max: Vector2)
    {
        worldLimits = AABB(min: min, max: max);
        
        worldSize = max - min;
        
        worldGridStep = worldSize / 32;
    }
    
    // MATERIALS
    // Adds a new material to the world. All previous material data is kept intact.
    func addMaterial() -> Int
    {
        var old = materialPairs;
        materialCount++;
        
        materialPairs = [];
        
        // replace old data.
        for i in 0..<materialCount
        {
            materialPairs.append([MaterialPair]());
            
            for j in 0..<materialCount
            {
                if ((i < (materialCount - 1)) && (j < (materialCount - 1)))
                {
                    materialPairs[i] += old[i][j];
                }
                else
                {
                    materialPairs[i] += defaultMatPair;
                }
            }
        }
        
        return materialCount - 1;
    }
    
    // Enables or disables collision between 2 materials.
    func setMaterialPairCollide(a: Int, b: Int, collide: Bool)
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].collide = collide;
            materialPairs[b][a].collide = collide;
        }
    }
    
    // Sets the collision response variables for a pair of materials.
    func setMaterialPairData(a: Int, b: Int, friction: CGFloat, elasticity: CGFloat)
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].friction = friction;
            materialPairs[a][b].elasticity = elasticity;
            
            materialPairs[b][a].friction = friction;
            materialPairs[b][a].elasticity = elasticity;
        }
    }
    
    // Sets a user function to call when 2 bodies of the given materials collide.
    func setMaterialPairFilterCallback(a: Int, b: Int, filter: (Body, Int, Body, Int, Int, Vector2, CGFloat) -> (Bool))
    {
        if ((a >= 0) && (a < materialCount) && (b >= 0) && (b < materialCount))
        {
            materialPairs[a][b].collisionFilter = filter;
            materialPairs[b][a].collisionFilter = filter;
        }
    }
    
    // Adds a body to the world. Bodies do this automatically on their constructors, you should not need to call this method most of the times.
    func addBody(body: Body)
    {
        if(!bodies.contains(body))
        {
            bodies += body;
        }
    }
    
    // Remove a body from the world. Call this outside of an update to remove the body.
    func removeBody(body: Body)
    {
        bodies -= body;
    }
    
    // Finds the closest PointMass in the world to a given point
    func getClosestPointMass(pt: Vector2) -> (Body?, PointMass?)
    {
        var retBody: Body? = nil;
        var retPoint: PointMass? = nil;
        
        var closestD = CGFloat.max;
        
        for body in bodies
        {
            var dist:CGFloat = 0;
            
            var pm = body.getClosestPointMass(pt, &dist);
            
            if(dist < closestD)
            {
                closestD = dist;
                retBody = body;
                retPoint = body.pointMasses[pm];
            }
        }
        
        return (retBody, retPoint);
    }
    
    // Given a global, get a body (if any) that contains this point.
    // Useful for picking objects with a cursor, etc.
    func getBodyContaining(pt: Vector2, bit: Bitmask) -> Body?
    {
        for body in bodies
        {
            if((bit == 0 || (body.bitmask & bit) != 0) && body.contains(pt))
            {
                return body;
            }
        }
        
        return nil;
    }
    
    // Given a global point, get all bodies (if any) that contain this point.
    // Useful for picking objects with a cursor, etc.
    func getBodiesContaining(pt: Vector2, bit: Bitmask) -> [Body]
    {
        var ret: [Body] = [];
        
        for body in bodies
        {
            if((bit == 0 || (body.bitmask & bit) != 0) && body.contains(pt))
            {
                ret += body;
            }
        }
        
        return ret;
    }
    
    // Returns a vector of bodies intersecting with the given line
    func getBodiesIntersecting(start: Vector2, end: Vector2, bit: Bitmask) -> [Body]
    {
        var ret: [Body] = [];
        
        for body in bodies
        {
            if((bit == 0 || (body.bitmask & bit) != 0) && body.intersectsLine(start, end))
            {
                ret += body;
            }
        }
        
        return ret;
    }
    
    // Casts a ray between the given points and returns the first body it comes in contact with
    func rayCast(start: Vector2, end: Vector2, inout _ retPt:Vector2, bit: Bitmask, _ ignoreList:[Body] = []) -> Body?
    {
        var closestD = start.distanceTo(end);
        var closestB:Body? = nil;
        var aabb:AABB? = nil;
        var lastBody:Body? = nil;
        var ret: [Body] = [];
        
        retPt = end;
        
        for body in bodies
        {
            if((bit == 0 || (body.bitmask & bit) != 0) && (!ignoreList.contains(body)))
            {
                if(body.raycast(start, end, &retPt, &aabb))
                {
                    lastBody = body;
                }
            }
        }
        
        return lastBody;
    }
    
    // Updates the world by a specific timestep
    func update(elapsed: CGFloat)
    {
        penetrationCount = 0;
        
        for body in bodies
        {
            body.derivePositionAndAngle(elapsed);
            body.accumulateExternalForces();
            body.accumulateInternalForces();
            
            body.integrate(elapsed);
            
            body.updateAABB(elapsed, forceUpdate: true);
            body.resetCollisionInfo();
            updateBodyBitmask(body);
        }
        
        let c:Int = bodies.count;
        for i in 0..<c
        {
            var body1 = bodies[i];
            
            for j in (i+1)..<c
            {
                var body2 = bodies[j];
                
                // another early-out - both bodies are static.
                if (((body1.isStatic) && (body2.isStatic)) ||
                    ((body1.bitmaskX & body2.bitmaskX) == 0) &&
                    ((body1.bitmaskY & body2.bitmaskY) == 0))
                {
                    continue;
                }
                
                // bitmask filtering
                if((body1.bitmask & body2.bitmask) == 0)
                {
                    continue;
                }
                
                // early out - these bodies materials are set NOT to collide
                if (!materialPairs[body1.material][body2.material].collide)
                {
                    continue;
                }
                
                // broad-phase collision via AABB.
                // early out
                if(!body1.aabb.intersects(body2.aabb))
                {
                    continue;
                }
                
                // okay, the AABB's of these 2 are intersecting.  now check for collision of A against B.
                bodyCollide(body1, body2);
                
                // and the opposite case, B colliding with A
                bodyCollide(body2, body1);
            }
        }
        
        handleCollisions();
        
        for body in bodies
        {
            body.dampenVelocity();
        }
    }
    
    // Checks collision between two bodies, and store the collision information if they do
    func bodyCollide(bA: Body, _ bB: Body)
    {
        var bApCount = bA.pointMasses.count;
        var bBpCount = bB.pointMasses.count;
        
        var boxB = bB.aabb;
        
        for i in 0..<bApCount
        {
            var pt = bA.pointMasses[i].position;
            
            // early out - if this point is outside the bounding box for bodyB, skip it!
            if (!boxB.contains(pt))
            {
                continue;
            }
            
            // early out - if this point is not inside bodyB, skip it!
            if (!bB.contains(pt))
            {
                continue;
            }
            
            var prevPt: Int = (i > 0) ? i - 1 : bApCount - 1;
            
            var prev = bA.pointMasses[prevPt].position;
            var next = bA.pointMasses[(i + 1) % bApCount].position;
            
            // now get the normal for this point. (NOT A UNIT VECTOR)
            var fromPrev = pt - prev;
            
            var toNext = next - pt;
            
            var ptNorm = fromPrev + toNext;
            
            ptNorm.perpendicularThis();
            
            // this point is inside the other body.  now check if the edges on either side intersect with and edges on bodyB.
            var closestAway = CGFloat.infinity;
            var closestSame = CGFloat.infinity;
            
            var infoAway = BodyCollisionInformation();
            var infoSame = BodyCollisionInformation();
            
            infoAway.bodyA = bA;
            infoAway.bodyApm = i;
            infoAway.bodyB = bB;
            
            infoSame = infoAway;
            
            var found = false;
            
            for j in 0..<bBpCount
            {
                var edgeD: CGFloat = 0;
                
                var b1 = j;
                var b2 = (j + 1) % (bBpCount);
                
                var normal = Vector2();
                var hitPt = Vector2();
                
                // test against this edge.
                var dist = bB.getClosestPointOnEdgeSquared(pt, j, &hitPt, &normal, &edgeD)
                
                // only perform the check if the normal for this edge is facing AWAY from the point normal.
                var dot = ptNorm =* normal;
                
                if (dot <= 0.0)
                {
                    if dist < closestAway
                    {
                        closestAway = dist;
                    
                        infoAway.bodyBpmA = b1;
                        infoAway.bodyBpmB = b2;
                        infoAway.edgeD = edgeD;
                        infoAway.hitPt = hitPt;
                        infoAway.normal = normal;
                        infoAway.penetration = dist;
                        found = true;
                    }
                }
                else
                {
                    if (dist < closestSame)
                    {
                        closestSame = dist;
                
                        infoSame.bodyBpmA = b1;
                        infoSame.bodyBpmB = b2;
                        infoSame.edgeD = edgeD;
                        infoSame.hitPt = hitPt;
                        infoSame.normal = normal;
                        infoSame.penetration = dist;
                    }
                }
            }
            
            // we've checked all edges on BodyB.  add the collision info to the stack.
            if ((found) && (closestAway > penetrationThreshold) && (closestSame < closestAway))
            {
                if(bA.collectCollisions)
                {
                    bA.pointMassCollisions += infoSame;
                }
                
                if(bB.collectCollisions)
                {
                    bB.pointMassCollisions += infoSame;
                }
                
                infoSame.penetration = sqrt(infoSame.penetration);
                collisionList += infoSame;
            }
            else
            {
                if(bA.collectCollisions)
                {
                    bA.pointMassCollisions += infoAway;
                }
                
                if(bB.collectCollisions)
                {
                    bB.pointMassCollisions += infoAway;
                }
                
                infoAway.penetration = sqrt(infoAway.penetration);
                collisionList += infoAway;
            }
        }
    }
    
    // Solves the collisions between bodies
    func handleCollisions()
    {
        let c = collisionList.count;
        for var i = 0; i < c; i++
        {
            let info = collisionList[i];
            
            if(info.bodyA == nil || info.bodyB == nil)
            {
                continue;
            }
            
            let bodyA = info.bodyA!;
            let bodyB = info.bodyB!;
            
            let A:PointMass = bodyA.pointMasses[info.bodyApm];
            let B1:PointMass = bodyB.pointMasses[info.bodyBpmA];
            let B2:PointMass = bodyB.pointMasses[info.bodyBpmB];
            
            // Velocity changes as a result of collision
            let bVel = (B1.velocity + B2.velocity) * 0.5;
            
            let relVel = A.velocity - bVel;
            let relDot = relVel =* info.normal;
            
            let material = materialPairs[bodyA.material][bodyB.material];
            
            if(!material.collisionFilter(bodyA, info.bodyApm, bodyB, info.bodyBpmA, info.bodyBpmB, info.hitPt, relDot))
            {
                continue;
            }
            
            if(info.penetration > penetrationThreshold)
            {
                NSLog("penetration above Penetration Threshold!!  penetration = \(info.penetration), threshold = \(penetrationThreshold), difference = \(info.penetration-penetrationThreshold)");
                
                penetrationCount++;
                continue;
            }
            
            let b1inf = 1.0 - info.edgeD;
            let b2inf = info.edgeD;
            
            let b2MassSum = B1.mass + B2.mass;
            
            let massSum = A.mass + b2MassSum;
            
            var rev_massSum = 1.0 / massSum;
            var Amove: CGFloat = info.penetration * (b2MassSum * rev_massSum);
            var Bmove: CGFloat = info.penetration * (A.mass * rev_massSum);
            
            if(isinf(A.mass))
            {
                Amove = 0;
                Bmove = info.penetration + 0.001;
            }
            else if(isinf(b2MassSum))
            {
                Amove = info.penetration + 0.001;
                Bmove = 0;
            }
            
            let B1move = Bmove * b1inf;
            let B2move = Bmove * b2inf;
            
            let AinvMass = isinf(A.mass) ? 0 : 1.0 / A.mass;
            let BinvMass = isinf(b2MassSum) ? 0 : 1.0 / b2MassSum;
            
            let jDenom = AinvMass + BinvMass;
            let elas = 1 + material.elasticity;
            
            let rev_jDenom = 1.0 / jDenom;
            let j = -((relVel * elas) =* info.normal) * rev_jDenom;
            
            if(!isinf(A.mass) && isinf(b2MassSum))
            {
                A.position += info.normal * Amove;
            }
            
            if(!isinf(B1.mass))
            {
                B1.position -= info.normal * B1move;
            }
            if(!isinf(B2.mass))
            {
                B2.position -= info.normal * B2move;
            }
            
            let tangent = info.normal.perpendicular();
            
            var friction = material.friction;
            var f = (relVel =* tangent) * friction * rev_jDenom;
            
            if(relDot <= 0.0001)
            {
                if(!isinf(A.mass))
                {
                    var rev_AMass = 1.0 / A.mass;
                    
                    A.velocity += (info.normal * (j * rev_AMass)) - (tangent * (f * rev_AMass));
                }
                
                if(!isinf(b2MassSum))
                {
                    var rev_BMass = 1.0 / b2MassSum;
                    
                    var jComp = info.normal * j * rev_BMass;
                    var fComp = tangent * (f / rev_BMass);
                    
                    B1.velocity -= (jComp * b1inf) - (fComp * b1inf);
                    B2.velocity -= (jComp * b2inf) - (fComp * b2inf);
                }
            }
        }
        
        collisionList.removeAll(keepCapacity: true);
    }
    
    // Update bodies' bitmask for early collision filtering
    func updateBodyBitmask(body: Body)
    {
        var box = body.aabb;
        
        var rev_Divider = worldGridStep / CGFloat(1.0);
        
        var min = (box.minimum - worldGridStep) * rev_Divider;
        var max = (box.maximum - worldGridStep) * rev_Divider;
        
        if(max.X < 0) { max.X = 0; } else if(max.X > 32) { max.X = 32; }
        if(max.Y < 0) { max.Y = 0; } else if(max.Y > 32) { max.Y = 32; }
        
        if(min.X < 0) { min.X = 0; } else if(min.X > 32) { min.X = 32; }
        if(min.Y < 0) { min.Y = 0; } else if(min.Y > 32) { min.Y = 32; }
        
        body.bitmaskX = 0;
        
        for i in Int(min.X)...Int(max.X)
        {
            body.bitmaskX +& i;
        }
        
        for i in Int(min.Y)...Int(max.Y)
        {
            body.bitmaskY +& i;
        }
    }
}