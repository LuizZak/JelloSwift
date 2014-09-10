//
//  BodyCollisionInformation.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Encapsulates information about a collision between two soft bodies
struct BodyCollisionInformation: Equatable
{
    var bodyA: Body?;
    var bodyApm: Int;
    
    var bodyB: Body?;
    var bodyBpmA: Int;
    var bodyBpmB: Int;
    
    var hitPt: Vector2 = Vector2();
    var edgeD: CGFloat = 0;
    var normal: Vector2 = Vector2();
    var penetration: CGFloat = 0;
    
    init()
    {
        self.bodyApm = -1;
        self.bodyBpmA = -1;
        self.bodyBpmB = -1;
    }
    
    init(bodyA: Body, bodyApm: Int, bodyB: Body, bodyBpmA: Int, bodyBpmB: Int)
    {
        self.bodyA = bodyA;
        self.bodyApm = bodyApm;
        self.bodyB = bodyB;
        self.bodyBpmA = bodyBpmA;
        self.bodyBpmB = bodyBpmB;
    }
}

func ==(lhs: BodyCollisionInformation, rhs: BodyCollisionInformation) -> Bool
{
    return lhs.bodyA == rhs.bodyA && lhs.bodyApm == rhs.bodyApm && lhs.bodyB == rhs.bodyB && lhs.bodyBpmA == rhs.bodyBpmA && lhs.bodyBpmB == rhs.bodyBpmB && lhs.edgeD == rhs.edgeD && lhs.hitPt == rhs.hitPt && lhs.normal == rhs.normal && lhs.penetration == rhs.penetration;
}