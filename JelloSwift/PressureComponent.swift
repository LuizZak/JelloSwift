//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a Pressure component that can be added to a body to include gas pressure as an internal force
public final class PressureComponent: BodyComponent
{
    // PRIVATE VARIABLES
    public var volume: CGFloat = 0
    public var gasAmmount: CGFloat = 0
    
    override public func prepare(body: Body)
    {
        
    }
    
    override public func accumulateInternalForces(body: Body)
    {
        super.accumulateInternalForces(body)
        
        volume = 0
        
        let c = body.pointMasses.count
        
        if(c < 1)
        {
            return
        }
        
        volume = max(0.5, polygonArea(body.pointMasses))
        
        // now loop through, adding forces!
        let invVolume = 1 / volume
        
        for (i, e) in body.edges.enumerate()
        {
            let j = (i + 1) % c
            let pressureV = (invVolume * e.length * gasAmmount)
            
            body.pointMasses[i].applyForce(body.pointNormals[i] * pressureV)
            body.pointMasses[j].applyForce(body.pointNormals[j] * pressureV)
        }
    }
}

// Creator for the Spring component
public class PressureComponentCreator : BodyComponentCreator
{
    public var gasAmmount: CGFloat
    
    public required init(gasAmmount: CGFloat = 0)
    {
        self.gasAmmount = gasAmmount
        
        super.init()
        
        bodyComponentClass = PressureComponent.self
    }
    
    public override func prepareBodyAfterComponent(body: Body)
    {
        body.getComponentType(PressureComponent)?.gasAmmount = gasAmmount
    }
}