//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents a Pressure component that can be added to a body to include gas
/// pressure as an internal force.
/// This component applies an outwards force in the body that tries to expand
/// the contents of the body, resulting in resistance to compression and
/// expansion past the rest shape of the body, like a balloon.
public final class PressureComponent: BodyComponent {
    
    /// The total volume of the body, as was calculated during the previous
    /// internal force accumulation step.
    /// Equal the polygonal area of the body's point masses.
    /// Is clamped to always be be >= 0.5
    fileprivate(set) public var volume: CGFloat = 0
    
    /// The gass pressure coefficient for the pressure component.
    /// Higher values result in higher expansion and resistance to compression.
    public var gasAmmount: CGFloat = 0
    
    override public func prepare(_ body: Body) {
        
    }
    
    override public func accumulateInternalForces(in body: Body) {
        super.accumulateInternalForces(in: body)
        
        if(body.pointMasses.count < 1) {
            volume = 0
            return
        }
        
        volume = max(0.5, polygonArea(of: body.pointMasses))
        
        // now loop through, adding forces!
        let invVolume = 1 / volume
        
        for e in body.edges {
            let pressureV = (invVolume * e.length * gasAmmount)
            
            let pointStart = body.pointMasses[e.startPointIndex]
            let pointEnd = body.pointMasses[e.endPointIndex]
            
            pointStart.applyForce(of: body.pointNormals[e.startPointIndex] * pressureV)
            pointEnd.applyForce(of: body.pointNormals[e.endPointIndex] * pressureV)
        }
    }
}

// Creator for the Spring component
public struct PressureComponentCreator : BodyComponentCreator {
    
    public var bodyComponentClass: BodyComponent.Type = PressureComponent.self
    
    /// The gass pressure coefficient for the pressure component.
    /// Higher values result in higher resistance to compression and higher
    /// expansion.
    public var gasAmmount: CGFloat
    
    public init(gasAmmount: CGFloat = 0) {
        self.gasAmmount = gasAmmount
    }
    
    public func prepareBodyAfterComponent(_ body: Body) {
        body.component(ofType: PressureComponent.self)?.gasAmmount = gasAmmount
    }
}
