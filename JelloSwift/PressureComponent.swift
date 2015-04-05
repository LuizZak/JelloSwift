//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a Pressure component that can be added to a body to include gas pressure as an internal force
class PressureComponent: BodyComponent
{
    // PRIVATE VARIABLES
    final var volume: CGFloat = 0;
    final var gasAmmount: CGFloat = 0;
    final var normalList: [Vector2] = [];
    final var edgeLengthList: [CGFloat] = [];
    
    override func prepare(body: Body)
    {
        normalList = [Vector2](count: body.pointMasses.count, repeatedValue: Vector2());
        edgeLengthList = [CGFloat](count: body.pointMasses.count, repeatedValue: 0);
    }
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        // internal forces based on pressure equations.  we need 2 loops to do this.  one to find the overall volume of the
        // body, and 1 to apply forces. we will need the normals for the edges in both loops, so we will cache them and remember them.
        volume = 0;
        
        let c = body.pointMasses.count;
        var prev = c - 1;
        var points = [Vector2](count: c, repeatedValue: Vector2());
        
        for (i, curEdge) in enumerate(body.edges)
        {
            let prev = (i - 1) < 0 ? c - 1 : i - 1;
            
            let edge1N = body.edges[prev].difference;
            let edge2N = curEdge.difference;
            
            normalList[i] = (edge1N + edge2N).perpendicular().normalized();
            edgeLengthList[i] = curEdge.length;
            
            points[i] = curEdge.start;
        }
        
        volume = max(0.5, polygonArea(points));
        
        // now loop through, adding forces!
        let invVolume: CGFloat = 1 / volume;
        
        for var i = 0; i < c; i++
        {
            let j = (i + 1) % c;
            let pressureV = (invVolume * edgeLengthList[i] * (gasAmmount));
            
            body.pointMasses[i].force += normalList[i] * pressureV;
            body.pointMasses[j].force += normalList[j] * pressureV;
        }
    }
}

// Creator for the Spring component
class PressureComponentCreator : BodyComponentCreator
{
    var gasAmmount: CGFloat;
    
    required init(gasAmmount: CGFloat = 0)
    {
        self.gasAmmount = gasAmmount;
        
        super.init();
        
        self.bodyComponentClass = PressureComponent.self;
    }
    
    override func prepareBodyAfterComponent(body: Body)
    {
        if let comp = body.getComponentType(PressureComponent)
        {
            comp.gasAmmount = self.gasAmmount;
        }
    }
}