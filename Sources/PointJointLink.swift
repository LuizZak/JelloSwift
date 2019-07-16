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
    fileprivate let _pointMass: PointMass
    
    /// The index of the point mass this joint is linked to
    fileprivate let _pointMassIndex: Int
    
    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body
    
    /// Gets the type of joint this joint link represents
    public let linkType = LinkType.point
    
    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    open var position: Vector2 {
        return _pointMass.position
    }
    
    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        return _pointMass.velocity
    }
    
    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        return _pointMass.mass
    }
    
    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    open var isStatic: Bool {
        return _pointMass.mass.isInfinite
    }

    /// Gets or sets a value specifying whether this joint link supports angling
    /// and torque forces.
    open var supportsAngling: Bool
    
    /// The angle of the joint.
    /// For point joints, this is the normal of the point.
    open var angle: JFloat {
        return _pointMass.normal.angle
    }
    
    /// Inits a new point joint link with the specified parameters
    public init(body: Body, pointMassIndex: Int, supportsAngling: Bool = true) {
        self.body = body
        _pointMass = body.pointMasses[pointMassIndex]
        _pointMassIndex = pointMassIndex
        self.supportsAngling = supportsAngling
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        _pointMass.applyForce(of: force)
    }
    
    /// Applies a torque (rotational) force to the subject of this joint link.
    ///
    /// Torque on point masses is applied by rotating the two adjacent point
    /// masses, such that the normal of the point mass rotates according to the
    /// specified torque force.
    ///
    /// - Parameter force: A torque force to apply to the subject of this joint
    /// link.
    open func applyTorque(_ force: JFloat) {
        let edge1 = body.edges[_pointMassIndex]
        let edge2 = body.edges[(_pointMassIndex + 1) % body.pointMasses.count]
        
        let angle1 = edge1.difference.perpendicular()
        let angle2 = edge2.difference.perpendicular()
        
        body.pointMasses[edge1.startPointIndex].applyForce(of: angle1 * force)
        body.pointMasses[edge2.endPointIndex].applyForce(of: -angle2 * force)
    }
    
    /// Changes the coordinate system of this joint link's components to the one
    /// specified.
    ///
    /// Absolute positional movement is performed for a point mass link.
    open func moveTo(_ position: Vector2) {
        _pointMass.position = position
    }
}
