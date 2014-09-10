//
//  GravityComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 30/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents a Gravity component that can be added to a body to make it constantly affected by gravity
class GravityComponent: BodyComponent
{
    var vector: Vector2 = Vector2(0, -9.8);
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        
        for p in body.pointMasses
        {
            p.applyForce(vector * p.mass);
        }
    }
}

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
            comp.vector = self.vector;
        }
    }
}