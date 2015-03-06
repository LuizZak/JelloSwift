//
//  BodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Protocol for body joints which unites two separate bodies
protocol BodyJoint
{
    /// Gets the first body being united by this joint
    var Body1 { get; }
    /// Gets the second body being united by this joint
    var Body2 { get; }
    
    
    /**
     * Resolves this body joint
     *
     * :param: dt The delta time to update the resolve on
     */
    func resolve(dt: NSTimeInterval);
}