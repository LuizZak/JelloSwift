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
public class ShapeJointLink: JointLinkType
{
    /// The body that this joint link is linked to
    private let _body: Body;
    
    /// The point masses this joint is linked to
    private let _pointMasses: [PointMass];
    
    /// The indices of this shape joint link
    private let _indices: [Int];
    
    /// Gets the body that this joint link is linked to
    public var body: Body { return _body; }
    
    /// Gets the type of joint this joint link represents
    public var linkType: LinkType { return LinkType.Shape }
    
    /// The offset to apply to the position of this shape joint, in body coordinates
    public var offset: Vector2 = Vector2.Zero;
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    public var position: Vector2
    {
        var center = Vector2.Zero;
        
        for p in _pointMasses
        {
            center += p.position;
        }
        
        center /= _pointMasses.count;
        center += offsetPosition;
        
        return center;
    }
    
    /// Offset position, calculated based on the owning body's angle
    private var offsetPosition: Vector2
    {
        if(offset == Vector2.Zero)
        {
            return Vector2.Zero;
        }
        
        return rotateVector(offset, _body.derivedAngle);
    }
    
    /// Gets the velocity of the object this joint links to
    public var velocity: Vector2
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
    public var mass: CGFloat
    {
        return _pointMasses.reduce(0, combine: { $0 + $1.mass });
    }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    public var isStatic: Bool
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
    public init(body: Body, pointMassIndexes: [Int])
    {
        _body = body;
        _pointMasses = pointMassIndexes.map { body.pointMasses[$0] };
        _indices = pointMassIndexes;
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// :param: force A force to apply to the subjects of this joint link
    public func applyForce(var force: Vector2)
    {
        let torqueF = offsetPosition =* force.perpendicular();
        
        for p in _pointMasses
        {
            let tempR = (p.position - position + offsetPosition).perpendicular();
            
            p.force += tempR * torqueF;
            p.force += force;
        }
    }
    
    // TODO: Implement the function below to derive the angle of the shape's angle
    
    /// Returns the average angle of the vertices of this ShapeJointLink, based on the body's original shape's vertices
    private func angle() -> CGFloat
    {
        var angle: CGFloat = 0;
        
        var originalSign: Int = 1;
        var originalAngle: CGFloat = 0;
        
        for i in _indices
        {
            let pm = _body.pointMasses[i];
            
            let baseNorm = _body.baseShape.localVertices[i].normalized();
            let curNorm  = (pm.position - _body.derivedPos).normalized();
            
            var thisAngle = atan2(baseNorm.X * curNorm.Y - baseNorm.Y * curNorm.X, baseNorm =* curNorm);
            
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