//
//  GravityComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 30/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents a Gravity component that can be added to a body to make it constantly affected by gravity
public final class GravityComponent: BodyComponent {
    
    /// The gravity vector to apply to the body
    public var gravity = Vector2(0, -9.8)
    
    /// Accumulates the force of gravity by applying a unified force downwards.
    /// This force ignores mass by multiplying the gravity component by mass before
    /// applying the force.
    override public func accumulateExternalForces(on body: Body) {
        super.accumulateExternalForces(on: body)
        
        for point in body.pointMasses {
            point.applyForce(of: gravity * point.mass)
        }
    }
    
    /// Changes the gravity of the bodies on a given world object
    public static func setGravity(on world: World, to vector: Vector2) {
        for b in world.bodies {
            b.component(ofType: GravityComponent.self)?.gravity = vector
        }
    }
}

/// Component that can be added to bodies to add a gravity-like constant force
open class GravityComponentCreator: BodyComponentCreator {
    open var vector: Vector2
    
    public required init(gravity: Vector2 = Vector2(0, -9.8)) {
        vector = gravity
        
        super.init()
        
        bodyComponentClass = GravityComponent.self
    }
    
    open override func prepareBodyAfterComponent(_ body: Body) {
        body.component(ofType: GravityComponent.self)?.gravity = vector
    }
}
