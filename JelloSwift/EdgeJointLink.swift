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
class EdgeJointLink: JointLinkType
{
    /// The body that this joint link is linked to
    private var _body: Body;
    
    /// The first point mass this joint is linked to
    private var _pointMass1: PointMass;
    /// The second point mass this joint is linked to
    private var _pointMass2: PointMass;
    
    /// The ratio of the edge this edge joint is linked to.
    /// Values must range between [0 - 1] inclusive, and dictate the middle point of the edge.
    /// Specifying either 0 or 1 makes this edge joint link behave essentially like a PointJointLink
    var edgeRatio: CGFloat;
    
    /// Gets the body that this joint link is linked to
    var body: Body { return _body; }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { return LinkType.Edge }
    
    /// Inits a new edge joint link with the specified parameters
    init(body: Body, edgeIndex: Int, edgeRatio: CGFloat = 0.5)
    {
        _body = body;
        _pointMass1 = _body.pointMasses[(edgeIndex / 2) % _body.pointMasses.count];
        _pointMass2 = _body.pointMasses[(edgeIndex / 2 + 1) % _body.pointMasses.count];
        
        self.edgeRatio = edgeRatio;
    }
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    func getPosition() -> Vector2
    {
        return calculateVectorRatio(_pointMass1.position, _pointMass2.position, edgeRatio);
    }
    
    /// Gets the velocity of the object this joint links to
    func getVelocity() -> Vector2
    {
        return calculateVectorRatio(_pointMass1.velocity, _pointMass2.velocity, edgeRatio);
    }
    
    /// Gets the total mass of the subject of this joint link
    func getMass() -> CGFloat
    {
        return _pointMass1.mass + (_pointMass2.mass - _pointMass1.mass) * edgeRatio;
    }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// :param: force A force to apply to the subjects of this joint link
    func applyForce(force: Vector2)
    {
        _pointMass1.applyForce(force * (1 - edgeRatio));
        _pointMass1.applyForce(force * (1 - edgeRatio));
    }
}