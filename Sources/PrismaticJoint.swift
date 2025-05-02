//
//  PrismaticBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint that links two joint links along an angled axis.
open class PrismaticBodyJoint: SpringBodyJoint {
    private var angle1: JFloat {
        return (bodyLink1.angle + referenceAngle1).truncatingRemainder(dividingBy: .pi * 2)
    }
    private var angle2: JFloat {
        return (bodyLink2.angle + referenceAngle2).truncatingRemainder(dividingBy: .pi * 2)
    }

    /// The reference angle of the first joint link
    public var referenceAngle1: JFloat

    /// The reference angle of the second joint link
    public var referenceAngle2: JFloat

    public var torsionSpringCoefficient: JFloat
    public var torsionSpringDamping: JFloat

    public init(
        on world: World,
        link1: JointLink,
        link2: JointLink,
        coefficient: JFloat,
        damping: JFloat,
        torsionCoefficient: JFloat,
        torsionDamping: JFloat,
        referenceAngle1: JFloat? = nil,
        referenceAngle2: JFloat? = nil,
        distance: RestDistance? = nil,
        plasticity: SpringPlasticity? = nil
    ) {
        self.referenceAngle1 = 0
        self.referenceAngle2 = 0
        self.torsionSpringCoefficient = torsionCoefficient
        self.torsionSpringDamping = torsionDamping

        super.init(
            on: world,
            link1: link1,
            link2: link2,
            coefficient: coefficient,
            damping: damping,
            distance: distance,
            plasticity: plasticity
        )

        self.referenceAngle1 = referenceAngle1 ?? angle1
        self.referenceAngle2 = referenceAngle2 ?? angle2
    }

    open override func resolve(_ dt: JFloat) {
        super.resolve(dt)

        let diff = (bodyLink2.position - bodyLink1.position).angle

        if bodyLink1.supportsAngling {
            let torque = calculateTorsionSpringTorque(
                angle: angle1, angularMomentum: bodyLink1.angularVelocity,
                targetAngle: diff,
                targetAngularMomentum: 0.0,
                springK: torsionSpringCoefficient,
                springD: torsionSpringDamping
            )
            bodyLink1.applyTorque(torque)
        }

        if bodyLink2.supportsAngling {
            let torque = calculateTorsionSpringTorque(
                angle: angle2, angularMomentum: bodyLink2.angularVelocity,
                targetAngle: diff,
                targetAngularMomentum: 0.0,
                springK: torsionSpringCoefficient,
                springD: torsionSpringDamping
            )
            bodyLink2.applyTorque(torque)
        }

        // Project links towards the rest angle of the joint
        if bodyLink1.supportsAngling {
            //project(bodyLink1, on: bodyLink2, angle: angle2)
        } else if bodyLink2.supportsAngling {
            //project(bodyLink2, on: bodyLink1, angle: angle1)
        }
    }

    private func project(_ link1: JointLink, on link2: JointLink, angle: JFloat) {
        let angleDir = Vector2(x: 1, y: 0).rotated(by: angle)
        let adotb = ((link1.position - link2.position) • angleDir)

        let force = calculateSpringForce(
            posA: link1.position,
            velA: link1.velocity,
            posB: link2.position + (angleDir * adotb),
            velB: link2.velocity,
            distance: 0,
            springK: springCoefficient,
            springD: springDamping
        )

        let mass1 = link1.mass
        let mass2 = link2.mass
        let massSum = mass1 + mass2

        link1.applyForce(of:  force * (massSum / mass1))
        link2.applyForce(of: -force * (massSum / mass2))
    }
}
