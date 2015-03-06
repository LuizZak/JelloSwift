//
//  BaseBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a joint link that links to multiple point masses of a body
class ShapeJointLink: JointLinkType
{
    /// The body that this joint link is linked to
    private var _body: Body;
    
    /// The point masses this joint is linked to
    private var _pointMasses: [PointMass];
    
    /// Gets the body that this joint link is linked to
    var body: Body { return _body; }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { return LinkType.Point }
    
    /// Inits a new point joint link with the specified parameters
    init(body: Body, pointMassIndexes: [Int])
    {
        _body = body;
        _pointMasses = [];
        
        for i in 0..<pointMassIndexes.count
        {
            _pointMasses += _body.pointMasses[i];
        }
    }
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    func getPosition() -> Vector2
    {
        var center = Vector2.Zero;
        
        for p in _pointMasses
        {
            center += p.position;
        }
        
        center /= _pointMasses.count;
        
        return center;
    }
    
    /// Gets the velocity of the object this joint links to
    func getVelocity() -> Vector2
    {
        var totalVel = Vector2.Zero;
        
        for p in _pointMasses
        {
            totalVel += p.velocity;
        }
        
        totalVel /= _pointMasses.count;
        
        return totalVel;
    }
    
    /// Gets the total mass of the subject of this joint link
    func getMass() -> CGFloat
    {
        return _pointMasses.reduce(0, combine: { $0 + $1.mass });
    }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    func isStatic() -> Bool
    {
        for p in _pointMasses
        {
            if(!isinf(p.mass))
            {
                return false;
            }
        }
        
        return true;
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// :param: force A force to apply to the subjects of this joint link
    func applyForce(force: Vector2)
    {
        for p in _pointMasses
        {
            p.applyForce(force);
        }
    }
}