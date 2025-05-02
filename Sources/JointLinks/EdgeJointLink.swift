//
//  EdgeBodyJointLink.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint link that links to an edge of a body
open class EdgeJointLink: JointLink {
    /// The edge index on the list of edges from the body that this joint links
    /// to
    fileprivate let _edgeIndex: Int
    /// The first point mass this joint is linked to
    fileprivate let _pointMass1: Int
    /// The second point mass this joint is linked to
    fileprivate let _pointMass2: Int

    /// The ratio of the edge this edge joint is linked to.
    /// Values must range between [0 - 1] inclusive, and dictate the middle
    /// point of the edge.
    /// Specifying either 0 or 1 makes this edge joint link behave essentially
    /// like a `PointJointLink`
    open var edgeRatio: JFloat

    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body

    /// Gets the type of joint this joint link represents
    public let linkType = LinkType.edge

    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    open var position: Vector2 {
        let pm1 = body.pointMasses[_pointMass1]
        let pm2 = body.pointMasses[_pointMass2]

        return calculateVectorRatio(
            pm1.position,
            vec2: pm2.position,
            ratio: edgeRatio
        )
    }

    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        let pm1 = body.pointMasses[_pointMass1]
        let pm2 = body.pointMasses[_pointMass2]

        return calculateVectorRatio(
            pm1.velocity,
            vec2: pm2.velocity,
            ratio: edgeRatio
        )
    }

    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        let pm1 = body.pointMasses[_pointMass1]
        let pm2 = body.pointMasses[_pointMass2]

        return pm1.mass * (1 - edgeRatio) + pm2.mass * (edgeRatio)
    }

    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    open var isStatic: Bool {
        let pm1 = body.pointMasses[_pointMass1]
        let pm2 = body.pointMasses[_pointMass2]

        return body.isStatic || (pm1.mass.isInfinite && pm2.mass.isInfinite)
    }

    /// Gets or sets a value specifying whether this joint link supports angling
    /// and torque forces.
    open var supportsAngling: Bool

    /// The angle of the joint.
    /// For edge joints, this is the angle of the edge.
    open var angle: JFloat {
        return body.edges[_edgeIndex].difference.angle
    }

    /// Gets the angular velocity for this edge.
    /// The angular velocity is computed as the average of the angular velocity
    /// of both particles.
    open var angularVelocity: JFloat {
        let pointMassIndex0 = body.edges[_edgeIndex].startPointIndex
        let pointMassIndex1 = body.edges[_edgeIndex].endPointIndex

        let center = body.edges[_edgeIndex].center

        let pointMass0 = body.pointMasses[pointMassIndex0]
        let pointMass1 = body.pointMasses[pointMassIndex1]

        let velocity0 = pointMass0.velocity
        let velocity1 = pointMass1.velocity

        let angular0 = velocity0.cross(pointMass0.position - center)
        let angular1 = velocity1.cross(pointMass1.position - center)

        return (angular0 + angular1) / 2
    }

    /// Inits a new edge joint link with the specified parameters
    public init(body: Body, edgeIndex: Int, edgeRatio: JFloat = 0.5, supportsAngling: Bool = true) {
        self.body = body
        _edgeIndex = edgeIndex
        _pointMass1 = edgeIndex % body.pointMasses.count
        _pointMass2 = (edgeIndex + 1) % body.pointMasses.count

        self.edgeRatio = edgeRatio
        self.supportsAngling = supportsAngling
    }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        body.applyForce(force * (1 - edgeRatio), toPointMassAt: _pointMass1)
        body.applyForce(force * (edgeRatio), toPointMassAt: _pointMass2)
    }

    /// Applies a direct positional translation of this joint link by a given
    /// offset.
    ///
    /// - parameter offset: An offset to apply to the member(s) of this joint link.
    open func translate(by offset: Vector2) {
        // TODO: Correctness with different edge ratios
        body.setPosition(body.pointMasses[_pointMass1].position + offset, ofPointMassAt: _pointMass1)
        body.setPosition(body.pointMasses[_pointMass2].position + offset, ofPointMassAt: _pointMass2)
    }

    /// Applies a torque (rotational) force to the subject of this joint link.
    ///
    /// - Parameter force: A torque force to apply to the subject of this joint
    /// link.
    open func applyTorque(_ force: JFloat) {
        //body.applyTorque(of: force)

        let direction = body.edges[_edgeIndex].difference.perpendicular()

        body.applyForce(direction * force * (1 - edgeRatio), toPointMassAt: _pointMass1)
        body.applyForce(-direction * force * (edgeRatio), toPointMassAt: _pointMass2)
    }
}
