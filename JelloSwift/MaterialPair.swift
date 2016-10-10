//
//  MaterialPair.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents information about the collision response behavior between two bodies
public struct MaterialPair
{
    // Whether the collision between the two bodies should happen
    public var collide = true
    // The elasticity of the point mass when bouncing off the bodies
    public var elasticity: CGFloat = 0.0
    // The relative friction between the two bodies
    public var friction: CGFloat = 1.0
    // A function to call and utilize as a collision filter when figuring out whether the two bodies should collide
    public var collisionFilter: (Body, Int, Body, Int, Int, Vector2, CGFloat) -> (Bool)
    
    public init()
    {
        collide = true
        friction = 0.3
        elasticity = 0.2
        collisionFilter = defaultCollisionFilter
    }
}

// The default collision filter. Always returns true, so all collisions passed through it are approved
public func defaultCollisionFilter(_ bodyA: Body, bodyApm: Int, bodyB: Body, bodyBpm1: Int, bodyBpm2: Int, hitPt: Vector2, normalVel: CGFloat) -> Bool
{
    return true
}
