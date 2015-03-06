//
//  BodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

func ==(lhs: BodyJoint, rhs: BodyJoint) -> Bool
{
    return lhs === rhs;
}

/// Base class for joints which unites two separate bodies
class BodyJoint: Equatable
{
    /// Gets the first link that contins informationa bout the first body linked by this joint
    internal var _bodyLink1: JointLinkType;
    /// Gets the second link that contins informationa bout the first body linked by this joint
    internal var _bodyLink2: JointLinkType;
    
    /// Whether to allow collisions between the two objects joined by this BodyJoint.
    /// Defaults to false
    var allowCollisions: Bool = false;
    
    /// Gets the first link that contins informationa bout the first body linked by this joint
    var bodyLink1: JointLinkType { return _bodyLink1 }
    /// Gets the second link that contins informationa bout the first body linked by this joint
    var bodyLink2: JointLinkType { return _bodyLink2 }
    
    /// Gets or sets the rest distance for this joint
    var restDistance: CGFloat
    
    init(world: World, link1: JointLinkType, link2: JointLinkType, distance: CGFloat = -1)
    {
        _bodyLink1 = link1;
        _bodyLink2 = link2;
        
        // Automatic distance calculation
        if(distance == -1)
        {
            restDistance = link1.getPosition().distanceTo(link2.getPosition());
        }
        else
        {
            restDistance = distance;
        }
        
        world.addJoint(self);
    }
    
    /**
     * Resolves this joint
     *
     * :param: dt The delta time to update the resolve on
     */
    func resolve(dt: CGFloat)
    {
        
    }
}

/// Protocol to be implemented by objects that specify the way a joint links with a body
protocol JointLinkType
{
    /// Gets the body that this joint link is linked to
    var body: Body { get }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { get }
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    func getPosition() -> Vector2;
    
    /// Gets the velocity of the object this joint links to
    func getVelocity() -> Vector2;
    
    /// Gets the total mass of the subject of this joint link
    func getMass() -> CGFloat;
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    func isStatic() -> Bool;
    
    /// Appies a given force to the subject of this joint link
    ///
    /// :param: force A force to apply to the subjects of this joint link
    func applyForce(force: Vector2);
}

/// The type of joint link of a BodyJointLink class
enum LinkType
{
    /// Specifies that the joint links at the whole body, relative to the center
    case Body
    /// Specifies that the joint links at a body's point
    case Point
    /// Specifies that the joint links at a body's edge (set of two points)
    case Edge
    /// Specifies that the joint links at an arbitrary set of points of a body
    case Shape
}