//
//  PointMass.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Specifies a point mass that composes a body
public final class PointMass
{
    /// The mass of this point mass.
    /// Leave this value always >0 to maintain consistency on the simulation, unless
    /// the point is supposed to be fixed.
    /// Values < 0.2 usually cause inconsistency and instability in the simulation
    public var mass: CGFloat = 1
    
    /// The global position of the point, in world coordinates
    public var position: Vector2 = Vector2.Zero
    /// The global velocity of the point mass
    public var velocity: Vector2 = Vector2.Zero
    /// The global force of the point mass
    public var force: Vector2 = Vector2.Zero
    
    public init(mass: CGFloat = 0, position: Vector2 = Vector2.Zero)
    {
        self.mass = mass
        self.position = position
    }
    
    /// Integrates a single physics simulation step for this point mass
    ///
    /// - parameter elapsed: The elapsed time to integrate by, usually in seconds
    public func integrate(elapsed: CGFloat)
    {
        if (mass != CGFloat.infinity)
        {
            let elapMass = elapsed / mass
            
            velocity += force * elapMass
            
            position += (velocity * elapsed)
        }
        
        force = Vector2.Zero
    }
    
    // Applies the given force vector to this point mass
    public func applyForce(force: Vector2)
    {
        self.force += force
    }
}