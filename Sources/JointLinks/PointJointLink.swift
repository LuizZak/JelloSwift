//
//  BodyJointLinks.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint link that links directly to a point mass of a body
open class PointJointLink: JointLink {
    // This is a very straightforward implementation, it basically delegates the
    // calls to the underlying point mass

    /// The point mass this joint is linked to
    fileprivate let _pointMass: Int

    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body

    /// Gets the type of joint this joint link represents
    public let linkType = LinkType.point

    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    open var position: Vector2 {
        return body.pointMasses[_pointMass].position
    }

    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        return body.pointMasses[_pointMass].velocity
    }

    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        return body.pointMasses[_pointMass].mass
    }

    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    open var isStatic: Bool {
        return body.pointMasses[_pointMass].mass.isInfinite
    }

    /// Inits a new point joint link with the specified parameters
    public init(body: Body, pointMassIndex: Int) {
        self.body = body
        _pointMass = pointMassIndex
    }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        body.applyForce(force, toPointMassAt: _pointMass)
    }

    /// Applies a direct positional translation of this joint link by a given
    /// offset.
    ///
    /// - parameter offset: An offset to apply to the member(s) of this joint link.
    open func translate(by offset: Vector2) {
        body.setPosition(position + offset, ofPointMassAt: _pointMass)
    }
}
