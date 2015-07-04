//
//  GravityComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 30/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents a Gravity component that can be added to a body to make it constantly affected by gravity
public final class GravityComponent: BodyComponent
{
    /// The gravity vector to apply to the body
    public var gravity: Vector2 = Vector2(0, -9.8)
    
    override public func accumulateExternalForces()
    {
        super.accumulateExternalForces()
        
        body.pointMasses.forEach { $0.applyForce(gravity * $0.mass) }
    }
    
    /// Changes the gravity of the bodies on a given world object
    public static func setGravityOnWorld(world: World, newGravity: Vector2)
    {
        for b in world.bodies
        {
            b.getComponentType(GravityComponent)?.gravity = newGravity
        }
    }
}

/// Component that can be added to bodies to add a gravity-like constant force
public class GravityComponentCreator: BodyComponentCreator
{
    public var vector: Vector2
    
    public required init(gravity: Vector2 = Vector2(0, -9.8))
    {
        self.vector = gravity
        
        super.init()
        
        self.bodyComponentClass = GravityComponent.self
    }
    
    public override func prepareBodyAfterComponent(body: Body)
    {
        body.getComponentType(GravityComponent)?.gravity = vector
    }
}