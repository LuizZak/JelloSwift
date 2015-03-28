//
//  GravityComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 30/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents a Gravity component that can be added to a body to make it constantly affected by gravity
class GravityComponent: BodyComponent
{
    /// The gravity vector to apply to the body
    final var gravity: Vector2 = Vector2(0, -9.8);
    
    override func accumulateExternalForces()
    {
        super.accumulateExternalForces();
        
        /*
        for p in body.pointMasses
        {
            p.applyForce(vector * p.mass);
        }
        */
        
        for var i = 0; i < body.pointMasses.count; i++
        {
            body.pointMasses[i].applyForce(gravity * body.pointMasses[i].mass);
        }
    }
    
    /// Changes the gravity of the bodies on a given world object
    static func setGravityOnWorld(world: World, newGravity: Vector2)
    {
        for b in world.bodies
        {
            if let g = b.getComponentType(GravityComponent)
            {
                g.gravity = newGravity;
            }
        }
    }
}

/// Component that can be added to bodies to add a gravity-like constant force
class GravityComponentCreator: BodyComponentCreator
{
    var vector: Vector2;
    
    required init(gravity: Vector2 = Vector2(0, -9.8))
    {
        self.vector = gravity;
        
        super.init();
        
        self.bodyComponentClass = GravityComponent.self;
    }
    
    override func prepareBodyAfterComponent(body: Body)
    {
        if let comp = body.getComponentType(GravityComponent)
        {
            comp.gravity = self.vector;
        }
    }
}