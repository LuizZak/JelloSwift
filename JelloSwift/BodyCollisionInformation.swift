//
//  BodyCollisionInformation.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Encapsulates information about a collision between two soft bodies
public struct BodyCollisionInformation: Equatable
{
    public var bodyA: Body
    public var bodyApm: Int = -1
    
    public var bodyB: Body
    public var bodyBpmA: Int = -1
    public var bodyBpmB: Int = -1
    
    public var hitPt = Vector2.zero
    public var edgeD: CGFloat = 0
    public var normal = Vector2.zero
    public var penetration: CGFloat = 0
    
    public init(bodyA: Body, bodyApm: Int, bodyB: Body)
    {
        self.bodyA = bodyA
        self.bodyApm = bodyApm
        self.bodyB = bodyB
        bodyBpmA = -1
        bodyBpmB = -1
    }
    
    public init(bodyA: Body, bodyApm: Int, bodyB: Body, bodyBpmA: Int, bodyBpmB: Int)
    {
        self.bodyA = bodyA
        self.bodyApm = bodyApm
        self.bodyB = bodyB
        self.bodyBpmA = bodyBpmA
        self.bodyBpmB = bodyBpmB
    }
}

public func ==(lhs: BodyCollisionInformation, rhs: BodyCollisionInformation) -> Bool
{
    return lhs.bodyA == rhs.bodyA && lhs.bodyApm == rhs.bodyApm && lhs.bodyB == rhs.bodyB && lhs.bodyBpmA == rhs.bodyBpmA && lhs.bodyBpmB == rhs.bodyBpmB && lhs.edgeD == rhs.edgeD && lhs.hitPt == rhs.hitPt && lhs.normal == rhs.normal && lhs.penetration == rhs.penetration
}
