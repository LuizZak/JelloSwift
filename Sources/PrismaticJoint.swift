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
    }
}
