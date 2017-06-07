//
//  BodyComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents a component that can be added to a body to change it's physical
/// characteristics
public protocol BodyComponent {
    /// Initializes a new instance of the BodyComponent class
    init(body: Body)
    
    /// Makes the body component prepare itself after it has been added to a 
    /// body
    func prepare(_ body: Body)
    
    /// This function should add all internal forces to the Force member
    /// variable of each PointMass in the body.
    /// These should be forces that try to maintain the shape of the body.
    func accumulateInternalForces(in body: Body)
    
    /// This function should add all external forces to the Force member
    /// variable of each PointMass in the body.
    /// These are external forces acting on the PointMasses, such as gravity, 
    /// etc.
    func accumulateExternalForces(on body: Body)
}

extension BodyComponent {
    public func prepare(_ body: Body) {
        
    }
    
    public func accumulateInternalForces(in body: Body) {
        
    }
    
    public func accumulateExternalForces(on body: Body) {
        
    }
}

/// Used to create body components into the body
public protocol BodyComponentCreator {
    var bodyComponentClass: BodyComponent.Type { get }
    
    /// Creates and attaches the component to a given body
    func attach(to body: Body)
    
    /// Performs post-attachment configurations to a body.
    /// called by `attach(to:)`
    func prepareBodyAfterComponent(_ body: Body)
}

public extension BodyComponentCreator {
    /// Creates and attaches the component to a given body
    public func attach(to body: Body) {
        body.addComponent(ofType: bodyComponentClass)
        
        prepareBodyAfterComponent(body)
    }
    
    /// Performs post-attachment configurations to a body.
    /// called by `attach(to:)`
    public func prepareBodyAfterComponent(_ body: Body) {
        
    }
}
