//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a Pressure component that can be added to a body to include gas pressure as an internal force
public class PressureComponent: BodyComponent
{
    // PRIVATE VARIABLES
    public final var volume: CGFloat = 0;
    public final var gasAmmount: CGFloat = 0;
    public final var normalList: [Vector2] = [];
    
    override public func prepare(body: Body)
    {
        normalList = [Vector2](count: body.pointMasses.count, repeatedValue: Vector2());
    }
    
    override public func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        // internal forces based on pressure equations.  we need 2 loops to do this.  one to find the overall volume of the
        // body, and 1 to apply forces. we will need the normals for the edges in both loops, so we will cache them and remember them.
        volume = 0;
        
        let c = body.pointMasses.count;
        
        if(c < 1)
        {
            return;
        }
        
        var prev = c - 1;
        var edge1N = body.edges.last!.difference;
        
        for var i = 0; i < c; i++
        {
            let edge2N = body.edges[i].difference;
            
            normalList[i] = (edge1N + edge2N).perpendicular().normalized();
            
            edge1N = edge2N;
        }
        
        volume = max(0.5, polygonArea(body.pointMasses));
        
        // now loop through, adding forces!
        let invVolume = 1 / volume;
        
        for i in 0..<c
        {
            let j = (i + 1) % c;
            let pressureV = (invVolume * body.edges[i].length * (gasAmmount));
            
            body.pointMasses[i].force += normalList[i] * pressureV;
            body.pointMasses[j].force += normalList[j] * pressureV;
        }
    }
}

// Creator for the Spring component
public class PressureComponentCreator : BodyComponentCreator
{
    public var gasAmmount: CGFloat;
    
    public required init(gasAmmount: CGFloat = 0)
    {
        self.gasAmmount = gasAmmount;
        
        super.init();
        
        self.bodyComponentClass = PressureComponent.self;
    }
    
    public override func prepareBodyAfterComponent(body: Body)
    {
        if let comp = body.getComponentType(PressureComponent)
        {
            comp.gasAmmount = self.gasAmmount;
        }
    }
}