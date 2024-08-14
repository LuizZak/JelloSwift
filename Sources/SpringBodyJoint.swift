//
//  SpringBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint that links two joint links with spring forces
open class SpringBodyJoint: BodyJoint {

    /// The spring coefficient for this spring body joint
    public var springCoefficient: JFloat

    /// The spring damping for this spring body joint
    public var springDamping: JFloat

    /// Optional plasticity information.
    /// If not provided, spring body joint does not undergo plasticity deformations.
    public var plasticity: SpringPlasticity?

    /// In case spring plasticity is available, this is used to limit plasticity
    /// effects.
    var initialRestDistance: RestDistance

    /// Gets or sets the rest distance for this joint
    /// In case the rest distance represents a ranged distance
    /// (`RestDistance.ranged`), the joint only applies forces if the distance
    /// between the links is `dist > restDistance.min && dist < restDistance.max`.
    open var restDistance: RestDistance

    /// Inits a new spring body joint with he specified parameters. Leave the
    /// distance nil to calculate the distance automatically from the current
    /// distance of the two provided joint links
    public init(
        on world: World,
        link1: JointLink,
        link2: JointLink,
        coefficient: JFloat,
        damping: JFloat,
        distance: RestDistance? = nil
    ) {
        self.springCoefficient = coefficient
        self.springDamping = damping
        self.initialRestDistance = 0

        // Automatic distance calculation
        self.restDistance =
                distance ?? .fixed(link1.position.distance(to: link2.position))

        super.init(on: world, link1: link1, link2: link2)

        self.initialRestDistance = restDistance
    }

    /// Resolves this joint
    ///
    /// - Parameter dt: The delta time to update the resolve on
    open override func resolve(_ dt: JFloat) {
        if !enabled {
            return
        }

        let pos1 = bodyLink1.position
        let pos2 = bodyLink2.position

        let dist = pos1.distance(to: pos2)
        // Affordable distance
        if restDistance.inRange(value: dist) {
            return
        }

        let targetDist = restDistance.clamp(value: dist)

        let force = calculateSpringForce(
            posA: pos1, velA: bodyLink1.velocity,
            posB: pos2, velB: bodyLink2.velocity,
            distance: targetDist,
            springK: springCoefficient,
            springD: springDamping
        )

        switch (bodyLink1.isStatic, bodyLink2.isStatic) {
        case (false, false):
            let mass1 = bodyLink1.mass
            let mass2 = bodyLink2.mass
            let massSum = mass1 + mass2

            bodyLink1.applyForce(of:  force * (massSum / mass1))
            bodyLink2.applyForce(of: -force * (massSum / mass2))

        case (false, true):
            bodyLink1.applyForce(of: force)

        case (true, false):
            bodyLink2.applyForce(of: -force)

        case (true, true):
            // No force applied in case both bodies are static
            break
        }

        // Apply plasticity, if present.
        if let plasticity = plasticity {
            restDistance =
                calculatePlasticity(
                    distance: dist,
                    restDistance: restDistance,
                    initialRestDistance: initialRestDistance,
                    plasticity: plasticity
                )
        }
    }
}
