//
//  SpringBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

class SpringBodyJoint : BodyJoint
{
    /// Gets the first link that contins informationa bout the first body linked by this joint
    private var _bodyLink1: JointLinkType;
    /// Gets the second link that contins informationa bout the first body linked by this joint
    private var _bodyLink2: JointLinkType;
    
    /// Gets the first link that contins informationa bout the first body linked by this joint
    var bodyLink1: JointLinkType { return _bodyLink1 }
    /// Gets the second link that contins informationa bout the first body linked by this joint
    var bodyLink2: JointLinkType { return _bodyLink2 }
    
    /// Gets or sets the rest distance for this joint
    var restDistance: CGFloat;
    
    /// The spring coefficient for this spring body joint
    var springK: CGFloat;
    /// The spring dampness for this spring body joint
    var springD: CGFloat;
    
    /// Inits a new spring body joint witht he specified parameters. Leave the distance as -1 to calculate the distance automatically from the current distance of the two provided joint links
    init(link1: JointLinkType, link2: JointLinkType, springK: CGFloat, springD: CGFloat, distance: CGFloat = -1)
    {
        _bodyLink1 = link1;
        _bodyLink2 = link2;
        self.springK = springK;
        self.springD = springD;
        
        // Automatic distance calculation
        if(distance == -1)
        {
            restDistance = link1.getPosition().distanceTo(link2.getPosition());
        }
        else
        {
            restDistance = distance;
        }
    }
    
    /**
     * Resolves this joint
     *
     * :param: dt The delta time to update the resolve on
    */
    func resolve(dt: NSTimeInterval)
    {
        let pos1 = _bodyLink1.getPosition();
        let pos2 = _bodyLink2.getPosition();
        
        let force = calculateSpringForce(pos1, _bodyLink1.getVelocity(), pos2, _bodyLink2.getVelocity(), restDistance, springK, springD);
        
        _bodyLink1.applyForce(force);
        _bodyLink2.applyForce(-force);
    }
}