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
    public var gravity = Vector2(0, -9.8)
    
    override public func accumulateExternalForces(_ body: Body)
    {
        super.accumulateExternalForces(body)
        
        body.pointMasses.forEach { $0.applyForce(gravity * $0.mass) }
    }
    
    /// Changes the gravity of the bodies on a given world object
    public static func setGravityOnWorld(_ world: World, newGravity: Vector2)
    {
        for b in world.bodies
        {
            b.getComponentType(GravityComponent.self)?.gravity = newGravity
        }
    }
}

/// Component that can be added to bodies to add a gravity-like constant force
open class GravityComponentCreator: BodyComponentCreator
{
    open var vector: Vector2
    
    public required init(gravity: Vector2 = Vector2(0, -9.8))
    {
        vector = gravity
        
        super.init()
        
        bodyComponentClass = GravityComponent.self
    }
    
    open override func prepareBodyAfterComponent(_ body: Body)
    {
        body.getComponentType(GravityComponent.self)?.gravity = vector
    }
}
