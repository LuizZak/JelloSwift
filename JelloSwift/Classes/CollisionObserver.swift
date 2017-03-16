//
//  CollisionObserver.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 24/04/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Protocol to be implemented by objects that want to be notified of all
/// collisions in a physics World
public protocol CollisionObserver: class {
    /**
     Called by the World to notify of a body collision
    
     - parameter info: The information for the collision
     */
    func bodiesDidCollide(_ info: BodyCollisionInformation)
    
    /// Called to notify that the given body collision information has exceeded
    /// a minimum specified penetration threshold.
    /// When this happens, the collision is ignored and dropped from the resolve
    /// list, and this delegate notifier is called.
    func bodyCollision(_ info: BodyCollisionInformation, didExceedPenetrationThreshold penetrationThreshold: JFloat)
}

public extension CollisionObserver {
    
    public func bodiesDidCollide(_ info: BodyCollisionInformation) {
        
    }
    
    public func bodyCollision(_ info: BodyCollisionInformation, didExceedPenetrationThreshold penetrationThreshold: JFloat) {
        
    }
}
