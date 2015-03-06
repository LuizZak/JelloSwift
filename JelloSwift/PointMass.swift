//
//  PointMass.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Specifies a point mass that composes a body
class PointMass: NSObject
{
    // The mass of this point mass.
    // Leave this value always >0 to maintain consistency on the simulation, unless
    // the point is supposed to fixed
    var mass: CGFloat = 1;
    
    // The spatial information for the point mass
    var position: Vector2 = Vector2();
    var velocity: Vector2 = Vector2();
    var force: Vector2 = Vector2();
    
    init(mass: CGFloat = 0, position: Vector2 = Vector2())
    {
        self.mass = mass;
        self.position = position;
        super.init();
    }
    
    // Integrates a single physics simulation step for this point mass
    func integrate(elapsed: CGFloat)
    {
        if (mass != CGFloat.infinity)
        {
            let elapMass = elapsed / mass;
            
            velocity += force * elapMass;
            
            position += (velocity * elapsed);
        }
        
        force = Vector2();
    }
    
    // Applies the given force vector to this point mass
    func applyForce(force: Vector2)
    {
        self.force += force;
    }
}