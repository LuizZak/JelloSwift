//
//  BodyJointLink.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a joint link that links to a while body
public class BodyJointLink: JointLinkType
{
    // Like the PointJointLink, this is a very straightforward implementation, delegating most of the methods to the underlying body object
    
    /// Gets the body that this joint link is linked to
    public private(set) var body: Body
    
    /// Gets the type of joint this joint link represents
    public let linkType: LinkType = LinkType.Body
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    public var position: Vector2
    {
        return body.derivedPos
    }
    
    /// Gets the velocity of the object this joint links to
    public var velocity: Vector2
    {
        return body.derivedVel
    }
    
    /// Gets the total mass of the subject of this joint link
    public var mass: CGFloat
    {
        return body.pointMasses.reduce(0, combine: { $0 + $1.mass })
    }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    public var isStatic: Bool
    {
        return body.isStatic || body.isPined
    }
    
    /// Inits a new body joint link with the specified parameters
    public init(body: Body)
    {
        self.body = body
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    public func applyForce(force: Vector2)
    {
        self.body.addGlobalForce(position, force)
    }
}