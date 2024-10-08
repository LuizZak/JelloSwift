//
//  BodyCollisionInformation.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

// Encapsulates information about a collision between two soft bodies
public struct BodyCollisionInformation {
    /// First body in collision, and the body that is penetrating the second
    /// body.
    public var bodyA: Body
    /// Point mass index that is penetrating the second body.
    public var bodyApm: Int = -1

    /// Second body in collision, and the body that is being penetrated.
    public var bodyB: Body
    /// First point mass index for the edge being penetrated
    public var bodyBpmA: Int = -1
    /// Second point mass index for the edge being penetrated
    public var bodyBpmB: Int = -1

    /// Global point at which the bodies are colliding.
    /// This point is always projected on top of the edge bodyBpmA - bodyBpmB
    public var hitPt = Vector2.zero
    /// A value from 0 - 1 specifying at which point in the edge
    /// bodyBpmA - bodyBpmB is the penetration occurring.
    public var edgeD: JFloat = 0
    /// Global normal for the collision. Always the penetrated edge's normal.
    public var normal = Vector2.zero
    /// Penetration distance.
    /// Is the distance required to move bodyApm in order to solve the collision
    public var penetration: JFloat = 0

    /// Inits this collision information with no edge information.
    public init(bodyA: Body, bodyApm: Int, bodyB: Body) {
        self.bodyA = bodyA
        self.bodyApm = bodyApm
        self.bodyB = bodyB
        bodyBpmA = -1
        bodyBpmB = -1
    }

    /// Inits this collision information with an edge associated to bodyB
    public init(bodyA: Body, bodyApm: Int, bodyB: Body, bodyBpmA: Int, bodyBpmB: Int) {
        self.bodyA = bodyA
        self.bodyApm = bodyApm
        self.bodyB = bodyB
        self.bodyBpmA = bodyBpmA
        self.bodyBpmB = bodyBpmB
    }
}
