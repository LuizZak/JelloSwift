//
//  CollisionObserver.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 24/04/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Protocol to be implemented by objects that want to be notified of all collisions in a physics World
public protocol CollisionObserver
{
    /**
     Called by the World to notify of a body collision
    
     - parameter info: The information for the collision
     */
    func bodiesDidCollide(_ info: BodyCollisionInformation)
}
