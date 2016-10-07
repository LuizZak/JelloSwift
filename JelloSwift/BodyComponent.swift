//
//  BodyComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a component that can be added to a body to change it's physical characteristics
open class BodyComponent
{
    // Initializes a new instance of the BodyComponent class
    public required init(body: Body)
    {
        
    }
    
    // Makes the body component prepare itself after it has been added to a body
    open func prepare(_ body: Body)
    {
        
    }
    
    // This function should add all internal forces to the Force member variable of each PointMass in the body.
    // These should be forces that try to maintain the shape of the body.
    open func accumulateInternalForces(_ body: Body)
    {
        
    }
    
    // This function should add all external forces to the Force member variable of each PointMass in the body.
    // These are external forces acting on the PointMasses, such as gravity, etc.
    open func accumulateExternalForces(_ body: Body)
    {
        
    }
}

// Used to create body components into the body
open class BodyComponentCreator
{
    open var bodyComponentClass: BodyComponent.Type = BodyComponent.self
    
    open func attachToBody(_ body: Body)
    {
        body.addComponentType(bodyComponentClass)
        
        prepareBodyAfterComponent(body)
    }
    
    open func prepareBodyAfterComponent(_ body: Body)
    {
        
    }
}
