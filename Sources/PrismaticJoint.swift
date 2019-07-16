//
//  PrismaticBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint that links two joint links along an angled axis.
open class PrismaticBodyJoint: SpringBodyJoint {
    private var omega1: JFloat = 0
    private var omega2: JFloat = 0

    private var angle1: JFloat {
        return (bodyLink1.angle + referenceAngle1).truncatingRemainder(dividingBy: .pi * 2)
    }
    private var angle2: JFloat {
        return (bodyLink2.angle + referenceAngle2).truncatingRemainder(dividingBy: .pi * 2)
    }

    private var previousAngle1: JFloat = 0
    private var previousAngle2: JFloat = 0

    /// The reference angle of the first joint link
    public var referenceAngle1: JFloat

    /// The reference angle of the second joint link
    public var referenceAngle2: JFloat

    public init(on world: World,
                link1: JointLink,
                link2: JointLink,
                coefficient: JFloat,
                damping: JFloat,
                referenceAngle1: JFloat? = nil,
                referenceAngle2: JFloat? = nil,
                distance: RestDistance? = nil,
                plasticity: SpringPlasticity? = nil) {

        self.referenceAngle1 = 0
        self.referenceAngle2 = 0

        super.init(on: world, link1: link1, link2: link2, coefficient: coefficient, damping: damping, distance: distance, plasticity: plasticity)

        previousAngle1 = angle1
        previousAngle2 = angle2

        self.referenceAngle1 = referenceAngle1 ?? angle1
        self.referenceAngle2 = referenceAngle2 ?? angle2
    }

    open override func resolve(_ dt: JFloat) {
        super.resolve(dt)

        omega1 = previousAngle1 - angle1
        omega2 = previousAngle2 - angle2

        previousAngle1 = angle1
        previousAngle2 = angle2

        let diff = (bodyLink2.position - bodyLink1.position).angle

        let strength: JFloat = 15

        if bodyLink1.supportsAngling {
            bodyLink1.applyTorque(distance(alpha: angle1, beta: diff) * strength + (strength * omega1))
        }

        if bodyLink2.supportsAngling {
            bodyLink2.applyTorque(distance(alpha: angle2, beta: diff) * strength + (strength * omega2))
        }

        // Project links towards the rest angle of the joint
        project(bodyLink2, on: bodyLink1, angle: angle1)
    }

    private func project(_ link1: JointLink, on link2: JointLink, angle: JFloat) {
        let angleDir = Vector2(x: 1, y: 0).rotated(by: angle)
        let adotb = ((link1.position - link2.position) • angleDir)
        
        let force =
            calculateSpringForce(posA: link1.position,
                                 velA: link1.velocity,
                                 posB: link2.position + (angleDir * adotb),
                                 velB: link2.velocity,
                                 distance: 0,
                                 springK: springCoefficient,
                                 springD: springDamping)

        let mass1 = link1.mass
        let mass2 = link2.mass
        let massSum = mass1 + mass2
        
        link1.applyForce(of:  force * (massSum / mass1))
        link2.applyForce(of: -force * (massSum / mass2))
    }
}

/**
 * Shortest distance (angular) between two angles.
 * It will be in range [0, 180].
 */
func distance<F: FloatingPoint>(alpha: F, beta: F) -> F {
    let sign: F = (alpha - beta >= 0 && alpha - beta <= F.pi) || (alpha - beta <= -F.pi && alpha - beta >= -(F.pi * 2)) ? 1 : -1
    let phi = abs(beta - alpha).truncatingRemainder(dividingBy: .pi * 2)       // This is either the distance or 360 - distance
    let distance = phi > .pi ? (.pi * 2) - phi : phi
    return distance * sign
}
