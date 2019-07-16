//
//  BodyJointLink.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint link that links to a while body
open class BodyJointLink: JointLink {
    // Like the PointJointLink, this is a very straightforward implementation,
    // delegating most of the methods to the underlying body object
    
    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body
    
    /// Gets the type of joint this joint link represents
    public let linkType = LinkType.body

    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    open var position: Vector2 {
        return body.derivedPos
    }
    
    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        return body.derivedVel
    }
    
    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        return body.pointMasses.reduce(0) { $0 + $1.mass }
    }

    /// Gets or sets a value specifying whether this joint link supports angling
    /// and torque forces.
    open var supportsAngling: Bool
    
    /// Gets a value specifying whether the object referenced by this 
    /// JointLinkType is static
    open var isStatic: Bool {
        return body.isStatic || body.isPined
    }
    
    open var angle: JFloat {
        return body.derivedAngle
    }
    
    /// Inits a new body joint link with the specified parameters
    public init(body: Body, supportsAngling: Bool = true) {
        self.body = body
        self.supportsAngling = supportsAngling
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        body.applyForce(force, atGlobalPoint: position)
    }
    
    /// Applies a torque (rotational) force to the subject of this joint link.
    ///
    /// - Parameter force: A torque force to apply to the subject of this joint
    /// link.
    open func applyTorque(_ force: JFloat) {
        body.applyTorque(of: force)
    }
    
    /// Changes the coordinate system of this joint link's components to the one
    /// specified.
    ///
    /// Relative positional movement is performed across the entire body for a
    /// body link.
    open func moveTo(_ position: Vector2) {
        let relative = position - self.position
        for pointMass in body.pointMasses {
            pointMass.position += relative
        }
    }
}
