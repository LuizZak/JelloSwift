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
    private let _body: Body;
    
    /// The point masses this joint is linked to
    private let _pointMasses: [PointMass];
    
    /// The indices of this shape joint link
    private let _indices: [Int];
    
    /// Gets the body that this joint link is linked to
    var body: Body { return _body; }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { return LinkType.Shape }
    
    /// The offset to apply to the position of this shape joint, in body coordinates
    var offset: Vector2 = Vector2.Zero;
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    var position: Vector2
    {
        var center = Vector2.Zero;
        
        for p in _pointMasses
        {
            center += p.position;
        }
        
        center /= _pointMasses.count;
        
        // Calculate the offset, if present
        if(offset != Vector2.Zero)
        {
            // Get the angle of the points and calculate their different to the orgiinal shape angle
            center += rotateVector(offset, _body.derivedAngle);
        }
        
        return center;
    }
    
    /// Gets the velocity of the object this joint links to
    var velocity: Vector2
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
    var mass: CGFloat
    {
        return _pointMasses.reduce(0, combine: { $0 + $1.mass });
    }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    var isStatic: Bool
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
    
    /// Inits a new point joint link with the specified parameters
    init(body: Body, pointMassIndexes: [Int])
    {
        _body = body;
        _pointMasses = pointMassIndexes.map { body.pointMasses[$0] };
        _indices = pointMassIndexes;
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
    
    // TODO: Implement the function below to derive the angle of the shape's angle
    
    /// Returns the average angle of the vertices of this ShapeJointLink, based on the body's original shape's vertices
    private func angle() -> CGFloat
    {
        // find the average angle of all of the masses.
        var angle: CGFloat = 0;
        
        var originalSign: Int = 1;
        var originalAngle: CGFloat = 0;
        
        for i in _indices
        {
            let pm = _body.pointMasses[i];
            
            let baseNorm = _body.baseShape.localVertices[i].normalized();
            let curNorm  = (pm.position - _body.derivedPos).normalized();
            
            var dot = baseNorm =* curNorm;
            
            if (dot > 1.0) { dot = 1.0; }
            if (dot < -1.0) { dot = -1.0; }
            
            var thisAngle = acos(dot);
            
            if (!vectorsAreCCW(baseNorm, curNorm)) { thisAngle = -thisAngle; }
            
            if (i == 0)
            {
                originalSign = signbit(thisAngle);
                originalAngle = thisAngle;
            }
            else
            {
                let diff = (thisAngle - originalAngle);
                let thisSign = signbit(thisAngle);
                
                if (abs(diff) > PI && (thisSign != originalSign))
                {
                    thisAngle = (thisSign == -1) ? (PI + (PI + thisAngle)) : ((PI - thisAngle) - PI);
                }
            }
            
            angle += thisAngle;
        }
        
        angle /= CGFloat(_pointMasses.count);
        
        return angle;
    }
}