//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

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
    fileprivate(set) public var volume: JFloat = 0
    
    /// The gass pressure coefficient for the pressure component.
    /// Higher values result in higher expansion and resistance to compression.
    public var gasAmmount: JFloat = 0
    
    public init() {
        
    }
    
    public func accumulateInternalForces(in body: Body, relaxing: Bool) {
        if body.pointMasses.count < 1 {
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
            
            pointStart.applyForce(of: pointStart.normal * pressureV)
            pointEnd.applyForce(of: pointEnd.normal * pressureV)
        }
    }
    
    public func accumulateExternalForces(on body: Body, world: World, relaxing: Bool) {
        
    }
}

// Creator for the Spring component
public struct PressureComponentCreator: BodyComponentCreator, Codable {
    
    public static var bodyComponentClass: BodyComponent.Type = PressureComponent.self
    
    /// The gass pressure coefficient for the pressure component.
    /// Higher values result in higher resistance to compression and higher
    /// expansion.
    public var gasAmmount: JFloat
    
    public init(gasAmmount: JFloat = 0) {
        self.gasAmmount = gasAmmount
    }
    
    public func prepareBodyAfterComponent(_ body: Body) {
        body.component(ofType: PressureComponent.self)?.gasAmmount = gasAmmount
    }
}
