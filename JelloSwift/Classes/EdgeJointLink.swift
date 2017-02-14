//
//  EdgeBodyJointLink.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a joint link that links to an edge of a body
open class EdgeJointLink: JointLinkType {
    /// The first point mass this joint is linked to
    fileprivate let _pointMass1: PointMass
    /// The second point mass this joint is linked to
    fileprivate let _pointMass2: PointMass
    
    /// The ratio of the edge this edge joint is linked to.
    /// Values must range between [0 - 1] inclusive, and dictate the middle point of the edge.
    /// Specifying either 0 or 1 makes this edge joint link behave essentially like a PointJointLink
    open var edgeRatio: CGFloat
    
    /// Gets the body that this joint link is linked to
    open fileprivate(set) var body: Body
    
    /// Gets the type of joint this joint link represents
    open let linkType = LinkType.edge
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    open var position: Vector2 {
        return calculateVectorRatio(_pointMass1.position, vec2: _pointMass2.position, ratio: edgeRatio)
    }
    
    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        return calculateVectorRatio(_pointMass1.velocity, vec2: _pointMass2.velocity, ratio: edgeRatio)
    }
    
    /// Gets the total mass of the subject of this joint link
    open var mass: CGFloat {
        return _pointMass1.mass + _pointMass2.mass
    }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    open var isStatic: Bool {
        return _pointMass1.mass.isInfinite && _pointMass2.mass.isInfinite
    }
    
    /// Inits a new edge joint link with the specified parameters
    public init(body: Body, edgeIndex: Int, edgeRatio: CGFloat = 0.5) {
        self.body = body
        _pointMass1 = body.pointMasses[edgeIndex % body.pointMasses.count]
        _pointMass2 = body.pointMasses[(edgeIndex + 1) % body.pointMasses.count]
        
        self.edgeRatio = edgeRatio
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        _pointMass1.applyForce(of: force * (1 - edgeRatio))
        _pointMass2.applyForce(of: force * (edgeRatio))
    }
}
